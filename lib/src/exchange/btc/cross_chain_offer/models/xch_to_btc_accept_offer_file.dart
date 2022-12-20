import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/cross_chain_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/validity_time.dart';
import 'package:chia_crypto_utils/src/exchange/btc/models/lightning_payment_request.dart';
import 'package:chia_crypto_utils/src/exchange/btc/utils/decode_lightning_payment_request.dart';

class XchToBtcAcceptOfferFile implements CrossChainOfferFile {
  XchToBtcAcceptOfferFile({
    required this.validityTime,
    required this.publicKey,
    required this.lightningPaymentRequest,
  });

  @override
  ValidityTime validityTime;
  @override
  JacobianPoint publicKey;
  LightningPaymentRequest lightningPaymentRequest;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.name,
        'validity_time': validityTime.toJson(),
        'public_key': publicKey.toHex(),
        'lightning_payment_request': <String, dynamic>{
          'payment_request': lightningPaymentRequest.paymentRequest,
          'timeout': lightningPaymentRequest.tags.timeout
        }
      };

  factory XchToBtcAcceptOfferFile.fromJson(Map<String, dynamic> json) {
    return XchToBtcAcceptOfferFile(
      validityTime: ValidityTime.fromJson(json['validity_time'] as Map<String, dynamic>),
      publicKey: JacobianPoint.fromHexG1(json['public_key'] as String),
      lightningPaymentRequest: decodeLightningPaymentRequest(
        (json['lightning_payment_request'] as Map<String, dynamic>)['payment_request'] as String,
      ),
    );
  }

  @override
  CrossChainOfferFileType get type => CrossChainOfferFileType.xchToBtcAccept;

  @override
  CrossChainOfferFilePrefix get prefix => CrossChainOfferFilePrefix.ccoffer_accept;
}
