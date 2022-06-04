// ignore_for_file: avoid_positional_boolean_parameters, lines_longer_than_80_chars
// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/bls/ec/ec.dart';
import 'package:chia_crypto_utils/src/bls/ec/helpers.dart';
import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';
import 'package:meta/meta.dart';
import 'package:quiver/core.dart';

@immutable
class JacobianPoint with ToBytesMixin {
  static const g1BytesLength = 48;
  static const g2BytesLength = 96;
  JacobianPoint(this.x, this.y, this.z, this.infinity, {EC? ec})
      : ec = ec ?? defaultEc,
        isExtension = x is! Fq {
    if (x.runtimeType != y.runtimeType) {
      throw ArgumentError(
        'Both x, y, and z should be similar field instances.',
      );
    }
  }

  factory JacobianPoint.fromBytes(List<int> bytes, bool isExtension, {EC? ec}) {
    ec ??= defaultEc;
    if (isExtension) {
      if (bytes.length != g2BytesLength) {
        throw ArgumentError('Expected 96 bytes.');
      }
    } else {
      if (bytes.length != g1BytesLength) {
        throw ArgumentError('Expected 48 bytes.');
      }
    }
    final mByte = bytes[0] & 0xE0;
    if ([0x20, 0x60, 0xE0].contains(mByte)) {
      throw ArgumentError('Invalid first three bits.');
    }
    final bitC = mByte & 0x80;
    final bitI = mByte & 0x40;
    final bitS = mByte & 0x20;
    if (bitC == 0) {
      throw ArgumentError('First bit must be 1.');
    }
    bytes = [bytes[0] & 0x1F] + bytes.sublist(1);
    if (bitI != 0) {
      for (final byte in bytes) {
        if (byte != 0) {
          throw ArgumentError(
            'Point at infinity set, but data not all zeroes.',
          );
        }
      }
      return AffinePoint(
        isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
        isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
        true,
        ec: ec,
      ).toJacobian();
    }
    final x = isExtension ? Fq2.fromBytes(bytes, ec.q) : Fq.fromBytes(bytes, ec.q);
    final yValue = yForX(x, ec: ec);
    bool sign;
    if (isExtension) {
      sign = signFq2(yValue as Fq2, ec: ec);
    } else {
      sign = signFq(yValue as Fq, ec: ec);
    }
    final y = sign == (bitS != 0) ? yValue : -yValue;
    return AffinePoint(x, y, false, ec: ec).toJacobian();
  }

  factory JacobianPoint.fromStreamG1(Iterator<int> iterator) {
    final publicKeyBytes = iterator.extractBytesAndAdvance(g1BytesLength);
    return JacobianPoint.fromBytesG1(publicKeyBytes);
  }

  factory JacobianPoint.fromStreamG2(Iterator<int> iterator) {
    final signatureBytes = iterator.extractBytesAndAdvance(g2BytesLength);
    return JacobianPoint.fromBytesG2(signatureBytes);
  }

  factory JacobianPoint.fromHex(String hex, bool isExtension, {EC? ec}) => JacobianPoint.fromBytes(
        const HexDecoder().convert(hex),
        isExtension,
        ec: ec,
      );

  factory JacobianPoint.generateG1() =>
      AffinePoint(defaultEc.gx, defaultEc.gy, false, ec: defaultEc).toJacobian();

  factory JacobianPoint.generateG2() => AffinePoint(
        defaultEcTwist.g2x,
        defaultEcTwist.g2y,
        false,
        ec: defaultEcTwist,
      ).toJacobian();

  factory JacobianPoint.infinityG1({bool? isExtension}) {
    isExtension ??= false;
    return JacobianPoint(
      isExtension ? Fq2.zero(defaultEc.q) : Fq.zero(defaultEc.q),
      isExtension ? Fq2.zero(defaultEc.q) : Fq.zero(defaultEc.q),
      isExtension ? Fq2.zero(defaultEc.q) : Fq.zero(defaultEc.q),
      true,
      ec: defaultEc,
    );
  }

  factory JacobianPoint.infinityG2({bool? isExtension}) {
    isExtension ??= true;
    return JacobianPoint(
      isExtension ? Fq2.zero(defaultEcTwist.q) : Fq.zero(defaultEcTwist.q),
      isExtension ? Fq2.zero(defaultEcTwist.q) : Fq.zero(defaultEcTwist.q),
      isExtension ? Fq2.zero(defaultEcTwist.q) : Fq.zero(defaultEcTwist.q),
      true,
      ec: defaultEcTwist,
    );
  }

  factory JacobianPoint.fromBytesG1(List<int> bytes, {bool? isExtension}) {
    isExtension ??= false;
    return JacobianPoint.fromBytes(bytes, isExtension, ec: defaultEc);
  }

