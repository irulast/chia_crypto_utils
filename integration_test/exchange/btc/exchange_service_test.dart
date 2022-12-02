// ignore_for_file: lines_longer_than_80_chars
@Timeout(Duration(minutes: 1))

import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/service/btc_to_xch.dart';
import 'package:chia_crypto_utils/src/exchange/service/exchange.dart';
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
  final exchangeService = BtcExchangeService();

  test(
      'should transfer XCH to chiaswap address and fail to clawback funds to XCH holder before delay has passed',
      () async {
    final xchToBtcService = XchToBtcService();
    final xchHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);

    // user input
    const btcHolderSignedPublicKey =
        'ac72743c39137845af0991c71796206c7784b49b76fa30f216ccdeba84e23b28b81d5af48a6cc754d6438057c084f206_b60876a2f323721d8404935991b2c2e392af7e07d93aeb68317646a4c72b7392c00c88331e1ca90330cc9511cd6f2a510b55ee0918ed4d1d58dbf06c805044b9dc906a58ed5252e9dd95d22ccdc9f3016e1848d95f998a2bfbe6f74f5040f688';
    const clawbackAddress =
        Address('xch1f845lxw5whdj747dpcf5409y2k0q6mq7fg3mu8205lpvya3sk44q6rrvsh');
    final sweepReceiptHash =
        Puzzlehash.fromHex('63b49b0dc5f8e216332dabc410d64ee92a8ae73ae0a1d929e76980646d435d98');

    // parse user input
    final btcHolderPublicKey = exchangeService.parseSignedPublicKey(btcHolderSignedPublicKey);
    final clawbackPuzzlehash = clawbackAddress.toPuzzlehash();

    await xchHolder.farmCoins();
    await xchHolder.refreshCoins();
    final coins = xchHolder.standardCoins;

    // generate address for XCH holder to send funds to
    final chiaswapPuzzleAddress = xchToBtcService.generateChiaswapPuzzleAddress(
      requestorKeychain: xchHolder.keychain,
      clawbackPuzzlehash: clawbackPuzzlehash,
      sweepReceiptHash: sweepReceiptHash,
      fulfillerPublicKey: btcHolderPublicKey,
    );

    final chiaswapPuzzlehash = chiaswapPuzzleAddress.toPuzzlehash();

    final coinsToSend = coins.sublist(0, 2);
    coins.removeWhere(coinsToSend.contains);

    final coinsValue = coinsToSend.fold(
      0,
      (int previousValue, element) => previousValue + element.amount,
    );
    final amountToSend = (coinsValue * 0.8).round();
    final fee = (coinsValue * 0.1).round();

    // XCH holder transfers funds to chiaswap address
    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(amountToSend, chiaswapPuzzlehash)],
      coinsInput: coinsToSend,
      changePuzzlehash: xchHolder.firstPuzzlehash,
      keychain: xchHolder.keychain,
      fee: fee,
    );
    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final chiaswapAddressBalance = await fullNodeSimulator.getBalance([chiaswapPuzzlehash]);

    expect(chiaswapAddressBalance, amountToSend);

    final chiaswapAddressCoins =
        await fullNodeSimulator.getCoinsByPuzzleHashes([chiaswapPuzzleAddress.toPuzzlehash()]);

    // this spend bundle will fail if pushed before the clawback delay period passes
    // the default delay is 24 hours
    final clawbackSpendbundle = xchToBtcService.createClawbackSpendBundle(
      payments: [Payment(chiaswapAddressBalance, clawbackPuzzlehash)],
      coinsInput: chiaswapAddressCoins,
      requestorKeychain: xchHolder.keychain,
      sweepReceiptHash: sweepReceiptHash,
      fulfillerPublicKey: btcHolderPublicKey,
    );

    expect(
      () async {
        await fullNodeSimulator.pushTransaction(clawbackSpendbundle);
      },
      throwsException,
    );
  });

  test(
      'should transfer XCH to chiaswap address and clawback funds to XCH holder after delay has passed',
      () async {
    final xchToBtcService = XchToBtcService();
    final xchHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);

    // user input
    const btcHolderSignedPublicKey =
        'ac72743c39137845af0991c71796206c7784b49b76fa30f216ccdeba84e23b28b81d5af48a6cc754d6438057c084f206_b60876a2f323721d8404935991b2c2e392af7e07d93aeb68317646a4c72b7392c00c88331e1ca90330cc9511cd6f2a510b55ee0918ed4d1d58dbf06c805044b9dc906a58ed5252e9dd95d22ccdc9f3016e1848d95f998a2bfbe6f74f5040f688';
    const clawbackAddress =
        Address('xch1f845lxw5whdj747dpcf5409y2k0q6mq7fg3mu8205lpvya3sk44q6rrvsh');
    final sweepReceiptHash =
        Puzzlehash.fromHex('63b49b0dc5f8e216332dabc410d64ee92a8ae73ae0a1d929e76980646d435d98');

    // parse user input
    final btcHolderPublicKey = exchangeService.parseSignedPublicKey(btcHolderSignedPublicKey);
    final clawbackPuzzlehash = clawbackAddress.toPuzzlehash();

    const clawbackDelaySeconds = 5;

    await xchHolder.farmCoins();
    await xchHolder.refreshCoins();
    final coins = xchHolder.standardCoins;

    // generate address for XCH holder to send funds to
    final chiaswapPuzzleAddress = xchToBtcService.generateChiaswapPuzzleAddress(
      clawbackDelaySeconds: clawbackDelaySeconds,
      requestorKeychain: xchHolder.keychain,
      clawbackPuzzlehash: clawbackPuzzlehash,
      sweepReceiptHash: sweepReceiptHash,
      fulfillerPublicKey: btcHolderPublicKey,
    );

    final chiaswapPuzzlehash = chiaswapPuzzleAddress.toPuzzlehash();

    final coinsToSend = coins.sublist(0, 2);
    coins.removeWhere(coinsToSend.contains);

    final coinsValue = coinsToSend.fold(
      0,
      (int previousValue, element) => previousValue + element.amount,
    );
    final amountToSend = (coinsValue * 0.8).round();
    final fee = (coinsValue * 0.1).round();

    // XCH holder transfers funds to chiaswap address
    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(amountToSend, chiaswapPuzzlehash)],
      coinsInput: coinsToSend,
      changePuzzlehash: xchHolder.firstPuzzlehash,
      keychain: xchHolder.keychain,
      fee: fee,
    );
    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final chiaswapAddressBalance = await fullNodeSimulator.getBalance([chiaswapPuzzlehash]);

    expect(chiaswapAddressBalance, amountToSend);

    final startingClawbackAddressBalance = await fullNodeSimulator.getBalance([clawbackPuzzlehash]);

    final chiaswapAddressCoins =
        await fullNodeSimulator.getCoinsByPuzzleHashes([chiaswapPuzzleAddress.toPuzzlehash()]);

    // the clawback spend bundle can be pushed after the clawback delay has passed in order to reclaim funds
    // in the event that the other party doesn't pay the lightning invoice within that time
    final clawbackSpendbundle = xchToBtcService.createClawbackSpendBundle(
      payments: [Payment(chiaswapAddressBalance, clawbackPuzzlehash)],
      coinsInput: chiaswapAddressCoins,
      clawbackDelaySeconds: clawbackDelaySeconds,
      requestorKeychain: xchHolder.keychain,
      sweepReceiptHash: sweepReceiptHash,
      fulfillerPublicKey: btcHolderPublicKey,
    );

    // the earliest you can spend a time-locked coin is 2 blocks later, since the time is checked
    // against the timestamp of the previous block
    for (var i = 0; i < 2; i++) {
      await fullNodeSimulator.moveToNextBlock();
    }

    // wait until clawback delay period has passed
    await Future<void>.delayed(const Duration(seconds: 10), () async {
      await fullNodeSimulator.pushTransaction(clawbackSpendbundle);
      await fullNodeSimulator.moveToNextBlock();
      final endingClawbackAddressBalance = await fullNodeSimulator.getBalance([clawbackPuzzlehash]);

      expect(
        endingClawbackAddressBalance,
        equals(startingClawbackAddressBalance + chiaswapAddressBalance),
      );
    });
  });

  test('should transfer XCH to chiaswap address and sweep funds to BTC holder using preimage',
      () async {
    final btcToXchService = BtcToXchService();
    final xchHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    final btcHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);

    // user input
    const xchHolderSignedPublicKey =
        'ad6abe3d432ccce5b40995611c4db6d71e2678f142b8635940c32c4b1c35dde7b01ab42581075eaee173aba747373f71_97c0d2c1acea7708df1eb4a75f625ca1fe95a9aa141a86c2e18bdfd1e8716cba2888f6230ea122ce9478a78f8257beaf0dfb81714f4de6337fa671cc29bb2d4e18e9aae31829016fd94f14e99f86a9ad990f2740d02583c6a85dc4b6b0233aaa';
    const sweepAddress = Address('xch1w4929z3fw7hxmkddjclmdp9e9zhfhkare9rkm2cj90kwawynn9wqeyuy8f');
    final sweepReceiptHash =
        Puzzlehash.fromHex('63b49b0dc5f8e216332dabc410d64ee92a8ae73ae0a1d929e76980646d435d98');

    // parse user input
    final xchHolderPublicKey = exchangeService.parseSignedPublicKey(xchHolderSignedPublicKey);
    final sweepPuzzlehash = sweepAddress.toPuzzlehash();

    await xchHolder.farmCoins();
    await xchHolder.refreshCoins();
    final coins = xchHolder.standardCoins;

    // generate address for XCH holder to send funds to
    final chiaswapPuzzleAddress = btcToXchService.generateChiaswapPuzzleAddress(
      requestorKeychain: btcHolder.keychain,
      sweepPuzzlehash: sweepPuzzlehash,
      sweepReceiptHash: sweepReceiptHash,
      fulfillerPublicKey: xchHolderPublicKey,
    );

    final chiaswapPuzzlehash = chiaswapPuzzleAddress.toPuzzlehash();

    final coinsToSend = coins.sublist(0, 2);
    coins.removeWhere(coinsToSend.contains);

    final coinsValue = coinsToSend.fold(
      0,
      (int previousValue, element) => previousValue + element.amount,
    );
    final amountToSend = (coinsValue * 0.8).round();
    final fee = (coinsValue * 0.1).round();

    // XCH holder transfers funds to chiaswap address
    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(amountToSend, chiaswapPuzzlehash)],
      coinsInput: coinsToSend,
      changePuzzlehash: xchHolder.firstPuzzlehash,
      keychain: xchHolder.keychain,
      fee: fee,
    );
    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final chiaswapAddressBalance = await fullNodeSimulator.getBalance([chiaswapPuzzlehash]);

    expect(chiaswapAddressBalance, amountToSend);

    final startingSweepAddressBalance = await fullNodeSimulator.getBalance([sweepPuzzlehash]);

    final chiaswapAddressCoins =
        await fullNodeSimulator.getCoinsByPuzzleHashes([chiaswapPuzzlehash]);

    // the BTC holder inputs the lightning preimage receipt they receive upon payment of the
    // lightning invoice to sweep funds
    final sweepPreimage =
        '5c1f10653dc3ff0531b77351dc6676de2e1f5f53c9f0a8867bcb054648f46a32'.hexToBytes();

    final sweepSpendbundle = btcToXchService.createSweepSpendBundle(
      payments: [Payment(chiaswapAddressBalance, sweepPuzzlehash)],
      coinsInput: chiaswapAddressCoins,
      requestorKeychain: btcHolder.keychain,
      sweepReceiptHash: sweepReceiptHash,
      sweepPreimage: sweepPreimage,
      fulfillerPublicKey: xchHolderPublicKey,
    );

    await fullNodeSimulator.pushTransaction(sweepSpendbundle);
    await fullNodeSimulator.moveToNextBlock();

    final endingSweepAddressBalance = await fullNodeSimulator.getBalance([sweepPuzzlehash]);

    expect(
      endingSweepAddressBalance,
      equals(startingSweepAddressBalance + chiaswapAddressBalance),
    );
  });

  test(
      'should transfer XCH to chiaswap address and fail to sweep funds to BTC holder when preimage is incorrect',
      () async {
    final btcToXchService = BtcToXchService();
    final xchHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    final btcHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);

    // user input
    const xchHolderSignedPublicKey =
        'ad6abe3d432ccce5b40995611c4db6d71e2678f142b8635940c32c4b1c35dde7b01ab42581075eaee173aba747373f71_97c0d2c1acea7708df1eb4a75f625ca1fe95a9aa141a86c2e18bdfd1e8716cba2888f6230ea122ce9478a78f8257beaf0dfb81714f4de6337fa671cc29bb2d4e18e9aae31829016fd94f14e99f86a9ad990f2740d02583c6a85dc4b6b0233aaa';
    const sweepAddress = Address('xch1w4929z3fw7hxmkddjclmdp9e9zhfhkare9rkm2cj90kwawynn9wqeyuy8f');
    final sweepReceiptHash =
        Puzzlehash.fromHex('63b49b0dc5f8e216332dabc410d64ee92a8ae73ae0a1d929e76980646d435d98');

    // parse user input
    final xchHolderPublicKey = exchangeService.parseSignedPublicKey(xchHolderSignedPublicKey);
    final sweepPuzzlehash = sweepAddress.toPuzzlehash();

    await xchHolder.farmCoins();
    await xchHolder.refreshCoins();
    final coins = xchHolder.standardCoins;

    // generate address for XCH holder to send funds to
    final chiaswapPuzzleAddress = btcToXchService.generateChiaswapPuzzleAddress(
      requestorKeychain: btcHolder.keychain,
      sweepPuzzlehash: sweepPuzzlehash,
      sweepReceiptHash: sweepReceiptHash,
      fulfillerPublicKey: xchHolderPublicKey,
    );

    final chiaswapPuzzlehash = chiaswapPuzzleAddress.toPuzzlehash();

    final coinsToSend = coins.sublist(0, 2);
    coins.removeWhere(coinsToSend.contains);

    final coinsValue = coinsToSend.fold(
      0,
      (int previousValue, element) => previousValue + element.amount,
    );
    final amountToSend = (coinsValue * 0.8).round();
    final fee = (coinsValue * 0.1).round();

    // XCH holder transfers funds to chiaswap address
    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(amountToSend, chiaswapPuzzlehash)],
      coinsInput: coinsToSend,
      changePuzzlehash: xchHolder.firstPuzzlehash,
      keychain: xchHolder.keychain,
      fee: fee,
    );
    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final chiaswapAddressBalance = await fullNodeSimulator.getBalance([chiaswapPuzzlehash]);

    expect(chiaswapAddressBalance, amountToSend);

    final chiaswapAddressCoins =
        await fullNodeSimulator.getCoinsByPuzzleHashes([chiaswapPuzzlehash]);

    // the BTC holder inputs the lightning preimage receipt they receive upon payment of the
    // lightning invoice to sweep funds
    final sweepPreimage = Puzzlehash.zeros().toBytes();

    expect(
      () {
        btcToXchService.createSweepSpendBundle(
          payments: [Payment(chiaswapAddressBalance, sweepPuzzlehash)],
          coinsInput: chiaswapAddressCoins,
          requestorKeychain: btcHolder.keychain,
          sweepReceiptHash: sweepReceiptHash,
          sweepPreimage: sweepPreimage,
          fulfillerPublicKey: xchHolderPublicKey,
        );
      },
      throwsStateError,
    );
  });

  test('should transfer XCH to chiaswap address and sweep funds to BTC holder using private key',
      () async {
    final btcToXchService = BtcToXchService();
    final xchHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    final btcHolder = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);

    // user input
    const xchHolderSignedPublicKey =
        'ad6abe3d432ccce5b40995611c4db6d71e2678f142b8635940c32c4b1c35dde7b01ab42581075eaee173aba747373f71_97c0d2c1acea7708df1eb4a75f625ca1fe95a9aa141a86c2e18bdfd1e8716cba2888f6230ea122ce9478a78f8257beaf0dfb81714f4de6337fa671cc29bb2d4e18e9aae31829016fd94f14e99f86a9ad990f2740d02583c6a85dc4b6b0233aaa';
    const sweepAddress = Address('xch1w4929z3fw7hxmkddjclmdp9e9zhfhkare9rkm2cj90kwawynn9wqeyuy8f');
    final sweepReceiptHash =
        Puzzlehash.fromHex('63b49b0dc5f8e216332dabc410d64ee92a8ae73ae0a1d929e76980646d435d98');

    // parse user input
    final xchHolderPublicKey = exchangeService.parseSignedPublicKey(xchHolderSignedPublicKey);
    final sweepPuzzlehash = sweepAddress.toPuzzlehash();

    await xchHolder.farmCoins();
    await xchHolder.refreshCoins();
    final coins = xchHolder.standardCoins;

    // generate address for XCH holder to send funds to
    final chiaswapPuzzleAddress = btcToXchService.generateChiaswapPuzzleAddress(
      requestorKeychain: btcHolder.keychain,
      sweepPuzzlehash: sweepPuzzlehash,
      sweepReceiptHash: sweepReceiptHash,
      fulfillerPublicKey: xchHolderPublicKey,
    );

    final chiaswapPuzzlehash = chiaswapPuzzleAddress.toPuzzlehash();

    final coinsToSend = coins.sublist(0, 2);
    coins.removeWhere(coinsToSend.contains);

    final coinsValue = coinsToSend.fold(
      0,
      (int previousValue, element) => previousValue + element.amount,
    );
    final amountToSend = (coinsValue * 0.8).round();
    final fee = (coinsValue * 0.1).round();

    // XCH holder transfers funds to chiaswap address
    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(amountToSend, chiaswapPuzzlehash)],
      coinsInput: coinsToSend,
      changePuzzlehash: xchHolder.firstPuzzlehash,
      keychain: xchHolder.keychain,
      fee: fee,
    );
    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final chiaswapAddressBalance = await fullNodeSimulator.getBalance([chiaswapPuzzlehash]);

    expect(chiaswapAddressBalance, amountToSend);

    final startingSweepAddressBalance = await fullNodeSimulator.getBalance([sweepPuzzlehash]);

    final chiaswapAddressCoins =
        await fullNodeSimulator.getCoinsByPuzzleHashes([chiaswapPuzzlehash]);

    // after the lightning invoice is paid, the XCH holder may share their private key
    // the BTC holder inputs the private key, allowing them to sweep funds from the chiaswap address
    
    // WARNING: this method effectively burns the private key that is exposed to the
    // other party
    final xchHolderPrivateKey =
        PrivateKey.fromHex('12880bf94cdab774339291042eec316a2e2f5a23f94ed3f0b07547cd6966b903');

    final sweepSpendbundle = btcToXchService.createSweepSpendBundleWithPk(
      payments: [Payment(chiaswapAddressBalance, sweepPuzzlehash)],
      coinsInput: chiaswapAddressCoins,
      requestorKeychain: btcHolder.keychain,
      sweepReceiptHash: sweepReceiptHash,
      fulfillerPrivateKey: xchHolderPrivateKey,
    );

    await fullNodeSimulator.pushTransaction(sweepSpendbundle);
    await fullNodeSimulator.moveToNextBlock();

    final endingSweepAddressBalance = await fullNodeSimulator.getBalance([sweepPuzzlehash]);

    expect(
      endingSweepAddressBalance,
      equals(startingSweepAddressBalance + chiaswapAddressBalance),
    );
  });
}
