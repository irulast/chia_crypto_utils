import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class FullDidRecord implements DidRecord {
  const FullDidRecord(this.delegate, this.coin);

  final DidRecord delegate;
  @override
  final Coin coin;

  @override
  Puzzlehash get backUpIdsHash => delegate.backUpIdsHash;

  @override
  List<Puzzlehash>? get backupIds => delegate.backupIds;

  @override
  Bytes get did => delegate.did;

  @override
  List<Puzzlehash> get hints => delegate.hints;

  @override
  LineageProof get lineageProof => delegate.lineageProof;

  @override
  DidMetadata get metadata => delegate.metadata;

  @override
  int get nVerificationsRequired => delegate.nVerificationsRequired;

  @override
  CoinSpend get parentSpend => delegate.parentSpend;

  @override
  Program get singletonStructure => delegate.singletonStructure;

  @override
  DidInfo? toDidInfoForPk(JacobianPoint publicKey) =>
      delegate.toDidInfoForPk(publicKey);

  @override
  DidInfo? toDidInfoFromParentInfo() => delegate.toDidInfoFromParentInfo();

  static FullDidRecord? fromParentCoinSpend(CoinSpend parentSpend, Coin coin) {
    final didRecord = DidRecord.fromParentCoinSpend(parentSpend, coin);

    if (didRecord != null) {
      return FullDidRecord(didRecord, coin);
    }

    return null;
  }

  static Future<FullDidRecord?> fromParentCoinSpendAsync(
    CoinSpend parentSpend,
    Coin coin,
  ) async {
    final didRecord =
        await DidRecord.fromParentCoinSpendAsync(parentSpend, coin);

    if (didRecord != null) {
      return FullDidRecord(didRecord, coin);
    }

    return null;
  }

  Future<FullDidRecordWithOriginCoin?> fetchOriginCoin(
    ChiaFullNodeInterface fullNode,
  ) async {
    final originCoin = await fullNode.getCoinById(did);

    if (originCoin != null) {
      return FullDidRecordWithOriginCoin(
        didRecord: this,
        originCoin: originCoin,
      );
    }

    return null;
  }
}
