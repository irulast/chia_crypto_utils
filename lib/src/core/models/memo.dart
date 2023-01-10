import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

abstract class Memo extends Bytes {
  factory Memo(List<int> bytesList) {
    return LazyMemo(bytesList);
  }
  factory Memo.precomputed(List<int> bytesList, String? memoString) {
    return PrecomputedMemo(bytesList, memoString);
  }
  factory Memo.computed(List<int> bytesList) {
    return PrecomputedMemo(bytesList, decodeStringFromBytes(Bytes(bytesList)));
  }
  String? get decodedString;
}

class LazyMemo extends Bytes implements Memo {
  LazyMemo(
    super.bytesList,
  );

  @override
  String? get decodedString => decodeStringFromBytes(this);
}

class PrecomputedMemo extends Bytes implements Memo {
  PrecomputedMemo(
    super.bytesList,
    this.decodedString,
  );

  @override
  String? decodedString;
}

String? decodeStringFromBytes(Bytes bytes) {
  try {
    final decodedString = utf8.decode(bytes);
    return decodedString;
  } on Exception {
    return null;
  }
}

extension ToPrecomputedMemo on Memo {
  PrecomputedMemo toPrecomputedMemo() {
    return PrecomputedMemo(byteList, decodedString);
  }
}
