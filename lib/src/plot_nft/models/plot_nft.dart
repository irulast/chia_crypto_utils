import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class PlotNft with ToBytesMixin {
  PlotNft({
    required this.launcherId,
    required this.singletonCoin,
    required this.poolState,
    required this.delayTime,
    required this.delayPuzzlehash,
  });

  final Bytes launcherId;
  final CoinPrototype singletonCoin;
  final PoolState poolState;
  final int delayTime;
  final Puzzlehash delayPuzzlehash;

  factory PlotNft.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;

    final launcherId = Puzzlehash.fromStream(iterator);
    final singletonCoin = CoinPrototype.fromStream(iterator);
    final poolState = PoolState.fromStream(iterator);
    final delayTime = intFrom64BitsStream(iterator);
    final delayPuzzlehash = Puzzlehash.fromStream(iterator);

    return PlotNft(
      launcherId: launcherId,
      singletonCoin: singletonCoin,
      poolState: poolState,
      delayTime: delayTime,
      delayPuzzlehash: delayPuzzlehash,
    );
  }

  @override
  Bytes toBytes() {
    return launcherId +
        singletonCoin.toBytes() +
        poolState.toBytes() +
        intTo64Bits(delayTime) +
        delayPuzzlehash;
  }

  @override
  String toString() =>
      'PlotNft(launcherId: $launcherId, singletonCoin: $singletonCoin, poolState: $poolState, delayTime: $delayTime, delayPuzzlehash: $delayPuzzlehash)';
}
