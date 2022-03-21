class IncorrectAnnouncementIdException implements Exception {
  static const message = 'Constructed announcement id does not match output';

  @override
  String toString() {
    return message;
  }
}
