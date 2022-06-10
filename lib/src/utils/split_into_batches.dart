extension SplitIntoBatches<T> on List<T> {
  List<List<T>> splitIntoBatches(int batchSize) {
    final listLength = length;
    final batches = <List<T>>[];

    for (var i = 0; i < listLength; i += batchSize) {
      final end = (i + batchSize < listLength) ? i + batchSize : listLength;
      batches.add(sublist(i, end));
    }
    return batches;
  }
}
