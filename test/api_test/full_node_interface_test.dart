// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/exceptions/bad_coin_id_exception.dart';
import 'package:chia_utils/src/api/simulator_full_node_interface.dart';
import 'package:chia_utils/src/api/simulator_http_rpc.dart';
import 'package:chia_utils/src/cat/puzzles/tails/delegated_tail/delegated_tail.clvm.hex.dart';
import 'package:chia_utils/src/cat/puzzles/tails/genesis_by_coin_id/genesis_by_coin_id.clvm.hex.dart';
import 'package:chia_utils/src/cat/service/wallet.dart';
import 'package:test/test.dart';

import '../simulator/simulator_utils.dart';

Future<void> main() async {
  if(!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final configurationProvider = ConfigurationProvider()
    ..setConfig(NetworkFactory.configId, {
      'yaml_file_path': 'lib/src/networks/chia/mainnet/config.yaml'
    }
  );
  final context = Context(configurationProvider);
  final blockchainNetworkLoader = ChiaBlockchainNetworkLoader();
  context.registerFactory(NetworkFactory(blockchainNetworkLoader.loadfromLocalFileSystem));

  final catWalletService = CatWalletService(context);

  final simulatorHttpRpc = SimulatorHttpRpc(SimulatorUtils.simulatorUrl,
    certBytes: SimulatorUtils.certBytes,
    keyBytes: SimulatorUtils.keyBytes,
  );
  final fullNodeSimulator = SimulatorFullNodeInterface(simulatorHttpRpc);


  // generate wallet
  const testMnemonic = [
      'elder', 'quality', 'this', 'chalk', 'crane', 'endless',
      'machine', 'hotel', 'unfair', 'castle', 'expand', 'refuse',
      'lizard', 'vacuum', 'embody', 'track', 'crash', 'truth',
      'arrow', 'tree', 'poet', 'audit', 'grid', 'mesh',
  ];
  final masterKeyPair = MasterKeyPair.fromMnemonic(testMnemonic);
  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 1; i++) {
    final set = WalletSet.fromPrivateKey(masterKeyPair.masterPrivateKey, i);
    walletsSetList.add(set);
  }
  final keychain = WalletKeychain(walletsSetList);

  final walletVector = keychain.unhardenedMap.values.first;
  final puzzlehash = walletVector.puzzlehash;
  final address = Address.fromPuzzlehash(puzzlehash, catWalletService.blockchainNetwork.addressPrefix);

  await fullNodeSimulator.farmCoins(address);
  await fullNodeSimulator.moveToNextBlock();

  final standardCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([puzzlehash]);
  final originCoin = standardCoins[0];

  // mint cat
  final curriedTail = delegatedTailProgram.curry([Program.fromBytes(walletVector.childPublicKey.toBytes())]);
  final assetId = Puzzlehash(curriedTail.hash());
  keychain.addOuterPuzzleHashesForAssetId(assetId);
  
  final curriedGenesisByCoinIdPuzzle = genesisByCoinIdProgram.curry([Program.fromBytes(originCoin.id.toUint8List())]);
  final tailSolution = Program.list([curriedGenesisByCoinIdPuzzle, Program.nil]);

  final signature = AugSchemeMPL.sign(walletVector.childPrivateKey, curriedGenesisByCoinIdPuzzle.hash());

  final spendBundle = catWalletService.makeMintingSpendbundle(
    tail: curriedTail, 
    solution: tailSolution, 
    standardCoins: [standardCoins.firstWhere((coin) => coin.amount >= 10000)], 
    destinationPuzzlehash: puzzlehash, 
    changePuzzlehash: puzzlehash, 
    amount: 10000, 
    signature: signature, 
    keychain: keychain,
    originId: originCoin.id,
  );

  await fullNodeSimulator.pushTransaction(spendBundle);
  await fullNodeSimulator.moveToNextBlock();

  final testStandardCoins = [
    CoinPrototype(
      parentCoinInfo: Puzzlehash.fromHex('27ae41e4649b934ca495991b7852b85500000000000000000000000000000001'), 
      puzzlehash: Puzzlehash.fromHex('0b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454ad'), 
      amount: 250000000000,
    ),
    CoinPrototype(
      parentCoinInfo: Puzzlehash.fromHex('e3b0c44298fc1c149afbf4c8996fb92400000000000000000000000000000001'), 
      puzzlehash: Puzzlehash.fromHex('0b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454ad'), 
      amount: 1750000000000,
    ),
  ];

  final testCatCoins = [
    CoinPrototype(
      parentCoinInfo: Puzzlehash.fromHex('0fe40b1ec35f3472c8cf0f244c207c26e7a8678413dceb87cff38dc2c1c95093'), 
      puzzlehash: Puzzlehash.fromHex('5db372b6e7577013035b4ee3fced2a7466d6ff1d3716b182afe520d83ee3427a'), 
      amount: 10000,
    ),
  ];
  
  test('should get standard coins by puzzlehashes', () async {
    final coins = await fullNodeSimulator.getCoinsByPuzzleHashes(testStandardCoins.map((c) => c.puzzlehash,).toList(), includeSpentCoins: true);
    for(final testCoin in testStandardCoins) {
      expect(coins.contains(testCoin), true);
    }
  });
  
  test('should get standard coin by id', () async {
    final coin = await fullNodeSimulator.getCoinById(testStandardCoins[0].id);
    expect(coin, testStandardCoins[0]);
  });

  test('should return null when coin is not found', () async {
    final coin = await fullNodeSimulator.getCoinById(Puzzlehash.fromHex('cd131985a09e31dc4f59353eabe1c977f508a649f3c09bb28823c060a497b3dc'));
    expect(coin, null);
  });

  test('should throw error when full node rejects invalid id', () async {
    var errorThrown = false;
    try {
      await fullNodeSimulator.getCoinById(Puzzlehash.fromHex('1cd131985a09e31dc4f59353eabe1c977f508a649f3c09bb28823c060a497b3dc'));
    } on BadCoinIdException {
      errorThrown = true;
    }
    expect(errorThrown, true);
  });

  test('should get cat coins by puzzlehashes', () async {
    final catCoins = await fullNodeSimulator.getCoinsByPuzzleHashes(testCatCoins.map((c) => c.puzzlehash,).toList());
    for(final testCatCoin in catCoins) {
      // can't check for parentCoinInfo because it will change based on the coin used to mint the cat
      expect(() => catCoins.firstWhere((catCoin) => catCoin.amount == testCatCoin.amount), returnsNormally);
      expect(() => catCoins.firstWhere((catCoin) => catCoin.puzzlehash == testCatCoin.puzzlehash), returnsNormally);
    }

  });
}
