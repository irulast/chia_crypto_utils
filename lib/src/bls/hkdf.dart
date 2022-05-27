import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:crypto/crypto.dart';

const blockSize = 32;

Bytes extract(List<int> salt, List<int> ikm) {
  final hmacSha256 = Hmac(sha256, salt);
  final digest = hmacSha256.convert(ikm);
  return Bytes(digest.bytes);
}

Bytes expand(int L, List<int> prk, List<int> info) {
  final N = (L / blockSize).ceil();
  var bytesWritten = 0;
  var okm = <int>[];
  var T = <int>[];
  for (var i = 1; i < N + 1; i++) {
    final h = Hmac(sha256, prk);
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
  return Bytes(okm);
}

Bytes extractExpand(int L, List<int> key, List<int> salt, List<int> info) {
  return expand(L, extract(salt, key), info);
}
