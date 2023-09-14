@Timeout(Duration(minutes: 5))

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

Future<void> main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  final coinSplittingService = CoinSplittingService(
    fullNodeSimulator,
    coinSearchWaitPeriod: const Duration(seconds: 5),
    blockchainUtils: SimulatorBlockchainUtils(fullNodeSimulator),
  );

  const desiredNumberOfCoins = 91;

  late ChiaEnthusiast meera;

  setUp(() async {
    meera = ChiaEnthusiast(fullNodeSimulator, walletSize: 10);
    await meera.farmCoins();
    await meera.issueMultiIssuanceCat(meera.keychainSecret.masterPrivateKey);
  });

  test('should split coins', () async {
    await coinSplittingService.splitCoins(
      catCoinToSplit: meera.catCoins[0],
      standardCoinsForFee: meera.standardCoins,
      keychain: meera.keychain,
      splitWidth: 3,
      feePerCoin: 10000,
      desiredNumberOfCoins: desiredNumberOfCoins,
      desiredAmountPerCoin: 101,
      changePuzzlehash: meera.firstPuzzlehash,
    );

    final meeraAssetId = meera.catCoinMap.keys.first;

    final resultingCoins = await fullNodeSimulator.getCatCoinsByOuterPuzzleHashes(
      meera.keychain.getOuterPuzzleHashesForAssetId(meeraAssetId),
    );

    expect(resultingCoins.where((c) => c.amount == 101).length, equals(91));
  });

  test('should throw error when cat balance is not enough to meet desired splitting parameters',
      () async {
    //cat coin balance is 100000000

    try {
      await coinSplittingService.splitCoins(
        catCoinToSplit: meera.catCoins[0],
        standardCoinsForFee: meera.standardCoins,
        keychain: meera.keychain,
        splitWidth: 3,
        feePerCoin: 1000,
        desiredNumberOfCoins: desiredNumberOfCoins,
        desiredAmountPerCoin: 10000000,
        changePuzzlehash: meera.firstPuzzlehash,
      );
    } catch (e) {
      expect(e, isA<ArgumentError>());
    }
  });

  test(
      'should throw error when cat balance is just barely not enough to meet desired splitting parameters',
      () async {
    try {
      await coinSplittingService.splitCoins(
        catCoinToSplit: meera.catCoins[0],
        standardCoinsForFee: meera.standardCoins,
        keychain: meera.keychain,
        splitWidth: 3,
        feePerCoin: 1000,
        desiredNumberOfCoins: desiredNumberOfCoins,
        desiredAmountPerCoin: 1111112,
        changePuzzlehash: meera.firstPuzzlehash,
      );
    } catch (e) {
      expect(e, isA<ArgumentError>());
    }
  });

  test('should work when cat balance is just barely enough to meet desired splitting parameters',
      () async {
    final returnedNumberOfCoins = await coinSplittingService.splitCoins(
      catCoinToSplit: meera.catCoins[0],
      standardCoinsForFee: meera.standardCoins,
      keychain: meera.keychain,
      splitWidth: 3,
      feePerCoin: 1000,
      desiredNumberOfCoins: desiredNumberOfCoins,
      desiredAmountPerCoin: 111111,
      changePuzzlehash: meera.firstPuzzlehash,
    );

    expect(returnedNumberOfCoins, equals(desiredNumberOfCoins));
  });

  test(
      'should throw error when standard balance is not enough to meet desired splitting parameters',
      () async {
    // standard balance is 1999900000000

    try {
      await coinSplittingService.splitCoins(
        catCoinToSplit: meera.catCoins[0],
        standardCoinsForFee: meera.standardCoins,
        keychain: meera.keychain,
        splitWidth: 3,
        feePerCoin: 50000000000,
        desiredNumberOfCoins: desiredNumberOfCoins,
        desiredAmountPerCoin: 101,
        changePuzzlehash: meera.firstPuzzlehash,
      );
    } catch (e) {
      expect(e, isA<ArgumentError>());
    }
  });

  test(
      'should throw error when standard balance is just barely not enough to meet desired splitting parameters',
      () async {
    try {
      await coinSplittingService.splitCoins(
        catCoinToSplit: meera.catCoins[0],
        standardCoinsForFee: meera.standardCoins,
        keychain: meera.keychain,
        splitWidth: 3,
        feePerCoin: 8583261803,
        desiredNumberOfCoins: desiredNumberOfCoins,
        desiredAmountPerCoin: 101,
        changePuzzlehash: meera.firstPuzzlehash,
      );
    } catch (e) {
      expect(e, isA<ArgumentError>());
    }
  });

  test(
      'should work when standard balance is just barely enough to meet desired splitting parameters',
      () async {
    final returnedNumberOfCoins = await coinSplittingService.splitCoins(
      catCoinToSplit: meera.catCoins[0],
      standardCoinsForFee: meera.standardCoins,
      keychain: meera.keychain,
      splitWidth: 3,
      feePerCoin: 200000000,
      desiredNumberOfCoins: desiredNumberOfCoins,
      desiredAmountPerCoin: 101,
      changePuzzlehash: meera.firstPuzzlehash,
    );

    expect(returnedNumberOfCoins, equals(returnedNumberOfCoins));
  });

  test('should throw error when there are not enough puzzlehashes to cover split width', () async {
    // a minimum of 10 puzzlehashes is needed to cover the split width
    final nathan = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    await nathan.farmCoins();
    await nathan.issueMultiIssuanceCat(nathan.keychainSecret.masterPrivateKey);

    try {
      await coinSplittingService.splitCoins(
        catCoinToSplit: nathan.catCoins[0],
        standardCoinsForFee: nathan.standardCoins,
        keychain: nathan.keychain,
        splitWidth: 3,
        feePerCoin: 10000,
        desiredNumberOfCoins: desiredNumberOfCoins,
        desiredAmountPerCoin: 101,
        changePuzzlehash: nathan.firstPuzzlehash,
      );
    } catch (e) {
      expect(e, isA<ArgumentError>());
    }
  });

  test(
      'should throw error when there are is just barely not enough puzzlehashes to cover split width',
      () async {
    final nathan = ChiaEnthusiast(fullNodeSimulator, walletSize: 9);
    await nathan.farmCoins();
    await nathan.issueMultiIssuanceCat(nathan.keychainSecret.masterPrivateKey);

    try {
      await coinSplittingService.splitCoins(
        catCoinToSplit: nathan.catCoins[0],
        standardCoinsForFee: nathan.standardCoins,
        keychain: nathan.keychain,
        splitWidth: 3,
        feePerCoin: 10000,
        desiredNumberOfCoins: desiredNumberOfCoins,
        desiredAmountPerCoin: 101,
        changePuzzlehash: nathan.firstPuzzlehash,
      );
    } catch (e) {
      expect(e, isA<ArgumentError>());
    }
  });
}
