// ignore_for_file: lines_longer_than_80_chars

import 'package:bech32m/bech32m.dart';
import 'package:chia_crypto_utils/src/clvm/bytes.dart';
import 'package:chia_crypto_utils/src/context/index.dart';
import 'package:chia_crypto_utils/src/core/models/address/crypto_address.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class Address extends Equatable implements CryptoAddress {
  const Address(this.address);
  Address.fromPuzzlehash(Puzzlehash puzzlehash, String addressPrefix)
      : address = segwit.encode(Segwit(addressPrefix, puzzlehash));

  factory Address.fromContext(Puzzlehash puzzlehash) {
    final addressPrefix = NetworkContext().blockchainNetwork.addressPrefix;
    return Address.fromPuzzlehash(puzzlehash, addressPrefix);
  }

  /// throws [InvalidAddressException] if address parsing fails
  factory Address.parse(String text) {
    final address = tryParse(text);
    if (address == null) {
      throw InvalidAddressException(text);
    }
    return address;
  }

  static Address? tryParse(String text) {
    try {
      if (!_prefixes.any((prefix) => text.startsWith(prefix))) {
        return null;
      }

      final address = Address(text)..toPuzzlehash();
      return address;
    } catch (e) {
      return null;
    }
  }

  @override
  final String address;

  static const _prefixes = {'xch', 'txch'};

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

  @override
  List<Object?> get props => [address];
}

class InvalidAddressException implements Exception {
  InvalidAddressException(this.address);

  final String address;

  @override
  String toString() => 'Invalid Address: $address';
}
