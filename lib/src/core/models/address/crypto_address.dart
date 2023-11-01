import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:equatable/equatable.dart';

abstract class CryptoAddress implements Equatable {
  static CryptoAddress? tryParse(String text) {
    final xchAddress = Address.tryParse(text);
    if (xchAddress != null) {
      return xchAddress;
    }
    final btcAddress = BtcAddress.tryParse(text);
    return btcAddress;
  }

  String get address;
}

extension AddressTypeX on CryptoAddress {
  CryptoAddressType get type {
    if (Address.tryParse(address) != null) {
      return CryptoAddressType.xch;
    }
    if (BtcAddress.tryParse(address) != null) {
      return CryptoAddressType.btc;
    }
    LoggingContext().error('Unknown address type: $address, returning btc');
    return CryptoAddressType.btc;
  }
}

enum CryptoAddressType {
  xch,
  btc,
}
