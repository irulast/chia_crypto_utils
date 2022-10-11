import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

abstract class Memo extends Bytes {
  factory Memo(List<int> bytesList) {
    return LazyMemo(bytesList);
  }
  factory Memo.precomputed(List<int> bytesList, String memoString) {
    return PrecomputedMemo(bytesList, memoString);
  }
  factory Memo.computed(List<int> bytesList) {
    return PrecomputedMemo(bytesList, decodeStringFromBytes(Bytes(bytesList)));
  }
  String? get decodedString;
}

class LazyMemo extends Bytes implements Memo {
  LazyMemo(
    List<int> bytesList,
  ) : super(bytesList);

  @override
  String? get decodedString => decodeStringFromBytes(this);
}

class PrecomputedMemo extends Bytes implements Memo {
  PrecomputedMemo(
    List<int> bytesList,
    this.decodedString,
  ) : super(bytesList);

  @override
  String? decodedString;
}

String? decodeStringFromBytes(Bytes bytes) {
  String? _decodedString;
  try {
    _decodedString = utf8.decode(bytes);
  } on Exception {
    try {
      _decodedString = bytes.toHex();
    } on Exception {
      //pass
    }
  }
  return _decodedString;
}

extension ToPrecomputedMemo on Memo {
  PrecomputedMemo toPrecomputedMemo() {
    return PrecomputedMemo(byteList, decodedString);
  }
}
