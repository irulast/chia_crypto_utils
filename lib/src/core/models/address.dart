import 'package:bech32m/bech32m.dart';
import 'package:chia_utils/src/core/models/puzzlehash.dart';

class Address {
  String address;

  Address(
    this.address,
  );

  factory Address.fromPuzzlehash(Puzzlehash puzzlehash, String addressPrefix) {
    return Address(segwit.encode(Segwit(addressPrefix, puzzlehash.bytes)));
  }

  Puzzlehash toPuzzlehash() {
    return Puzzlehash(segwit.decode(address).program);
  }
}