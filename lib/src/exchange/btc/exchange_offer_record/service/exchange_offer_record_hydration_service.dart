import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/exchange_offer_record/exceptions/invalid_exchange_public_key_exception.dart';
import 'package:chia_crypto_utils/src/exchange/btc/exchange_offer_record/exceptions/missing_message_coin_child_exception.dart';

class ExchangeOfferRecordHydrationService {
  ExchangeOfferRecordHydrationService(this.fullNode);

  final ChiaFullNodeInterface fullNode;
  ExchangeOfferService get exchangeOfferService => ExchangeOfferService(fullNode);

  Future<ExchangeOfferRecord> hydrateExchangeInitializationCoin(
    Coin initializationCoin,
    PrivateKey masterPrivateKey,
    WalletKeychain keychain,
  ) async {
    final initializationCoinId = initializationCoin.id;

    final exchangeCoins =
        await fullNode.getCoinsByHint(Puzzlehash(initializationCoinId), includeSpentCoins: true);

    late final CoinSpend? initializationCoinSpend;
    late final DateTime? initializedTime;
    late final int? derivationIndex;
    late final PrivateKey? requestorPrivateKey;
    late final String? serializedOfferFile;
    late final MakerCrossChainOfferFile? offerFile;
    try {
      initializationCoinSpend = await fullNode.getCoinSpend(initializationCoin);
      initializedTime =
          await fullNode.getDateTimeFromBlockIndex(initializationCoin.spentBlockIndex);

      final memos = await initializationCoinSpend!.memos;
      derivationIndex = decodeInt(memos.first);

      final wallectVector =
          await WalletVector.fromPrivateKeyAsync(masterPrivateKey, derivationIndex);
      requestorPrivateKey = wallectVector.childPrivateKey;

      serializedOfferFile = memos[1].decodedString;
      offerFile = await MakerCrossChainOfferFile.fromSerializedOfferFileAsync(
        serializedOfferFile!,
      );
    } catch (e) {
      LoggingContext().error(e.toString());
      throw InvalidInitializationCoinException();
    }

    final exchangeType = offerFile.exchangeType;
    const exchangeRole = ExchangeRole.maker;

    final mojos = offerFile.mojos;
    final satoshis = offerFile.satoshis;
    final messagePuzzlehash = offerFile.messageAddress.toPuzzlehash();
    final offerValidityTime = offerFile.validityTime;
    final requestorPublicKey = offerFile.publicKey;
    final requestorLightningPaymentRequest = offerFile.lightningPaymentRequest;

    // check whether offer was submitted to dexie
    var submittedToDexie = false;
    final dexieId = generateDexieId(serializedOfferFile);
    final dexieResponse = await DexieApi().inspectOffer(dexieId);
    if (dexieResponse.success && dexieResponse.offerJson != null) {
      submittedToDexie = true;
    }

    // check whether the 3 mojo addition from the initialization coin spend was spent, indicating cancelation
    final cancelCoin =
        await exchangeOfferService.getCancelCoin(initializationCoin, messagePuzzlehash);
    late final DateTime? canceledTime;
    if (cancelCoin.isSpent) {
      canceledTime = await fullNode.getDateTimeFromBlockIndex(cancelCoin.spentBlockIndex);
    } else {
      canceledTime = null;
    }

    final exchangeOfferRecord = ExchangeOfferRecord(
      initializationCoinId: initializationCoinId,
      derivationIndex: derivationIndex,
      type: exchangeType,
      role: exchangeRole,
      mojos: mojos,
      satoshis: satoshis,
      messagePuzzlehash: messagePuzzlehash,
      requestorPublicKey: requestorPublicKey,
      offerValidityTime: offerValidityTime,
      serializedMakerOfferFile: serializedOfferFile,
      lightningPaymentRequest: requestorLightningPaymentRequest,
      submittedToDexie: submittedToDexie,
      initializedTime: initializedTime,
      canceledTime: canceledTime,
    );

    // look for message coins
    final messageCoins = await fullNode.scroungeForReceivedNotificationCoins([messagePuzzlehash]);

    if (messageCoins.isEmpty) {
      // still waiting for taker
      return exchangeOfferRecord;
    }

    final messageCoinInfos = <MessageCoinInfo>[];
    for (final messageCoin in messageCoins) {
      final messageCoinInfo = await exchangeOfferService.parseAndValidateReceivedMessageCoin(
        messageCoin: messageCoin,
        initializationCoinId: initializationCoinId,
        serializedOfferFile: serializedOfferFile,
        messagePuzzlehash: messagePuzzlehash,
        exchangeType: exchangeType,
        satoshis: satoshis,
      );

      if (messageCoinInfo != null) {
        if (messageCoinInfo.messageCoinDeclinedTime == null) {
          messageCoinInfos.add(messageCoinInfo);

          // if accepted message coin is found, stop searching
          if (messageCoinInfo.messageCoinAcceptedTime != null) break;
        }
      }
    }

    if (messageCoinInfos.isEmpty) {
      // still waiting for valid message coin
      return exchangeOfferRecord;
    }

    final messageCoinInfo = messageCoinInfos.last;

    final serializedOfferAcceptFile = messageCoinInfo.serializedOfferAcceptFile;
    final fulfillerPublicKey = messageCoinInfo.fulfillerPublicKey;
    final exchangeValidityTime = messageCoinInfo.exchangeValidityTime;
    final lightningPaymentRequest =
        requestorLightningPaymentRequest ?? messageCoinInfo.lightningPaymentRequest!;

    final messageCoinReceivedTime = messageCoinInfo.messageCoinReceivedTime;

    // generate escrow puzzlehash from initial offer file and offer accept file from message coin
    final escrowPuzzlehash = offerFile.getEscrowPuzzlehash(
      requestorPrivateKey: requestorPrivateKey,
      clawbackDelaySeconds: exchangeValidityTime,
      sweepPaymentHash: lightningPaymentRequest.paymentHash!,
      fulfillerPublicKey: fulfillerPublicKey,
    );

    final exchangeOfferRecordWithMessageCoin = exchangeOfferRecord.copyWith(
      lightningPaymentRequest: lightningPaymentRequest,
      messageCoinId: messageCoinInfo.id,
      serializedTakerOfferFile: serializedOfferAcceptFile,
      fulfillerPublicKey: fulfillerPublicKey,
      escrowPuzzlehash: escrowPuzzlehash,
      exchangeValidityTime: exchangeValidityTime,
      messageCoinReceivedTime: messageCoinReceivedTime,
      messageCoinAcceptedTime: messageCoinInfo.messageCoinAcceptedTime,
    );

    if (messageCoinInfo.messageCoinAcceptedTime == null) {
      // exchange offer has valid message coin pending acceptance
      return exchangeOfferRecordWithMessageCoin;
    }

    final escrowCoins = exchangeCoins.where((coin) => coin.puzzlehash == escrowPuzzlehash).toList();

    final toRemove = <Coin>[];
    for (final escrowCoin in escrowCoins) {
      final validation = await validateExchangeCoin(
        coin: escrowCoin,
        requestorPublicKey: requestorPublicKey,
        fulfillerPublicKey: fulfillerPublicKey,
      );

      if (!validation) {
        toRemove.add(escrowCoin);
      }
    }

    escrowCoins.removeWhere(toRemove.contains);

    if (escrowCoins.totalValue < mojos) {
      // escrow transfer has not been completed yet
      return exchangeOfferRecordWithMessageCoin;
    }

    // escrow transfer has been completed
    final escrowCoinId = escrowCoins.first.id;
    final parentCoin = await fullNode.getCoinById(escrowCoins.first.parentCoinInfo);
    final escrowTransferCompletedBlockIndex = parentCoin!.spentBlockIndex;
    final escrowTransferCompletedTime =
        await fullNode.getDateTimeFromBlockIndex(escrowTransferCompletedBlockIndex);

    final escrowTransferConfirmedTime = await getConfirmedTime(escrowTransferCompletedBlockIndex);

    final exchangeOfferRecordAfterEscrowTransfer = exchangeOfferRecordWithMessageCoin.copyWith(
      escrowCoinId: escrowCoinId,
      escrowTransferCompletedTime: escrowTransferCompletedTime,
      escrowTransferConfirmedTime: escrowTransferConfirmedTime,
    );

    final spentEscrowCoins = escrowCoins.where((coin) => coin.isSpent).toList();

    if (spentEscrowCoins.totalValue < mojos) {
      // escrow coins have not been swept or clawed back yet
      return exchangeOfferRecordAfterEscrowTransfer;
    }

    // escrow coins have been swept or clawed back
    final completedBlockIndex = spentEscrowCoins.first.spentBlockIndex;

    final completedTime = await fullNode.getDateTimeFromBlockIndex(completedBlockIndex);
    final confirmedTime = await getConfirmedTime(completedBlockIndex);

    final requestorSpentEscrowCoins = await didRequestorSpendEscrowCoins(
      spentEscrowCoin: spentEscrowCoins.first,
      requestorPublicKey: requestorPublicKey,
      fulfillerPublicKey: fulfillerPublicKey,
      requestorPuzzlehashes: keychain.puzzlehashes,
    );

    late final DateTime? clawbackTime;
    late final DateTime? clawbackConfirmedTime;
    late final DateTime? sweepTime;
    late final DateTime? sweepConfirmedTime;
    if (requestorSpentEscrowCoins) {
      switch (exchangeType) {
        case ExchangeType.xchToBtc:
          // maker clawed back
          clawbackTime = completedTime;
          clawbackConfirmedTime = confirmedTime;
          sweepTime = null;
          sweepConfirmedTime = null;
          break;
        case ExchangeType.btcToXch:
          // maker swept
          sweepTime = completedTime;
          sweepConfirmedTime = confirmedTime;
          clawbackTime = null;
          clawbackConfirmedTime = null;
          break;
      }
    } else {
      switch (exchangeType) {
        case ExchangeType.xchToBtc:
          // taker swept
          sweepTime = completedTime;
          sweepConfirmedTime = confirmedTime;
          clawbackTime = null;
          clawbackConfirmedTime = null;
          break;
        case ExchangeType.btcToXch:
          // taker clawed back
          clawbackTime = completedTime;
          clawbackConfirmedTime = confirmedTime;
          sweepTime = null;
          sweepConfirmedTime = null;
          break;
      }
    }

    return exchangeOfferRecordAfterEscrowTransfer.copyWith(
      clawbackTime: clawbackTime,
      clawbackConfirmedTime: clawbackConfirmedTime,
      sweepTime: sweepTime,
      sweepConfirmedTime: sweepConfirmedTime,
    );
  }

