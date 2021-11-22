// ignore_for_file: non_constant_identifier_names
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:chia_utils/src/bls/bls12381.dart';
import 'package:chia_utils/src/bls/field.dart';
import 'package:chia_utils/src/bls/field_base.dart';
import 'package:chia_utils/src/bls/field_ext.dart';
import 'package:chia_utils/src/clvm/bytes.dart';
import 'package:crypto/crypto.dart';
import 'package:quiver/core.dart';
import 'package:quiver/iterables.dart';

class EC {
  final BigInt q;
  final Field a;
  final Field b;
  final Fq gx;
  final Fq gy;
  final Fq2 g2x;
  final Fq2 g2y;
  final BigInt n;
  final BigInt h;
  final BigInt x;
  final BigInt k;
  final BigInt sqrtN3;
  final BigInt sqrtN3m1o2;
  EC(this.q, this.a, this.b, this.gx, this.gy, this.g2x, this.g2y, this.n,
      this.h, this.x, this.k, this.sqrtN3, this.sqrtN3m1o2);
}

final defaultEc = EC(q, a, b, gx, gy, g2x, g2y, n, h, x, k, sqrtN3, sqrtN3m1o2);
final defaultEcTwist =
    EC(q, aTwist, bTwist, gx, gy, g2x, g2y, n, hEff, x, k, sqrtN3, sqrtN3m1o2);

class AffinePoint {
  Field x;
  Field y;
  bool infinity;
  EC ec;
  bool isExtension;

  AffinePoint(this.x, this.y, this.infinity, {EC? ec})
      : ec = ec ?? defaultEc,
        isExtension = x is! Fq {
    if (x.runtimeType != y.runtimeType) {
      throw ArgumentError('Both x and y should be similar field instances.');
    }
  }

  bool get isOnCurve => infinity ? true : y * y == x * x * x + ec.a * x + ec.b;

  AffinePoint operator +(AffinePoint other) {
    return addPoints(this, other, ec: ec);
  }

  AffinePoint operator *(other) {
    if (other is! Fq && other is! BigInt) {
      throw ArgumentError('Must multiply AffinePoint with BigInt or Fq.');
    }
    return scalarMultJacobian(other, toJacobian(), ec: ec).toAffine();
  }

  AffinePoint operator -(AffinePoint other) => this + -other;
  AffinePoint operator -() => AffinePoint(x, -y, infinity, ec: ec);

  JacobianPoint toJacobian() =>
      JacobianPoint(x, y, x is Fq ? Fq.one(ec.q) : Fq2.one(ec.q), infinity,
          ec: ec);

  AffinePoint deepcopy() =>
      AffinePoint(x.deepcopy(), y.deepcopy(), infinity, ec: ec);

  @override
  String toString() => 'AffinePoint(x=$x, y=$y, i=$infinity)';

  @override
  bool operator ==(Object other) => other is AffinePoint
      ? x == other.x && y == other.y && infinity == other.infinity
      : false;

  @override
  int get hashCode => hash3(x, y, infinity);
}

class JacobianPoint {
  Field x;
  Field y;
  Field z;
  bool infinity;
  EC ec;
  bool isExtension;

  JacobianPoint(this.x, this.y, this.z, this.infinity, {EC? ec})
      : ec = ec ?? defaultEc,
        isExtension = x is! Fq {
    if (x.runtimeType != y.runtimeType) {
      throw ArgumentError(
          'Both x, y, and z should be similar field instances.');
    }
  }

  bool get isOnCurve => infinity ? true : toAffine().isOnCurve;
  bool get isValid => isOnCurve && this * ec.n == G2Infinity();

  JacobianPoint operator -() => (-toAffine()).toJacobian();

  AffinePoint toAffine() => infinity
      ? AffinePoint(Fq.zero(ec.q), Fq.zero(ec.q), infinity, ec: ec)
      : AffinePoint(x / z.pow(BigInt.two), y / z.pow(BigInt.from(3)), infinity,
          ec: ec);

  int getFingerprint() =>
      bytesToInt(sha256.convert(toBytes()).bytes.sublist(0, 4), Endian.big);

  JacobianPoint operator +(JacobianPoint other) =>
      addPointsJacobian(this, other, ec: ec);

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

  Uint8List toBytes() => pointToBytes(this, ec);

  @override
  String toString() => 'JacobianPoint(x=$x, y=$y, z=$z, i=$infinity)';

  JacobianPoint deepcopy() =>
      JacobianPoint(x.deepcopy(), y.deepcopy(), z.deepcopy(), infinity, ec: ec);
}

bool signFq(Fq element, {EC? ec}) {
  ec ??= defaultEc;
  return element > Fq(ec.q, (ec.q - BigInt.one) ~/ BigInt.two);
}

bool signFq2(Fq2 element, {EC? ec}) {
  ec ??= defaultEcTwist;
  if (element.elements[1] == Fq(ec.q, BigInt.zero)) {
    return signFq(element.elements[0] as Fq);
  }
  return element.elements[1] > Fq(ec.q, (ec.q - BigInt.one) ~/ BigInt.two);
}

