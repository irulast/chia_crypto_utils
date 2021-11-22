import 'dart:typed_data';

import 'package:crypto/crypto.dart';

final blockSize = 32;

Uint8List extract(List<int> salt, List<int> ikm) {
  var hmacSha256 = Hmac(sha256, salt);
  var digest = hmacSha256.convert(ikm);
  return Uint8List.fromList(digest.bytes);
}

Uint8List expand(int L, List<int> prk, List<int> info) {
  var N = (L / blockSize).ceil();
  var bytesWritten = 0;
  List<int> okm = [];
  List<int> T = [];
  for (var i = 1; i < N + 1; i++) {
    var h = Hmac(sha256, prk);
    if (i == 1) {
      T = h.convert(info + [1]).bytes;
    } else {
      T = h.convert(T + info + [i]).bytes;
    }
    var toWrite = L - bytesWritten;
    if (toWrite > blockSize) {
      toWrite = blockSize;
    }
    okm += T.sublist(0, toWrite);
    bytesWritten += toWrite;
  }
  assert(bytesWritten == L);
  return Uint8List.fromList(okm);
}

Uint8List extractExpand(int L, List<int> key, List<int> salt, List<int> info) {
  return expand(L, extract(salt, key), info);
}
