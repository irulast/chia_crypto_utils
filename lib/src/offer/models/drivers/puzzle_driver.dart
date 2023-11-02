import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/offer/models/drivers/did_puzzle_driver.dart';
import 'package:chia_crypto_utils/src/offer/models/offered_coin/offered_coin.dart';
import 'package:deep_pick/deep_pick.dart';

abstract class PuzzleDriver {
  static PuzzleDriver? match(Program fullPuzzle) {
    final uncurried = fullPuzzle.uncurry();
    final matchingDrivers =
        drivers.where((e) => e.doesMatchUncurried(uncurried, fullPuzzle));
    if (matchingDrivers.isEmpty) {
      return null;
    }
    return matchingDrivers.single;
  }

  static Future<PuzzleDriver?> matchAsync(
    Program fullPuzzle, {
    List<PuzzleDriver>? driversToCheck,
  }) async {
    final unCurried = await fullPuzzle.uncurryAsync();
    final matchingDrivers = (driversToCheck ?? drivers)
        .where((e) => e.doesMatchUncurried(unCurried, fullPuzzle));
    if (matchingDrivers.isEmpty) {
      return null;
    }
    return matchingDrivers.single;
  }

  bool doesMatch(Program fullPuzzle);
  bool doesMatchUncurried(
    ModAndArguments uncurriedFullPuzzle,
    Program fullPuzzle,
  );

  Program getNewFullPuzzleForP2Puzzle(
    Program currentFullPuzzle,
    Program p2Puzzle,
  );
  Puzzlehash? getAssetId(Program fullPuzzle);

  OfferedCoin makeOfferedCoinFromParentSpend(
    CoinPrototype coin,
    CoinSpend parentSpend,
  );

  SpendType get type;

  Program getP2Solution(CoinSpend coinSpend);
  Program getP2Puzzle(CoinSpend coinSpend);

  CoinPrototype getChildCoinForP2Payment(
    CoinSpend coinSpend,
    Payment p2Payment,
  );
}

CoinPrototype getSingletonChildFromCoinSpend(CoinSpend coinSpend) {
  return coinSpend.additions.singleWhere((element) => element.amount.isOdd);
}

extension PuzzlePayments on PuzzleDriver {
  /// faster than [getP2Payments], but less accurate when dealing with irregular spends.
  List<Payment> getP2PaymentsFromSolution(CoinSpend coinSpend) {
    final innerSolution = getP2Solution(coinSpend);
    return BaseWalletService.extractPaymentsFromSolution(innerSolution);
  }

  /// most accurate way to get p2 payments
  List<Payment> getP2Payments(CoinSpend coinSpend) {
    final innerSolution = getP2Solution(coinSpend);
    final innerPuzzle = getP2Puzzle(coinSpend);

    final createCoinConditions =
        BaseWalletService.extractConditionsFromProgramList(
      innerPuzzle.run(innerSolution).program.toList(),
      CreateCoinCondition.isThisCondition,
      CreateCoinCondition.fromProgram,
    );

    return createCoinConditions.map((e) => e.toPayment()).toList();
  }

  Future<List<Payment>> getP2PaymentsAsync(CoinSpend coinSpend) async {
    final result = await spawnAndWaitForIsolate(
      taskArgument: PuzzleDriverAndCoinSpend(coinSpend, this),
      isolateTask: _getP2PaymentsTask,
      handleTaskCompletion: (taskResultJson) {
        return pick(taskResultJson, 'payments').letStringListOrThrow(
          (string) => Payment.fromProgram(Program.deserializeHex(string)),
        );
      },
    );
    return result;
  }

  Future<Puzzlehash> getP2PuzzlehashAsync(CoinSpend coinSpend) async {
    final result = await spawnAndWaitForIsolate(
      taskArgument: PuzzleDriverAndCoinSpend(coinSpend, this),
      isolateTask: _getP2PuzzleHashTask,
      handleTaskCompletion: (taskResultJson) {
        return Puzzlehash.fromHex(
          pick(taskResultJson, 'p2_puzzle_hash').asStringOrThrow(),
        );
      },
    );
    return result;
  }

