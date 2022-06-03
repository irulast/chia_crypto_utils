// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

Future<void> main() async {
  const nTests = 4;

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

  final keychainSecret = KeychainCoreSecret.generate();

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 2; i++) {
    final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final keychain = WalletKeychain.fromWalletSets(walletsSetList);

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final walletService = StandardWalletService();

  final senderPuzzlehash = keychain.unhardenedMap.values.toList()[0].puzzlehash;
  final senderAddress = Address.fromPuzzlehash(
    senderPuzzlehash,
    walletService.blockchainNetwork.addressPrefix,
  );
  final receiverPuzzlehash = keychain.unhardenedMap.values.toList()[1].puzzlehash;

  for (var i = 0; i < nTests; i++) {
    await fullNodeSimulator.farmCoins(senderAddress);
  }
  await fullNodeSimulator.moveToNextBlock();

  final coins = await fullNodeSimulator.getCoinsByPuzzleHashes([senderPuzzlehash]);

  test('Should push transaction with fee', () async {
    final startingSenderBalance = await fullNodeSimulator.getBalance([senderPuzzlehash]);

    final startingReceiverBalance = await fullNodeSimulator.getBalance([receiverPuzzlehash]);

    final coinsToSend = coins.sublist(0, 2);
    coins.removeWhere(coinsToSend.contains);

    final coinsValue = coinsToSend.fold(
      0,
      (int previousValue, element) => previousValue + element.amount,
    );
    final amountToSend = (coinsValue * 0.8).round();
    final fee = (coinsValue * 0.1).round();

    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(amountToSend, receiverPuzzlehash)],
      coinsInput: coinsToSend,
      changePuzzlehash: senderPuzzlehash,
      keychain: keychain,
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

    final coinsValue = coinsToSend.fold(
      0,
      (int previousValue, element) => previousValue + element.amount,
    );
    final amountToSend = (coinsValue * 0.8).round();

    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(amountToSend, receiverPuzzlehash)],
      coinsInput: coinsToSend,
      changePuzzlehash: senderPuzzlehash,
      keychain: keychain,
    );

    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final endingSenderBalance = await fullNodeSimulator.getBalance([senderPuzzlehash]);
    expect(startingSenderBalance - endingSenderBalance, amountToSend);

    final endingReceiverBalance = await fullNodeSimulator.getBalance([receiverPuzzlehash]);
    expect(endingReceiverBalance - startingReceiverBalance, amountToSend);
  });

  test('Should push transaction with multiple payments', () async {
    final startingSenderBalance = await fullNodeSimulator.getBalance([senderPuzzlehash]);

    final startingReceiverCoins =
        await fullNodeSimulator.getCoinsByPuzzleHashes([receiverPuzzlehash]);
    final startingReceiverBalance = startingReceiverCoins.fold(
      0,
      (int previousValue, coin) => previousValue + coin.amount,
    );

    final coinsToSend = coins.sublist(0, 2);
    coins.removeWhere(coinsToSend.contains);

    final coinsValue = coinsToSend.fold(
      0,
      (int previousValue, element) => previousValue + element.amount,
    );
    final amountsToSend = [(coinsValue * 0.2).round(), (coinsValue * 0.6).round()];
    final totalAmountToSend = amountsToSend.fold(0, (int previousValue, a) => previousValue + a);

    final payments = amountsToSend.map((a) => Payment(a, receiverPuzzlehash)).toList();

    final spendBundle = walletService.createSpendBundle(
      payments: payments,
      coinsInput: coinsToSend,
      changePuzzlehash: senderPuzzlehash,
      keychain: keychain,
    );

    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final endingSenderBalance = await fullNodeSimulator.getBalance([senderPuzzlehash]);
    expect(startingSenderBalance - endingSenderBalance, totalAmountToSend);

    final endingReceiverCoins =
        await fullNodeSimulator.getCoinsByPuzzleHashes([receiverPuzzlehash]);
    final newReceiverCoins =
        endingReceiverCoins.where((coin) => !startingReceiverCoins.contains(coin));
    expect(newReceiverCoins.length == 2, true);
    expect(
      () {
        for (final newCoin in newReceiverCoins) {
          // throws exception if not found
          amountsToSend.singleWhere((a) => a == newCoin.amount);
        }
      },
      returnsNormally,
    );

    final endingReceiverBalance = endingReceiverCoins.fold(
      0,
      (int previousValue, coin) => previousValue + coin.amount,
    );
    expect(endingReceiverBalance - startingReceiverBalance, totalAmountToSend);
  });

  test('Should push transaction with origin', () async {
    final startingSenderBalance = await fullNodeSimulator.getBalance([senderPuzzlehash]);

    final startingReceiverBalance = await fullNodeSimulator.getBalance([receiverPuzzlehash]);

    final coinsToSend = coins.sublist(0, 2);
    coins.removeWhere(coinsToSend.contains);

    final coinsValue = coinsToSend.fold(
      0,
      (int previousValue, element) => previousValue + element.amount,
    );
    final amountToSend = (coinsValue * 0.8).round();

    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(amountToSend, receiverPuzzlehash)],
      coinsInput: coinsToSend,
      changePuzzlehash: senderPuzzlehash,
      keychain: keychain,
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
