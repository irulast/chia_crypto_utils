import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class NameInfo with ToJsonMixin {
  NameInfo({
    required this.address,
  });

  final Address address;

  NameInfo.fromJson(Map<String, dynamic> json) : address = Address(json['address'] as String);

  @override
  Map<String, dynamic> toJson() {
    return {'address': address.address};
  }
}
