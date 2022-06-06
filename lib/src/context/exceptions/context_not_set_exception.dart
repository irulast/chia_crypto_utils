class ContextNotSetException implements Exception {
  ContextNotSetException(this.unsetContextMemberName);
  final String unsetContextMemberName;

  @override
  String toString() {
    return 'Attempting to use non nullable piece of context that has not been set: $unsetContextMemberName';
  }
}
