// ignore_for_file: non_constant_identifier_names
import 'dart:math' as math;

import 'package:chia_utils/src/bls/bls12381.dart';
import 'package:chia_utils/src/bls/ec/affine_point.dart';
import 'package:chia_utils/src/bls/ec/jacobian_point.dart';
import 'package:chia_utils/src/bls/field.dart';
import 'package:chia_utils/src/bls/field_base.dart';
import 'package:chia_utils/src/bls/field_ext.dart';
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

Field yForX(Field x, {EC? ec}) {
  ec ??= defaultEc;
  var u = x * x * x + ec.a * x + ec.b as dynamic;
  var y = u.modSqrt();
  if (y == BigInt.zero || !AffinePoint(x, y, false, ec: ec).isOnCurve) {
    throw ArgumentError('No y for point x.');
  }
  return y;
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
