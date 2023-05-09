import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class CatFullCoin with CoinPrototypeDecoratorMixin implements CatCoin, Coin {
  const CatFullCoin({
    required this.parentCoinSpend,
    required this.catProgram,
    required this.lineageProof,
    required this.assetId,
    required this.delegate,
  });

  factory CatFullCoin.fromParentSpend({
    required CoinSpend parentCoinSpend,
    required Coin coin,
  }) {
    final catCoinBase = CatCoin.fromParentSpend(parentCoinSpend: parentCoinSpend, coin: coin);
    return CatFullCoin(
      parentCoinSpend: parentCoinSpend,
      catProgram: catCoinBase.catProgram,
      lineageProof: catCoinBase.lineageProof,
      assetId: catCoinBase.assetId,
      delegate: coin,
    );
  }

  static Future<CatFullCoin> fromParentSpendAsync({
    required CoinSpend parentCoinSpend,
    required Coin coin,
  }) async {
    final catCoinBase =
        await CatCoin.fromParentSpendAsync(parentCoinSpend: parentCoinSpend, coin: coin);
    return CatFullCoin(
      parentCoinSpend: parentCoinSpend,
      catProgram: catCoinBase.catProgram,
      lineageProof: catCoinBase.lineageProof,
      assetId: catCoinBase.assetId,
      delegate: coin,
    );
  }

  @override
  final Coin delegate;

  @override
  final Puzzlehash assetId;

  @override
  final Program catProgram;

  @override
  final Program lineageProof;

  @override
  final CoinSpend parentCoinSpend;

  Future<HydratedCatCoin> hydrate(TailDatabaseApi tailDatabaseApi) async {
    final tailInfo = await tailDatabaseApi.getTailInfo(assetId);

    return HydratedCatCoin(
      parentCoinSpend: parentCoinSpend,
      catProgram: catProgram,
      lineageProof: lineageProof,
      assetId: assetId,
      delegate: delegate,
      tailInfo: tailInfo,
    );
  }

  @override
  bool get coinbase => delegate.coinbase;

  @override
  int get confirmedBlockIndex => delegate.confirmedBlockIndex;

  @override
  int get spentBlockIndex => delegate.spentBlockIndex;

  @override
  int get timestamp => delegate.timestamp;

  @override
  Map<String, dynamic> toFullJson() {
    return delegate.toFullJson();
  }
}
