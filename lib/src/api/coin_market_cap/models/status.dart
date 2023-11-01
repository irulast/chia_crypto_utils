class Status {
  Status.fromJson(Map<String, dynamic> json)
      : timestamp = json['timestamp'] as String,
        errorCode = json['error_code'] as int,
        errorMessage = json['error_message'] as String?,
        elapsed = json['elapsed'] as int,
        creditCount = json['credit_count'] as int;
  final String timestamp;
  final int errorCode;
  final String? errorMessage;
  final int elapsed;
  final int creditCount;

  @override
  String toString() => 'Status(timestamp: $timestamp, errorCode: $errorCode, '
      'errorMessage: $errorMessage, elapsed: $elapsed, creditCount: $creditCount)';
}
