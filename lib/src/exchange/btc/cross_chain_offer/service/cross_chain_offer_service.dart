import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class CrossChainOfferFileService {
  XchToBtcMakerOfferFile createXchToBtcMakerOfferFile({
    required Bytes initializationCoinId,
    required int amountMojos,
    required int amountSatoshis,
    required Address messageAddress,
    required int validityTime,
    required JacobianPoint requestorPublicKey,
    required LightningPaymentRequest paymentRequest,
  }) {
    final offeredAmount =
        ExchangeAmount(type: ExchangeAmountType.XCH, amount: amountMojos);
    final requestedAmount =
        ExchangeAmount(type: ExchangeAmountType.BTC, amount: amountSatoshis);

    return XchToBtcMakerOfferFile(
      initializationCoinId: initializationCoinId,
      offeredAmount: offeredAmount,
      requestedAmount: requestedAmount,
      messageAddress: messageAddress,
      validityTime: validityTime,
      publicKey: requestorPublicKey,
      lightningPaymentRequest: paymentRequest,
    );
  }

  BtcToXchMakerOfferFile createBtcToXchMakerOfferFile({
    required Bytes initializationCoinId,
    required int amountMojos,
    required int amountSatoshis,
    required Address messageAddress,
    required int validityTime,
    required JacobianPoint requestorPublicKey,
  }) {
    final offeredAmount =
        ExchangeAmount(type: ExchangeAmountType.BTC, amount: amountSatoshis);
    final requestedAmount =
        ExchangeAmount(type: ExchangeAmountType.XCH, amount: amountMojos);

    return BtcToXchMakerOfferFile(
      initializationCoinId: initializationCoinId,
      offeredAmount: offeredAmount,
      requestedAmount: requestedAmount,
      messageAddress: messageAddress,
      validityTime: validityTime,
      publicKey: requestorPublicKey,
    );
  }

  static void checkValidity(CrossChainOfferFile offerFile) {
    if (offerFile.validityTime <
        (DateTime.now().millisecondsSinceEpoch / 1000)) {
      throw ExpiredCrossChainOfferFile();
    }
  }

  XchToBtcTakerOfferFile createXchToBtcTakerOfferFile({
    required String serializedMakerOfferFile,
    required Bytes initializationCoinId,
    required int validityTime,
    required JacobianPoint requestorPublicKey,
    required LightningPaymentRequest paymentRequest,
  }) {
    final acceptedOfferHash =
        Bytes.encodeFromString(serializedMakerOfferFile).sha256Hash();

    return XchToBtcTakerOfferFile(
      initializationCoinId: initializationCoinId,
      validityTime: validityTime,
      publicKey: requestorPublicKey,
      lightningPaymentRequest: paymentRequest,
      acceptedOfferHash: acceptedOfferHash,
    );
  }

  BtcToXchTakerOfferFile createBtcToXchTakerOfferFile({
    required String serializedMakerOfferFile,
    required Bytes initializationCoinId,
    required int validityTime,
    required JacobianPoint requestorPublicKey,
  }) {
    final acceptedOfferHash =
        Bytes.encodeFromString(serializedMakerOfferFile).sha256Hash();

    return BtcToXchTakerOfferFile(
      initializationCoinId: initializationCoinId,
      validityTime: validityTime,
      publicKey: requestorPublicKey,
      acceptedOfferHash: acceptedOfferHash,
    );
  }
}
