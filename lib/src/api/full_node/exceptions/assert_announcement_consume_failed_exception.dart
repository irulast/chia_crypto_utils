class AssertAnnouncementConsumeFailedException implements Exception {
  AssertAnnouncementConsumeFailedException();

  @override
  String toString() {
    return 'Asserted announcement that was not consumed';
  }
}
