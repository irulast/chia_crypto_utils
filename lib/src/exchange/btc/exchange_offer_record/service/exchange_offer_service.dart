import 'dart:math';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/exchange_offer_record/exceptions/missing_message_coin_child_exception.dart';

class ExchangeOfferService {
  ExchangeOfferService(this.fullNode);

  final ChiaFullNodeInterface fullNode;
  final StandardWalletService standardWalletService = StandardWalletService();
  final ExchangeOfferWalletService exchangeOfferWalletService = ExchangeOfferWalletService();

  Future<ChiaBaseResponse> pushInitializationSpendBundle({
    required Puzzlehash messagePuzzlehash,
    required List<CoinPrototype> coinsInput,
    required Bytes initializationCoinId,
    required WalletKeychain keychain,
    required int derivationIndex,
    required String serializedOfferFile,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) async {
    final initializationSpendBundle = exchangeOfferWalletService.createInitializationSpendBundle(
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: coinsInput,
      keychain: keychain,
      derivationIndex: derivationIndex,
      serializedOfferFile: serializedOfferFile,
      changePuzzlehash: changePuzzlehash,
      fee: fee,
      initializationCoinId: initializationCoinId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    final result = await fullNode.pushTransaction(initializationSpendBundle);

    return result;
  }

  Future<ChiaBaseResponse> cancelExchangeOffer({
    required Bytes initializationCoinId,
    required Puzzlehash messagePuzzlehash,
    required PrivateKey masterPrivateKey,
    required int derivationIndex,
    required Puzzlehash targetPuzzlehash,
    WalletKeychain? keychain,
    List<Coin> coinsForFee = const [],
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) async {
    final initializationCoin = await fullNode.getCoinById(initializationCoinId);
    final cancelCoin = await getCancelCoin(initializationCoin!, messagePuzzlehash);

    final walletVector = await WalletVector.fromPrivateKeyAsync(masterPrivateKey, derivationIndex);

    final cancelationSpendBundle = exchangeOfferWalletService.createCancelationSpendBundle(
      initializationCoinId: initializationCoinId,
      targetPuzzlehash: targetPuzzlehash,
      cancelCoin: cancelCoin,
      walletVector: walletVector,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    if (fee == 0) {
      final result = await fullNode.pushTransaction(cancelationSpendBundle);
      return result;
    }

    if (keychain == null || coinsForFee.isEmpty) {
      throw MissingInputsForFeeException();
    }

    final totalSpendBundle = createTotalSpendBundle(
      coinsForFee: coinsForFee,
      keychain: keychain,
      fee: fee,
      changePuzzlehash: targetPuzzlehash,
      standardSpendBundle: cancelationSpendBundle,
    );
    final result = await fullNode.pushTransaction(totalSpendBundle);
    return result;
  }

  Future<ChiaBaseResponse> sendMessageCoin({
    required Puzzlehash messagePuzzlehash,
    required List<CoinPrototype> coinsInput,
    required WalletKeychain keychain,
    required String serializedTakerOfferFile,
    required Bytes initializationCoinId,
    int amount = minimumNotificationCoinAmount,
    int fee = 0,
    Puzzlehash? changePuzzlehash,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) async {
    // check whether offer is canceled
    final cancelCoin =
        (await fullNode.getCoinsByPuzzleHashes([messagePuzzlehash], includeSpentCoins: true))
            .where((coin) => coin.parentCoinInfo == initializationCoinId && coin.amount == 3);

    if (cancelCoin.isNotEmpty) {
      if (cancelCoin.first.isSpent) throw OfferCanceledException();
    }

    final messageSpendBundle = exchangeOfferWalletService.createMessageSpendBundle(
      messagePuzzlehash: messagePuzzlehash,
      coinsInput: coinsInput,
      keychain: keychain,
      serializedTakerOfferFile: serializedTakerOfferFile,
      initializationCoinId: initializationCoinId,
      changePuzzlehash: changePuzzlehash,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    final result = await fullNode.pushTransaction(messageSpendBundle);

    return result;
  }

  Future<MessageCoinInfo?> getNextValidMessageCoin({
    required Bytes initializationCoinId,
    required String serializedOfferFile,
    required Puzzlehash messagePuzzlehash,
    required ExchangeType exchangeType,
    int? satoshis,
    List<Bytes> declinedMessageCoinIds = const <Bytes>[],
  }) async {
    // find valid message coin that hasn't been accepted or declined yet
    final messageCoins = await fullNode.scroungeForReceivedNotificationCoins([messagePuzzlehash]);

    for (final messageCoin in messageCoins) {
      if (declinedMessageCoinIds.contains(messageCoin.id)) {
        continue;
      }

      final messageCoinInfo = await parseAndValidateReceivedMessageCoin(
        messageCoin: messageCoin,
        initializationCoinId: initializationCoinId,
        serializedOfferFile: serializedOfferFile,
        messagePuzzlehash: messagePuzzlehash,
        exchangeType: exchangeType,
        satoshis: satoshis,
      );

      if (messageCoinInfo != null) {
        return messageCoinInfo;
      }
    }
    return null;
  }

  Future<MessageCoinInfo?> parseAndValidateReceivedMessageCoin({
    required NotificationCoin messageCoin,
    required Bytes initializationCoinId,
    required String serializedOfferFile,
    required Puzzlehash messagePuzzlehash,
    required ExchangeType exchangeType,
    int? satoshis,
  }) async {
    if (exchangeType == ExchangeType.btcToXch && satoshis == null) {
      throw Exception(
        'satoshis input is required to validate message coins for BTC to XCH exchange offer',
      );
    }

    try {
      final serializedOfferAcceptFileMemo = decodeStringFromBytes(messageCoin.message.last);
      final offerAcceptFile = await TakerCrossChainOfferFile.fromSerializedOfferFileAsync(
        serializedOfferAcceptFileMemo!,
      );

      switch (exchangeType) {
        case ExchangeType.xchToBtc:
          if (offerAcceptFile.type != CrossChainOfferFileType.btcToXchAccept) return null;
          break;
        case ExchangeType.btcToXch:
          if (offerAcceptFile.type != CrossChainOfferFileType.xchToBtcAccept) return null;
          break;
      }

      if (offerAcceptFile.acceptedOfferHash ==
          Bytes.encodeFromString(serializedOfferFile).sha256Hash()) {
        LightningPaymentRequest? lightningPaymentRequest;
        if (offerAcceptFile.type == CrossChainOfferFileType.xchToBtcAccept) {
          final xchToBtcOfferAcceptFile = offerAcceptFile as XchToBtcTakerOfferFile;

          lightningPaymentRequest = xchToBtcOfferAcceptFile.lightningPaymentRequest;

          if (!validateLightningPaymentRequest(lightningPaymentRequest, satoshis!)) return null;
        }

        final spentTime = await fullNode.getDateTimeFromBlockIndex(messageCoin.spentBlockIndex);

        final messageCoinChild = await fullNode.getSingleChildCoinFromCoin(messageCoin);

        if (messageCoinChild == null) return null;

        if (messageCoinChild.isSpent) {
          final messageCoinChildSpend = await fullNode.getCoinSpend(messageCoinChild);
          final spentMessageCoinChildMemos = await messageCoinChildSpend!.memos;
          final messageCoinChildSpentTime =
              await fullNode.getDateTimeFromBlockIndex(messageCoinChild.spentBlockIndex);

          if (spentMessageCoinChildMemos.contains(initializationCoinId)) {
            // message coin was accepted
            return MessageCoinInfo(
              messageCoin: messageCoin,
              messageCoinReceivedTime: spentTime!,
              serializedOfferAcceptFile: serializedOfferAcceptFileMemo,
              lightningPaymentRequest: lightningPaymentRequest,
              fulfillerPublicKey: offerAcceptFile.publicKey,
              exchangeValidityTime: offerAcceptFile.validityTime,
              messageCoinAcceptedTime: messageCoinChildSpentTime,
            );
          } else {
            // message coin was declined
            return MessageCoinInfo(
              messageCoin: messageCoin,
              messageCoinReceivedTime: spentTime!,
              serializedOfferAcceptFile: serializedOfferAcceptFileMemo,
              lightningPaymentRequest: lightningPaymentRequest,
              fulfillerPublicKey: offerAcceptFile.publicKey,
              exchangeValidityTime: offerAcceptFile.validityTime,
              messageCoinDeclinedTime: messageCoinChildSpentTime,
            );
          }
        }

        return MessageCoinInfo(
          messageCoin: messageCoin,
          messageCoinReceivedTime: spentTime!,
          serializedOfferAcceptFile: serializedOfferAcceptFileMemo,
          lightningPaymentRequest: lightningPaymentRequest,
          fulfillerPublicKey: offerAcceptFile.publicKey,
          exchangeValidityTime: offerAcceptFile.validityTime,
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<ChiaBaseResponse> acceptMessageCoin({
    required Bytes initializationCoinId,
    required Coin messageCoin,
    required PrivateKey masterPrivateKey,
    required int derivationIndex,
    required String serializedOfferFile,
    required Puzzlehash targetPuzzlehash,
    WalletKeychain? keychain,
    List<Coin> coinsForFee = const [],
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) async {
    final messageCoinChild = await fullNode.getSingleChildCoinFromCoin(messageCoin);

    if (messageCoinChild == null) {
      throw MissingMessageCoinChildException();
    }

    final walletVector = await WalletVector.fromPrivateKeyAsync(masterPrivateKey, derivationIndex);

    final acceptanceSpendBundle = exchangeOfferWalletService.createMessageCoinAcceptanceSpendBundle(
      initializationCoinId: initializationCoinId,
      messageCoinChild: messageCoinChild,
      targetPuzzlehash: targetPuzzlehash,
      walletVector: walletVector,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    if (fee == 0) {
      final result = await fullNode.pushTransaction(acceptanceSpendBundle);
      return result;
    }

    if (keychain == null || coinsForFee.isEmpty) {
      throw MissingInputsForFeeException();
    }

    final totalSpendBundle = createTotalSpendBundle(
      coinsForFee: coinsForFee,
      keychain: keychain,
      fee: fee,
      changePuzzlehash: targetPuzzlehash,
      standardSpendBundle: acceptanceSpendBundle,
    );
    final result = await fullNode.pushTransaction(totalSpendBundle);
    return result;
  }

  Future<ChiaBaseResponse> declineMessageCoin({
    required Bytes initializationCoinId,
    required Coin messageCoin,
    required PrivateKey masterPrivateKey,
    required int derivationIndex,
    required String serializedOfferFile,
    required Puzzlehash targetPuzzlehash,
    WalletKeychain? keychain,
    List<Coin> coinsForFee = const [],
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) async {
    final messageCoinChild = await fullNode.getSingleChildCoinFromCoin(messageCoin);

    if (messageCoinChild == null) {
      throw MissingMessageCoinChildException();
    }

    final walletVector = await WalletVector.fromPrivateKeyAsync(masterPrivateKey, derivationIndex);

    final declinationSpendBundle =
        exchangeOfferWalletService.createMessageCoinDeclinationSpendBundle(
      messageCoinChild: messageCoinChild,
      targetPuzzlehash: targetPuzzlehash,
      walletVector: walletVector,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    if (fee == 0) {
      final result = await fullNode.pushTransaction(declinationSpendBundle);
      return result;
    }

    if (keychain == null || coinsForFee.isEmpty) {
      throw MissingInputsForFeeException();
    }

    final totalSpendBundle = createTotalSpendBundle(
      coinsForFee: coinsForFee,
      keychain: keychain,
      fee: fee,
      changePuzzlehash: targetPuzzlehash,
      standardSpendBundle: declinationSpendBundle,
    );
    final result = await fullNode.pushTransaction(totalSpendBundle);
    return result;
  }

  Future<ChiaBaseResponse> transferFundsToEscrowPuzzlehash({
    required Bytes initializationCoinId,
    required int mojos,
    required Puzzlehash escrowPuzzlehash,
    required PrivateKey requestorPrivateKey,
    required List<CoinPrototype> coinsInput,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) async {
    final escrowSpendBundle = exchangeOfferWalletService.createEscrowTransferSpendBundle(
      initializationCoinId: initializationCoinId,
      mojos: mojos,
      escrowPuzzlehash: escrowPuzzlehash,
      requestorPrivateKey: requestorPrivateKey,
      coinsInput: coinsInput,
      keychain: keychain,
      fee: fee,
      changePuzzlehash: changePuzzlehash,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    final result = await fullNode.pushTransaction(escrowSpendBundle);
    return result;
  }

  Future<ChiaBaseResponse> sweepEscrowPuzzlehash({
    required Bytes initializationCoinId,
    required Puzzlehash escrowPuzzlehash,
    required Puzzlehash requestorPuzzlehash,
    required PrivateKey requestorPrivateKey,
    required int exchangeValidityTime,
    required Bytes paymentHash,
    required Bytes preimage,
    required JacobianPoint fulfillerPublicKey,
    WalletKeychain? keychain,
    List<Coin> coinsForFee = const [],
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) async {
    final escrowCoins = await fullNode.getCoinsByPuzzleHashes([escrowPuzzlehash]);

    final sweepSpendBundle = exchangeOfferWalletService.createSweepSpendBundle(
      initializationCoinId: initializationCoinId,
      escrowCoins: escrowCoins,
      requestorPuzzlehash: requestorPuzzlehash,
      requestorPrivateKey: requestorPrivateKey,
      exchangeValidityTime: exchangeValidityTime,
      paymentHash: paymentHash,
      preimage: preimage,
      fulfillerPublicKey: fulfillerPublicKey,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    if (fee == 0) {
      final result = await fullNode.pushTransaction(sweepSpendBundle);
      return result;
    }

    if (keychain == null || coinsForFee.isEmpty) {
      throw MissingInputsForFeeException();
    }

    final totalSpendBundle = createTotalSpendBundle(
      coinsForFee: coinsForFee,
      keychain: keychain,
      fee: fee,
      changePuzzlehash: changePuzzlehash,
      standardSpendBundle: sweepSpendBundle,
    );
    final result = await fullNode.pushTransaction(totalSpendBundle);
    return result;
  }

  Future<ChiaBaseResponse> clawbackEscrowFunds({
    required Bytes initializationCoinId,
    required Puzzlehash escrowPuzzlehash,
    required Puzzlehash requestorPuzzlehash,
    required PrivateKey requestorPrivateKey,
    required int exchangeValidityTime,
    required Bytes paymentHash,
    required JacobianPoint fulfillerPublicKey,
    WalletKeychain? keychain,
    List<Coin> coinsForFee = const [],
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) async {
    final escrowCoins = await fullNode.getCoinsByPuzzleHashes([escrowPuzzlehash]);

    final clawbackSpendBundle = exchangeOfferWalletService.createClawbackSpendBundle(
      initializationCoinId: initializationCoinId,
      escrowCoins: escrowCoins,
      requestorPuzzlehash: requestorPuzzlehash,
      requestorPrivateKey: requestorPrivateKey,
      exchangeValidityTime: exchangeValidityTime,
      paymentHash: paymentHash,
      fulfillerPublicKey: fulfillerPublicKey,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    if (fee == 0) {
      final result = await fullNode.pushTransaction(clawbackSpendBundle);
      return result;
    }

    if (keychain == null || coinsForFee.isEmpty) {
      throw MissingInputsForFeeException();
    }

    final totalSpendBundle = createTotalSpendBundle(
      coinsForFee: coinsForFee,
      keychain: keychain,
      fee: fee,
      changePuzzlehash: changePuzzlehash,
      standardSpendBundle: clawbackSpendBundle,
    );
    final result = await fullNode.pushTransaction(totalSpendBundle);
    return result;
  }

  static int randomDerivationIndexForExchange() => Random.secure().nextInt(9000000) + 1000000;

  bool validateLightningPaymentRequest(
    LightningPaymentRequest lightningPaymentRequest,
    int satoshis,
  ) {
    if (lightningPaymentRequest.tags.timeout! < 600) {
      // timeout isn't long enough to allow for exchange to complete
      return false;
    }

    if ((lightningPaymentRequest.amount * 100000000) != satoshis) {
      // lightning payment request amount doesn't match offer file
      return false;
    }
    return true;
  }

  static const derivationIndexLength = 7;

  SpendBundle createTotalSpendBundle({
    required List<Coin> coinsForFee,
    required WalletKeychain keychain,
    required int fee,
    required SpendBundle standardSpendBundle,
    Puzzlehash? changePuzzlehash,
  }) {
    final feeSpendBundle = standardWalletService.createFeeSpendBundle(
      fee: fee,
      standardCoins: coinsForFee,
      keychain: keychain,
      changePuzzlehash: changePuzzlehash,
    );
    final totalSpendBundle = standardSpendBundle + feeSpendBundle;
    return totalSpendBundle;
  }

  Future<Coin> getCancelCoin(Coin initializationCoin, Puzzlehash messagePuzzlehash) async {
    try {
      final initializationCoinSpend = await fullNode.getCoinSpend(initializationCoin);
      final additions = await initializationCoinSpend!.additionsAsync;
      final cancelCoinId =
          additions.where((addition) => addition.puzzlehash == messagePuzzlehash).single.id;
      final cancelCoin = await fullNode.getCoinById(cancelCoinId);
      return cancelCoin!;
    } catch (e) {
      throw MissingCancelCoinException();
    }
  }
}

class MessageCoinInfo {
  MessageCoinInfo({
    required this.messageCoin,
    required this.messageCoinReceivedTime,
    required this.serializedOfferAcceptFile,
    required this.fulfillerPublicKey,
    required this.exchangeValidityTime,
    this.lightningPaymentRequest,
    this.messageCoinDeclinedTime,
    this.messageCoinAcceptedTime,
  });

  final Coin messageCoin;
  final DateTime messageCoinReceivedTime;
  final String serializedOfferAcceptFile;
  final JacobianPoint fulfillerPublicKey;
  final int exchangeValidityTime;
  final LightningPaymentRequest? lightningPaymentRequest;
  final DateTime? messageCoinDeclinedTime;
  final DateTime? messageCoinAcceptedTime;

  Bytes get id => messageCoin.id;
}
