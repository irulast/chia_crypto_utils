import 'dart:typed_data';

import 'package:crypto/crypto.dart';

final hmacBlockSize = 64;

Uint8List hash256(List<int> m) {
  return Uint8List.fromList(sha256.convert(m).bytes);
}

Uint8List hash512(List<int> m) {
  return Uint8List.fromList(hash256(m + [0]) + hash256(m + [1]));
}

Uint8List hmac256(List<int> m, List<int> k) {
  if (k.length > hmacBlockSize) {
    k = hash256(k);
  }
  while (k.length < hmacBlockSize) {
    k = k + [0];
  }
  var opad = List.filled(0x5C, hmacBlockSize);
  var ipad = List.filled(0x36, hmacBlockSize);
  List<int> kopad = [];
  for (var i = 0; i < hmacBlockSize; i++) {
    kopad.add(k[i] ^ opad[i]);
  }
  List<int> kipad = [];
  for (var i = 0; i < hmacBlockSize; i++) {
    kipad.add(k[i] ^ ipad[i]);
  }
  return hash256(kopad + hash256(kipad + m));
}
