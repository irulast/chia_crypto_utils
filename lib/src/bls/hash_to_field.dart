// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:chia_utils/src/bls/bls12381.dart';
import 'package:crypto/crypto.dart';
import 'package:quiver/collection.dart';
import 'package:quiver/iterables.dart';

import '../clvm/bytes.dart';

Uint8List I2OSP(BigInt val, int length) {
  if (val < BigInt.zero || val >= BigInt.one << 8 * length) {
    throw ArgumentError('Bad I2OSP call: val=$val, length=$length.');
  }
  var bytes = List.filled(length, 0);
  var tempVal = val;
  for (var i = length - 1; i >= 0; i--) {
    bytes[i] = (tempVal & BigInt.from(0xFF)).toInt();
    tempVal >>= 8;
  }
  var result = Uint8List.fromList(bytes);
  var toBytesVal = bigIntToBytes(val, length, Endian.big);
  assert(listsEqual(result, toBytesVal),
      'Expected $toBytesVal, but found $result');
  return result;
}

BigInt OS2IP(List<int> octets) {
  var result = BigInt.zero;
  for (var octet in octets) {
    result <<= 8;
    result += BigInt.from(octet);
  }
  assert(result == bytesToBigInt(octets, Endian.big));
  return result;
}

Uint8List bytesXor(List<int> a, List<int> b) {
  return Uint8List.fromList(
      zip([a, b]).map((element) => element[0] ^ element[1]).toList());
}

Uint8List expandMessageXmd(
    List<int> msg, List<int> DST, int lenInBytes, Hash hash) {
  var bInBytes = hash.convert([]).bytes.length;
  var rInBytes = hash.blockSize;
  var ell = (lenInBytes + bInBytes - 1) ~/ bInBytes;
  if (ell > 255) {
    throw ArgumentError('Bap expandMessageXmd call: ell=$ell out of range.');
  }
  var DST_prime = DST + I2OSP(BigInt.from(DST.length), 1);
  var Z_pad = I2OSP(BigInt.zero, rInBytes);
  var l_i_b_str = I2OSP(BigInt.from(lenInBytes), 2);
  var b_0 = hash
      .convert(Z_pad + msg + l_i_b_str + I2OSP(BigInt.zero, 1) + DST_prime)
      .bytes;
  List<List<int>> bVals = [];
  bVals.add(hash.convert(b_0 + I2OSP(BigInt.one, 1) + DST_prime).bytes);
  for (var i = 1; i < ell; i++) {
    bVals.add(hash
        .convert(bytesXor(b_0, bVals[i - 1]) +
            I2OSP(BigInt.from(i + 1), 1) +
            DST_prime)
        .bytes);
  }
  List<int> pseudoRandomBytes = [];
  for (var item in bVals) {
    pseudoRandomBytes.addAll(item);
  }
  return Uint8List.fromList(pseudoRandomBytes.sublist(0, lenInBytes));
}

Uint8List expandMessageXof(
    List<int> msg, List<int> DST, int lenInBytes, Hash hash) {
  var DST_prime = DST + I2OSP(BigInt.from(DST.length), 1);
  var msg_prime = msg + I2OSP(BigInt.from(lenInBytes), 2) + DST_prime;
  return Uint8List.fromList(
      hash.convert(msg_prime).bytes.sublist(0, lenInBytes));
}

List<List<BigInt>> hashToField(
    List<int> msg,
    int count,
    List<int> DST,
    BigInt modulus,
    int degree,
    int blen,
    Uint8List Function(List<int>, List<int>, int, Hash) expand,
    Hash hash) {
  var lenInBytes = count * degree * blen;
  List<int> pseudoRandomBytes = expand(msg, DST, lenInBytes, hash);
  List<List<BigInt>> uVals = [];
  for (var i = 0; i < count; i++) {
    List<BigInt> eVals = [];
    for (var j = 0; j < degree; j++) {
      var elmOffset = blen * (j + i * degree);
      var tv = pseudoRandomBytes.sublist(elmOffset, elmOffset + blen);
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