  Future<Program> getP2PuzzleAsync(CoinSpend coinSpend) async {
    final result = await spawnAndWaitForIsolate(
      taskArgument: PuzzleDriverAndCoinSpend(coinSpend, this),
      isolateTask: _getP2PuzzleTask,
      handleTaskCompletion: (taskResultJson) {
        return Program.deserializeHex(
          pick(taskResultJson, 'p2_puzzle').asStringOrThrow(),
        );
      },
    );
    return result;
  }

  Future<CoinPrototype> getChildCoinForP2PaymentAsync(
    CoinSpend coinSpend,
    Payment p2Payment,
  ) async {
    final result = await spawnAndWaitForIsolate(
      taskArgument: PuzzleDriverCoinSpendAndPayment(coinSpend, this, p2Payment),
      isolateTask: _getChildCoinForP2PaymentTask,
      handleTaskCompletion: CoinPrototype.fromJson,
    );
    return result;
  }

  Future<Bytes> getChildCoinIdForP2PaymentAsync(
    CoinSpend coinSpend,
    Payment p2Payment,
  ) async {
    final result = await spawnAndWaitForIsolate(
      taskArgument: PuzzleDriverCoinSpendAndPayment(coinSpend, this, p2Payment),
      isolateTask: _getChildCoinIdForP2PaymentTask,
      handleTaskCompletion: (taskResultJson) {
        return pick(taskResultJson, 'coin_id').asBytesOrThrow();
      },
    );
    return result;
  }
}

Map<String, dynamic> _getP2PuzzleTask(PuzzleDriverAndCoinSpend arguments) {
  return {
    'p2_puzzle': arguments.puzzleDriver.getP2Puzzle(arguments.coinSpend).toHex()
  };
}

Map<String, dynamic> _getP2PuzzleHashTask(PuzzleDriverAndCoinSpend arguments) {
  return {
    'p2_puzzle_hash':
        arguments.puzzleDriver.getP2Puzzle(arguments.coinSpend).hash().toHex()
  };
}

Map<String, dynamic> _getChildCoinForP2PaymentTask(
  PuzzleDriverCoinSpendAndPayment arguments,
) {
  return arguments.puzzleDriver
      .getChildCoinForP2Payment(arguments.coinSpend, arguments.payment)
      .toJson();
}

Map<String, dynamic> _getChildCoinIdForP2PaymentTask(
  PuzzleDriverCoinSpendAndPayment arguments,
) {
  return {
    'coin_id': arguments.puzzleDriver
        .getChildCoinForP2Payment(arguments.coinSpend, arguments.payment)
        .id
        .byteList,
  };
}

Map<String, dynamic> _getP2PaymentsTask(PuzzleDriverAndCoinSpend arguments) {
  return {
    'payments': arguments.puzzleDriver
        .getP2Payments(arguments.coinSpend)
        .map((e) => e.toProgram().toHex())
        .toList(),
  };
}

class PuzzleDriverAndCoinSpend {
  PuzzleDriverAndCoinSpend(this.coinSpend, this.puzzleDriver);

  final CoinSpend coinSpend;
  final PuzzleDriver puzzleDriver;
}

class PuzzleDriverCoinSpendAndPayment extends PuzzleDriverAndCoinSpend {
  PuzzleDriverCoinSpendAndPayment(
    super.coinSpend,
    super.puzzleDriver,
    this.payment,
  );

  final Payment payment;
}

final drivers = [
  Cat2PuzzleDriver(),
  Cat1PuzzleDriver(),
  NftPuzzleDriver(),
  DidNftPuzzleDriver(),
  StandardPuzzleDriver(),
  DidPuzzleDriver(),
];
