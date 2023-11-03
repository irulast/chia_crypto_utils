import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class FullDidRecordWithOriginCoin {
  const FullDidRecordWithOriginCoin({
    required this.didRecord,
    required this.originCoin,
  });

  final FullDidRecord didRecord;
  final CoinPrototype originCoin;

  DidInfoWithOriginCoin? toDidInfoWithOriginCoin(WalletKeychain keychain) {
    final didInfo = didRecord.toDidInfo(keychain);

    if (didInfo != null) {
      return DidInfoWithOriginCoin(didInfo: didInfo, originCoin: originCoin);
    }

    return null;
  }
}
