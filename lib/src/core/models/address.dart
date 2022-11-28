// ignore_for_file: lines_longer_than_80_chars

import 'package:bech32m/bech32m.dart';
import 'package:chia_crypto_utils/src/clvm/bytes.dart';
import 'package:chia_crypto_utils/src/context/index.dart';
import 'package:meta/meta.dart';

@immutable
class Address {
  const Address(this.address);

  Address.fromPuzzlehash(Puzzlehash puzzlehash, String addressPrefix)
      : address = segwit.encode(Segwit(addressPrefix, puzzlehash));

  factory Address.fromContext(Puzzlehash puzzlehash) {
    final addressPrefix = NetworkContext().blockchainNetwork.addressPrefix;
    return Address.fromPuzzlehash(puzzlehash, addressPrefix);
  }

  final String address;

  String get prefix => address.startsWith('txch') ? 'txch' : 'xch';

  Puzzlehash toPuzzlehash() {
    return Puzzlehash(segwit.decode(address).program);
  }

  @override
  int get hashCode => address.hashCode;

  @override
  bool operator ==(Object other) {
    return other is Address && other.address == address;
  }

  @override
  String toString() => 'Address($address)';
}
