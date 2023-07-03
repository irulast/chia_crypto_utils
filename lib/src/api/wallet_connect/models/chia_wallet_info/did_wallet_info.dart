import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class DIDWalletInfo with WalletInfoDecorator implements ChiaWalletInfo {
  const DIDWalletInfo(this.delegate, this.didInfo);

  factory DIDWalletInfo.fromDID(
      {required DidInfo did, required CoinPrototype originCoin, required int id, String? name}) {
    final delegate = ChiaWalletInfoImp(
      id: id,
      name: name,
      type: ChiaWalletType.did,
      data: jsonEncode(did.toChiaJson(originCoin)),
      meta: {},
    );

    return DIDWalletInfo(delegate, did);
  }

  @override
  final ChiaWalletInfo delegate;
  final DidInfo didInfo;
}
