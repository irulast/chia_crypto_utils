import 'package:chia_crypto_utils/chia_crypto_utils.dart';

List<CoinPrototype> selectCoinsForAmount(
  List<CoinPrototype> coinsInput,
  int amount, {
  int? maxNumberOfCoins,
  int minMojos = 50,
  CoinSelectionType selectionType = CoinSelectionType.closestValue,
}) {
  return selectionType.selector.select(
    coinsInput,
    amount,
    maxNumberOfCoins: maxNumberOfCoins,
    minMojos: minMojos,
  );
}

enum CoinSelectionType {
  biggetsFirst(BiggestFirstCoinSelector()),
  smallestFirst(SmallestFirstCoinSelector()),
  closestValue(ClosestValueCoinSelector());

  const CoinSelectionType(this.selector);
  final CoinSelector selector;

  List<CoinPrototype> select(
    List<CoinPrototype> coins,
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
  List<CoinPrototype> select(
    List<CoinPrototype> coins,
    int amount, {
    int minMojos = 50,
    required int? maxNumberOfCoins,
  });
}

class SmallestFirstCoinSelector implements CoinSelector {
  const SmallestFirstCoinSelector();

  @override
  List<CoinPrototype> select(
    List<CoinPrototype> coins,
    int amount, {
    int minMojos = 50,
    required int? maxNumberOfCoins,
  }) {
    return _selectSortedCoinsForAmount(
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
  List<CoinPrototype> select(
    List<CoinPrototype> coins,
    int amount, {
    int minMojos = 50,
    required int? maxNumberOfCoins,
  }) {
    return _selectSortedCoinsForAmount(
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
  List<CoinPrototype> select(
    List<CoinPrototype> coins,
    int amount, {
    int minMojos = 50,
    required int? maxNumberOfCoins,
  }) {
    final coinsWithDiffs = coins.map((e) => CoinWithDiff(e, (e.amount - amount).abs())).toList()
      ..sort((a, b) => a.diff.compareTo(b.diff));

    final selectedCoins = <CoinPrototype>[];
    var totalCoinValue = 0;

    void addSelectedCoin(CoinPrototype coin) {
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

    throw InsufficientBalanceException(
      requiredBalance: amount,
      currentBalance: totalCoinValue,
    );
  }
}

class CoinWithDiff {
  CoinWithDiff(this.coin, this.diff);
  final CoinPrototype coin;
  final int diff;
}

List<CoinPrototype> _selectSortedCoinsForAmount(
  List<CoinPrototype> coinsInput,
  int amount, {
  required int Function(CoinPrototype a, CoinPrototype b) comparor,
  required int minMojos,
  required int? maxNumberOfCoins,
}) {
  final coins = List<CoinPrototype>.from(coinsInput)
    ..sort(
      comparor,
    );
  var totalCoinValue = 0;

  final selectedCoins = <CoinPrototype>[];
  final smallCoins = <CoinPrototype>[];

  void addSelectedCoin(CoinPrototype coin) {
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
    throw InsufficientBalanceException(requiredBalance: amount, currentBalance: totalCoinValue);
  }

  return selectedCoins;
}
