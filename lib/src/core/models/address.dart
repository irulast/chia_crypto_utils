// ignore_for_file: lines_longer_than_80_chars

import 'package:bech32m/bech32m.dart';
import 'package:chia_utils/src/core/models/puzzlehash.dart';
import 'package:meta/meta.dart';
import 'package:chia_utils/src/core/models/bytes.dart';

@immutable
class Address {
  const Address(this.address);

  final String address;

  factory Address.fromPuzzlehash(Puzzlehash puzzlehash, String addressPrefix) {
    return Address(segwit.encode(Segwit(addressPrefix, puzzlehash.toUint8List())));
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
