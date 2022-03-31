// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/simulator_full_node_interface.dart';
import 'package:chia_utils/src/api/simulator_http_rpc.dart';
import 'package:chia_utils/src/networks/network_context.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

import '../simulator/simulator_utils.dart';

Future<void> main() async {
  if(!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }
  final simulatorHttpRpc = SimulatorHttpRpc(SimulatorUtils.simulatorUrl,
    certBytes: SimulatorUtils.certBytes,
    keyBytes: SimulatorUtils.keyBytes,
  );
  final fullNodeSimulator = SimulatorFullNodeInterface(simulatorHttpRpc);

  final context = NetworkContext.makeContext(Network.mainnet);
  final walletService = StandardWalletService(context);

  final testMnemonic = WalletKeychain.generateMnemonic();

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
