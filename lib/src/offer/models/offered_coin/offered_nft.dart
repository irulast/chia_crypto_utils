import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/offer/models/offered_coin/offered_coin.dart';

class OfferedNft implements OfferedCoin {
  OfferedNft(this.nft, this.settlementProgram);

  factory OfferedNft.fromOfferBundleParentSpend(CoinPrototype coin, CoinSpend parentSpend) {
    final nftRecord = NftRecord.fromParentCoinSpend(parentSpend, coin);
    if (nftRecord == null) {
      throw InvalidNftException();
    }
    final nftFullPuzzleAndSettlementProgram = () {
      for (final settlementProgram in [settlementPaymentsProgram, settlementPaymentsProgramOld]) {
        final fullPuzzleWithOfferInnerPuzzle =
            nftRecord.getFullPuzzleWithNewP2Puzzle(settlementProgram);
        if (fullPuzzleWithOfferInnerPuzzle.hash() == coin.puzzlehash) {
          return [fullPuzzleWithOfferInnerPuzzle, settlementProgram];
        }
      }
      throw Exception('no matching settlement program');
    }();

    return OfferedNft(
      Nft.fromFullPuzzle(
        fullPuzzle: nftFullPuzzleAndSettlementProgram[0],
        singletonCoin: coin,
        lineageProof: nftRecord.lineageProof,
      ),
      nftFullPuzzleAndSettlementProgram[1],
    );
  }

  @override
  CoinPrototype get coin => nft.coin;

  final Nft nft;

  @override
  CoinSpend toOfferSpend(List<Program> innerSolutions) {
    return nft.toSpendWithInnerSolution(Program.list(innerSolutions));
  }

  @override
  SpendType get type => SpendType.nft;

  @override
  Bytes get assetId => nft.launcherId;

  @override
  final Program settlementProgram;

  @override
  Future<Puzzlehash> get p2Puzzlehash async => p2PuzzlehashSync;

  @override
  Puzzlehash get p2PuzzlehashSync => nft.p2Puzzlehash;
}
