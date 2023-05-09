import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class NameRegistrationInfo with ToJsonMixin {
  NameRegistrationInfo(this.registrationAddress, this.publicKey);

  factory NameRegistrationInfo.fromJson(Map<String, dynamic> json) {
    return NameRegistrationInfo(
      pick(json, 'paymentAddress').letStringOrThrow(Address.new),
      pick(json, 'publicKey').asStringOrThrow(),
    );
  }

  final Address registrationAddress;
  final String publicKey;

  @override
  Map<String, dynamic> toJson() {
    return {
      'paymentAddress': registrationAddress.address,
      'publicKey': publicKey,
    };
  }
}
