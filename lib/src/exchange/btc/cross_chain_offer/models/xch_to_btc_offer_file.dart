import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/cross_chain_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/exchange_amount.dart';
import 'package:chia_crypto_utils/src/exchange/btc/models/lightning_payment_request.dart';
import 'package:chia_crypto_utils/src/exchange/btc/utils/decode_lightning_payment_request.dart';

class XchToBtcOfferFile implements CrossChainOfferFile {
  XchToBtcOfferFile({
    required this.offeredAmount,
    required this.requestedAmount,
    required this.messageAddress,
    required this.publicKey,
    required this.lightningPaymentRequest,
  });

  ExchangeAmount offeredAmount;
  ExchangeAmount requestedAmount;
  Address messageAddress;
  @override
  JacobianPoint publicKey;
  LightningPaymentRequest lightningPaymentRequest;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.name,
        'offered': offeredAmount.toJson(),
        'requested': requestedAmount.toJson(),
        'message_address': <String, dynamic>{
          'type': messageAddress.prefix,
          'address': messageAddress.address
        },
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
      publicKey: JacobianPoint.fromHexG1(json['public_key'] as String),
      lightningPaymentRequest: decodeLightningPaymentRequest(
        (json['lightning_payment_request'] as Map<String, dynamic>)['payment_request'] as String,
      ),
    );
  }

  @override
  CrossChainOfferFileType get type => CrossChainOfferFileType.xchToBtc;

  @override
  CrossChainOfferFilePrefix get prefix => CrossChainOfferFilePrefix.ccoffer;
}
