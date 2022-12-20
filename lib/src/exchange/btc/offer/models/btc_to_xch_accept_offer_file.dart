import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class BtcToXchAcceptOfferFile {
  BtcToXchAcceptOfferFile({required this.validityTime, required this.publicKey});

  int validityTime;
  JacobianPoint publicKey;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'validity_time': validityTime,
        'public_key': publicKey.toHex(),
      };

  factory BtcToXchAcceptOfferFile.fromJson(Map<String, dynamic> json) {
    return BtcToXchAcceptOfferFile(
      validityTime: json['validity_time'] as int,
      publicKey: JacobianPoint.fromHexG1(json['public_key'] as String),
    );
  }
}
