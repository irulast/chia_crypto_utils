import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/cross_chain_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/exchange_amount.dart';

class BtcToXchOfferFile implements CrossChainOfferFile {
  BtcToXchOfferFile({
    required this.offeredAmount,
    required this.requestedAmount,
    required this.messageAddress,
    required this.publicKey,
  });

  ExchangeAmount offeredAmount;
  ExchangeAmount requestedAmount;
  Address messageAddress;
  @override
  JacobianPoint publicKey;

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
      };

  factory BtcToXchOfferFile.fromJson(Map<String, dynamic> json) {
    return BtcToXchOfferFile(
      offeredAmount: ExchangeAmount.fromJson(json['offered'] as Map<String, dynamic>),
      requestedAmount: ExchangeAmount.fromJson(json['requested'] as Map<String, dynamic>),
      messageAddress:
          Address((json['message_address'] as Map<String, dynamic>)['address'] as String),
      publicKey: JacobianPoint.fromHexG1(json['public_key'] as String),
    );
  }

  @override
  CrossChainOfferFileType get type => CrossChainOfferFileType.btcToXch;

  @override
  CrossChainOfferFilePrefix get prefix => CrossChainOfferFilePrefix.ccoffer;
}
