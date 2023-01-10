import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class XchToBtcOfferAcceptFile implements CrossChainOfferAcceptFile {
  XchToBtcOfferAcceptFile({
    required this.validityTime,
    required this.publicKey,
    required this.acceptedOfferHash,
    required this.lightningPaymentRequest,
  });

  @override
  int validityTime;
  @override
  JacobianPoint publicKey;
  LightningPaymentRequest lightningPaymentRequest;
  @override
  Bytes acceptedOfferHash;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'validity_time': validityTime,
        'public_key': publicKey.toHex(),
        'lightning_payment_request': <String, dynamic>{
          'payment_request': lightningPaymentRequest.paymentRequest,
          'timeout': lightningPaymentRequest.tags.timeout
        },
        'accepted_offer_hash': acceptedOfferHash.toHex(),
      };

  factory XchToBtcOfferAcceptFile.fromJson(Map<String, dynamic> json) {
    return XchToBtcOfferAcceptFile(
      validityTime: json['validity_time'] as int,
      publicKey: JacobianPoint.fromHexG1(json['public_key'] as String),
      lightningPaymentRequest: decodeLightningPaymentRequest(
        (json['lightning_payment_request'] as Map<String, dynamic>)['payment_request'] as String,
      ),
      acceptedOfferHash: (json['accepted_offer_hash'] as String).hexToBytes(),
    );
  }

  static XchToBtcOfferAcceptFile? maybeFromSerializedOfferFile(String serializedOfferFile) {
    try {
      final deserializedOfferFile = deserializeCrossChainOfferFile(serializedOfferFile);
      if (deserializedOfferFile.type != CrossChainOfferFileType.xchToBtcAccept) {
        return null;
      }
      return deserializedOfferFile as XchToBtcOfferAcceptFile;
    } catch (e) {
      return null;
    }
  }

  factory XchToBtcOfferAcceptFile.fromSerializedOfferFile(String serializedOfferFile) {
    final deserializedOfferFile = maybeFromSerializedOfferFile(serializedOfferFile);

    if (deserializedOfferFile == null) {
      throw InvalidCrossChainOfferType(CrossChainOfferFileType.xchToBtcAccept.name);
    }
    return deserializedOfferFile;
  }

  @override
  CrossChainOfferExchangeInfo getExchangeInfo(
    CrossChainOfferFile offerFile,
    PrivateKey requestorPrivateKey,
  ) {
    final btcToXchOfferFile = offerFile as BtcToXchOfferFile;

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
}
