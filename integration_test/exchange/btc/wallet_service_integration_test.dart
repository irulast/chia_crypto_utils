// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/wallet.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

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

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final walletService = BtcExchangeWalletService();

  final xchHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
  final clawbackPrivateKey = masterSkToWalletSk(xchHolder.keychainSecret.masterPrivateKey, 1);
  final clawbackPublicKey = clawbackPrivateKey.getG1();
  final clawbackPuzzlehash = xchHolder.firstPuzzlehash;
  await xchHolder.farmCoins();
  await xchHolder.refreshCoins();

  final btcHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
  final sweepPrivateKey = masterSkToWalletSk(btcHolder.keychainSecret.masterPrivateKey, 1);
  final sweepPublicKey = sweepPrivateKey.getG1();

  final sweepPreimage =
      '5c1f10653dc3ff0531b77351dc6676de2e1f5f53c9f0a8867bcb054648f46a32'.hexToBytes();
  final sweepReceiptHash = Program.fromBytes(sweepPreimage).hash();
  // Puzzlehash.fromHex('63b49b0dc5f8e216332dabc410d64ee92a8ae73ae0a1d929e76980646d435d98');
  // Puzzlehash.fromHex('6779d8cca6cb2423d0c55b3511e002e91c95b1f6ea8d93a61a563833e538d797');

  test('should transfer xch to holding address and clawback funds', () async {
    final coins = xchHolder.standardCoins;

    final holdingAddressPuzzle = walletService.generateHoldingAddressPuzzle(
      clawbackPublicKey: clawbackPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      sweepPublicKey: sweepPublicKey,
    );

    final holdingAddressPuzzlehash = holdingAddressPuzzle.hash();

    final coinsToSend = coins.sublist(0, 2);
    coins.removeWhere(coinsToSend.contains);

    final coinsValue = coinsToSend.fold(
      0,
      (int previousValue, element) => previousValue + element.amount,
    );
    final amountToSend = (coinsValue * 0.8).round();
    final fee = (coinsValue * 0.1).round();

    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(amountToSend, holdingAddressPuzzlehash)],
      coinsInput: coinsToSend,
      changePuzzlehash: xchHolder.firstPuzzlehash,
      keychain: xchHolder.keychain,
      fee: fee,
    );
    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final holdingAddressBalance = await fullNodeSimulator.getBalance([holdingAddressPuzzlehash]);

    expect(holdingAddressBalance, amountToSend);

    final startingClawbackAddressBalance = await fullNodeSimulator.getBalance([clawbackPuzzlehash]);

    final clawbackCoinsInput =
        await fullNodeSimulator.getCoinsByPuzzleHashes([holdingAddressPuzzlehash]);

    final clawbackSpendbundle = walletService.createExchangeSpendBundle(
      payments: [Payment(holdingAddressBalance, clawbackPuzzlehash)],
      coinsInput: clawbackCoinsInput,
      clawbackPrivateKey: clawbackPrivateKey,
      sweepPrivateKey: sweepPrivateKey,
      clawbackPublicKey: clawbackPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      sweepPublicKey: sweepPublicKey,
    );

    // await Future<void>.delayed(const Duration(seconds: 5));

    await fullNodeSimulator.pushTransaction(clawbackSpendbundle);
    await fullNodeSimulator.moveToNextBlock();

    final endingClawbackAddressBalance = await fullNodeSimulator.getBalance([clawbackPuzzlehash]);

    expect(
      endingClawbackAddressBalance,
      equals(startingClawbackAddressBalance + holdingAddressBalance),
    );
  });
}
