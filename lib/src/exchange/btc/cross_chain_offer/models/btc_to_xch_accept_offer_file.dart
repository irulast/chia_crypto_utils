import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/cross_chain_offer_file.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/validity_time.dart';

class BtcToXchAcceptOfferFile implements CrossChainOfferFile {
  BtcToXchAcceptOfferFile({required this.validityTime, required this.publicKey});

  @override
  ValidityTime validityTime;
  @override
  JacobianPoint publicKey;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.name,
        'validity_time': validityTime.toJson(),
        'public_key': publicKey.toHex(),
      };

  factory BtcToXchAcceptOfferFile.fromJson(Map<String, dynamic> json) {
    return BtcToXchAcceptOfferFile(
      validityTime: ValidityTime.fromJson(json['validity_time'] as Map<String, dynamic>),
      publicKey: JacobianPoint.fromHexG1(json['public_key'] as String),
    );
  }

  @override
  CrossChainOfferFileType get type => CrossChainOfferFileType.btcToXchAccept;

  @override
  CrossChainOfferFilePrefix get prefix => CrossChainOfferFilePrefix.ccoffer_accept;
}
