import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class DIDWalletInfo with WalletInfoDecorator implements ChiaWalletInfo {
  DIDWalletInfo({
    required this.id,
    this.name,
    required this.didInfoWithOriginCoin,
  }) : delegate = ChiaWalletInfoImp(
          id: id,
          name: name,
          type: ChiaWalletType.did,
          data: jsonEncode(didInfoWithOriginCoin.toJson()),
          meta: {},
        );

  @override
  final ChiaWalletInfo delegate;
  @override
  final String? name;
  @override
  final int id;
  final DidInfoWithOriginCoin didInfoWithOriginCoin;
}
