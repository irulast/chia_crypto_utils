import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:compute/compute.dart';

class BtcToXchMakerOfferFile implements MakerCrossChainOfferFile {
  BtcToXchMakerOfferFile({
    this.initializationCoinId,
    required this.offeredAmount,
    required this.requestedAmount,
    required this.messageAddress,
    required this.validityTime,
    required this.publicKey,
  });

  factory BtcToXchMakerOfferFile._fromSerializedOfferFileTask(String serializedOfferFile) {
    return BtcToXchMakerOfferFile.fromSerializedOfferFile(serializedOfferFile);
  }

  factory BtcToXchMakerOfferFile.fromSerializedOfferFile(String serializedOfferFile) {
    final deserializedOfferFile = maybeFromSerializedOfferFile(serializedOfferFile);

    if (deserializedOfferFile == null) {
      throw InvalidCrossChainOfferType(CrossChainOfferFileType.btcToXch.name);
    }
    return deserializedOfferFile;
  }

  factory BtcToXchMakerOfferFile.fromJson(Map<String, dynamic> json) {
    return BtcToXchMakerOfferFile(
      initializationCoinId: (json['initialization_coin_id'] as String?)?.hexToBytes(),
      offeredAmount: ExchangeAmount.fromJson(json['offered'] as Map<String, dynamic>),
      requestedAmount: ExchangeAmount.fromJson(json['requested'] as Map<String, dynamic>),
      messageAddress:
          Address((json['message_address'] as Map<String, dynamic>)['address'] as String),
      validityTime: json['validity_time'] as int,
      publicKey: JacobianPoint.fromHexG1(json['public_key'] as String),
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
  LightningPaymentRequest? get lightningPaymentRequest => null;
  @override
  int get mojos => requestedAmount.amount;
  @override
  int get satoshis => offeredAmount.amount;

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
      };

  static BtcToXchMakerOfferFile? maybeFromSerializedOfferFile(String serializedOfferFile) {
    try {
      final deserializedOfferFile =
          CrossChainOfferFile.fromSerializedOfferFile(serializedOfferFile);
      if (deserializedOfferFile.type != CrossChainOfferFileType.btcToXch) {
        return null;
      }
      return deserializedOfferFile as BtcToXchMakerOfferFile;
    } catch (e) {
      return null;
    }
  }

  static Future<BtcToXchMakerOfferFile> fromSerializedOfferFileAsync(
    String serializedOfferFile,
  ) async {
    final result =
        await compute(BtcToXchMakerOfferFile._fromSerializedOfferFileTask, serializedOfferFile);

    return result;
  }

  @override
  CrossChainOfferExchangeInfo getExchangeInfo(
    CrossChainOfferFile offerAcceptFile,
    PrivateKey requestorPrivateKey,
  ) {
    final xchToBtcOfferAcceptFile = offerAcceptFile as XchToBtcTakerOfferFile;

    final amountMojos = requestedAmount.amount;
    final amountSatoshis = offeredAmount.amount;
    final validityTime = xchToBtcOfferAcceptFile.validityTime;
    final paymentRequest = xchToBtcOfferAcceptFile.lightningPaymentRequest;
    final paymentHash = paymentRequest.tags.paymentHash!;
    final fulfillerPublicKey = xchToBtcOfferAcceptFile.publicKey;

    final escrowPuzzlehash = BtcToXchService.generateEscrowPuzzlehash(
      requestorPrivateKey: requestorPrivateKey,
      clawbackDelaySeconds: validityTime,
      sweepPaymentHash: paymentHash,
      fulfillerPublicKey: fulfillerPublicKey,
    );

    return CrossChainOfferExchangeInfo(
      requestorPublicKey: requestorPrivateKey.getG1(),
      fulfillerPublicKey: fulfillerPublicKey,
      amountMojos: amountMojos,
      amountSatoshis: amountSatoshis,
      validityTime: validityTime,
      escrowPuzzlehash: escrowPuzzlehash,
      paymentRequest: paymentRequest,
    );
  }

  @override
  CrossChainOfferFileType get type => CrossChainOfferFileType.btcToXch;

  @override
  CrossChainOfferFilePrefix get prefix => CrossChainOfferFilePrefix.ccoffer;

  @override
  Puzzlehash getEscrowPuzzlehash({
    required PrivateKey requestorPrivateKey,
    required int clawbackDelaySeconds,
    required Bytes sweepPaymentHash,
    required JacobianPoint fulfillerPublicKey,
  }) {
    return BtcToXchService.generateEscrowPuzzlehash(
      requestorPrivateKey: requestorPrivateKey,
      clawbackDelaySeconds: clawbackDelaySeconds,
      sweepPaymentHash: sweepPaymentHash,
      fulfillerPublicKey: fulfillerPublicKey,
    );
  }
}
