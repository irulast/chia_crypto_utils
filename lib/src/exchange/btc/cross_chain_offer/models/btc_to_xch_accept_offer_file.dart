import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class BtcToXchOfferAcceptFile implements CrossChainOfferAcceptFile {
  BtcToXchOfferAcceptFile({
    required this.validityTime,
    required this.publicKey,
    required this.acceptedOfferHash,
  });

  @override
  int validityTime;
  @override
  JacobianPoint publicKey;
  @override
  Bytes acceptedOfferHash;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'validity_time': validityTime,
        'public_key': publicKey.toHex(),
        'accepted_offer_hash': acceptedOfferHash.toHex(),
      };

  factory BtcToXchOfferAcceptFile.fromJson(Map<String, dynamic> json) {
    return BtcToXchOfferAcceptFile(
      validityTime: json['validity_time'] as int,
      publicKey: JacobianPoint.fromHexG1(json['public_key'] as String),
      acceptedOfferHash: (json['accepted_offer_hash'] as String).hexToBytes(),
    );
  }

  static BtcToXchOfferAcceptFile? maybeFromSerializedOfferFile(String serializedOfferFile) {
    try {
      final deserializedOfferFile = deserializeCrossChainOfferFile(serializedOfferFile);
      if (deserializedOfferFile.type != CrossChainOfferFileType.btcToXchAccept) {
        return null;
      }
      return deserializedOfferFile as BtcToXchOfferAcceptFile;
    } catch (e) {
      return null;
    }
  }

  factory BtcToXchOfferAcceptFile.fromSerializedOfferFile(String serializedOfferFile) {
    final deserializedOfferFile = maybeFromSerializedOfferFile(serializedOfferFile);

    if (deserializedOfferFile == null) {
      throw InvalidCrossChainOfferType(CrossChainOfferFileType.btcToXchAccept.name);
    }
    return deserializedOfferFile;
  }

  @override
  CrossChainOfferExchangeInfo getExchangeInfo(
    CrossChainOfferFile offerFile,
    PrivateKey requestorPrivateKey,
  ) {
    final xchToBtcOfferFile = offerFile as XchToBtcOfferFile;

    final amountMojos = xchToBtcOfferFile.offeredAmount.amount;
    final amountSatoshis = xchToBtcOfferFile.requestedAmount.amount;
    final paymentRequest = xchToBtcOfferFile.lightningPaymentRequest;
    final paymentHash = paymentRequest.tags.paymentHash!;
    final fulfillerPublicKey = xchToBtcOfferFile.publicKey;

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
  CrossChainOfferFileType get type => CrossChainOfferFileType.btcToXchAccept;

  @override
  CrossChainOfferFilePrefix get prefix => CrossChainOfferFilePrefix.ccoffer_accept;
}
