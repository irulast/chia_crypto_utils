abstract class Summable {
  int get amount;
}

extension Sum on Iterable<Summable> {
  int sum() => fold(0, (int previousValue, item) => previousValue + item.amount);
}
