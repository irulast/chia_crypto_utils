// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/bls/bls12381.dart';
import 'package:crypto/crypto.dart';
import 'package:quiver/collection.dart';
import 'package:quiver/iterables.dart';

List<int> I2OSP(BigInt val, int length) {
  if (val < BigInt.zero || val >= BigInt.one << 8 * length) {
    throw ArgumentError('Bad I2OSP call: val=$val, length=$length.');
  }
  final bytes = List.filled(length, 0);
  var tempVal = val;
  for (var i = length - 1; i >= 0; i--) {
    bytes[i] = (tempVal & BigInt.from(0xFF)).toInt();
    tempVal >>= 8;
  }
  final result = bytes;
  final toBytesVal = bigIntToBytes(val, length, Endian.big);
  assert(listsEqual(result, toBytesVal), 'Expected $toBytesVal, but found $result');
  return result;
}

BigInt OS2IP(List<int> octets) {
  var result = BigInt.zero;
  for (final octet in octets) {
    result <<= 8;
    result += BigInt.from(octet);
  }
  assert(result == bytesToBigInt(octets, Endian.big));
  return result;
}

Bytes bytesXor(List<int> a, List<int> b) {
  return Bytes(zip([a, b]).map((element) => element[0] ^ element[1]).toList());
}

Bytes expandMessageXmd(List<int> msg, List<int> DST, int lenInBytes, Hash hash) {
  final bInBytes = hash.convert([]).bytes.length;
  final rInBytes = hash.blockSize;
  final ell = (lenInBytes + bInBytes - 1) ~/ bInBytes;
  if (ell > 255) {
    throw ArgumentError('Bap expandMessageXmd call: ell=$ell out of range.');
  }
  final DST_prime = DST + I2OSP(BigInt.from(DST.length), 1);
  final Z_pad = I2OSP(BigInt.zero, rInBytes);
  final l_i_b_str = I2OSP(BigInt.from(lenInBytes), 2);
  final b_0 = hash.convert(Z_pad + msg + l_i_b_str + I2OSP(BigInt.zero, 1) + DST_prime).bytes;
  final bVals = <List<int>>[];
  bVals.add(hash.convert(b_0 + I2OSP(BigInt.one, 1) + DST_prime).bytes);
  for (var i = 1; i < ell; i++) {
    bVals.add(
      hash.convert(bytesXor(b_0, bVals[i - 1]) + I2OSP(BigInt.from(i + 1), 1) + DST_prime).bytes,
    );
  }
  final pseudoRandomBytes = <int>[];
  for (final item in bVals) {
    pseudoRandomBytes.addAll(item);
  }
  return Bytes(pseudoRandomBytes.sublist(0, lenInBytes));
}

Bytes expandMessageXof(List<int> msg, List<int> DST, int lenInBytes, Hash hash) {
  final DST_prime = DST + I2OSP(BigInt.from(DST.length), 1);
  final msg_prime = msg + I2OSP(BigInt.from(lenInBytes), 2) + DST_prime;
  return Bytes(hash.convert(msg_prime).bytes.sublist(0, lenInBytes));
}

List<List<BigInt>> hashToField(
  List<int> msg,
  int count,
  List<int> DST,
  BigInt modulus,
  int degree,
  int blen,
  Bytes Function(List<int>, List<int>, int, Hash) expand,
  Hash hash,
) {
  final lenInBytes = count * degree * blen;
  final List<int> pseudoRandomBytes = expand(msg, DST, lenInBytes, hash);
  final uVals = <List<BigInt>>[];
  for (var i = 0; i < count; i++) {
    final eVals = <BigInt>[];
    for (var j = 0; j < degree; j++) {
      final elmOffset = blen * (j + i * degree);
      final tv = pseudoRandomBytes.sublist(elmOffset, elmOffset + blen);
      eVals.add(OS2IP(tv) % modulus);
    }
    uVals.add(eVals);
  }
  return uVals;
}

List<List<BigInt>> Hp(List<int> msg, int count, List<int> DST) {
  return hashToField(msg, count, DST, q, 1, 64, expandMessageXmd, sha256);
}

List<List<BigInt>> Hp2(List<int> msg, int count, List<int> DST) {
  return hashToField(msg, count, DST, q, 2, 64, expandMessageXmd, sha256);
}
