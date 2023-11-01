extension UnixTimestampX on DateTime {
  int get unixTimestamp => millisecondsSinceEpoch ~/ 1000;
}
