// ignore_for_file: annotate_overrides

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class XchToBtcOfferFile implements CrossChainOfferFile {
  XchToBtcOfferFile({
    required this.offeredAmount,
    required this.requestedAmount,
    required this.messageAddress,
    required this.validityTime,
    required this.publicKey,
    required this.lightningPaymentRequest,
  });

  ExchangeAmount offeredAmount;
  ExchangeAmount requestedAmount;
  Address messageAddress;
  @override
  int validityTime;
  @override
  JacobianPoint publicKey;
  LightningPaymentRequest lightningPaymentRequest;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
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

  factory XchToBtcOfferFile.fromJson(Map<String, dynamic> json) {
    return XchToBtcOfferFile(
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

  static XchToBtcOfferFile? maybeFromSerializedOfferFile(String serializedOfferFile) {
    try {
      final deserializedOfferFile = deserializeCrossChainOfferFile(serializedOfferFile);
      if (deserializedOfferFile.type != CrossChainOfferFileType.xchToBtc) {
        return null;
      }
      return deserializedOfferFile as XchToBtcOfferFile;
    } catch (e) {
      return null;
    }
  }

  factory XchToBtcOfferFile.fromSerializedOfferFile(String serializedOfferFile) {
    final deserializedOfferFile = maybeFromSerializedOfferFile(serializedOfferFile);

    if (deserializedOfferFile == null) {
      throw InvalidCrossChainOfferType(CrossChainOfferFileType.xchToBtc.name);
    }
    return deserializedOfferFile;
  }

  @override
  CrossChainOfferExchangeInfo getExchangeInfo(
    CrossChainOfferFile offerAcceptFile,
    PrivateKey requestorPrivateKey,
  ) {
    final btcToXchOfferAcceptFile = offerAcceptFile as BtcToXchOfferAcceptFile;

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
}