  factory JacobianPoint.fromHexG1(String hex, {bool? isExtension}) {
    return JacobianPoint.fromBytesG1(
      const HexDecoder().convert(hex.stripBytesPrefix()),
      isExtension: isExtension,
    );
  }

  factory JacobianPoint.fromHexG2(String hex, {bool? isExtension}) {
    return JacobianPoint.fromBytesG2(
      const HexDecoder().convert(hex.stripBytesPrefix()),
      isExtension: isExtension,
    );
  }

  factory JacobianPoint.fromBytesG2(List<int> bytes, {bool? isExtension}) {
    isExtension ??= true;
    return JacobianPoint.fromBytes(bytes, isExtension, ec: defaultEcTwist);
  }

  final Field x;
  final Field y;
  final Field z;
  final bool infinity;
  final EC ec;
  final bool isExtension;

  bool get isG1 => toBytes().length == g1BytesLength;
  bool get isG2 => toBytes().length == g2BytesLength;

  bool get isOnCurve => infinity || toAffine().isOnCurve;
  bool get isValid => isOnCurve && this * ec.n == JacobianPoint.infinityG2();

  @override
  Bytes toBytes() {
    final point = toAffine();
    final output = point.x.toBytes();
    if (point.infinity) {
      return Bytes([0xc0] + List.filled(output.length - 1, 0));
    }
    bool sign;
    if (isExtension) {
      sign = signFq2(point.y as Fq2, ec: ec);
    } else {
      sign = signFq(point.y as Fq, ec: ec);
    }
    if (sign) {
      output[0] |= 0xA0;
    } else {
      output[0] |= 0x80;
    }
    return output;
  }

  AffinePoint toAffine() => infinity
      ? AffinePoint(Fq.zero(ec.q), Fq.zero(ec.q), infinity, ec: ec)
      : AffinePoint(
          x / z.pow(BigInt.two),
          y / z.pow(BigInt.from(3)),
          infinity,
          ec: ec,
        );

  JacobianPoint double() {
    if (y == (isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q)) || infinity) {
      return JacobianPoint(
        isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
        isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
        isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
        true,
        ec: ec,
      );
    }
    final S = x * y * y * Fq(ec.q, BigInt.from(4));
    final Z_sq = z * z;
    final Z_4th = Z_sq * Z_sq;
    final Y_sq = y * y;
    final Y_4th = Y_sq * Y_sq;
    final M = x * x * Fq(ec.q, BigInt.from(3)) + ec.a * Z_4th;
    final X_p = M * M - S * Fq(ec.q, BigInt.two);
    final Y_p = M * (S - X_p) - Y_4th * Fq(ec.q, BigInt.from(8));
    final Z_p = y * z * Fq(ec.q, BigInt.two);
    return JacobianPoint(X_p, Y_p, Z_p, false, ec: ec);
  }

  int getFingerprint() => bytesToInt(sha256.convert(toBytes()).bytes.sublist(0, 4), Endian.big);

  JacobianPoint operator -() => (-toAffine()).toJacobian();

  JacobianPoint operator +(JacobianPoint other) {
    if (infinity) {
      return other;
    } else if (other.infinity) {
      return this;
    }
    final U1 = x * other.z.pow(BigInt.two);
    final U2 = other.x * z.pow(BigInt.two);
    final S1 = y * other.z.pow(BigInt.from(3));
    final S2 = other.y * z.pow(BigInt.from(3));
    if (U1 == U2) {
      if (S1 != S2) {
        return JacobianPoint(
          isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
          isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
          isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
          true,
          ec: ec,
        );
      } else {
        return double();
      }
    }
    final H = U2 - U1;
    final R = S2 - S1;
    final H_sq = H * H;
    final H_cu = H * H_sq;
    final X3 = R * R - H_cu - U1 * H_sq * Fq(ec.q, BigInt.two);
    final Y3 = R * (U1 * H_sq - X3) - S1 * H_cu;
    final Z3 = H * z * other.z;
    return JacobianPoint(X3, Y3, Z3, false, ec: ec);
  }

  JacobianPoint operator *(Object other) {
    final c = other.extractBigInt();
    if (c == null) {
      throw ArgumentError('Must multiply JacobianPoint with BigInt or Fq.');
    }
    return scalarMultJacobian(c, this, ec: ec);
  }

  @override
  bool operator ==(Object other) => other is JacobianPoint && toAffine() == other.toAffine();

  @override
  int get hashCode => hash4(x, y, z, infinity);

  @override
  String toString() => 'JacobianPoint(0x${toHex()})';

  JacobianPoint clone() => JacobianPoint(x.clone(), y.clone(), z.clone(), infinity, ec: ec);
}
