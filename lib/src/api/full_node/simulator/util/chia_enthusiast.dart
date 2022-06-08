import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:get_it/get_it.dart';

class ChiaEnthusiast {
  ChiaEnthusiast(
    this.fullNodeSimulator, {
    List<String>? mnemonic,
    int derivations = 1,
  }) : keychainSecret = (mnemonic != null)
            ? KeychainCoreSecret.fromMnemonic(mnemonic)
            : KeychainCoreSecret.generate() {
    final walletsSetList = <WalletSet>[];

    for (var i = 0; i < derivations; i++) {
      final set = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
      walletsSetList.add(set);
    }
    keychain = WalletKeychain.fromWalletSets(walletsSetList);
  }
  final SimulatorFullNodeInterface fullNodeSimulator;
  late WalletKeychain keychain;
  final KeychainCoreSecret keychainSecret;

  final CatWalletService catWalletService = CatWalletService();

  List<Puzzlehash> get puzzlehashes =>
      keychain.unhardenedMap.values.map((wv) => wv.puzzlehash).toList();

  List<Puzzlehash> get outerPuzzlehashes => keychain.unhardenedMap.values.fold(
        <Puzzlehash>[],
        (previousValue, wv) => previousValue + wv.assetIdtoOuterPuzzlehash.values.toList(),
      );

  UnhardenedWalletVector get firstWalletVector => keychain.unhardenedMap.values.first;

  Puzzlehash get firstPuzzlehash => firstWalletVector.puzzlehash;

  Address get address => Address.fromPuzzlehash(
        firstWalletVector.puzzlehash,
        GetIt.I.get<BlockchainNetwork>().addressPrefix,
      );

  List<Coin> standardCoins = [];
  List<CatCoin> catCoins = [];

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

  void addAssetIdToKeychain(Puzzlehash assetId) {
    keychain.addOuterPuzzleHashesForAssetId(assetId);
  }

  Future<void> refreshCoins() async {
    standardCoins = await fullNodeSimulator.getCoinsByPuzzleHashes(puzzlehashes);
    catCoins = await fullNodeSimulator.getCatCoinsByOuterPuzzleHashes(outerPuzzlehashes);
  }

  Future<void> farmCoins([int nFarms = 1]) async {
    for (var i = 0; i < nFarms; i++) {
      await fullNodeSimulator.farmCoins(address);
    }
    await fullNodeSimulator.moveToNextBlock();
    await refreshCoins();
  }

  Future<void> issueMultiIssuanceCat([PrivateKey? privateKey]) async {
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
      amount: 100000000,
      signature: signature,
      keychain: keychain,
      originId: originCoin.id,
    );

    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();
    await refreshCoins();
  }
}
