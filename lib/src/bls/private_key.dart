import 'dart:convert';
import 'dart:typed_data';

import 'package:chia_utils/src/bls/ec.dart';
import 'package:chia_utils/src/bls/hkdf.dart';
import 'package:chia_utils/src/clvm/bytes.dart';
import 'package:hex/hex.dart';

class PrivateKey {
  static final int size = 32;

  BigInt value;

  PrivateKey(this.value) : assert(value < defaultEc.n);

  factory PrivateKey.fromBytes(List<int> bytes) =>
      PrivateKey(bytesToBigInt(bytes, Endian.big) % defaultEc.n);
  factory PrivateKey.fromSeed(List<int> seed) {
    var L = 48;
    var okm = extractExpand(
        L, seed + [0], utf8.encode('BLS-SIG-KEYGEN-SALT-'), [0, L]);
    return PrivateKey(bytesToBigInt(okm, Endian.big) % defaultEc.n);
  }
  factory PrivateKey.fromBigInt(BigInt n) => PrivateKey(n % defaultEc.n);
  factory PrivateKey.aggregate(List<PrivateKey> privateKeys) =>
      PrivateKey(privateKeys.fold(BigInt.zero,
              (BigInt aggregate, privateKey) => aggregate + privateKey.value) %
          defaultEc.n);

  JacobianPoint getG1() => G1Generator() * value;

  Uint8List toBytes() => bigIntToBytes(value, size, Endian.big);

  @override
  String toString() => 'PrivateKey(0x${HexEncoder().convert(toBytes())})';

  @override
  bool operator ==(other) => other is PrivateKey && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
