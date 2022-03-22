import 'package:bech32m/bech32m.dart';
import 'package:chia_utils/src/core/models/puzzlehash.dart';
import 'package:meta/meta.dart';

@immutable
class Address {
  const Address(this.address);

  final String address;

  factory Address.fromPuzzlehash(Puzzlehash puzzlehash, String addressPrefix) {
    return Address(segwit.encode(Segwit(addressPrefix, puzzlehash.bytes)));
  }

  Puzzlehash toPuzzlehash() {
    return Puzzlehash(segwit.decode(address).program);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ address.hashCode;

  @override
  bool operator ==(Object other) {
    return other is Address && other.address == address;
  }

  @override
  String toString() {
    return 'Address($address)';
  }
}