  Future<ExchangeOfferRecord> hydrateSentMessageCoin(
    NotificationCoin sentMessageCoin,
    WalletKeychain keychain,
  ) async {
    final messageCoinReceivedTime =
        await fullNode.getDateTimeFromBlockIndex(sentMessageCoin.spentBlockIndex);
    final messagePuzzlehash = sentMessageCoin.targetPuzzlehash;

    late final Bytes? initializationCoinId;
    late final String? serializedOfferAcceptFile;
    late final TakerCrossChainOfferFile? offerAcceptFile;
    try {
      initializationCoinId = sentMessageCoin.message.first;
      serializedOfferAcceptFile = decodeStringFromBytes(sentMessageCoin.message[1]);

      offerAcceptFile =
          await TakerCrossChainOfferFile.fromSerializedOfferFileAsync(serializedOfferAcceptFile!);
    } catch (e) {
      LoggingContext().error(e.toString());
      throw InvalidMessageCoinException();
    }

    final requestorPublicKey = offerAcceptFile.publicKey;
    final exchangeValidityTime = offerAcceptFile.validityTime;
    final exchangeType = offerAcceptFile.exchangeType;
    final requestorLightningPaymentRequest = offerAcceptFile.lightningPaymentRequest;
    const exchangeRole = ExchangeRole.taker;

    // find private key matching public key in offer accept file in keychain
    late final PrivateKey? requestorPrivateKey;
    late final int? derivationIndex;
    for (final wv in keychain.hardenedWalletVectors) {
      if (wv.childPublicKey == requestorPublicKey) {
        requestorPrivateKey = wv.childPrivateKey;
        derivationIndex = wv.derivationIndex;
      }
    }

    if (requestorPrivateKey == null || derivationIndex == null) {
      throw InvalidExchangePublicKeyException();
    }

    // get serialized offer file
    final initializationCoin = await fullNode.getCoinById(initializationCoinId);
    final initializationCoinSpend = await fullNode.getCoinSpend(initializationCoin!);
    final initializationCoinMemos = await initializationCoinSpend!.memos;
    final serializedOfferFile = initializationCoinMemos.last.decodedString!;

    late final MakerCrossChainOfferFile offerFile;
    try {
      offerFile = await MakerCrossChainOfferFile.fromSerializedOfferFileAsync(serializedOfferFile);
    } catch (e) {
      LoggingContext().error(e.toString());
      throw InvalidInitializationCoinException();
    }

    final mojos = offerFile.mojos;
    final satoshis = offerFile.satoshis;
    final offerValidityTime = offerFile.validityTime;
    final fulfillerPublicKey = offerFile.publicKey;
    final fulfillerLightningPaymentRequest = offerFile.lightningPaymentRequest;

    final lightningPaymentRequest =
        requestorLightningPaymentRequest ?? fulfillerLightningPaymentRequest;
    final paymentHash = lightningPaymentRequest!.paymentHash;

    final escrowPuzzlehash = offerAcceptFile.getEscrowPuzzlehash(
      requestorPrivateKey: requestorPrivateKey,
      clawbackDelaySeconds: exchangeValidityTime,
      sweepPaymentHash: paymentHash!,
      fulfillerPublicKey: fulfillerPublicKey,
    );

    // check whether the 3 mojo addition from the initialization coin spend was spent, indicating cancelation
    final cancelCoin =
        await exchangeOfferService.getCancelCoin(initializationCoin, messagePuzzlehash);
    late final DateTime? canceledTime;
    if (cancelCoin.isSpent) {
      canceledTime = await fullNode.getDateTimeFromBlockIndex(cancelCoin.spentBlockIndex);
    } else {
      canceledTime = null;
    }

    final messageCoinChild = await fullNode.getSingleChildCoinFromCoin(sentMessageCoin);

    if (messageCoinChild == null) {
      throw MissingMessageCoinChildException();
    }

    final exchangeOfferRecord = ExchangeOfferRecord(
      initializationCoinId: initializationCoinId,
      derivationIndex: derivationIndex,
      type: exchangeType,
      role: exchangeRole,
      mojos: mojos,
      satoshis: satoshis,
      messagePuzzlehash: messagePuzzlehash,
      requestorPublicKey: requestorPublicKey,
      offerValidityTime: offerValidityTime,
      serializedMakerOfferFile: serializedOfferFile,
      lightningPaymentRequest: lightningPaymentRequest,
      messageCoinId: sentMessageCoin.id,
      serializedTakerOfferFile: serializedOfferAcceptFile,
      fulfillerPublicKey: fulfillerPublicKey,
      exchangeValidityTime: exchangeValidityTime,
      escrowPuzzlehash: escrowPuzzlehash,
      messageCoinReceivedTime: messageCoinReceivedTime,
      canceledTime: canceledTime,
    );

    if (messageCoinChild.isNotSpent) {
      // waiting for maker to accept or decline
      return exchangeOfferRecord;
    }

    final makerMessageCoinSpend = await fullNode.getCoinSpend(messageCoinChild);
    final memos = await makerMessageCoinSpend!.memos;
    final messageCoinChildSpentTime =
        await fullNode.getDateTimeFromBlockIndex(messageCoinChild.spentBlockIndex);

    if (!memos.contains(initializationCoinId)) {
      // message coin was declined
      return exchangeOfferRecord.copyWith(
        messageCoinDeclinedTime: messageCoinChildSpentTime,
      );
    }

    // message coin was accepted, check for escrow transfer
    final escrowCoins =
        await fullNode.getCoinsByPuzzleHashes([escrowPuzzlehash], includeSpentCoins: true);

    final toRemove = <Coin>[];
    for (final escrowCoin in escrowCoins) {
      final validation = await validateExchangeCoin(
        coin: escrowCoin,
        requestorPublicKey: requestorPublicKey,
        fulfillerPublicKey: fulfillerPublicKey,
      );

      if (!validation) {
        toRemove.add(escrowCoin);
      }
    }

    escrowCoins.removeWhere(toRemove.contains);

    final exchangeOfferRecordAfterMessageCoinAcceptance = exchangeOfferRecord.copyWith(
      messageCoinAcceptedTime: messageCoinChildSpentTime,
    );

    if (escrowCoins.totalValue < mojos) {
      // escrow transfer has not been completed yet
      return exchangeOfferRecordAfterMessageCoinAcceptance;
    }

    // funds were transfered to escrow address
    final escrowCoinId = escrowCoins.first.id;
    final parentCoin = await fullNode.getCoinById(escrowCoins.first.parentCoinInfo);
    final escrowTransferCompletedBlockIndex = parentCoin!.spentBlockIndex;
    final escrowTransferCompletedTime =
        await fullNode.getDateTimeFromBlockIndex(escrowTransferCompletedBlockIndex);

    final escrowTransferConfirmedTime = await getConfirmedTime(escrowTransferCompletedBlockIndex);

    final exchangeOfferRecordAfterEscrowTransfer =
        exchangeOfferRecordAfterMessageCoinAcceptance.copyWith(
      escrowCoinId: escrowCoinId,
      escrowTransferCompletedTime: escrowTransferCompletedTime,
      escrowTransferConfirmedTime: escrowTransferConfirmedTime,
    );

    final spentEscrowCoins = escrowCoins.where((coin) => coin.isSpent).toList();

    if (spentEscrowCoins.totalValue < mojos) {
      // escrow coins have not yet been swept or clawed back
      return exchangeOfferRecordAfterEscrowTransfer;
    }

    // escrow coins have been swept or clawed back
    final completedBlockIndex = spentEscrowCoins.first.spentBlockIndex;

    final completedTime = await fullNode.getDateTimeFromBlockIndex(completedBlockIndex);
    final confirmedTime = await getConfirmedTime(completedBlockIndex);

    final requestorSpentEscrowCoins = await didRequestorSpendEscrowCoins(
      spentEscrowCoin: spentEscrowCoins.first,
      requestorPublicKey: requestorPublicKey,
      fulfillerPublicKey: fulfillerPublicKey,
      requestorPuzzlehashes: keychain.puzzlehashes,
    );

    late final DateTime? clawbackTime;
    late final DateTime? clawbackConfirmedTime;
    late final DateTime? sweepTime;
    late final DateTime? sweepConfirmedTime;
    if (requestorSpentEscrowCoins) {
      switch (exchangeType) {
        case ExchangeType.xchToBtc:
          // taker clawed back
          clawbackTime = completedTime;
          clawbackConfirmedTime = confirmedTime;
          sweepTime = null;
          sweepConfirmedTime = null;
          break;
        case ExchangeType.btcToXch:
          // taker swept
          sweepTime = completedTime;
          sweepConfirmedTime = confirmedTime;
          clawbackTime = null;
          clawbackConfirmedTime = null;
          break;
      }
    } else {
      switch (exchangeType) {
        case ExchangeType.xchToBtc:
          // maker swept
          sweepTime = completedTime;
          sweepConfirmedTime = confirmedTime;
          clawbackTime = null;
          clawbackConfirmedTime = null;
          break;
        case ExchangeType.btcToXch:
          // maker clawed back
          clawbackTime = completedTime;
          clawbackConfirmedTime = confirmedTime;
          sweepTime = null;
          sweepConfirmedTime = null;
          break;
      }
    }

    return exchangeOfferRecordAfterEscrowTransfer.copyWith(
      clawbackTime: clawbackTime,
      clawbackConfirmedTime: clawbackConfirmedTime,
      sweepTime: sweepTime,
      sweepConfirmedTime: sweepConfirmedTime,
    );
  }

