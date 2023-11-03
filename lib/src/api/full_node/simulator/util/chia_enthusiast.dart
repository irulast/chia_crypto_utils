import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/full_node/simulator/util/chia_enthusiast_base.dart';

class ChiaEnthusiast extends ChiaEnthusiastBase {
  ChiaEnthusiast(
    this.fullNodeSimulator, {
    super.mnemonic,
    CatWalletService? catWalletService,
    super.walletSize,
    super.plotNftWalletSize,
  }) : catWalletService = catWalletService ?? Cat2WalletService();

  final CatWalletService catWalletService;

  SpendType get catType => catWalletService.spendType;

  Wallet get wallet => ColdWallet(fullNode: fullNode, keychain: keychain);

  OfferService get offerService =>
      OfferService(wallet, OfferWalletService(catWalletService));

  EnhancedChiaFullNodeInterface get fullNode =>
      EnhancedChiaFullNodeInterface.fromUrl(fullNodeSimulator.fullNode.baseURL);

  final SimulatorFullNodeInterface fullNodeSimulator;

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

  Future<void> refreshCoins() async {
    standardCoins =
        await fullNodeSimulator.getCoinsByPuzzleHashes(puzzlehashes);

    catCoins = (await fullNode.getCatCoinsByHints(puzzlehashes))
        .where((element) => element.type == catType)
        .toList();
  }

  Future<void> farmCoins([int nFarms = 1]) async {
    for (var i = 0; i < nFarms; i++) {
      await fullNodeSimulator.farmCoins(address);
    }
    await fullNodeSimulator.moveToNextBlock();
    await refreshCoins();
  }

  Future<Puzzlehash> issueMultiIssuanceCat([PrivateKey? privateKey]) async {
    await refreshCoins();
    final privateKeyForCat = privateKey ?? firstWalletVector.childPrivateKey;

    final curriedTail = delegatedTailProgram
        .curry([Program.fromAtom(privateKeyForCat.getG1().toBytes())]);
    final assetId = Puzzlehash(curriedTail.hash());

    final originCoin = standardCoins[0];

    final curriedGenesisByCoinIdPuzzle =
        genesisByCoinIdProgram.curry([Program.fromAtom(originCoin.id)]);
    final tailSolution =
        Program.list([curriedGenesisByCoinIdPuzzle, Program.nil]);

    final signature = AugSchemeMPL.sign(
      privateKeyForCat,
      curriedGenesisByCoinIdPuzzle.hash(),
    );

    final spendBundle = catWalletService.makeIssuanceSpendbundle(
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
    return assetId;
  }

  Future<void> issueDid([List<Bytes> recoveryIds = const []]) async {
    await refreshCoins();
    final didRecoverySpendBundle =
        didWalletService.createGenerateDIDSpendBundle(
      standardCoins: [standardCoins[0]],
      targetPuzzleHash: firstWalletVector.puzzlehash,
      keychain: keychain,
      changePuzzlehash: firstWalletVector.puzzlehash,
      backupIds: recoveryIds,
      metadata: const DidMetadata({'name': 'test_did', 'role': 'admin'}),
    );

    await fullNodeSimulator.pushTransaction(didRecoverySpendBundle);

    await fullNodeSimulator.moveToNextBlock();

    final didInfos = await fullNodeSimulator
        .getDidRecordsFromHint(firstWalletVector.puzzlehash);

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
    didInfo = (await fullNodeSimulator.getDidRecordForDid(didInfo!.did))
        ?.toDidInfo(keychain);
  }

  Future<void> recoverDid(Bytes did) async {
    didInfo =
        (await fullNodeSimulator.getDidRecordForDid(did))?.toDidInfo(keychain);
  }
}
