import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/simulator_full_node_interface.dart';
import 'package:chia_utils/src/api/simulator_http_rpc.dart';
import 'package:chia_utils/src/cat/puzzles/tails/delegated_tail/delegated_tail.clvm.hex.dart';
import 'package:chia_utils/src/cat/puzzles/tails/genesis_by_coin_id/genesis_by_coin_id.clvm.hex.dart';
import 'package:chia_utils/src/cat/service/wallet.dart';
import 'package:chia_utils/src/core/models/payment.dart';

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

  final testMnemonic = WalletKeychain.generateMnemonic();

  final masterKeyPair = MasterKeyPair.fromMnemonic(testMnemonic);

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 11; i++) {
    final set1 = WalletSet.fromPrivateKey(masterKeyPair.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final keychain = WalletKeychain(walletsSetList);

  final senderWalletSet = keychain.unhardenedMap.values.first;
  final senderAddress = Address.fromPuzzlehash(senderWalletSet.puzzlehash, catWalletService.blockchainNetwork.addressPrefix);

  await fullNodeSimulator.farmCoins(senderAddress);
  await fullNodeSimulator.farmCoins(senderAddress);
  await fullNodeSimulator.farmCoins(senderAddress);
  await fullNodeSimulator.moveToNextBlock();

  var coins = await fullNodeSimulator.getCoinsByPuzzleHashes([senderWalletSet.puzzlehash]);
  final originCoin = coins[0];

  // mint cat
  final curriedTail = delegatedTailProgram.curry([Program.fromBytes(senderWalletSet.childPublicKey.toBytes())]);
  final assetId = Puzzlehash(curriedTail.hash());
  keychain.addOuterPuzzleHashesForAssetId(assetId);
  
  final curriedGenesisByCoinIdPuzzle = genesisByCoinIdProgram.curry([Program.fromBytes(originCoin.id.toUint8List())]);
  final tailSolution = Program.list([curriedGenesisByCoinIdPuzzle, Program.nil]);

  final signature = AugSchemeMPL.sign(senderWalletSet.childPrivateKey, curriedGenesisByCoinIdPuzzle.hash());

  final spendBundle = catWalletService.makeMintingSpendbundle(
    tail: curriedTail, 
    solution: tailSolution, 
    standardCoins: coins, 
    destinationPuzzlehash: senderWalletSet.puzzlehash, 
    changePuzzlehash: senderWalletSet.puzzlehash, 
    amount: 10000, 
    signature: signature, 
    keychain: keychain,
    originId: originCoin.id,
  );

  await fullNodeSimulator.pushTransaction(spendBundle);
  await fullNodeSimulator.moveToNextBlock();

  final catCoins = await fullNodeSimulator.getCatCoinsByOuterPuzzleHashes([WalletKeychain.makeOuterPuzzleHash(senderWalletSet.puzzlehash, assetId)]);

  coins = await fullNodeSimulator.getCoinsByPuzzleHashes([senderWalletSet.puzzlehash]);
  final payments = <Payment>[];
  for (var i = 0; i < 10; i++) {
    // to avoid duplicate coins amounts must differ
    payments.add(Payment(990 + i, senderWalletSet.puzzlehash));
  }
  final sendBundle = catWalletService.createSpendBundle(payments, catCoins, senderWalletSet.puzzlehash, keychain);

  await fullNodeSimulator.pushTransaction(sendBundle);
  await fullNodeSimulator.moveToNextBlock();
}