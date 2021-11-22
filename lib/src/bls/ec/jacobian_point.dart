// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:chia_utils/src/bls/ec/affine_point.dart';
import 'package:chia_utils/src/bls/ec/ec.dart';
import 'package:chia_utils/src/bls/field.dart';
import 'package:chia_utils/src/bls/field_base.dart';
import 'package:chia_utils/src/bls/field_ext.dart';
import 'package:chia_utils/src/clvm/bytes.dart';
import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';
import 'package:quiver/core.dart';

class JacobianPoint {
  Field x;
  Field y;
  Field z;
  bool infinity;
  EC ec;
  bool isExtension;

  bool get isOnCurve => infinity ? true : toAffine().isOnCurve;
  bool get isValid => isOnCurve && this * ec.n == JacobianPoint.infinityG2();

  JacobianPoint(this.x, this.y, this.z, this.infinity, {EC? ec})
      : ec = ec ?? defaultEc,
        isExtension = x is! Fq {
    if (x.runtimeType != y.runtimeType) {
      throw ArgumentError(
          'Both x, y, and z should be similar field instances.');
    }
  }

  factory JacobianPoint.fromBytes(List<int> bytes, bool isExtension, {EC? ec}) {
    ec ??= defaultEc;
    if (isExtension) {
      if (bytes.length != 96) {
        throw ArgumentError('Expected 96 bytes.');
      }
    } else {
      if (bytes.length != 48) {
        throw ArgumentError('Expected 48 bytes.');
      }
    }
    var mByte = bytes[0] & 0xE0;
    if ([0x20, 0x60, 0xE0].contains(mByte)) {
      throw ArgumentError('Invalid first three bits.');
    }
    var bitC = mByte & 0x80;
    var bitI = mByte & 0x40;
    var bitS = mByte & 0x20;
    if (bitC == 0) {
      throw ArgumentError('First bit must be 1.');
    }
    bytes = [bytes[0] & 0x1F] + bytes.sublist(1);
    if (bitI != 0) {
      for (var byte in bytes) {
        if (byte != 0) {
          throw ArgumentError(
              'Point at infinity set, but data not all zeroes.');
        }
      }
      return AffinePoint(isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
              isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q), true,
              ec: ec)
          .toJacobian();
    }
    var x =
        isExtension ? Fq2.fromBytes(bytes, ec.q) : Fq.fromBytes(bytes, ec.q);
    var yValue = yForX(x, ec: ec);
    bool sign;
    if (isExtension) {
      sign = signFq2(yValue as Fq2, ec: ec);
    } else {
      sign = signFq(yValue as Fq, ec: ec);
    }
    Field y;
    if (sign == (bitS != 0)) {
      y = yValue;
    } else {
      y = -yValue;
    }
    return AffinePoint(x, y, false, ec: ec).toJacobian();
  }

  factory JacobianPoint.fromHex(String hex, bool isExtension, {EC? ec}) =>
      JacobianPoint.fromBytes(HexDecoder().convert(hex), isExtension, ec: ec);

  factory JacobianPoint.generateG1() =>
      AffinePoint(defaultEc.gx, defaultEc.gy, false, ec: defaultEc)
          .toJacobian();

  factory JacobianPoint.generateG2() =>
      AffinePoint(defaultEcTwist.g2x, defaultEcTwist.g2y, false,
              ec: defaultEcTwist)
          .toJacobian();

  factory JacobianPoint.infinityG1({bool? isExtension}) {
    isExtension ??= false;
    return JacobianPoint(
        isExtension ? Fq2.zero(defaultEc.q) : Fq.zero(defaultEc.q),
        isExtension ? Fq2.zero(defaultEc.q) : Fq.zero(defaultEc.q),
        isExtension ? Fq2.zero(defaultEc.q) : Fq.zero(defaultEc.q),
        true,
        ec: defaultEc);
  }

  factory JacobianPoint.infinityG2({bool? isExtension}) {
    isExtension ??= true;
    return JacobianPoint(
        isExtension ? Fq2.zero(defaultEcTwist.q) : Fq.zero(defaultEcTwist.q),
        isExtension ? Fq2.zero(defaultEcTwist.q) : Fq.zero(defaultEcTwist.q),
        isExtension ? Fq2.zero(defaultEcTwist.q) : Fq.zero(defaultEcTwist.q),
        true,
        ec: defaultEcTwist);
  }

  factory JacobianPoint.fromBytesG1(List<int> bytes, {bool? isExtension}) {
    isExtension ??= false;
    return JacobianPoint.fromBytes(bytes, isExtension, ec: defaultEc);
  }

  factory JacobianPoint.fromBytesG2(List<int> bytes, {bool? isExtension}) {
    isExtension ??= true;
    return JacobianPoint.fromBytes(bytes, isExtension, ec: defaultEcTwist);
  }

  Uint8List toBytes() {
    var point = toAffine();
    var output = point.x.toBytes();
    if (point.infinity) {
      return Uint8List.fromList([0xc0] + List.filled(output.length - 1, 0));
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

  String toHex() => HexEncoder().convert(toBytes());

  AffinePoint toAffine() => infinity
      ? AffinePoint(Fq.zero(ec.q), Fq.zero(ec.q), infinity, ec: ec)
      : AffinePoint(x / z.pow(BigInt.two), y / z.pow(BigInt.from(3)), infinity,
          ec: ec);

  JacobianPoint double() {
    if (y == (isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q)) || infinity) {
      return JacobianPoint(
          isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
          isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
          isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
          true,
          ec: ec);
    }
    var S = x * y * y * Fq(ec.q, BigInt.from(4));
    var Z_sq = z * z;
    var Z_4th = Z_sq * Z_sq;
    var Y_sq = y * y;
    var Y_4th = Y_sq * Y_sq;
    var M = x * x * Fq(ec.q, BigInt.from(3)) + ec.a * Z_4th;
    var X_p = M * M - S * Fq(ec.q, BigInt.two);
    var Y_p = M * (S - X_p) - Y_4th * Fq(ec.q, BigInt.from(8));
    var Z_p = y * z * Fq(ec.q, BigInt.two);
    return JacobianPoint(X_p, Y_p, Z_p, false, ec: ec);
  }

  int getFingerprint() =>
      bytesToInt(sha256.convert(toBytes()).bytes.sublist(0, 4), Endian.big);

  JacobianPoint operator -() => (-toAffine()).toJacobian();

  JacobianPoint operator +(JacobianPoint other) {
    if (infinity) {
      return other;
    } else if (other.infinity) {
      return this;
    }
    var U1 = x * other.z.pow(BigInt.two);
    var U2 = other.x * z.pow(BigInt.two);
    var S1 = y * other.z.pow(BigInt.from(3));
    var S2 = other.y * z.pow(BigInt.from(3));
    if (U1 == U2) {
      if (S1 != S2) {
        return JacobianPoint(
            isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
            isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
            isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
            true,
            ec: ec);
      } else {
        return double();
      }
    }
    var H = U2 - U1;
    var R = S2 - S1;
    var H_sq = H * H;
    var H_cu = H * H_sq;
    var X3 = R * R - H_cu - U1 * H_sq * Fq(ec.q, BigInt.two);
    var Y3 = R * (U1 * H_sq - X3) - S1 * H_cu;
    var Z3 = H * z * other.z;
    return JacobianPoint(X3, Y3, Z3, false, ec: ec);
  }

  JacobianPoint operator *(other) {
    if (other is! BigInt && other is! Fq) {
      throw ArgumentError('Must multiply JacobianPoint with BigInt or Fq.');
    }
    return scalarMultJacobian(other, this, ec: ec);
  }

  @override
  bool operator ==(Object other) =>
      other is JacobianPoint ? toAffine() == other.toAffine() : false;

  @override
  int get hashCode => hash4(x, y, z, infinity);

  @override
  String toString() => 'JacobianPoint(x=$x, y=$y, z=$z, i=$infinity)';

  JacobianPoint clone() =>
      JacobianPoint(x.clone(), y.clone(), z.clone(), infinity, ec: ec);
}