  Future<DateTime?> getConfirmedTime(int completedBlockIndex) async {
    final expectedConfirmedBlockIndex = completedBlockIndex + 32;
    final currentBlockIndex = await fullNode.getCurrentBlockIndex();

    if (currentBlockIndex != null) {
      if (currentBlockIndex >= expectedConfirmedBlockIndex) {
        // if we are 32 blocks past the completed block index, then check the next 20 blocks for the
        // closest block with a peak and therefore a date time
        for (var i = 0; i < 20; i++) {
          final confirmedTime =
              await fullNode.getDateTimeFromBlockIndex(expectedConfirmedBlockIndex + i);

          if (confirmedTime != null) return confirmedTime;
        }
      }

      // if current block index within 32 blocks of the completed time the transaction hasn't
      // received sufficient confirmations yet
      return null;
    }

    // if current block index returns null, we don't know whether we have sufficient confirmations,
    // so just try to get date time from the expected confirmed block index
    return fullNode.getDateTimeFromBlockIndex(expectedConfirmedBlockIndex);
  }

  Future<bool> validateExchangeCoin({
    required Coin coin,
    required JacobianPoint requestorPublicKey,
    required JacobianPoint fulfillerPublicKey,
  }) async {
    try {
      final parentCoin = await fullNode.getCoinById(coin.parentCoinInfo);
      final coinSpend = await fullNode.getCoinSpend(parentCoin!);
      final memos = await coinSpend!.paymentsAsync.then((value) => value.memos);
      final exchangeCoinMemos = ExchangeCoinMemos.maybeFromMemos(memos);
      return exchangeCoinMemos!.verify(fulfillerPublicKey) ||
          exchangeCoinMemos.verify(requestorPublicKey);
    } catch (e) {
      return false;
    }
  }

