// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

Future<void> main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final simulatorHttpRpc = SimulatorHttpRpc(
    SimulatorUtils.simulatorUrl,
    certBytes: SimulatorUtils.certBytes,
    keyBytes: SimulatorUtils.keyBytes,
  );

  final fullNodeSimulator = SimulatorFullNodeInterface(simulatorHttpRpc);

  // generate wallet
  const testMnemonic = [
    'elder',
    'quality',
    'this',
    'chalk',
    'crane',
    'endless',
    'machine',
    'hotel',
    'unfair',
    'castle',
    'expand',
    'refuse',
    'lizard',
    'vacuum',
    'embody',
    'track',
    'crash',
    'truth',
    'arrow',
    'tree',
    'poet',
    'audit',
    'grid',
    'mesh',
  ];
  final keychainSecret = KeychainCoreSecret.fromMnemonic(testMnemonic);
  final walletsSetList = <WalletSet>[];

  for (var i = 0; i < 1; i++) {
    final set = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
    walletsSetList.add(set);
  }
  final keychain = WalletKeychain.fromWalletSets(walletsSetList);

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final catWalletService = Cat2WalletService();

  final walletVector = keychain.unhardenedMap.values.first;
  final puzzlehash = walletVector.puzzlehash;
  final address = Address.fromPuzzlehash(
    puzzlehash,
    catWalletService.blockchainNetwork.addressPrefix,
  );

  await fullNodeSimulator.farmCoins(address);
  await fullNodeSimulator.moveToNextBlock();

  final standardCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([puzzlehash]);
  final originCoin = standardCoins[0];

  // issue cat
  final curriedTail =
      delegatedTailProgram.curry([Program.fromBytes(walletVector.childPublicKey.toBytes())]);
  final assetId = Puzzlehash(curriedTail.hash());
  keychain.addOuterPuzzleHashesForAssetId(assetId);

  final curriedGenesisByCoinIdPuzzle =
      genesisByCoinIdProgram.curry([Program.fromBytes(originCoin.id)]);
  final tailSolution = Program.list([curriedGenesisByCoinIdPuzzle, Program.nil]);

  final signature = AugSchemeMPL.sign(
    walletVector.childPrivateKey,
    curriedGenesisByCoinIdPuzzle.hash(),
  );

  final spendBundle = catWalletService.makeIssuanceSpendbundle(
    tail: curriedTail,
    solution: tailSolution,
    standardCoins: [standardCoins.firstWhere((coin) => coin.amount >= 10000)],
    destinationPuzzlehash: puzzlehash,
    changePuzzlehash: puzzlehash,
    amount: 10000,
    makeSignature: (_) => signature,
    keychain: keychain,
    originId: originCoin.id,
  );

  await fullNodeSimulator.pushTransaction(spendBundle);
  await fullNodeSimulator.moveToNextBlock();

  final blockchainState = await fullNodeSimulator.getBlockchainState();
  final catPuzzlehash = WalletKeychain.makeOuterPuzzleHash(puzzlehash, assetId);

  // specific parent info values are not used because there is possible variation in parent info in the simulator
  final testStandardCoins = [
    CoinPrototype(
      parentCoinInfo: Puzzlehash.zeros(),
      puzzlehash: puzzlehash,
      amount: 250000000000,
    ),
    CoinPrototype(
      parentCoinInfo: Puzzlehash.zeros(),
      puzzlehash: puzzlehash,
      amount: 1750000000000,
    ),
  ];

  final testCatCoins = [
    CoinPrototype(
      parentCoinInfo: Puzzlehash.zeros(),
      puzzlehash: catPuzzlehash,
      amount: 10000,
    ),
  ];

  test('should get standard coins by puzzlehashes', () async {
    final coins = await fullNodeSimulator.getCoinsByPuzzleHashes(
      testStandardCoins
          .map(
            (c) => c.puzzlehash,
          )
          .toList(),
      includeSpentCoins: true,
    );
    for (final testCoin in testStandardCoins) {
      expect(
        () => coins.firstWhere((coin) => coin.amount == testCoin.amount),
        returnsNormally,
      );
      expect(
        () => coins.firstWhere((coin) => coin.puzzlehash == testCoin.puzzlehash),
        returnsNormally,
      );
    }
  });

  test('should get standard coins by id', () async {
    //get coins by puzzlehash first because sometimes parent info comes back differently
    final coinsGotByPuzzlehashes = await fullNodeSimulator.getCoinsByPuzzleHashes(
      testStandardCoins
          .map(
            (c) => c.puzzlehash,
          )
          .toList(),
      includeSpentCoins: true,
    );
    final coinIds = coinsGotByPuzzlehashes
        .map(
          (c) => c.id,
        )
        .toList();
    final coinsGotByIds = await fullNodeSimulator.getCoinsByIds(
      coinIds,
      includeSpentCoins: true,
    );
    for (final coinGotByPuzzlehash in coinsGotByPuzzlehashes) {
      expect(
        () => coinsGotByIds.firstWhere((coin) => coin.id == coinGotByPuzzlehash.id),
        returnsNormally,
      );
    }
  });

  test('should get standard coins by parent id', () async {
    //get coins by puzzlehash first because sometimes parent info comes back differently
    final coinsGotByPuzzlehashes = await fullNodeSimulator.getCoinsByPuzzleHashes(
      testStandardCoins
          .map(
            (c) => c.puzzlehash,
          )
          .toList(),
      includeSpentCoins: true,
    );
    final coinParentInfo = coinsGotByPuzzlehashes
        .map(
          (c) => c.parentCoinInfo,
        )
        .toList();
    final coinsGotByParentIds = await fullNodeSimulator.getCoinsByParentIds(
      coinParentInfo,
      includeSpentCoins: true,
    );
    for (final coinGotByPuzzlehash in coinsGotByPuzzlehashes) {
      expect(
        () => coinsGotByParentIds.firstWhere((coin) => coin.id == coinGotByPuzzlehash.id),
        returnsNormally,
      );
    }
  });

  test('should return null when coin is not found', () async {
    final coin = await fullNodeSimulator.getCoinById(
      Bytes.fromHex(
        'cd131985a09e31dc4f59353eabe1c977f508a649f3c09bb28823c060a497b3dc',
      ),
    );
    expect(coin, null);
  });

  test('should throw error when full node rejects invalid id', () async {
    var errorThrown = false;
    try {
      await fullNodeSimulator.getCoinById(
        Bytes.fromHex(
          '1cd131985a09e31dc4f59353eabe1c977f508a649f3c09bb28823c060a497b3dc',
        ),
      );
    } on BadCoinIdException {
      errorThrown = true;
    }
    expect(errorThrown, true);
  });

  test('should get cat coins by puzzlehashes', () async {
    final catCoins = await fullNodeSimulator.getCoinsByPuzzleHashes(
      testCatCoins
          .map(
            (c) => c.puzzlehash,
          )
          .toList(),
    );
    for (final testCatCoin in testCatCoins) {
      // can't check for parentCoinInfo because it will change based on the coin used to mint the cat
      expect(
        () => catCoins.firstWhere((catCoin) => catCoin.amount == testCatCoin.amount),
        returnsNormally,
      );
      expect(
        () => catCoins.firstWhere(
          (catCoin) => catCoin.puzzlehash == testCatCoin.puzzlehash,
        ),
        returnsNormally,
      );
    }
  });

  test('should get cat coins by memo', () async {
    final catCoins = await fullNodeSimulator.getCatCoinsByHint(
      puzzlehash,
    );

    for (final testCatCoin in testCatCoins) {
      expect(
        () => catCoins.firstWhere((catCoin) => catCoin.amount == testCatCoin.amount),
        returnsNormally,
      );
      expect(
        () => catCoins.firstWhere(
          (catCoin) => catCoin.puzzlehash == testCatCoin.puzzlehash,
        ),
        returnsNormally,
      );
    }
  });

  test('should correctly check for spent coins when there are spent coins', () async {
    final spentCoinsCheck = await fullNodeSimulator.checkForSpentCoins(standardCoins);

    expect(
      spentCoinsCheck,
      equals(true),
    );
  });

  test('should correctly check for spent coins when coins have not been spent', () async {
    final spentCoinsCheck = await fullNodeSimulator.checkForSpentCoins(testStandardCoins);

    expect(
      spentCoinsCheck,
      equals(false),
    );
  });

  test('should get block records', () async {
    final blockRecords = await fullNodeSimulator.getBlockRecords(0, 3);
    var expectedHeight = 0;

    for (final blockRecord in blockRecords) {
      expect(blockRecord.headerHash, isA<Bytes>());
      expect(blockRecord.height, equals(expectedHeight));
      expectedHeight++;
    }
  });

  test('should get block record by height', () async {
    final response = await fullNodeSimulator.getBlockRecordByHeight(1);
    final blockRecord = response.blockRecord;

    expect(blockRecord, isNotNull);

    expect(blockRecord!.headerHash, isA<Bytes>());
    expect(blockRecord.height, equals(1));
  });

  test('should get additions and removals', () async {
    final headerHash = blockchainState?.peak?.headerHash;

    expect(headerHash, isNotNull);

    if (headerHash != null) {
      final additionsAndRemovals = await fullNodeSimulator.getAdditionsAndRemovals(headerHash);
      final additions = additionsAndRemovals.additions;
      final removals = additionsAndRemovals.removals;
      final expectedAdditions = spendBundle.additions;
      final expectedRemovals = [standardCoins.firstWhere((coin) => coin.amount >= 10000)];

      for (final expectedAddition in expectedAdditions) {
        expect(
          () => additions.firstWhere((addition) => addition.id == expectedAddition.id),
          returnsNormally,
        );
      }

      for (final expectedRemoval in expectedRemovals) {
        expect(
          () => removals.firstWhere((removal) => removal.id == expectedRemoval.id),
          returnsNormally,
        );
      }
    }
  });
}
