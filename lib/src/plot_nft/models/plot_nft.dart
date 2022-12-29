import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/plot_nft/models/lineage_proof.dart';

class PlotNft with ToBytesMixin {
  PlotNft({
    required this.launcherId,
    required this.singletonCoin,
    required this.poolState,
    required this.delayTime,
    required this.delayPuzzlehash,
    required this.lineageProof,
  });

  final Bytes launcherId;
  final CoinPrototype singletonCoin;
  final PoolState poolState;
  final int delayTime;
  final Puzzlehash delayPuzzlehash;
  final LineageProof lineageProof;

  factory PlotNft.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;

    final launcherId = Puzzlehash.fromStream(iterator);
    final singletonCoin = CoinPrototype.fromStream(iterator);
    final poolState = PoolState.fromStream(iterator);
    final delayTime = intFrom64BitsStream(iterator);
    final delayPuzzlehash = Puzzlehash.fromStream(iterator);
    final lineageProof = LineageProof.fromStream(iterator);

    return PlotNft(
      launcherId: launcherId,
      singletonCoin: singletonCoin,
      poolState: poolState,
      delayTime: delayTime,
      delayPuzzlehash: delayPuzzlehash,
      lineageProof: lineageProof,
    );
  }

  Puzzlehash get contractPuzzlehash => PlotNftWalletService.launcherIdToP2Puzzlehash(
        launcherId,
        delayTime,
        delayPuzzlehash,
      );
  Future<Puzzlehash> get contractPuzzlehashAsync =>
      PlotNftWalletService.launcherIdToP2PuzzlehashAsync(
        launcherId,
        delayTime,
        delayPuzzlehash,
      );
  @override
  Bytes toBytes() {
    return launcherId +
        singletonCoin.toBytes() +
        poolState.toBytes() +
        intTo64Bits(delayTime) +
        delayPuzzlehash +
        lineageProof.toBytes();
  }

  @override
  String toString() =>
      'PlotNft(launcherId: $launcherId, singletonCoin: $singletonCoin, poolState: $poolState, delayTime: $delayTime, delayPuzzlehash: $delayPuzzlehash, lineagProof: $lineageProof';
}
