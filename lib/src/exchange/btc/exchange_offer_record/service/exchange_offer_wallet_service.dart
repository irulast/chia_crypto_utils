import 'dart:collection';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class ExchangeOfferWalletService {
  ExchangeOfferWalletService();

  final StandardWalletService standardWalletService = StandardWalletService();

  SpendBundle createInitializationSpendBundle({
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
  }) {
    final initializationSpendBundle = standardWalletService.createSpendBundle(
      payments: [
        Payment(
          3,
          messagePuzzlehash,
          memos: <Memo>[
            Memo(encodeInt(derivationIndex)),
            Memo(Bytes.encodeFromString(serializedOfferFile)),
          ],
        )
      ],
      coinsInput: coinsInput,
      keychain: keychain,
      changePuzzlehash: changePuzzlehash,
      fee: fee,
      originId: initializationCoinId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    return initializationSpendBundle;
  }

  SpendBundle createCancelationSpendBundle({
    required Bytes initializationCoinId,
    required Puzzlehash targetPuzzlehash,
    required CoinPrototype cancelCoin,
    required WalletVector walletVector,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    final requestorPrivateKey = walletVector.childPrivateKey;

    final memos = ExchangeCoinMemos(
      initializationCoinId: initializationCoinId,
      requestorPrivateKey: requestorPrivateKey,
    ).toMemos();

    final messagePuzzlehashKeychain = makeKeychainFromWalletVector(walletVector);

    final cancelationSpendBundle = standardWalletService.createSpendBundle(
      payments: [
        Payment(3, targetPuzzlehash, memos: memos),
      ],
      coinsInput: [cancelCoin],
      keychain: messagePuzzlehashKeychain,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    return cancelationSpendBundle;
  }

  SpendBundle createMessageSpendBundle({
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
  }) {
    final notificationService = NotificationWalletService();

    final notificationSpendBundle = notificationService.createNotificationSpendBundle(
      targetPuzzlehash: messagePuzzlehash,
      message: <Memo>[
        Memo(initializationCoinId),
        Memo(Bytes.encodeFromString(serializedTakerOfferFile))
      ],
      amount: amount,
      coinsInput: coinsInput,
      keychain: keychain,
      fee: fee,
      changePuzzlehash: changePuzzlehash,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    return notificationSpendBundle;
  }

  SpendBundle createMessageCoinAcceptanceSpendBundle({
    required Bytes initializationCoinId,
    required CoinPrototype messageCoinChild,
    required Puzzlehash targetPuzzlehash,
    required WalletVector walletVector,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    final requestorPrivateKey = walletVector.childPrivateKey;

    final memos = ExchangeCoinMemos(
      initializationCoinId: initializationCoinId,
      requestorPrivateKey: requestorPrivateKey,
    ).toMemos();

    final messagePuzzlehashKeychain = makeKeychainFromWalletVector(walletVector);

    final acceptanceSpendBundle = standardWalletService.createSpendBundle(
      payments: [
        Payment(
          messageCoinChild.amount,
          targetPuzzlehash,
          memos: memos,
        ),
      ],
      coinsInput: [messageCoinChild],
      keychain: messagePuzzlehashKeychain,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    return acceptanceSpendBundle;
  }

  SpendBundle createMessageCoinDeclinationSpendBundle({
    required CoinPrototype messageCoinChild,
    required Puzzlehash targetPuzzlehash,
    required WalletVector walletVector,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    final messagePuzzlehashKeychain = makeKeychainFromWalletVector(walletVector);

    final declinationSpendBundle = standardWalletService.createSpendBundle(
      payments: [
        Payment(messageCoinChild.amount, targetPuzzlehash),
      ],
      coinsInput: [messageCoinChild],
      keychain: messagePuzzlehashKeychain,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    return declinationSpendBundle;
  }

  SpendBundle createEscrowTransferSpendBundle({
    required Bytes initializationCoinId,
    required int mojos,
    required Puzzlehash escrowPuzzlehash,
    required List<CoinPrototype> coinsInput,
    required WalletKeychain keychain,
    required PrivateKey requestorPrivateKey,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    final memos = ExchangeCoinMemos(
      initializationCoinId: initializationCoinId,
      requestorPrivateKey: requestorPrivateKey,
    ).toMemos();

    final escrowSpendBundle = standardWalletService.createSpendBundle(
      payments: [
        Payment(
          mojos,
          escrowPuzzlehash,
          memos: memos,
        )
      ],
      coinsInput: coinsInput,
      keychain: keychain,
      fee: fee,
      changePuzzlehash: changePuzzlehash,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    return escrowSpendBundle;
  }

  SpendBundle createSweepSpendBundle({
    required Bytes initializationCoinId,
    required List<Coin> escrowCoins,
    required Puzzlehash requestorPuzzlehash,
    required PrivateKey requestorPrivateKey,
    required int exchangeValidityTime,
    required Bytes paymentHash,
    required Bytes preimage,
    required JacobianPoint fulfillerPublicKey,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    final btcToXchService = BtcToXchService();
    final memos = ExchangeCoinMemos(
      initializationCoinId: initializationCoinId,
      requestorPrivateKey: requestorPrivateKey,
    ).toMemos();

    final sweepSpendBundle = btcToXchService.createSweepSpendBundle(
      payments: [
        Payment(
          escrowCoins.totalValue,
          requestorPuzzlehash,
          memos: memos,
        )
      ],
      coinsInput: escrowCoins,
      requestorPrivateKey: requestorPrivateKey,
      clawbackDelaySeconds: exchangeValidityTime,
      sweepPaymentHash: paymentHash,
      sweepPreimage: preimage,
      fulfillerPublicKey: fulfillerPublicKey,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    return sweepSpendBundle;
  }

  SpendBundle createClawbackSpendBundle({
    required Bytes initializationCoinId,
    required List<Coin> escrowCoins,
    required Puzzlehash requestorPuzzlehash,
    required PrivateKey requestorPrivateKey,
    required int exchangeValidityTime,
    required Bytes paymentHash,
    required JacobianPoint fulfillerPublicKey,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    final xchToBtcService = XchToBtcService();
    final memos = ExchangeCoinMemos(
      initializationCoinId: initializationCoinId,
      requestorPrivateKey: requestorPrivateKey,
    ).toMemos();

    final clawbackSpendBundle = xchToBtcService.createClawbackSpendBundle(
      payments: [Payment(escrowCoins.totalValue, requestorPuzzlehash, memos: memos)],
      coinsInput: escrowCoins,
      requestorPrivateKey: requestorPrivateKey,
      clawbackDelaySeconds: exchangeValidityTime,
      sweepPaymentHash: paymentHash,
      fulfillerPublicKey: fulfillerPublicKey,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
    );

    return clawbackSpendBundle;
  }

  static WalletKeychain makeKeychainFromWalletVector(WalletVector walletVector) {
    // ignore: prefer_collection_literals
    final hardenedMap = LinkedHashMap<Puzzlehash, WalletVector>();
    hardenedMap[walletVector.puzzlehash] = walletVector;

    return WalletKeychain(
      hardenedMap: hardenedMap,
      unhardenedMap: LinkedHashMap<Puzzlehash, UnhardenedWalletVector>(),
      singletonWalletVectorsMap: {},
    );
  }
}
