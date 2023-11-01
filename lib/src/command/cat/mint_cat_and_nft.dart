import 'package:chia_crypto_utils/chia_crypto_utils.dart';

/// for getting eve coin of cat and logo nft for tail database registration
Future<void> mintEverythingWithSignatureCatAndNft({
  required EnhancedChiaFullNodeInterface fullNode,
  required String tailLogoUrl,
  required String metadataUrl,
  required WalletKeychain keychain,
  required Puzzlehash destinationPuzzleHash,
  required PrivateKey tailPrivateKey,
  required PrivateKey didPrivateKey,
  required Bytes did,
  required int mintFee,
}) async {
  final nonSwitchPuzzleHashes = keychain.puzzlehashes.sublist(1);
  final tailService = EverythingWithSignatureTailService();
  final nftWalletService = NftWalletService();
  final blockChainUtils = BlockchainUtils(fullNode, logger: print);

  var coins = await fullNode.getCoinsByPuzzleHashes(nonSwitchPuzzleHashes);

  final issuanceResult = tailService.makeIssuanceSpendBundle(
    standardCoins: selectCoinsForAmount(
      coins,
      mintFee + 2,
      selectionType: CoinSelectionType.biggetsFirst,
    ),
    tailPrivateKey: tailPrivateKey,
    destinationPuzzlehash: destinationPuzzleHash,
    changePuzzlehash: nonSwitchPuzzleHashes.random,
    amount: 2,
    keychain: keychain,
    fee: mintFee,
  );
  final catIssuanceSpendBundle = issuanceResult.spendBundle;
  await fullNode.pushTransaction(catIssuanceSpendBundle);
  await blockChainUtils.waitForSpendBundle(
    catIssuanceSpendBundle,
    logMessage: 'Waiting for cat mint bundle to be included',
  );

  final netAdditions = catIssuanceSpendBundle.netAdditions.toSet();

  final resultingCat = (await fullNode.getCatCoinsByHints([destinationPuzzleHash]))
      .singleWhere(netAdditions.contains);

  print('asset id:${resultingCat.assetId}');

  final evgCoinId = resultingCat.parentCoinInfo;
  print('eve coin id: $evgCoinId');

  coins = await fullNode.getCoinsByPuzzleHashes(nonSwitchPuzzleHashes);

  final didInfo =
      await fullNode.getDidRecordsByHints([getPuzzleFromPk(didPrivateKey.getG1()).hash()]).then(
    (value) => value.singleWhere((element) => element.did == did),
  );

  final uriHashProvider = UriHashProvider();

  final nftMintBundle = nftWalletService.createGenerateNftSpendBundle(
    minterPuzzlehash: nonSwitchPuzzleHashes.random,
    targetPuzzlehash: destinationPuzzleHash,
    metadata: NftMetadata(
      dataUris: [tailLogoUrl],
      dataHash: await uriHashProvider.getHashForUri(tailLogoUrl),
      metaUris: [metadataUrl],
      metaHash: await uriHashProvider.getHashForUri(metadataUrl),
    ),
    fee: mintFee,
    coins: selectCoinsForAmount(
      coins,
      mintFee + 1,
      selectionType: CoinSelectionType.biggetsFirst,
    ),
    keychain: keychain,
    targetDidInfo: didInfo.toDidInfoForPkOrThrow(didPrivateKey.getG1()),
    didPrivateKey: didPrivateKey,
    changePuzzlehash: nonSwitchPuzzleHashes.random,
  );

  await fullNode.pushTransaction(nftMintBundle);

  await blockChainUtils.waitForSpendBundle(
    nftMintBundle,
    logMessage: 'Waiting for tail nft mint bundle to be included',
  );

  final nftNetAdditions = nftMintBundle.netAdditions.toSet();

  final nft = (await fullNode.getNftRecordsByHints([destinationPuzzleHash]))
      .singleWhere((e) => nftNetAdditions.contains(e.coin));
  print('logo nft id: ${nft.nftId}');
  print('logo nft launcher id: ${nft.launcherId}');
}
