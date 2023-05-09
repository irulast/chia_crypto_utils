import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class HydratedCatCoin extends CatFullCoin {
  HydratedCatCoin({
    required super.parentCoinSpend,
    required super.catProgram,
    required super.lineageProof,
    required super.assetId,
    required super.delegate,
    required this.tailInfo,
  });

  final TailInfo tailInfo;
}