Uint8List pointToBytes(JacobianPoint pointJ, EC ec) {
  var point = pointJ.toAffine();
  var output = point.x.toBytes();
  if (point.infinity) {
    return Uint8List.fromList([0xc0] + List.filled(output.length - 1, 0));
  }
  bool sign;
  if (pointJ.isExtension) {
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

JacobianPoint bytesToPoint(List<int> bytes, EC ec, bool isExtension) {
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
        throw ArgumentError('Point at infinity set, but data not all zeroes.');
      }
    }
    return AffinePoint(isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
            isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q), true,
            ec: ec)
        .toJacobian();
  }
  var x = isExtension ? Fq2.fromBytes(bytes, ec.q) : Fq.fromBytes(bytes, ec.q);
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

Field yForX(Field x, {EC? ec}) {
  ec ??= defaultEc;
  var u = x * x * x + ec.a * x + ec.b as dynamic;
  var y = u.modSqrt();
  if (y == BigInt.zero || !AffinePoint(x, y, false, ec: ec).isOnCurve) {
    throw ArgumentError('No y for point x.');
  }
  return y;
}

AffinePoint doublePoint(AffinePoint p1, {EC? ec}) {
  ec ??= defaultEc;
  var x = p1.x;
  var y = p1.y;
  var left = x * x * Fq(ec.q, BigInt.from(3)) + ec.a;
  var s = left / (y * Fq(ec.q, BigInt.two));
  var newX = s * s - x - x;
  var newY = s * (x - newX) - y;
  return AffinePoint(newX, newY, false, ec: ec);
}

AffinePoint addPoints(AffinePoint p1, AffinePoint p2, {EC? ec}) {
  assert(p1.isOnCurve);
  assert(p2.isOnCurve);
  if (p1.infinity) {
    return p2;
  } else if (p2.infinity) {
    return p1;
  } else if (p1 == p2) {
    return doublePoint(p1, ec: ec);
  }
  var x1 = p1.x;
  var y1 = p1.y;
  var x2 = p2.x;
  var y2 = p2.y;
  var s = (y2 - y1) / (x2 - x1);
  var newX = s * s - x1 - x2;
  var newY = s * (x1 - newX) - y1;
  return AffinePoint(newX, newY, false, ec: ec);
}

JacobianPoint doublePointJacobian(JacobianPoint p1, {EC? ec}) {
  ec ??= defaultEc;
  var X = p1.x;
  var Y = p1.y;
  var Z = p1.z;
  if (Y == (p1.isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q)) || p1.infinity) {
    return JacobianPoint(
        p1.isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
        p1.isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
        p1.isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
        true,
        ec: ec);
  }
  var S = X * Y * Y * Fq(ec.q, BigInt.from(4));
  var Z_sq = Z * Z;
  var Z_4th = Z_sq * Z_sq;
  var Y_sq = Y * Y;
  var Y_4th = Y_sq * Y_sq;
  var M = X * X * Fq(ec.q, BigInt.from(3)) + ec.a * Z_4th;
  var X_p = M * M - S * Fq(ec.q, BigInt.two);
  var Y_p = M * (S - X_p) - Y_4th * Fq(ec.q, BigInt.from(8));
  var Z_p = Y * Z * Fq(ec.q, BigInt.two);
  return JacobianPoint(X_p, Y_p, Z_p, false, ec: ec);
}

JacobianPoint addPointsJacobian(JacobianPoint p1, JacobianPoint p2, {EC? ec}) {
  ec ??= defaultEc;
  if (p1.infinity) {
    return p2;
  } else if (p2.infinity) {
    return p1;
  }
  var U1 = p1.x * p2.z.pow(BigInt.two);
  var U2 = p2.x * p1.z.pow(BigInt.two);
  var S1 = p1.y * p2.z.pow(BigInt.from(3));
  var S2 = p2.y * p1.z.pow(BigInt.from(3));
  if (U1 == U2) {
    if (S1 != S2) {
      return JacobianPoint(
          p1.isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
          p1.isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
          p1.isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
          true,
          ec: ec);
    } else {
      return doublePointJacobian(p1, ec: ec);
    }
  }
  var H = U2 - U1;
  var R = S2 - S1;
  var H_sq = H * H;
  var H_cu = H * H_sq;
  var X3 = R * R - H_cu - U1 * H_sq * Fq(ec.q, BigInt.two);
  var Y3 = R * (U1 * H_sq - X3) - S1 * H_cu;
  var Z3 = H * p1.z * p2.z;
  return JacobianPoint(X3, Y3, Z3, false, ec: ec);
}

AffinePoint scalarMult(c, AffinePoint p1, {EC? ec}) {
  ec ??= defaultEc;
  if (p1.infinity || c % ec.q == 0) {
    return AffinePoint(p1.isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
        p1.isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q), true,
        ec: ec);
  }
  var result = AffinePoint(p1.isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
      p1.isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q), true,
      ec: ec);
  var addend = p1;
  while (c > 0) {
    if (c & 1) {
      result += addend;
    }
    addend += addend;
    c >>= 1;
  }
  return result;
}