  Future<bool> didRequestorSpendEscrowCoins({
    required Coin spentEscrowCoin,
    required JacobianPoint requestorPublicKey,
    required JacobianPoint fulfillerPublicKey,
    required List<Puzzlehash> requestorPuzzlehashes,
  }) async {
    final completionCoinSpend = await fullNode.getCoinSpend(spentEscrowCoin);

    final completionSpendMemos = await completionCoinSpend!.paymentsAsync
        .then((value) => ExchangeCoinMemos.maybeFromMemos(value.memos));

    // determine who spent the escrow coins by checking the key that was used to sign the memo
    if (completionSpendMemos != null && completionSpendMemos.verify(requestorPublicKey)) {
      return true;
    } else if (completionSpendMemos != null && completionSpendMemos.verify(fulfillerPublicKey)) {
      return false;
    } else {
      // if memos are incorrect, try to determine who spent the coins by checking whether the additions
      // of the escrow coin spend include the requestor's puzzlehash
      // if so, then the requestor was the one who spent the escrow coins, if not then it was the fulfilelr
      final additionPuzzlehashes =
          completionCoinSpend.additions.map((addition) => addition.puzzlehash);
      final requestorPuzzlehashesInAdditions =
          additionPuzzlehashes.where((ph) => requestorPuzzlehashes.contains(ph));

      if (requestorPuzzlehashesInAdditions.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    }
  }
}
