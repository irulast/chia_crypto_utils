import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:compute/compute.dart';

class XchToBtcTakerOfferFile implements TakerCrossChainOfferFile {
  XchToBtcTakerOfferFile({
    this.initializationCoinId,
    required this.validityTime,
    required this.publicKey,
    required this.acceptedOfferHash,
    required this.lightningPaymentRequest,
  });

  factory XchToBtcTakerOfferFile._fromSerializedOfferFileTask(String serializedOfferFile) {
    return XchToBtcTakerOfferFile.fromSerializedOfferFile(serializedOfferFile);
  }

  factory XchToBtcTakerOfferFile.fromSerializedOfferFile(String serializedOfferFile) {
    final deserializedOfferFile = maybeFromSerializedOfferFile(serializedOfferFile);

    if (deserializedOfferFile == null) {
      throw InvalidCrossChainOfferType(CrossChainOfferFileType.xchToBtcAccept.name);
    }
    return deserializedOfferFile;
  }

  factory XchToBtcTakerOfferFile.fromJson(Map<String, dynamic> json) {
    return XchToBtcTakerOfferFile(
      initializationCoinId: (json['initialization_coin_id'] as String?)?.hexToBytes(),
      validityTime: json['validity_time'] as int,
      publicKey: JacobianPoint.fromHexG1(json['public_key'] as String),
      lightningPaymentRequest: decodeLightningPaymentRequest(
        (json['lightning_payment_request'] as Map<String, dynamic>)['payment_request'] as String,
      ),
      acceptedOfferHash: (json['accepted_offer_hash'] as String).hexToBytes(),
    );
  }

  @override
  final Bytes? initializationCoinId;
  @override
  final int validityTime;
  @override
  final JacobianPoint publicKey;
  @override
  final LightningPaymentRequest lightningPaymentRequest;
  @override
  final Bytes acceptedOfferHash;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'initialization_coin_id': initializationCoinId?.toHex(),
        'validity_time': validityTime,
        'public_key': publicKey.toHex(),
        'lightning_payment_request': <String, dynamic>{
          'payment_request': lightningPaymentRequest.paymentRequest,
          'timeout': lightningPaymentRequest.tags.timeout
        },
        'accepted_offer_hash': acceptedOfferHash.toHex(),
      };

  static XchToBtcTakerOfferFile? maybeFromSerializedOfferFile(String serializedOfferFile) {
    try {
      final deserializedOfferFile =
          CrossChainOfferFile.fromSerializedOfferFile(serializedOfferFile);
      if (deserializedOfferFile.type != CrossChainOfferFileType.xchToBtcAccept) {
        return null;
      }
      return deserializedOfferFile as XchToBtcTakerOfferFile;
    } catch (e) {
      return null;
    }
  }

  static Future<XchToBtcTakerOfferFile> fromSerializedOfferFileAsync(
    String serializedOfferFile,
  ) async {
    final result =
        await compute(XchToBtcTakerOfferFile._fromSerializedOfferFileTask, serializedOfferFile);

    return result;
  }

  @override
  CrossChainOfferExchangeInfo getExchangeInfo(
    CrossChainOfferFile offerFile,
    PrivateKey requestorPrivateKey,
  ) {
    final btcToXchOfferFile = offerFile as BtcToXchMakerOfferFile;

    final amountMojos = btcToXchOfferFile.requestedAmount.amount;
    final amountSatoshis = btcToXchOfferFile.offeredAmount.amount;
    final fulfillerPublicKey = btcToXchOfferFile.publicKey;

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
  CrossChainOfferFileType get type => CrossChainOfferFileType.xchToBtcAccept;

  @override
  CrossChainOfferFilePrefix get prefix => CrossChainOfferFilePrefix.ccoffer_accept;

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
