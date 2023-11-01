class AssertAnnouncementConsumeFailedException implements Exception {
  AssertAnnouncementConsumeFailedException();

  @override
  String toString() {
    return 'Asserted announcement that was not consumed';
  }
}

class FeeTooSmallException implements Exception {
  FeeTooSmallException(this.fee);

  final int fee;

  @override
  String toString() {
    return 'Fee of $fee is too small for spend bundle to be included';
  }
}
