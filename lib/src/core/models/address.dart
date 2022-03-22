// ignore_for_file: lines_longer_than_80_chars

import 'package:bech32m/bech32m.dart';
import 'package:chia_utils/src/core/models/bytes.dart';

class Address {
  String address;

  Address(
    this.address,
  );

  factory Address.fromPuzzlehash(Puzzlehash puzzlehash, String addressPrefix) {
    return Address(segwit.encode(Segwit(addressPrefix, puzzlehash.toUint8List())));
  }

  Puzzlehash toPuzzlehash() {
    return Puzzlehash(segwit.decode(address).program);
  }
}
