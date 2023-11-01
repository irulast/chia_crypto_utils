import 'package:bitcoin_base/bitcoin.dart';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/models/address/crypto_address.dart';
import 'package:equatable/equatable.dart';

class BtcAddress extends Equatable implements CryptoAddress {
  const BtcAddress(this.address);

  static BtcAddress? tryParse(String address) {
    if (_parseBipAddress(address) != null || _parseSegwitAddress(address) != null) {
      return BtcAddress(address);
    }
    return null;
  }

  static BipAddress? _parseBipAddress(String address) {
    try {
      return P2shAddress(address: address);
    } catch (_) {}

    try {
      return P2pkhAddress(address: address);
    } catch (_) {}

    return null;
  }

  static SegwitAddress? _parseSegwitAddress(String address) {
    try {
      return P2wpkhAddress(address: address);
    } catch (_) {}

    try {
      return P2trAddress(address: address);
    } catch (_) {}
    return null;
  }

  @override
  final String address;

  @override
  List<Object?> get props => [address];
}
