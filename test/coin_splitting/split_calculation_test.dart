import 'dart:math';

import 'package:chia_crypto_utils/src/api/coin_splitting/service/coin_splitting_service.dart';
import 'package:test/test.dart';

void main() {
  final binarySplittingInputToExpectedOutputMap = <int, List<int>>{
// desiredNumberOfCoins: [numberOfNWidthSplits, numberOfDeca]
    1: [0, 0],
    2: [1, 0],
    4: [2, 0],
    8: [3, 0],
    16: [4, 0],
    32: [5, 0],
    64: [6, 0],
    128: [7, 0],
    256: [8, 0],
    512: [9, 0],
    3: [1, 0],
    5: [2, 0],
    9: [3, 0],
    17: [4, 0],
    33: [5, 0],
    65: [6, 0],
    129: [7, 0],
    257: [8, 0],
    513: [9, 0],
    400: [2, 2],
    52: [2, 1],
    127: [0, 2],
    2500: [1, 3],
    1912879: [4, 5],
    99: [3, 1],
    400000: [2, 5],
    32000: [5, 3],
  };

  final septSplittingInputToExpectedOutputMap = <int, List<int>>{
// desiredNumberOfCoins: [numberOfNWidthSplits, numberOfDeca]
    1: [0, 0],
    2: [0, 0],
    7: [1, 0],
    49: [2, 0],
    343: [3, 0],
    2401: [4, 0],
    16807: [5, 0],
    117649: [6, 0],
    823543: [7, 0],
    8: [1, 0],
    50: [2, 0],
    344: [3, 0],
    2402: [4, 0],
    16808: [5, 0],
    117650: [6, 0],
    823544: [7, 0],
    7000: [1, 3],
    1000000: [0, 6],
  };

  final forHundredSplittingInputToExpectedOutputMap = <int, List<int>>{
// desiredNumberOfCoins: [numberOfNWidthSplits, numberOfDeca]
    1: [0, 0],
    2: [0, 0],
    400: [1, 0],
    7000: [1, 1],
    1700000: [2, 1],
  };

  test('should correctly calculate number of binary splits', () {
    binarySplittingInputToExpectedOutputMap.forEach((desiredNumberOfCoins, expectedNumberOfSplits) {
      final numberOfSplits = CoinSplittingService.calculateNumberOfNWidthSplitsRequired(
        desiredNumberOfCoins: desiredNumberOfCoins,
        initialSplitWidth: 2,
      );
      expect(numberOfSplits, equals(expectedNumberOfSplits[0]));

      final resultingCoinsFromNWidthSplits = pow(2, numberOfSplits).toInt();

      final numberOfDecaSplits = CoinSplittingService.calculateNumberOfDecaSplitsRequired(
        resultingCoinsFromNWidthSplits,
        desiredNumberOfCoins,
      );
      expect(numberOfDecaSplits, equals(expectedNumberOfSplits[1]));
    });
  });

  test('should correctly calculate number of 7 splits', () {
    septSplittingInputToExpectedOutputMap.forEach((desiredNumberOfCoins, expectedNumberOfSplits) {
      final numberOfSplits = CoinSplittingService.calculateNumberOfNWidthSplitsRequired(
        desiredNumberOfCoins: desiredNumberOfCoins,
        initialSplitWidth: 7,
      );
      expect(numberOfSplits, equals(expectedNumberOfSplits[0]));

      final resultingCoinsFromNWidthSplits = pow(7, numberOfSplits).toInt();

      final numberOfDecaSplits = CoinSplittingService.calculateNumberOfDecaSplitsRequired(
        resultingCoinsFromNWidthSplits,
        desiredNumberOfCoins,
      );
      expect(numberOfDecaSplits, equals(expectedNumberOfSplits[1]));
    });
  });

  test('should correctly calculate number of 400 splits', () {
    forHundredSplittingInputToExpectedOutputMap.forEach((desiredNumberOfCoins, expectedNumberOfSplits) {
      final numberOfSplits = CoinSplittingService.calculateNumberOfNWidthSplitsRequired(
        desiredNumberOfCoins: desiredNumberOfCoins,
        initialSplitWidth: 400,
      );
      expect(numberOfSplits, equals(expectedNumberOfSplits[0]));

      final resultingCoinsFromNWidthSplits = pow(400, numberOfSplits).toInt();

      final numberOfDecaSplits = CoinSplittingService.calculateNumberOfDecaSplitsRequired(
        resultingCoinsFromNWidthSplits,
        desiredNumberOfCoins,
      );
      expect(numberOfDecaSplits, equals(expectedNumberOfSplits[1]));
    });
  });
}
