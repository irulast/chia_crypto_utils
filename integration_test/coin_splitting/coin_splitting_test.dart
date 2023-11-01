@Timeout(Duration(seconds: 120))
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/coin_splitting/service/standard_coin_splitting_service_updated.dart';
import 'package:test/test.dart';

void main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  final testCases = <SplittingTestCase>[];

  for (final desiredNumberOfCoins in [
    10,
    // 76,
    // 120,
    // 500,
  ]) {
    for (final desiredCoinAmount in [100]) {
      for (final feePerCoin in [50]) {
        for (final splitWith in [
          10,
          // 10,
          // 12,
          // 100,
        ]) {
          testCases.add(
            SplittingTestCase(
              numberOfCoins: desiredNumberOfCoins,
              coinAmount: desiredCoinAmount,
              feePerCoin: feePerCoin,
              splitWidth: splitWith,
            ),
          );
        }
      }
    }
  }

  group('should correctly split coins', () {
    for (final testCase in testCases) {
      test('for test case: $testCase', () async {
        final nathan = ChiaEnthusiast(fullNodeSimulator, walletSize: 102);

        await nathan.farmCoins();
        final initialCoins = nathan.standardCoins;

        final coinSplittingService = StandardCoinSplittingService();

        late final SpendBundle spendBundle;

        void constructSpendBundle() {
          spendBundle = coinSplittingService.createCoinSplittingSpendBundle(
            coin: nathan.standardCoins.first,
            targetCoinCount: testCase.numberOfCoins,
            targetAmountPerCoin: testCase.coinAmount,
            feePerCoinSpend: testCase.feePerCoin,
            splitWidth: testCase.splitWidth,
            keychain: nathan.keychain,
            changePuzzleHash: nathan.keychain.puzzlehashes.first,
          );
        }

        if (testCase.splitWidth > testCase.numberOfCoins) {
          expect(
            constructSpendBundle,
            throwsA(predicate(
                (p0) => p0 is InvalidCoinSplittingParametersException)),
          );
          return;
        } else {
          constructSpendBundle();
        }

        await fullNodeSimulator.pushTransaction(spendBundle);

        await fullNodeSimulator.moveToNextBlock();

        await nathan.refreshCoins();
        final endingCoins = nathan.standardCoins;

        final totalFee = (testCase.numberOfCoins / testCase.splitWidth).ceil() *
            testCase.feePerCoin;

        expect(
          endingCoins.totalValue,
          initialCoins.totalValue - totalFee,
        );

        expect(
            endingCoins.length, initialCoins.length + testCase.numberOfCoins);

        var matchingCoinAmounts = 0;

        for (final coin in nathan.standardCoins) {
          if (coin.amount == testCase.coinAmount) {
            matchingCoinAmounts++;
          }
        }

        expect(matchingCoinAmounts, testCase.numberOfCoins);
      });
    }
  });
}

class SplittingTestCase {
  SplittingTestCase({
    required this.numberOfCoins,
    required this.coinAmount,
    required this.feePerCoin,
    required this.splitWidth,
  });

  final int numberOfCoins;
  final int coinAmount;
  final int feePerCoin;
  final int splitWidth;

  @override
  String toString() {
    return 'SplittingTestCase(numberOfCoins: $numberOfCoins, coinAmount: $coinAmount, feePerCoin: $feePerCoin,  splitWith: $splitWidth)';
  }
}
