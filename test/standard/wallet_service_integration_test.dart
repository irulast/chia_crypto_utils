import 'package:chia_utils/src/api/chia_full_node_interface.dart';
import 'package:chia_utils/src/api/full_node_http_rpc.dart';
import 'package:chia_utils/src/api/simulator_full_node_interface.dart';
import 'package:chia_utils/src/api/simulator_http_rpc.dart';
import 'package:chia_utils/src/context/context.dart';
import 'package:chia_utils/src/core/models/address.dart';
import 'package:chia_utils/src/core/models/bytes.dart';
import 'package:chia_utils/src/core/models/coin.dart';
import 'package:chia_utils/src/core/models/master_key_pair.dart';
import 'package:chia_utils/src/core/models/wallet_keychain.dart';
import 'package:chia_utils/src/core/models/wallet_set.dart';
import 'package:chia_utils/src/networks/chia/chia_blockckahin_network_loader.dart';
import 'package:chia_utils/src/networks/network_factory.dart';
import 'package:chia_utils/src/standard/service/wallet.dart';
import 'package:http/http.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  final simulatorHttpRpc = SimulatorHttpRpc('https://localhost:5000',
    certPath: path.join(path.current, 'test/simulator/temp/config/ssl/full_node/private_full_node.crt'),
    keyPath: path.join(path.current, 'test/simulator/temp/config/ssl/full_node/private_full_node.key'),
  );
  final fullNodeSimulator = SimulatorFullNodeInterface(simulatorHttpRpc);

  final configurationProvider = ConfigurationProvider()
    ..setConfig(NetworkFactory.configId, {
      'yaml_file_path': 'lib/src/networks/chia/mainnet/config.yaml'
    }
  );
  final context = Context(configurationProvider);
  final blockcahinNetworkLoader = ChiaBlockchainNetworkLoader();
  context.registerFactory(NetworkFactory(blockcahinNetworkLoader.loadfromLocalFileSystem));
  final walletService = StandardWalletService(context);

  const testMnemonic = [
      'elder', 'quality', 'this', 'chalk', 'crane', 'endless',
      'machine', 'hotel', 'unfair', 'castle', 'expand', 'refuse',
      'lizard', 'vacuum', 'embody', 'track', 'crash', 'truth',
      'arrow', 'tree', 'poet', 'audit', 'grid', 'mesh',
  ];

  final masterKeyPair = MasterKeyPair.fromMnemonic(testMnemonic);

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 2; i++) {
    final set1 = WalletSet.fromPrivateKey(masterKeyPair.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final keychain = WalletKeychain(walletsSetList);

  final senderPuzzlehash = keychain.unhardenedMap.values.toList()[0].puzzlehash;
  final senderAddress = Address.fromPuzzlehash(senderPuzzlehash, walletService.blockchainNetwork.addressPrefix);
  final receiverPuzzlehash = keychain.unhardenedMap.values.toList()[1].puzzlehash;

  await fullNodeSimulator.farmCoins(senderAddress);
  await fullNodeSimulator.farmCoins(senderAddress);
  await fullNodeSimulator.farmCoins(senderAddress);
  await fullNodeSimulator.moveToNextBlock();

  final coins = await fullNodeSimulator.getCoinsByPuzzleHashes([senderPuzzlehash]);

  test('Should push transaction with fee', () async {
    final startingSenderBalance = await fullNodeSimulator.getBalance([senderPuzzlehash]);

    final startingReceiverBalance = await fullNodeSimulator.getBalance([receiverPuzzlehash]);

    final coinsToSend = coins.sublist(0, 2);
    coins.removeWhere(coinsToSend.contains);

    final coinsValue = coinsToSend.fold(0, (int previousValue, element) => previousValue + element.amount);
    final amountToSend = (coinsValue * 0.8).round();
    final fee = (coinsValue * 0.1).round();

    final spendBundle = walletService.createSpendBundle(
        coinsToSend,
        amountToSend,
        receiverPuzzlehash,
        senderPuzzlehash,
        keychain,
        fee: fee,
    );

    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final endingSenderBalance = await fullNodeSimulator.getBalance([senderPuzzlehash]);
    expect(startingSenderBalance - endingSenderBalance, amountToSend + fee);

    final endingReceiverBalance = await fullNodeSimulator.getBalance([receiverPuzzlehash]);
    expect(endingReceiverBalance - startingReceiverBalance, amountToSend);
  });

  test('Should push transaction without fee', () async {
    final startingSenderBalance = await fullNodeSimulator.getBalance([senderPuzzlehash]);

    final startingReceiverBalance = await fullNodeSimulator.getBalance([receiverPuzzlehash]);

    final coinsToSend = coins.sublist(0, 2);
    coins.removeWhere(coinsToSend.contains);

    final coinsValue = coinsToSend.fold(0, (int previousValue, element) => previousValue + element.amount);
    final amountToSend = (coinsValue * 0.8).round();

    final spendBundle = walletService.createSpendBundle(
        coinsToSend,
        amountToSend,
        receiverPuzzlehash,
        senderPuzzlehash,
        keychain,
    );

    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final endingSenderBalance = await fullNodeSimulator.getBalance([senderPuzzlehash]);
    expect(startingSenderBalance - endingSenderBalance, amountToSend);

    final endingReceiverBalance = await fullNodeSimulator.getBalance([receiverPuzzlehash]);
    expect(endingReceiverBalance - startingReceiverBalance, amountToSend);
  });

  test('Should push transaction with origin', () async {
    final startingSenderBalance = await fullNodeSimulator.getBalance([senderPuzzlehash]);

    final startingReceiverBalance = await fullNodeSimulator.getBalance([receiverPuzzlehash]);

    final coinsToSend = coins.sublist(0, 2);
    coins.removeWhere(coinsToSend.contains);

    final coinsValue = coinsToSend.fold(0, (int previousValue, element) => previousValue + element.amount);
    final amountToSend = (coinsValue * 0.8).round();

    final spendBundle = walletService.createSpendBundle(
        coinsToSend,
        amountToSend,
        receiverPuzzlehash,
        senderPuzzlehash,
        keychain,
        originId: coinsToSend[coinsToSend.length - 1].id,
    );

    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final endingSenderBalance = await fullNodeSimulator.getBalance([senderPuzzlehash]);
    expect(startingSenderBalance - endingSenderBalance, amountToSend);

    final endingReceiverBalance = await fullNodeSimulator.getBalance([receiverPuzzlehash]);
    expect(endingReceiverBalance - startingReceiverBalance, amountToSend);
  });
}
