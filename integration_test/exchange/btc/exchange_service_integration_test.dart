// ignore_for_file: lines_longer_than_80_chars
@Timeout(Duration(minutes: 5))

import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/service/btc_to_xch.dart';
import 'package:chia_crypto_utils/src/exchange/service/xch_to_btc.dart';
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
  final walletService = StandardWalletService();

  final sweepPreimage =
      '5c1f10653dc3ff0531b77351dc6676de2e1f5f53c9f0a8867bcb054648f46a32'.hexToBytes();
  final sweepReceiptHash =
      Puzzlehash.fromHex('63b49b0dc5f8e216332dabc410d64ee92a8ae73ae0a1d929e76980646d435d98');

  test(
      'should transfer XCH to holding address and fail to clawback funds to XCH holder before delay has passed',
      () async {
    final exchangeService = XchToBtcExchangeService();

    // generating disposable private and public keys for each participant
    final xchHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    final xchHolderPrivateKey = KeychainCoreSecret.generate().masterPrivateKey;
    final xchHolderPublicKey = xchHolderPrivateKey.getG1();
    final clawbackPuzzlehash = xchHolder.firstPuzzlehash;

    final btcHolderPrivateKey = KeychainCoreSecret.generate().masterPrivateKey;
    final btcHolderPublicKey = btcHolderPrivateKey.getG1();

    await xchHolder.farmCoins();
    await xchHolder.refreshCoins();
    final coins = xchHolder.standardCoins;

    final holdingAddressPuzzlehash = exchangeService.generateHoldingAddressPuzzlehash(
      clawbackDelaySeconds: 10,
      myPublicKey: xchHolderPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      counterpartyPublicKey: btcHolderPublicKey,
    );

    final coinsToSend = coins.sublist(0, 2);
    coins.removeWhere(coinsToSend.contains);

    final coinsValue = coinsToSend.fold(
      0,
      (int previousValue, element) => previousValue + element.amount,
    );
    final amountToSend = (coinsValue * 0.8).round();
    final fee = (coinsValue * 0.1).round();

    // XCH holder transfers funds to holding address
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

    final holdingAddressCoins =
        await fullNodeSimulator.getCoinsByPuzzleHashes([holdingAddressPuzzlehash]);

    // the clawback delay period has not passed yet, so pushing this spend bundle should fail
    final clawbackSpendbundle = exchangeService.createClawbackSpendBundle(
      amount: holdingAddressBalance,
      clawbackAddress: clawbackPuzzlehash.toAddressWithContext(),
      holdingAddressCoins: holdingAddressCoins,
      clawbackDelaySeconds: 10,
      myPrivateKey: xchHolderPrivateKey,
      myPublicKey: xchHolderPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      counterpartyPublicKey: btcHolderPublicKey,
    );

    expect(
      () async {
        await fullNodeSimulator.pushTransaction(clawbackSpendbundle);
      },
      throwsException,
    );
  });

  test(
      'should transfer XCH to holding address and clawback funds to XCH holder after delay has passed',
      () async {
    final exchangeService = XchToBtcExchangeService();

    // generating disposable private and public keys for each participant
    final xchHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    final xchHolderPrivateKey = KeychainCoreSecret.generate().masterPrivateKey;
    final xchHolderPublicKey = xchHolderPrivateKey.getG1();
    final clawbackPuzzlehash = xchHolder.firstPuzzlehash;

    final btcHolderPrivateKey = KeychainCoreSecret.generate().masterPrivateKey;
    final btcHolderPublicKey = btcHolderPrivateKey.getG1();

    await xchHolder.farmCoins();
    await xchHolder.refreshCoins();
    final coins = xchHolder.standardCoins;

    final holdingAddressPuzzlehash = exchangeService.generateHoldingAddressPuzzlehash(
      clawbackDelaySeconds: 5,
      myPublicKey: xchHolderPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      counterpartyPublicKey: btcHolderPublicKey,
    );

    final coinsToSend = coins.sublist(0, 2);
    coins.removeWhere(coinsToSend.contains);

    final coinsValue = coinsToSend.fold(
      0,
      (int previousValue, element) => previousValue + element.amount,
    );
    final amountToSend = (coinsValue * 0.8).round();
    final fee = (coinsValue * 0.1).round();

    // XCH holder transfers funds to holding address
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

    final holdingAddressCoins =
        await fullNodeSimulator.getCoinsByPuzzleHashes([holdingAddressPuzzlehash]);

    // the clawback spend bundle can be pushed after the clawback delay has passed in order to reclaim funds
    // in the event that the other party doens't pay the lightning invoice within that time
    final clawbackSpendbundle = exchangeService.createClawbackSpendBundle(
      amount: holdingAddressBalance,
      clawbackAddress: clawbackPuzzlehash.toAddressWithContext(),
      holdingAddressCoins: holdingAddressCoins,
      clawbackDelaySeconds: 5,
      myPrivateKey: xchHolderPrivateKey,
      myPublicKey: xchHolderPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      counterpartyPublicKey: btcHolderPublicKey,
    );

    // the earliest you can spend a time-locked coin is 2 blocks later, since the time is checked
    // against the timestamp of the previous block
    for (var i = 0; i < 2; i++) {
      await fullNodeSimulator.moveToNextBlock();
    }

    await Future<void>.delayed(const Duration(seconds: 10), () async {
      await fullNodeSimulator.pushTransaction(clawbackSpendbundle);
      await fullNodeSimulator.moveToNextBlock();
      final endingClawbackAddressBalance = await fullNodeSimulator.getBalance([clawbackPuzzlehash]);

      expect(
        endingClawbackAddressBalance,
        equals(startingClawbackAddressBalance + holdingAddressBalance),
      );
    });
  });

  test('should transfer XCH to holding address and sweep funds to BTC holder using private key',
      () async {
    final exchangeService = BtcToXchExchangeService();

    // generating disposable private and public keys for each participant
    final xchHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    final xchHolderPrivateKey = KeychainCoreSecret.generate().masterPrivateKey;
    final xchHolderPublicKey = xchHolderPrivateKey.getG1();

    final btcHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    final btcHolderPrivateKey = KeychainCoreSecret.generate().masterPrivateKey;
    final btcHolderPublicKey = btcHolderPrivateKey.getG1();
    final sweepPuzzlehash = btcHolder.firstPuzzlehash;

    await xchHolder.farmCoins();
    await xchHolder.refreshCoins();
    final coins = xchHolder.standardCoins;

    final holdingAddressPuzzlehash = exchangeService.generateHoldingAddressPuzzlehash(
      clawbackDelaySeconds: 10,
      myPublicKey: btcHolderPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      counterpartyPublicKey: xchHolderPublicKey,
    );

    final coinsToSend = coins.sublist(0, 2);
    coins.removeWhere(coinsToSend.contains);

    final coinsValue = coinsToSend.fold(
      0,
      (int previousValue, element) => previousValue + element.amount,
    );
    final amountToSend = (coinsValue * 0.8).round();
    final fee = (coinsValue * 0.1).round();

    // XCH holder transfers funds to holding address
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

    final startingSweepAddressBalance = await fullNodeSimulator.getBalance([sweepPuzzlehash]);

    final holdingAddressCoins =
        await fullNodeSimulator.getCoinsByPuzzleHashes([holdingAddressPuzzlehash]);

    // after the lightning invoice is paid, the XCH holder shares their disposable private key
    // with the BTC holder, allowing them to sweep funds from the holding address
    final sweepSpendbundle = exchangeService.createSweepSpendBundleWithPk(
      amount: holdingAddressBalance,
      sweepAddress: sweepPuzzlehash.toAddressWithContext(),
      holdingAddressCoins: holdingAddressCoins,
      clawbackDelaySeconds: 10,
      myPrivateKey: btcHolderPrivateKey,
      myPublicKey: btcHolderPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      counterpartyPublicKey: xchHolderPublicKey,
      counterpartyPrivateKey: xchHolderPrivateKey,
    );

    await fullNodeSimulator.pushTransaction(sweepSpendbundle);
    await fullNodeSimulator.moveToNextBlock();

    final endingSweepAddressBalance = await fullNodeSimulator.getBalance([sweepPuzzlehash]);

    expect(
      endingSweepAddressBalance,
      equals(startingSweepAddressBalance + holdingAddressBalance),
    );
  });

  test('should transfer XCH to holding address and sweep funds to BTC holder using preimage',
      () async {
    final exchangeService = BtcToXchExchangeService();

    // generating disposable private and public keys for each participant
    final xchHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    final xchHolderPrivateKey = KeychainCoreSecret.generate().masterPrivateKey;
    final xchHolderPublicKey = xchHolderPrivateKey.getG1();

    final btcHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    final btcHolderPrivateKey = masterSkToWalletSk(btcHolder.keychainSecret.masterPrivateKey, 1);
    final btcHolderPublicKey = btcHolderPrivateKey.getG1();
    final sweepPuzzlehash = btcHolder.firstPuzzlehash;

    await xchHolder.farmCoins();
    await xchHolder.refreshCoins();
    final coins = xchHolder.standardCoins;

    final holdingAddressPuzzlehash = exchangeService.generateHoldingAddressPuzzlehash(
      clawbackDelaySeconds: 10,
      myPublicKey: btcHolderPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      counterpartyPublicKey: xchHolderPublicKey,
    );

    final coinsToSend = coins.sublist(0, 2);
    coins.removeWhere(coinsToSend.contains);

    final coinsValue = coinsToSend.fold(
      0,
      (int previousValue, element) => previousValue + element.amount,
    );
    final amountToSend = (coinsValue * 0.8).round();
    final fee = (coinsValue * 0.1).round();

    // XCH holder transfers funds to holding address
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

    final startingSweepAddressBalance = await fullNodeSimulator.getBalance([sweepPuzzlehash]);

    final holdingAddressCoins =
        await fullNodeSimulator.getCoinsByPuzzleHashes([holdingAddressPuzzlehash]);

    // if the XCH holder disappears and doesn't provide their private key, the BTC holder may use
    // the lightning preimage receipt they receive upon payment of the lightning invoice to
    // sweep funds instead
    final sweepSpendbundle = exchangeService.createSweepSpendBundleWithPreimage(
      clawbackDelaySeconds: 10,
      amount: holdingAddressBalance,
      sweepAddress: sweepPuzzlehash.toAddressWithContext(),
      holdingAddressCoins: holdingAddressCoins,
      myPrivateKey: btcHolderPrivateKey,
      myPublicKey: btcHolderPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      sweepPreimage: sweepPreimage,
      counterpartyPublicKey: xchHolderPublicKey,
    );

    await fullNodeSimulator.pushTransaction(sweepSpendbundle);
    await fullNodeSimulator.moveToNextBlock();

    final endingSweepAddressBalance = await fullNodeSimulator.getBalance([sweepPuzzlehash]);

    expect(
      endingSweepAddressBalance,
      equals(startingSweepAddressBalance + holdingAddressBalance),
    );
  });
}
