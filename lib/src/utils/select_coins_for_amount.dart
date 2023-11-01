import 'package:chia_crypto_utils/chia_crypto_utils.dart';

/// throws [InsufficientBalanceException]
List<T> selectCoinsForAmount<T extends CoinPrototype>(
  List<T> coinsInput,
  int amount, {
  int? maxNumberOfCoins,
  int minMojos = 50,
  CoinSelectionType selectionType = CoinSelectionType.closestValue,
}) {
  return selectionType.selector.select<T>(
    coinsInput,
    amount,
    maxNumberOfCoins: maxNumberOfCoins,
    minMojos: minMojos,
  );
}

/// throws [InsufficientStandardBalanceException]
List<Coin> selectStandardCoinsForAmount(
  List<Coin> coinsInput,
  int amount, {
  int? maxNumberOfCoins,
  int minMojos = 50,
  CoinSelectionType selectionType = CoinSelectionType.closestValue,
}) {
  try {
    return selectionType.selector.select<Coin>(
      coinsInput,
      amount,
      maxNumberOfCoins: maxNumberOfCoins,
      minMojos: minMojos,
    );
  } on InsufficientBalanceException catch (e) {
    throw InsufficientStandardBalanceException(
      requiredBalance: amount,
      currentBalance: e.currentBalance,
    );
  }
}

/// throws [InsufficientCatBalanceException]
List<CatCoin> selectCatCoinsForAmount(
  List<CatCoin> coinsInput,
  int amount, {
  required Puzzlehash assetId,
  int? maxNumberOfCoins,
  int minMojos = 50,
  CoinSelectionType selectionType = CoinSelectionType.closestValue,
}) {
  try {
    return selectionType.selector.select<CatCoin>(
      coinsInput,
      amount,
      maxNumberOfCoins: maxNumberOfCoins,
      minMojos: minMojos,
    );
  } on InsufficientBalanceException catch (e) {
    throw InsufficientCatBalanceException(
      requiredBalance: amount,
      currentBalance: e.currentBalance,
      assetId: assetId,
    );
  }
}

enum CoinSelectionType {
  biggetsFirst(BiggestFirstCoinSelector()),
  smallestFirst(SmallestFirstCoinSelector()),
  closestValue(ClosestValueCoinSelector());

  const CoinSelectionType(this.selector);
  final CoinSelector selector;

  List<CoinPrototype> select<T extends CoinPrototype>(
    List<T> coins,
    int amount, {
    int minMojos = 50,
    required int? maxNumberOfCoins,
  }) =>
      selector.select(
        coins,
        amount,
        maxNumberOfCoins: maxNumberOfCoins,
        minMojos: minMojos,
      );
}

abstract class CoinSelector {
  List<T> select<T extends CoinPrototype>(
    List<T> coins,
    int amount, {
    int minMojos = 50,
    required int? maxNumberOfCoins,
  });
}

class SmallestFirstCoinSelector implements CoinSelector {
  const SmallestFirstCoinSelector();

  @override
  List<T> select<T extends CoinPrototype>(
    List<T> coins,
    int amount, {
    int minMojos = 50,
    required int? maxNumberOfCoins,
  }) {
    return _selectSortedCoinsForAmount<T>(
      coins,
      amount,
      comparor: (a, b) => a.amount.compareTo(b.amount),
      maxNumberOfCoins: maxNumberOfCoins,
      minMojos: minMojos,
    );
  }
}

class BiggestFirstCoinSelector implements CoinSelector {
  const BiggestFirstCoinSelector();

  @override
  List<T> select<T extends CoinPrototype>(
    List<T> coins,
    int amount, {
    int minMojos = 50,
    required int? maxNumberOfCoins,
  }) {
    return _selectSortedCoinsForAmount<T>(
      coins,
      amount,
      comparor: (a, b) => b.amount.compareTo(a.amount),
      maxNumberOfCoins: maxNumberOfCoins,
      minMojos: minMojos,
    );
  }
}

class ClosestValueCoinSelector implements CoinSelector {
  const ClosestValueCoinSelector();

  @override
  List<T> select<T extends CoinPrototype>(
    List<T> coins,
    int amount, {
    int minMojos = 50,
    required int? maxNumberOfCoins,
  }) {
    final coinsWithDiffs = coins
        .map((e) => CoinWithDiff(e, (e.amount - amount).abs()))
        .toList()
      ..sort((a, b) => a.diff.compareTo(b.diff));

    final selectedCoins = <T>[];
    var totalCoinValue = 0;

    void addSelectedCoin(T coin) {
      selectedCoins.add(coin);
      totalCoinValue += coin.amount;

      if (maxNumberOfCoins != null && selectedCoins.length > maxNumberOfCoins) {
        throw MaxCoinsExceededException(maxNumberOfCoins);
      }
    }

    for (final coinWithDiff in coinsWithDiffs) {
      if (coinWithDiff.coin.amount < minMojos) {
        continue;
      }

      addSelectedCoin(coinWithDiff.coin);

      if (totalCoinValue >= amount) {
        return selectedCoins;
      }
    }

    if (totalCoinValue < amount) {
      throw InsufficientBalanceException(
        requiredBalance: amount,
        currentBalance: totalCoinValue,
      );
    }

    return selectedCoins;
  }
}

class CoinWithDiff<T extends CoinPrototype> {
  CoinWithDiff(this.coin, this.diff);

  final T coin;
  final int diff;
}

List<T> _selectSortedCoinsForAmount<T extends CoinPrototype>(
  List<T> coinsInput,
  int amount, {
  required int Function(CoinPrototype a, CoinPrototype b) comparor,
  required int minMojos,
  required int? maxNumberOfCoins,
}) {
  final coins = List<T>.from(coinsInput)
    ..sort(
      comparor,
    );
  var totalCoinValue = 0;

  final selectedCoins = <T>[];
  final smallCoins = <T>[];

  void addSelectedCoin(T coin) {
    selectedCoins.add(coin);
    totalCoinValue += coin.amount;

    if (maxNumberOfCoins != null && selectedCoins.length > maxNumberOfCoins) {
      throw MaxCoinsExceededException(maxNumberOfCoins);
    }
  }

  for (final coin in coins) {
    if (coin.amount < minMojos) {
      smallCoins.add(coin);
      continue;
    }
    if (totalCoinValue >= amount) {
      break;
    }
    addSelectedCoin(coin);
  }

  if (totalCoinValue >= amount) {
    return selectedCoins;
  }

  // if coins above minimum amount cutoff isnt enough, try adding small coins as well
  for (final smallCoin in smallCoins) {
    if (totalCoinValue >= amount) {
      break;
    }

    addSelectedCoin(smallCoin);
  }

  if (totalCoinValue < amount) {
    throw InsufficientBalanceException(
        requiredBalance: amount, currentBalance: totalCoinValue);
  }

  return selectedCoins;
}
