class NamesdaoApiException implements Exception {
  const NamesdaoApiException(this.message);
  final String message;

  @override
  String toString() => 'NamesdaoApiException(message: $message)';
}
