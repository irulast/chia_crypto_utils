import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  // CreateWalletWithPlotNFTCommand used to generate test values
  final singletonCoin = CoinPrototype(
    parentCoinInfo:
        Puzzlehash.fromHex('17ff3c80192a7e616926e9194d69fd3fa0def1827964b1bf4f05d6b7de3f43c9'),
    puzzlehash:
        Puzzlehash.fromHex('01178c847be8e6766954ebf9db5c20dc263d02d0bb3cc057a1412fd1d7158daf'),
    amount: 1,
  );

  final poolState = PoolState(
    poolSingletonState: PoolSingletonState.farmingToPool,
    targetPuzzlehash:
        Puzzlehash.fromHex('6bde1e0c6f9d3b93dc5e7e878723257ede573deeed59e3b4a90f5c86de1a0bd3'),
    ownerPublicKey: JacobianPoint.fromHexG1(
      '0x95b96e957115f0bc3858163c9d89b948b895d1296dc660030f635ebc62d5d99cbdb38c6e0c995d5d92ef907e34195e8e',
    ),
    relativeLockHeight: 100,
  );

  final plotNft = PlotNft(
    launcherId:
        Puzzlehash.fromHex('17ff3c80192a7e616926e9194d69fd3fa0def1827964b1bf4f05d6b7de3f43c9'),
    singletonCoin: singletonCoin,
    poolState: poolState,
    delayTime: 604800,
    delayPuzzlehash:
        Puzzlehash.fromHex('a229c30fba7b35557ec417fbce1fc9eaf2bac74e574b2f0b079c03bde3c99d16'),
  );

  test('should correctly serialize and deserialize plot nft', () {
    final plotNftSerialized = plotNft.toBytes();
    final plotNftDeserialized = PlotNft.fromBytes(plotNftSerialized);
    final plotNftReserialized = plotNftDeserialized.toBytes();

    expect(plotNftReserialized, equals(plotNftSerialized));
  });
}
