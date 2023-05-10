import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:compute/compute.dart';

class XchToBtcMakerOfferFile implements MakerCrossChainOfferFile {
  XchToBtcMakerOfferFile({
    this.initializationCoinId,
    required this.offeredAmount,
    required this.requestedAmount,
    required this.messageAddress,
    required this.validityTime,
    required this.publicKey,
    required this.lightningPaymentRequest,
  });

  factory XchToBtcMakerOfferFile._fromSerializedOfferFileTask(String serializedOfferFile) {
    return XchToBtcMakerOfferFile.fromSerializedOfferFile(serializedOfferFile);
  }

  factory XchToBtcMakerOfferFile.fromSerializedOfferFile(String serializedOfferFile) {
    final deserializedOfferFile = maybeFromSerializedOfferFile(serializedOfferFile);

    if (deserializedOfferFile == null) {
      throw InvalidCrossChainOfferType(CrossChainOfferFileType.xchToBtc.name);
    }
    return deserializedOfferFile;
  }

  factory XchToBtcMakerOfferFile.fromJson(Map<String, dynamic> json) {
    return XchToBtcMakerOfferFile(
      initializationCoinId: (json['initialization_coin_id'] as String?)?.hexToBytes(),
      offeredAmount: ExchangeAmount.fromJson(json['offered'] as Map<String, dynamic>),
      requestedAmount: ExchangeAmount.fromJson(json['requested'] as Map<String, dynamic>),
      messageAddress:
          Address((json['message_address'] as Map<String, dynamic>)['address'] as String),
      validityTime: json['validity_time'] as int,
      publicKey: JacobianPoint.fromHexG1(json['public_key'] as String),
      lightningPaymentRequest: decodeLightningPaymentRequest(
        (json['lightning_payment_request'] as Map<String, dynamic>)['payment_request'] as String,
      ),
    );
  }

  @override
  final Bytes? initializationCoinId;
  @override
  final ExchangeAmount offeredAmount;
  @override
  final ExchangeAmount requestedAmount;
  @override
  final Address messageAddress;
  @override
  final int validityTime;
  @override
  final JacobianPoint publicKey;
  @override
  final LightningPaymentRequest lightningPaymentRequest;
  @override
  int get mojos => offeredAmount.amount;
  @override
  int get satoshis => requestedAmount.amount;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'initialization_coin_id': initializationCoinId?.toHex(),
        'offered': offeredAmount.toJson(),
        'requested': requestedAmount.toJson(),
        'message_address': <String, dynamic>{
          'type': messageAddress.prefix,
          'address': messageAddress.address
        },
        'validity_time': validityTime,
        'public_key': publicKey.toHex(),
        'lightning_payment_request': <String, dynamic>{
          'payment_request': lightningPaymentRequest.paymentRequest,
          'timeout': lightningPaymentRequest.tags.timeout
        }
      };

  static XchToBtcMakerOfferFile? maybeFromSerializedOfferFile(String serializedOfferFile) {
    try {
      final deserializedOfferFile =
          CrossChainOfferFile.fromSerializedOfferFile(serializedOfferFile);
      if (deserializedOfferFile.type != CrossChainOfferFileType.xchToBtc) {
        return null;
      }
      return deserializedOfferFile as XchToBtcMakerOfferFile;
    } catch (e) {
      return null;
    }
  }

  static Future<XchToBtcMakerOfferFile> fromSerializedOfferFileAsync(
    String serializedOfferFile,
  ) async {
    final result =
        await compute(XchToBtcMakerOfferFile._fromSerializedOfferFileTask, serializedOfferFile);

    return result;
  }

  @override
  CrossChainOfferExchangeInfo getExchangeInfo(
    CrossChainOfferFile offerAcceptFile,
    PrivateKey requestorPrivateKey,
  ) {
    final btcToXchOfferAcceptFile = offerAcceptFile as BtcToXchTakerOfferFile;

    final amountMojos = offeredAmount.amount;
    final amountSatoshis = requestedAmount.amount;
    final validityTime = btcToXchOfferAcceptFile.validityTime;
    final fulfillerPublicKey = btcToXchOfferAcceptFile.publicKey;

    final escrowPuzzlehash = XchToBtcService.generateEscrowPuzzlehash(
      requestorPrivateKey: requestorPrivateKey,
      clawbackDelaySeconds: validityTime,
      sweepPaymentHash: lightningPaymentRequest.tags.paymentHash!,
      fulfillerPublicKey: fulfillerPublicKey,
    );

    return CrossChainOfferExchangeInfo(
      requestorPublicKey: requestorPrivateKey.getG1(),
      fulfillerPublicKey: fulfillerPublicKey,
      amountMojos: amountMojos,
      amountSatoshis: amountSatoshis,
      validityTime: validityTime,
      escrowPuzzlehash: escrowPuzzlehash,
      paymentRequest: lightningPaymentRequest,
    );
  }

  @override
  CrossChainOfferFileType get type => CrossChainOfferFileType.xchToBtc;

  @override
  CrossChainOfferFilePrefix get prefix => CrossChainOfferFilePrefix.ccoffer;

  @override
  Puzzlehash getEscrowPuzzlehash({
    required PrivateKey requestorPrivateKey,
    required int clawbackDelaySeconds,
    required Bytes sweepPaymentHash,
    required JacobianPoint fulfillerPublicKey,
  }) {
    return XchToBtcService.generateEscrowPuzzlehash(
      requestorPrivateKey: requestorPrivateKey,
      clawbackDelaySeconds: clawbackDelaySeconds,
      sweepPaymentHash: sweepPaymentHash,
      fulfillerPublicKey: fulfillerPublicKey,
    );
  }
}
