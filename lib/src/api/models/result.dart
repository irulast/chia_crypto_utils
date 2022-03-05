class Result<T> {
  T? payload;
  String? error;

  bool get success {
    return error == null;
  }
}