JacobianPoint scalarMultJacobian(c, JacobianPoint p1, {EC? ec}) {
  ec ??= defaultEc;
  if (c is Fq) {
    c = c.value;
  }
  if (p1.infinity || c % ec.q == BigInt.zero) {
    return JacobianPoint(
        p1.isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
        p1.isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
        p1.isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
        true,
        ec: ec);
  }
  var result = JacobianPoint(
      p1.isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
      p1.isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
      p1.isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
      true,
      ec: ec);
  var addend = p1;
  while (c > BigInt.zero) {
    if (c & BigInt.one != BigInt.zero) {
      result += addend;
    }
    addend += addend;
    c >>= 1;
  }
  return result;
}

JacobianPoint G1Generator({EC? ec}) {
  ec ??= defaultEc;
  return AffinePoint(ec.gx, ec.gy, false, ec: ec).toJacobian();
}

JacobianPoint G2Generator({EC? ec}) {
  ec ??= defaultEcTwist;
  return AffinePoint(ec.g2x, ec.g2y, false, ec: ec).toJacobian();
}

JacobianPoint G1Infinity({bool? isExtension, EC? ec}) {
  isExtension ??= false;
  ec ??= defaultEc;
  return JacobianPoint(
      isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
      isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
      isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
      true,
      ec: ec);
}

JacobianPoint G2Infinity({bool? isExtension, EC? ec}) {
  isExtension ??= true;
  ec ??= defaultEcTwist;
  return JacobianPoint(
      isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
      isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
      isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
      true,
      ec: ec);
}

JacobianPoint G1FromBytes(List<int> bytes, {bool? isExtension, EC? ec}) {
  isExtension ??= false;
  ec ??= defaultEc;
  return bytesToPoint(bytes, ec, isExtension);
}

JacobianPoint G2FromBytes(List<int> bytes, {bool? isExtension, EC? ec}) {
  isExtension ??= true;
  ec ??= defaultEcTwist;
  return bytesToPoint(bytes, ec, isExtension);
}

AffinePoint untwist(AffinePoint point, {EC? ec}) {
  ec ??= defaultEc;
  var f = Fq12.one(ec.q);
  var wsq = Fq12(ec.q, [f.root, Fq6.zero(ec.q)]);
  var wcu = Fq12(ec.q, [Fq6.zero(ec.q), f.root]);
  return AffinePoint(point.x / wsq, point.y / wcu, false, ec: ec);
}

AffinePoint twist(AffinePoint point, {EC? ec}) {
  ec ??= defaultEcTwist;
  var f = Fq12.one(ec.q);
  var wsq = Fq12(ec.q, [f.root, Fq6.zero(ec.q)]);
  var wcu = Fq12(ec.q, [Fq6.zero(ec.q), f.root]);
  var newX = point.x * wsq;
  var newY = point.y * wcu;
  return AffinePoint(newX, newY, false, ec: ec);
}

JacobianPoint evalIso(JacobianPoint P, List<List<Fq2>> mapCoeffs, EC ec) {
  var x = P.x;
  var y = P.y;
  var z = P.z;
  List<Fq2?> mapVals = List.filled(4, null);
  var maxOrd = mapCoeffs[0].length;
  for (var coeffs in mapCoeffs.sublist(1)) {
    maxOrd = math.max(maxOrd, coeffs.length);
  }
  List<Fq2?> zPows = List.filled(maxOrd, null);
  zPows[0] = z.pow(BigInt.zero) as Fq2;
  zPows[1] = z.pow(BigInt.two) as Fq2;
  for (var i in range(2, zPows.length)) {
    assert(zPows[i.toInt() - 1] != null);
    assert(zPows[1] != null);
    zPows[i.toInt()] = zPows[i.toInt() - 1]! * zPows[1] as Fq2;
  }
  for (var item in enumerate(mapCoeffs)) {
    var coeffsZ =
        zip([item.value.reversed.toList(), zPows.sublist(0, item.value.length)])
            .map((item) => item[0]! * item[1])
            .toList();
    var tmp = coeffsZ[0];
    for (var coeff in coeffsZ.sublist(1, coeffsZ.length)) {
      tmp *= x;
      tmp += coeff;
    }
    mapVals[item.index] = tmp as Fq2;
  }
  assert(mapCoeffs[1].length + 1 == mapCoeffs[0].length);
  assert(zPows[1] != null);
  assert(mapVals[1] != null);
  mapVals[1] = mapVals[1]! * zPows[1] as Fq2;
  assert(mapVals[2] != null);
  assert(mapVals[3] != null);
  mapVals[2] = mapVals[2]! * y as Fq2;
  mapVals[3] = mapVals[3]! * z.pow(BigInt.from(3)) as Fq2;
  var Z = mapVals[1]! * mapVals[3];
  var X = mapVals[0]! * mapVals[3] * Z;
  var Y = mapVals[2]! * mapVals[1] * Z * Z;
  return JacobianPoint(X, Y, Z, P.infinity, ec: ec);
}
