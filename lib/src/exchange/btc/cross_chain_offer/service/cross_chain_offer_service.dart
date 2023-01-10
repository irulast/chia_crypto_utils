import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class CrossChainOfferService {
  CrossChainOfferService(this.fullNode);

  final ChiaFullNodeInterface fullNode;
  final DexieApi dexieApi = DexieApi();
  final standardWalletService = StandardWalletService();

  XchToBtcOfferFile createXchToBtcOfferFile({
    required int amountMojos,
    required int amountSatoshis,
    required Address messageAddress,
    required int validityTime,
    required JacobianPoint requestorPublicKey,
    required LightningPaymentRequest paymentRequest,
  }) {
    final offeredAmount = ExchangeAmount(type: ExchangeAmountType.XCH, amount: amountMojos);
    final requestedAmount = ExchangeAmount(type: ExchangeAmountType.BTC, amount: amountSatoshis);

    return XchToBtcOfferFile(
      offeredAmount: offeredAmount,
      requestedAmount: requestedAmount,
      messageAddress: messageAddress,
      validityTime: validityTime,
      publicKey: requestorPublicKey,
      lightningPaymentRequest: paymentRequest,
    );
  }

  BtcToXchOfferFile createBtcToXchOfferFile({
    required int amountMojos,
    required int amountSatoshis,
    required Address messageAddress,
    required int validityTime,
    required JacobianPoint requestorPublicKey,
  }) {
    final offeredAmount = ExchangeAmount(type: ExchangeAmountType.BTC, amount: amountSatoshis);
    final requestedAmount = ExchangeAmount(type: ExchangeAmountType.XCH, amount: amountMojos);

    return BtcToXchOfferFile(
      offeredAmount: offeredAmount,
      requestedAmount: requestedAmount,
      messageAddress: messageAddress,
      validityTime: validityTime,
      publicKey: requestorPublicKey,
    );
  }

  static void checkValidity(CrossChainOfferFile offerFile) {
    if (offerFile.validityTime < (DateTime.now().millisecondsSinceEpoch / 1000)) {
      throw ExpiredCrossChainOfferFile();
    }
  }

  XchToBtcOfferAcceptFile createXchToBtcAcceptFile({
    required String serializedOfferFile,
    required int validityTime,
    required JacobianPoint requestorPublicKey,
    required LightningPaymentRequest paymentRequest,
  }) {
    final acceptedOfferHash = Bytes.encodeFromString(serializedOfferFile).sha256Hash();

    return XchToBtcOfferAcceptFile(
      validityTime: validityTime,
      publicKey: requestorPublicKey,
      lightningPaymentRequest: paymentRequest,
      acceptedOfferHash: acceptedOfferHash,
    );
  }

  BtcToXchOfferAcceptFile createBtcToXchAcceptFile({
    required String serializedOfferFile,
    required int validityTime,
    required JacobianPoint requestorPublicKey,
  }) {
    final acceptedOfferHash = Bytes.encodeFromString(serializedOfferFile).sha256Hash();

    return BtcToXchOfferAcceptFile(
      validityTime: validityTime,
      publicKey: requestorPublicKey,
      acceptedOfferHash: acceptedOfferHash,
    );
  }

  Future<void> sendMessageCoin({
    required WalletKeychain keychain,
    required List<Coin> coinsInput,
    required Puzzlehash messagePuzzlehash,
    required PrivateKey requestorPrivateKey,
    required String serializedOfferAcceptFile,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
  }) async {
    final messageSpendBundle = standardWalletService.createSpendBundle(
      payments: [
        Payment(50, messagePuzzlehash, memos: <String>[serializedOfferAcceptFile])
      ],
      coinsInput: coinsInput,
      changePuzzlehash: changePuzzlehash,
      keychain: keychain,
      fee: fee,
    );

    await fullNode.pushTransaction(messageSpendBundle);
  }

  Future<bool> verifyMessageCoinReceipt(
    Puzzlehash messagePuzzlehash,
    String serializedOfferAcceptFile,
  ) async {
    final coins = await fullNode.getCoinsByPuzzleHashes(
      [messagePuzzlehash],
    );

    for (final coin in coins) {
      final parentCoin = await fullNode.getCoinById(coin.parentCoinInfo);
      final coinSpend = await fullNode.getCoinSpend(parentCoin!);
      final memos = await coinSpend!.memoStrings;

      for (final memo in memos) {
        if (memo == serializedOfferAcceptFile) return true;
      }
    }

    return false;
  }

  Future<String?> getOfferAcceptFileFromMessagePuzzlehash(
    Puzzlehash messagePuzzlehash,
    String serializedOfferFile,
  ) async {
    final coins = await fullNode.getCoinsByPuzzleHashes(
      [messagePuzzlehash],
    );

    for (final coin in coins) {
      final parentCoin = await fullNode.getCoinById(coin.parentCoinInfo);
      final coinSpend = await fullNode.getCoinSpend(parentCoin!);
      final memos = await coinSpend!.memoStrings;

      for (final memo in memos) {
        if (memo.startsWith('ccoffer_accept')) {
          try {
            final deserializedMemo =
                deserializeCrossChainOfferFile(memo) as CrossChainOfferAcceptFile;
            if (deserializedMemo.acceptedOfferHash ==
                Bytes.encodeFromString(serializedOfferFile).sha256Hash()) return memo;
          } catch (e) {
            continue;
          }
        }
      }
    }
    return null;
  }
}
