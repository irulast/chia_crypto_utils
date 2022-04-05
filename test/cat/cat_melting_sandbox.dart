import 'dart:math';
import 'dart:typed_data';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/simulator_full_node_interface.dart';
import 'package:chia_utils/src/api/simulator_http_rpc.dart';
import 'package:chia_utils/src/cat/models/spendable_cat.dart';
import 'package:chia_utils/src/cat/puzzles/cat/cat.clvm.hex.dart';
import 'package:chia_utils/src/cat/puzzles/tails/delegated_tail/delegated_tail.clvm.hex.dart';
import 'package:chia_utils/src/cat/puzzles/tails/meltable_genesis_by_coined/meltable_genesis_by_coin_id.clvm.dart';
import 'package:chia_utils/src/cat/service/wallet.dart';
import 'package:chia_utils/src/clvm/keywords.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_condition.dart';

import '../simulator/simulator_utils.dart';

void main() async {
  // set up context, services
  final configurationProvider = ConfigurationProvider()
    ..setConfig(NetworkFactory.configId, {
      'yaml_file_path': 'lib/src/networks/chia/mainnet/config.yaml'
    }
  );
  final context = Context(configurationProvider);
  final blockcahinNetworkLoader = ChiaBlockchainNetworkLoader();
  context.registerFactory(NetworkFactory(blockcahinNetworkLoader.loadfromLocalFileSystem));
  final walletService = StandardWalletService(context);

  final catWalletService = CatWalletService(context);

  // set up keychain
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

  final walletSet = keychain.unhardenedMap.values.first;

  final address = Address.fromPuzzlehash(walletSet.puzzlehash, walletService.blockchainNetwork.addressPrefix);

  // set up simulator
  final simulatorHttpRpc = SimulatorHttpRpc(SimulatorUtils.simulatorUrl,
    certBytes: SimulatorUtils.certBytes,
    keyBytes: SimulatorUtils.keyBytes,
  );
  final fullNodeSimulator = SimulatorFullNodeInterface(simulatorHttpRpc);

  await fullNodeSimulator.farmCoins(address);
  await fullNodeSimulator.moveToNextBlock();

  var coins = await fullNodeSimulator.getCoinsByPuzzleHashes([address.toPuzzlehash()]);
  final originCoin = coins[0];

  // mint cat
  final curriedTail = delegatedTailProgram.curry([Program.fromBytes(walletSet.childPublicKey.toBytes())]);

  keychain.addOuterPuzzleHashesForAssetId(Puzzlehash(curriedTail.hash()));
  
  final curriedMeltableGenesisByCoinIdPuzzle = meltableGenesisByCoinIdProgram.curry([Program.fromBytes(originCoin.id.toUint8List())]);
  final tailSolution = Program.list([curriedMeltableGenesisByCoinIdPuzzle, Program.nil]);
  

  final mintSignature = AugSchemeMPL.sign(walletSet.childPrivateKey, curriedMeltableGenesisByCoinIdPuzzle.hash());

  final spendBundle = catWalletService.makeIssuanceSpendbundle(
    tail: curriedTail, 
    solution: tailSolution, 
    standardCoins: coins, 
    destinationPuzzlehash: address.toPuzzlehash(), 
    changePuzzlehash: address.toPuzzlehash(), 
    amount: 1000, 
    signature: mintSignature, 
    keychain: keychain,
    originId: originCoin.id,
  );

  // spendBundle.debug();
  // return;

  await fullNodeSimulator.pushTransaction(spendBundle);
  await fullNodeSimulator.moveToNextBlock();

  final outerPuzzlehash = WalletKeychain.makeOuterPuzzleHash(address.toPuzzlehash(), Puzzlehash(curriedTail.hash()));
  final cats = await fullNodeSimulator.getCatCoinsByOuterPuzzleHashes([outerPuzzlehash]);

  print('Minted cats: ');
  print(cats[0].toJson());
  print(' ');

  // attempt to melt
  final catToMelt = cats[0];
  final delta = 500;

  // final signatureForMelt = AugSchemeMPL.sign(
  //   walletSet.childPrivateKey,
  //   intToBytesStandard(-1, Endian.big, signed: true) + catToMelt.id.toUint8List() + Bytes.fromHex(catWalletService.blockchainNetwork.aggSigMeExtraData).toUint8List()
  // );

  // same as https://github.com/Chia-Network/chia-blockchain/blob/4bd5c53f48cb049eff36c87c00d21b1f2dd26b27/chia/wallet/puzzles/p2_delegated_puzzle_or_hidden_puzzle.py#L119
  final innerPuzzle = getPuzzleFromPk(walletSet.childPublicKey);
  final destinationPuzzlehash = Puzzlehash(innerPuzzle.hash());

  // print(intToBytesStandard(-47728299033, Endian.big, signed: true));
  // final acs = Program.fromInt(1);
  final innerSolution = Program.list([
    Program.nil,
    Program.list([
      Program.fromBigInt(keywords['q']!),
      Program.list([
        Program.fromInt(51), 
        Program.fromBytes(destinationPuzzlehash.toUint8List()), 
        Program.fromInt(catToMelt.amount - delta)
      ]),
      Program.list([
        Program.fromInt(51), 
        Program.fromInt(0),
        Program.fromInt(-113),
        curriedTail,
        tailSolution
      ])
    ]),
    Program.nil,
  ]);

  innerPuzzle.run(innerSolution);
  // print(innerSolution.serializeHex());
  // return;
  final spendableCat = SpendableCat(
    coin: catToMelt, innerPuzzle: innerPuzzle, innerSolution: innerSolution, extraDelta: -delta,
  );

  final meltSpendBundle = catWalletService.makeCatSpendBundleFromSpendableCats([spendableCat], keychain);

  coins = await fullNodeSimulator.getCoinsByPuzzleHashes([address.toPuzzlehash()]);
  final coin = coins[0];
  const fee = 0;

  final xchSpendbundle = catWalletService.standardWalletService.createSpendBundle(
    payments: [Payment(coin.amount - fee + delta, address.toPuzzlehash())],
    coinsInput: [coin], // destination puzzlehash
    changePuzzlehash: address.toPuzzlehash(), //change puzzlehash
    keychain: keychain,
  );

  final finalSpendBundle = meltSpendBundle + xchSpendbundle + mintSignature;
  

  // finalSpendBundle.debug();
  // return;

  print('attempting to push transaction...');
  final coinsBefore = await fullNodeSimulator.getCoinsByPuzzleHashes([address.toPuzzlehash()]);
  await fullNodeSimulator.pushTransaction(finalSpendBundle); // throws error
  await fullNodeSimulator.moveToNextBlock();

  final catsAfter = await fullNodeSimulator.getCatCoinsByOuterPuzzleHashes([outerPuzzlehash]);

  print('cats after: ');
  print((catsAfter[0]).toJson());
  print(' ');

  final coinsAfter = await fullNodeSimulator.getCoinsByPuzzleHashes([address.toPuzzlehash()]);

  final claimedXchCoin = coinsAfter.singleWhere((element) => !coinsBefore.contains(element));
  print('claimedXchCoin:');
  print(claimedXchCoin.toJson());
  final parent = await fullNodeSimulator.getCoinById(claimedXchCoin.parentCoinInfo);
  print('claimedXchCoin parent');
  print(parent!.toJson());

  print('claimed xch value: ');
  print(claimedXchCoin.amount - parent.amount);
}
