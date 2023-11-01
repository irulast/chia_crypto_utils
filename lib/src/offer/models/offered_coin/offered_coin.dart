import 'package:chia_crypto_utils/chia_crypto_utils.dart';

abstract class OfferedCoin {
  CoinPrototype get coin;
  SpendType get type;
  CoinSpend toOfferSpend(List<Program> innerSolutions);
  Bytes? get assetId;
  Program get settlementProgram;
  Future<Puzzlehash> get p2Puzzlehash;
  Puzzlehash get p2PuzzlehashSync;
}

extension ToMixedCoinsX on Iterable<OfferedCoin> {
  MixedCoins toMixedCoins() {
    return MixedCoins.fromOfferedCoins(toList());
  }
}
