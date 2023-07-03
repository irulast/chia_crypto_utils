extension UnixTimeStamp on DateTime {
  int get unixTimeStamp => millisecondsSinceEpoch ~/ 1000;
}
