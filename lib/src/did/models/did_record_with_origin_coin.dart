import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class DidRecordWithOriginCoin {
  const DidRecordWithOriginCoin(
      {required this.didRecord, required this.originCoin});

  final DidRecord didRecord;
  final CoinPrototype originCoin;

  DidInfoWithOriginCoin? toDidInfoWithOriginCoin(WalletKeychain keychain) {
    final didInfo = didRecord.toDidInfo(keychain);

    if (didInfo != null) {
      return DidInfoWithOriginCoin(didInfo: didInfo, originCoin: originCoin);
    }

    return null;
  }

  Future<DidInfoWithOriginCoin?> toDidInfoWithOriginCoinAsync(
      WalletKeychain keychain) async {
    final didInfo = await didRecord.toDidInfoAsync(keychain);

    if (didInfo != null) {
      return DidInfoWithOriginCoin(didInfo: didInfo, originCoin: originCoin);
    }

    return null;
  }
}
