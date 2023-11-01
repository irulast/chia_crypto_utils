import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class ColdWallet implements Wallet {
  ColdWallet({
    required this.fullNode,
    required this.keychain,
  });

  @override
  final EnhancedChiaFullNodeInterface fullNode;
  final WalletKeychain keychain;

  @override
  WalletKeychain getKeychain() => keychain;

  @override
  Future<List<CatFullCoin>> getCatCoins() => fullNode.getCatCoinsByHints(keychain.puzzlehashes);

  @override
  Future<List<DidInfoWithOriginCoin>> getDidInfosWithOriginCoin() async {
    final didRecords = await fullNode.getDidRecordsByHints(keychain.puzzlehashes);

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
  Future<List<NftRecordWithMintInfo>> getNftRecordsWithMintInfo() async {
    final nftRecords = await fullNode.getNftRecordsByHints(keychain.puzzlehashes);

    final nftRecordsWithMintInfo = <NftRecordWithMintInfo>[];

    for (final nftRecord in nftRecords) {
      final nftRecordWithMintInfo = await nftRecord.fetchMintInfo(fullNode);

      if (nftRecordWithMintInfo != null) {
        nftRecordsWithMintInfo.add(nftRecordWithMintInfo);
      }
    }

    return nftRecordsWithMintInfo;
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
          throw InvalidCatException(message: 'Invalid cat version: $catVersion');
      }
    }
    final outerPuzzlehashes = keychain.getOuterPuzzleHashesForAssetId(assetId);

    return fullNode
        .getCatCoinsByOuterPuzzleHashes(outerPuzzlehashes)
        .then((value) => value.where((element) => element.catVersion == catVersion).toList());
  }

  @override
  Future<List<Coin>> getCoins() => fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);
  @override
  Future<NftRecord?> getNftRecordByLauncherId(Bytes launcherId) =>
      fullNode.getNftByLauncherId(launcherId);
}
