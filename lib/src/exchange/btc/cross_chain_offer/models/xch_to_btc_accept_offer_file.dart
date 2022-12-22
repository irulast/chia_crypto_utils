import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/cross_chain_offer_accept_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/cross_chain_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/models/lightning_payment_request.dart';
import 'package:chia_crypto_utils/src/exchange/btc/utils/decode_lightning_payment_request.dart';

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

  @override
  CrossChainOfferFileType get type => CrossChainOfferFileType.xchToBtcAccept;

  @override
  CrossChainOfferFilePrefix get prefix => CrossChainOfferFilePrefix.ccoffer_accept;
}
