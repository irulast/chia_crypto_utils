import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/full_node/simulator/util/chia_enthusiast_base.dart';

class ChiaEnthusiast extends ChiaEnthusiastBase {
  ChiaEnthusiast(
    this.fullNodeSimulator, {
    super.mnemonic,
    super.walletSize,
    super.plotNftWalletSize,
  });

  final SimulatorFullNodeInterface fullNodeSimulator;

  Map<Puzzlehash, List<CatCoin>> get cat1CoinMap {
    final catCoinMap = <Puzzlehash, List<CatCoin>>{};
    for (final cat1Coin in cat1Coins) {
      if (catCoinMap.containsKey(cat1Coin.assetId)) {
        catCoinMap[cat1Coin.assetId]!.add(cat1Coin);
      } else {
        catCoinMap[cat1Coin.assetId] = [cat1Coin];
      }
    }
    return catCoinMap;
  }

  Map<Puzzlehash, List<CatCoin>> get catCoinMap {
    final catCoinMap = <Puzzlehash, List<CatCoin>>{};
    for (final catCoin in catCoins) {
      if (catCoinMap.containsKey(catCoin.assetId)) {
        catCoinMap[catCoin.assetId]!.add(catCoin);
      } else {
        catCoinMap[catCoin.assetId] = [catCoin];
      }
    }
    return catCoinMap;
  }

  void addCat1AssetIdToKeychain(Puzzlehash assetId) {
    keychain.addCat1OuterPuzzleHashesForAssetId(assetId);
  }

  void addAssetIdToKeychain(Puzzlehash assetId) {
    keychain.addOuterPuzzleHashesForAssetId(assetId);
  }

  Future<void> refreshCoins() async {
    standardCoins = await fullNodeSimulator.getCoinsByPuzzleHashes(puzzlehashes);
    cat1Coins = (await fullNodeSimulator.getCatCoinsByOuterPuzzleHashes(outerPuzzlehashes))
        .where((element) => element.type == SpendType.cat1)
        .toList();
    catCoins = (await fullNodeSimulator.getCatCoinsByOuterPuzzleHashes(outerPuzzlehashes))
        .where((element) => element.type == SpendType.cat)
        .toList();
  }

  Future<void> farmCoins([int nFarms = 1]) async {
    for (var i = 0; i < nFarms; i++) {
      await fullNodeSimulator.farmCoins(address);
    }
    await fullNodeSimulator.moveToNextBlock();
    await refreshCoins();
  }

  Future<void> issueMultiIssuanceCat1([PrivateKey? privateKey]) async {
    await refreshCoins();
    final privateKeyForCat = privateKey ?? firstWalletVector.childPrivateKey;

    final curriedTail =
        delegatedTailProgram.curry([Program.fromBytes(privateKeyForCat.getG1().toBytes())]);
    final assetId = Puzzlehash(curriedTail.hash());
    addCat1AssetIdToKeychain(assetId);

    final originCoin = standardCoins[0];

    final curriedGenesisByCoinIdPuzzle =
        genesisByCoinIdProgram.curry([Program.fromBytes(originCoin.id)]);
    final tailSolution = Program.list([curriedGenesisByCoinIdPuzzle, Program.nil]);

    final signature = AugSchemeMPL.sign(privateKeyForCat, curriedGenesisByCoinIdPuzzle.hash());

    final spendBundle = cat1WalletService.makeIssuanceSpendbundle(
      tail: curriedTail,
      solution: tailSolution,
      standardCoins: [standardCoins.firstWhere((coin) => coin.amount >= 10000)],
      destinationPuzzlehash: firstWalletVector.puzzlehash,
      changePuzzlehash: firstWalletVector.puzzlehash,
      amount: 10000,
      makeSignature: (_) => signature,
      keychain: keychain,
      originId: originCoin.id,
    );

    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();
    await refreshCoins();
  }

  Future<Puzzlehash> issueMultiIssuanceCat([PrivateKey? privateKey]) async {
    await refreshCoins();
    final privateKeyForCat = privateKey ?? firstWalletVector.childPrivateKey;

    final curriedTail =
        delegatedTailProgram.curry([Program.fromBytes(privateKeyForCat.getG1().toBytes())]);
    final assetId = Puzzlehash(curriedTail.hash());
    addAssetIdToKeychain(assetId);

    final originCoin = standardCoins[0];

    final curriedGenesisByCoinIdPuzzle =
        genesisByCoinIdProgram.curry([Program.fromBytes(originCoin.id)]);
    final tailSolution = Program.list([curriedGenesisByCoinIdPuzzle, Program.nil]);

    final signature = AugSchemeMPL.sign(privateKeyForCat, curriedGenesisByCoinIdPuzzle.hash());

    final spendBundle = catWalletService.makeIssuanceSpendbundle(
      tail: curriedTail,
      solution: tailSolution,
      standardCoins: [standardCoins.firstWhere((coin) => coin.amount >= 10000)],
      destinationPuzzlehash: firstWalletVector.puzzlehash,
      changePuzzlehash: firstWalletVector.puzzlehash,
      amount: 100000000,
      makeSignature: (_) => signature,
      keychain: keychain,
      originId: originCoin.id,
    );

    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();
    await refreshCoins();
    return assetId;
  }

  Future<void> issueDid([List<Bytes> recoveryIds = const []]) async {
    await refreshCoins();
    final didRecoverySpendBundle = didWalletService.createGenerateDIDSpendBundle(
      standardCoins: [standardCoins[0]],
      targetPuzzleHash: firstWalletVector.puzzlehash,
      keychain: keychain,
      changePuzzlehash: firstWalletVector.puzzlehash,
      backupIds: recoveryIds,
      metadata: const DidMetadata({'name': 'test_did', 'role': 'admin'}),
    );

    await fullNodeSimulator.pushTransaction(didRecoverySpendBundle);

    await fullNodeSimulator.moveToNextBlock();

    final didInfos = await fullNodeSimulator.getDidRecordsFromHint(firstWalletVector.puzzlehash);

    if (didInfos.length > 1) {
      throw Exception('Chia enthusiast can only have one did');
    }

    didInfo = didInfos[0].toDidInfo(keychain);
    await refreshCoins();
  }

  Future<void> refreshDidInfo() async {
    if (didInfo == null) {
      throw Exception('Did must be issued before it can be refreshed');
    }
    didInfo = (await fullNodeSimulator.getDidRecordForDid(didInfo!.did))?.toDidInfo(keychain);
  }

  Future<void> recoverDid(Bytes did) async {
    didInfo = (await fullNodeSimulator.getDidRecordForDid(did))?.toDidInfo(keychain);
  }
}
