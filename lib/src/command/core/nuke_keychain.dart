import 'package:chia_crypto_utils/chia_crypto_utils.dart';

Future<void> nukeKeychain({
  required WalletKeychain keychain,
  required EnhancedChiaFullNodeInterface fullNode,
  required BlockchainUtils blockchainUtils,
  required int feePerCoin,
  required int burnBundleSize,
}) async {
  return transferKeychain(
    destinationPuzzlehash: burnPuzzlehash,
    keychain: keychain,
    fullNode: fullNode,
    blockchainUtils: blockchainUtils,
    feePerCoin: feePerCoin,
    spendBundleSize: burnBundleSize,
  );
}

Future<void> transferKeychain({
  required Puzzlehash destinationPuzzlehash,
  required WalletKeychain keychain,
  required EnhancedChiaFullNodeInterface fullNode,
  required BlockchainUtils blockchainUtils,
  required int feePerCoin,
  required int spendBundleSize,
}) async {
  final catWalletService = Cat2WalletService();
  final standardWalletService = StandardWalletService();

  final catCoins = await fullNode.getCatCoinsByHints(keychain.puzzlehashes);

  final catCoinsGroupedByAssetId = catCoins
      .where((element) => element.type == SpendType.cat)
      .groupByAssetId();

  final batchedCatMap = catCoinsGroupedByAssetId.map(
      (key, value) => MapEntry(key, value.splitIntoBatches(spendBundleSize)));

  for (final catMapEntry in batchedCatMap.entries) {
    keychain.addOuterPuzzleHashesForAssetId(catMapEntry.key);
    print('sent cat coins with asset id ${catMapEntry.key}');
    final batchedCats = catMapEntry.value;

    for (final listEntry in batchedCats.asMap().entries) {
      final catBatch = listEntry.value;
      final index = listEntry.key;
      final standardCoins =
          await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

      final fee = catBatch.length * feePerCoin;
      final standardCoinsForFee = selectCoinsForAmount(
        standardCoins,
        fee,
        minMojos: 20,
        selectionType: CoinSelectionType.biggetsFirst,
      );
      final spendBundle = catWalletService.createSpendBundle(
        payments: [CatPayment(catBatch.totalValue, destinationPuzzlehash)],
        catCoinsInput: catBatch,
        keychain: keychain,
        fee: feePerCoin,
        standardCoinsForFee: standardCoinsForFee,
        changePuzzlehash: keychain.puzzlehashes.first,
      );

      await fullNode.pushTransaction(spendBundle);
      print(
          'pushed ${catMapEntry.key} cat spend bundle (${index + 1}/${batchedCats.length})');
      await blockchainUtils.waitForSpendBundle(spendBundle);
    }
  }

  print('sending nfts');

  final nftWalletService = NftWalletService();
  final nfts = await fullNode.getNftRecordsByHints(keychain.puzzlehashes);
  final batchedNfts = nfts.splitIntoBatches(spendBundleSize);
  for (final listEntry in batchedNfts.asMap().entries) {
    final nftBatch = listEntry.value;

    final index = listEntry.key;
    final standardCoins =
        await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

    final fee = nftBatch.length * feePerCoin;
    final standardCoinsForFee = selectCoinsForAmount(
      standardCoins,
      fee,
      minMojos: 20,
      selectionType: CoinSelectionType.biggetsFirst,
    );
    var totalSpendBundle = SpendBundle.empty;

    for (final nft in nftBatch) {
      totalSpendBundle += nftWalletService.createSpendBundle(
        targetPuzzlehash: destinationPuzzlehash,
        nftCoin: nft.toNft(keychain),
        keychain: keychain,
      );
    }
    if (fee > 0) {
      totalSpendBundle += standardWalletService.createFeeSpendBundle(
        fee: fee,
        standardCoins: standardCoinsForFee,
        keychain: keychain,
        changePuzzlehash: keychain.puzzlehashes.first,
      );
    }

    await fullNode.pushTransaction(totalSpendBundle);
    print('pushed nft spend bundle (${index + 1}/${batchedNfts.length})');
    await blockchainUtils.waitForSpendBundle(totalSpendBundle);
  }
  print('sending dids');

  final didWalletService = DIDWalletService();
  final dids = await fullNode.getDidRecordsByHints(keychain.puzzlehashes);
  final batchedDids = dids.splitIntoBatches(spendBundleSize);
  for (final listEntry in batchedDids.asMap().entries) {
    final didBatch = listEntry.value;

    final index = listEntry.key;
    final standardCoins =
        await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

    final fee = didBatch.length * feePerCoin;
    final standardCoinsForFee = selectCoinsForAmount(
      standardCoins,
      fee,
      minMojos: 20,
      selectionType: CoinSelectionType.biggetsFirst,
    );
    var totalSpendBundle = SpendBundle.empty;

    for (final did in didBatch) {
      totalSpendBundle += didWalletService.createSpendBundle(
        didInfo: did.toDidInfoOrThrow(keychain),
        keychain: keychain,
        newP2Puzzlehash: destinationPuzzlehash,
      );
    }
    if (fee > 0) {
      totalSpendBundle += standardWalletService.createFeeSpendBundle(
        fee: fee,
        standardCoins: standardCoinsForFee,
        keychain: keychain,
        changePuzzlehash: keychain.puzzlehashes.first,
      );
    }

    await fullNode.pushTransaction(totalSpendBundle);
    print('pushed did spend bundle (${index + 1}/${batchedDids.length})');
    await blockchainUtils.waitForSpendBundle(totalSpendBundle);
  }

  final standardCoinsToNuke =
      await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

  final batchedStandardCoins =
      standardCoinsToNuke.splitIntoBatches(spendBundleSize);
  print('sending standard coins');
  for (final entry in batchedStandardCoins.asMap().entries) {
    final index = entry.key;
    final standardCoinBatch = entry.value;
    final batchValue = standardCoinBatch.totalValue;

    final spendBundle = standardWalletService.createSpendBundle(
      payments: [Payment(1, destinationPuzzlehash)],
      coinsInput: standardCoinBatch,
      keychain: keychain,
      fee: batchValue - 1,
    );

    await fullNode.pushTransaction(spendBundle);
    print(
        'pushed standard spend bundle (${index + 1}/${batchedStandardCoins.length})');
    await blockchainUtils.waitForSpendBundle(spendBundle);
  }
}
