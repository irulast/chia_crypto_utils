import 'dart:typed_data';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/simulator_full_node_interface.dart';
import 'package:chia_utils/src/api/simulator_http_rpc.dart';
import 'package:chia_utils/src/cat/models/spendable_cat.dart';
import 'package:chia_utils/src/cat/puzzles/tails/delegated_tail/delegated_tail.clvm.hex.dart';
import 'package:chia_utils/src/cat/puzzles/tails/genesis_by_coin_id/genesis_by_coin_id.clvm.hex.dart';
import 'package:chia_utils/src/cat/service/wallet.dart';

import '../simulator/simulator_utils.dart';

void main() async {
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

  const testMnemonic = [
      'elder', 'quality', 'this', 'chalk', 'crane', 'endless',
      'machine', 'hotel', 'unfair', 'castle', 'expand', 'refuse',
      'lizard', 'vacuum', 'embody', 'track', 'crash', 'truth',
      'arrow', 'tree', 'poet', 'audit', 'grid', 'mesh',
  ];
  // final testMnemonic = 'guilt rail green junior loud track cupboard citizen begin play west adapt myself panda eye finger nuclear someone update light dance exotic expect layer'.split(' ');

  final masterKeyPair = MasterKeyPair.fromMnemonic(testMnemonic);

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 11; i++) {
    final set1 = WalletSet.fromPrivateKey(masterKeyPair.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final keychain = WalletKeychain(walletsSetList);

  final address = Address.fromPuzzlehash(keychain.unhardenedMap.values.first.puzzlehash, walletService.blockchainNetwork.addressPrefix);

  final simulatorHttpRpc = SimulatorHttpRpc(SimulatorUtils.simulatorUrl,
    certBytes: SimulatorUtils.certBytes,
    keyBytes: SimulatorUtils.keyBytes,
  );
  final fullNodeSimulator = SimulatorFullNodeInterface(simulatorHttpRpc);

  await fullNodeSimulator.farmCoins(address);
  await fullNodeSimulator.moveToNextBlock();

  final coins = await fullNodeSimulator.getCoinsByPuzzleHashes([address.toPuzzlehash()]);
  final originCoin = coins[0];

  // mint cat first
  final walletSet = keychain.unhardenedMap.values.first;
  print(masterKeyPair.masterPublicKey.toHex());

  final publicKey = walletSet.childPublicKey;
  final curriedTail = delegatedTailProgram.curry([Program.fromBytes(publicKey.toBytes())]);
  
  final curriedGenesisByCoinId = genesisByCoinIdProgram.curry([Program.fromBytes(originCoin.id.toUint8List())]);
  final tailSolution = Program.list([curriedGenesisByCoinId, Program.nil]);

  final signature = AugSchemeMPL.sign(walletSet.childPrivateKey, curriedGenesisByCoinId.hash());


  final spendBundle = catWalletService.makeMintingSpendbundle(
    tail: curriedTail, 
    solution: tailSolution, 
    standardCoins: coins, 
    destinationPuzzlehash: address.toPuzzlehash(), 
    changePuzzlehash: address.toPuzzlehash(), 
    amount: 1000, 
    signature: signature, 
    keychain: keychain,
    originId: originCoin.id,
  );

  await fullNodeSimulator.pushTransaction(spendBundle);
  await fullNodeSimulator.moveToNextBlock();

  final outer = WalletKeychain.makeOuterPuzzleHash(address.toPuzzlehash(), Puzzlehash(curriedTail.hash()));
  final cats = await fullNodeSimulator.getCatCoinsByOuterPuzzleHashes([outer]);
  
  final catToMelt = cats[0];

  final signatureForMelt = AugSchemeMPL.sign(
    walletSet.childPrivateKey,
    intToBytesStandard(-1, Endian.big, signed: true) + catToMelt.id.toUint8List() + Bytes.fromHex(catWalletService.blockchainNetwork.aggSigMeExtraData).toUint8List()
  );

  // print(intToBytesStandard(-47728299033, Endian.big, signed: true));
  final acs = Program.fromInt(1);
  final innerSolution = Program.list([
    Program.list([
      Program.fromInt(51), 
      Program.fromBytes(acs.hash()), 
      Program.fromInt(catToMelt.amount - 1)
    ]),
    Program.list([
      Program.fromInt(51), 
      Program.fromInt(0),
      Program.fromInt(-113),
      curriedTail,
      Program.nil
    ])
  ]);
  // print(innerSolution.serializeHex());

  final spendableCat = SpendableCat(
    coin: catToMelt, innerPuzzle: acs, innerSolution: innerSolution, extraDelta: -1
  );

  print(catToMelt.lineageProof);

  final meltSpendBundle = catWalletService.makeCatSpendBundleFromSpendableCats([spendableCat], keychain, signed: false);
  final finalSpendBundle = SpendBundle.aggregate([
    meltSpendBundle,
    SpendBundle(coinSpends: [], aggregatedSignature: signatureForMelt),
  ]);


  // await fullNodeSimulator.pushTransaction(finalSpendBundle);
  // await fullNodeSimulator.moveToNextBlock();
}

