import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/offer/models/offered_coin/offered_coin.dart';

class OfferedStandardCoin implements OfferedCoin {
  OfferedStandardCoin(this.coin, this.settlementProgram);
  factory OfferedStandardCoin.fromOfferBundleCoin(CoinPrototype coin) {
    final matchingSettlementProgram = () {
      for (final settlementProgram in [settlementPaymentsProgram, settlementPaymentsProgramOld]) {
        if (settlementProgram.hash() == coin.puzzlehash) {
          return settlementProgram;
        }
      }
      throw Exception('no matching settlement program');
    }();

    return OfferedStandardCoin(coin, matchingSettlementProgram);
  }

  @override
  Bytes? get assetId => null;

  @override
  final CoinPrototype coin;

  @override
  final Program settlementProgram;

  @override
  CoinSpend toOfferSpend(List<Program> innerSolutions) {
    return CoinSpend(
      coin: coin,
      puzzleReveal: settlementProgram,
      solution: Program.list(innerSolutions),
    );
  }

  @override
  SpendType get type => SpendType.standard;

  @override
  Future<Puzzlehash> get p2Puzzlehash async => p2PuzzlehashSync;

  @override
  Puzzlehash get p2PuzzlehashSync => coin.puzzlehash;
}
