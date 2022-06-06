import 'dart:convert';
import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/bls/hkdf.dart';
import 'package:hex/hex.dart';
import 'package:meta/meta.dart';

@immutable
class PrivateKey with ToBytesMixin {
  PrivateKey(this.value)
      : assert(
          value < defaultEc.n,
          'Private key must be less than ${defaultEc.n}',
        );

  factory PrivateKey.fromBytes(List<int> bytes) =>
      PrivateKey(bytesToBigInt(bytes, Endian.big) % defaultEc.n);

  factory PrivateKey.fromHex(String hex) => PrivateKey.fromBytes(const HexDecoder().convert(hex));

  factory PrivateKey.fromSeed(List<int> seed) {
    const L = 48;
    final okm = extractExpand(
      L,
      seed + [0],
      utf8.encode('BLS-SIG-KEYGEN-SALT-'),
      [0, L],
    );
    return PrivateKey(bytesToBigInt(okm, Endian.big) % defaultEc.n);
  }

  PrivateKey.fromBigInt(BigInt n) : this(n % defaultEc.n);

  factory PrivateKey.fromStream(Iterator<int> iterator) {
    final bytes = iterator.extractBytesAndAdvance(size);
    return PrivateKey.fromBytes(bytes);
  }

  PrivateKey.aggregate(List<PrivateKey> privateKeys)
      : this(
          privateKeys.fold<BigInt>(
                BigInt.zero,
                (aggregate, privateKey) => aggregate + privateKey.value,
              ) %
              defaultEc.n,
        );

  final BigInt value;

  static const int size = 32;

  JacobianPoint getG1() => JacobianPoint.generateG1() * value;

  @override
  Bytes toBytes() => bigIntToBytes(value, size, Endian.big);

  @override
  String toString() => 'PrivateKey(0x${toHex()})';

  @override
  bool operator ==(dynamic other) => other is PrivateKey && value == other.value;

  @override
  int get hashCode => runtimeType.hashCode ^ value.hashCode;
}
