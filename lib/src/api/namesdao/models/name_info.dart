import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class NameInfo {
  NameInfo({
    required this.address,
  });

  final Address address;

  NameInfo.fromJson(Map<String, dynamic> json) : address = Address(json['address'] as String);
}
