import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:crypto/crypto.dart';

const hmacBlockSize = 64;

Bytes hash256(List<int> m) {
  return Bytes(sha256.convert(m).bytes);
}

Bytes hash512(List<int> m) {
  return Bytes(hash256(m + [0]) + hash256(m + [1]));
}

Bytes hmac256(List<int> m, List<int> k) {
  if (k.length > hmacBlockSize) {
    k = hash256(k);
  }
  while (k.length < hmacBlockSize) {
    k = k + [0];
  }
  final opad = List.filled(0x5C, hmacBlockSize);
  final ipad = List.filled(0x36, hmacBlockSize);
  final kopad = <int>[];
  for (var i = 0; i < hmacBlockSize; i++) {
    kopad.add(k[i] ^ opad[i]);
  }
  final kipad = <int>[];
  for (var i = 0; i < hmacBlockSize; i++) {
    kipad.add(k[i] ^ ipad[i]);
  }
  return hash256(kopad + hash256(kipad + m));
}
