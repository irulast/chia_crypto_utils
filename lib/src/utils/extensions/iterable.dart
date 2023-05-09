import 'dart:math';

extension Fatten<T> on Iterable<Iterable<T>> {
  // flatten a list of lists
  List<T> flatten() => expand((element) => element).toList();
}

extension RandomItem<T> on List<T> {
  static final _random = Random();
  T getRandomItem() {
    return this[_random.nextInt(length)];
  }
}
