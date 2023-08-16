import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class ColdWallet implements Wallet {
  ColdWallet({
    required this.fullNode,
    required this.keychain,
  });

  @override
  final ChiaFullNodeInterface fullNode;
  final WalletKeychain keychain;

  @override
  WalletKeychain getKeychain() => keychain;

  @override
  Future<List<CatFullCoin>> getCatCoins() async {
    final catCoins = <CatFullCoin>[];
    for (final puzzlehash in keychain.puzzlehashes) {
      final catCoinsByHint = await fullNode.getCatCoinsByHint(puzzlehash);
      catCoins.addAll(catCoinsByHint);
    }

    return catCoins;
  }

  @override
  Future<List<DidInfoWithOriginCoin>> getDidInfosWithOriginCoin() async {
    final didRecords = await fullNode.getDidRecordsFromHints(keychain.puzzlehashes);

    final didInfosWithOriginCoin = <DidInfoWithOriginCoin>[];
    for (final didRecord in didRecords) {
      final didInfoWithOriginCoin = await didRecord.toDidInfo(keychain)?.fetchOriginCoin(fullNode);

      if (didInfoWithOriginCoin != null) {
        didInfosWithOriginCoin.add(didInfoWithOriginCoin);
      }
    }

    return didInfosWithOriginCoin;
  }

  @override
  Future<List<CatCoin>> getCatCoinsByAssetId(Puzzlehash assetId, {int catVersion = 2}) {
    if (!keychain.hasAssetId(assetId)) {
      switch (catVersion) {
        case 1:
          keychain.addCat1OuterPuzzleHashesForAssetId(assetId);
          break;
        case 2:
          keychain.addOuterPuzzleHashesForAssetId(assetId);
          break;
        default:
          throw Exception('Invalid catVersion: $catVersion');
      }
    }
    final outerPuzzlehashes = keychain.getOuterPuzzleHashesForAssetId(assetId);
    return fullNode
        .getCatCoinsByOuterPuzzleHashes(outerPuzzlehashes)
        .then((value) => value.where((element) => element.catVersion == catVersion).toList());
  }

  @override
  Future<List<Coin>> getCoins() => fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);
}
