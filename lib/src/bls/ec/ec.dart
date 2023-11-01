// ignore_for_file: non_constant_identifier_names

import 'package:chia_crypto_utils/src/bls/bls12381.dart';
import 'package:chia_crypto_utils/src/bls/ec/affine_point.dart';
import 'package:chia_crypto_utils/src/bls/ec/jacobian_point.dart';
import 'package:chia_crypto_utils/src/bls/field/extensions/fq2.dart';
import 'package:chia_crypto_utils/src/bls/field/field.dart';
import 'package:chia_crypto_utils/src/bls/field/field_base.dart';
import 'package:quiver/iterables.dart';

class EC {
  const EC(
    this.q,
    this.a,
    this.b,
    this.gx,
    this.gy,
    this.g2x,
    this.g2y,
    this.n,
    this.h,
    this.x,
    this.k,
    this.sqrtN3,
    this.sqrtN3m1o2,
  );

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
}

final defaultEc = EC(q, a, b, gx, gy, g2x, g2y, n, h, x, k, sqrtN3, sqrtN3m1o2);
final defaultEcTwist = EC(q, aTwist, bTwist, gx, gy, g2x, g2y, n, hEff, x, k, sqrtN3, sqrtN3m1o2);

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
  final u = x * x * x + ec.a * x + ec.b;

  final y = () {
    if (u is Fq) {
      return u.modSqrt();
    } else if (u is Fq2) {
      return u.modSqrt();
    }
    throw Exception(
      'unsupported type ${u.runtimeType}. It must be or $Fq or $Fq2',
    );
  }();
  if (y.equal(BigInt.zero) || !AffinePoint(x, y, false, ec: ec).isOnCurve) {
    throw ArgumentError('No y for point x.');
  }
  return y;
}

AffinePoint scalarMult(BigInt c, AffinePoint p1, {EC? ec}) {
  ec ??= defaultEc;
  if (p1.infinity || c % ec.q == BigInt.zero) {
    return AffinePoint(
      p1.isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
      p1.isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
      true,
      ec: ec,
    );
  }
  var result = AffinePoint(
    p1.isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
    p1.isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
    true,
    ec: ec,
  );
  var addend = p1;
  var _c = c;
  while (_c > BigInt.zero) {
    if (_c & BigInt.one == BigInt.one) {
      result += addend;
    }
    addend += addend;
    _c >>= 1;
  }
  return result;
}

JacobianPoint scalarMultJacobian(BigInt c, JacobianPoint p1, {EC? ec}) {
  ec ??= defaultEc;

  if (p1.infinity || c % ec.q == BigInt.zero) {
    return JacobianPoint(
      p1.isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
      p1.isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
      p1.isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
      true,
      ec: ec,
    );
  }
  var result = JacobianPoint(
    p1.isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
    p1.isExtension ? Fq2.one(ec.q) : Fq.one(ec.q),
    p1.isExtension ? Fq2.zero(ec.q) : Fq.zero(ec.q),
    true,
    ec: ec,
  );
  var addend = p1;
  var _c = c;
  while (_c > BigInt.zero) {
    if (_c & BigInt.one != BigInt.zero) {
      result += addend;
    }
    addend += addend;
    _c >>= 1;
  }
  return result;
}

JacobianPoint evalIso(JacobianPoint P, List<List<Fq2>> mapCoeffs, EC ec) {
  final x = P.x;
  final y = P.y;
  final z = P.z;

  final maxOrd = mapCoeffs.maxLength;
  final zPows = z.nPows(maxOrd);

  final mapVals = List<Fq2?>.filled(4, null);

  for (final item in enumerate(mapCoeffs)) {
    final coeffsZ = zip([item.value.reversed.toList(), zPows.sublist(0, item.value.length)])
        .map((item) => item[0] * item[1])
        .toList();
    var tmp = coeffsZ[0];
    for (final coeff in coeffsZ.sublist(1, coeffsZ.length)) {
      tmp *= x;
      tmp += coeff;
    }
    mapVals[item.index] = tmp as Fq2;
  }
  assert(
    mapCoeffs[1].length + 1 == mapCoeffs[0].length,
    'mapCoeffs[0] must have one element more than mapCoeffs[1]',
  );
  assert(mapVals[1] != null, 'mapVals[1] must be non-null');
  mapVals[1] = mapVals[1]! * zPows[1] as Fq2;
  assert(mapVals[2] != null, 'mapVals[2] must be non-null');
  assert(mapVals[3] != null, 'mapVals[3] must be non-null');
  mapVals[2] = mapVals[2]! * y as Fq2;
  mapVals[3] = mapVals[3]! * z.pow(BigInt.from(3)) as Fq2;
  final Z = mapVals[1]! * mapVals[3];
  final X = mapVals[0]! * mapVals[3] * Z;
  final Y = mapVals[2]! * mapVals[1] * Z * Z;
  return JacobianPoint(X, Y, Z, P.infinity, ec: ec);
}

extension MaxLength<T> on List<List<T>> {
  int get maxLength {
    var max = 0;
    for (final item in this) {
      if (item.length > max) max = item.length;
    }
    return max;
  }
}

extension NFq2Pows on Field {
  List<Fq2> nPows(int length) {
    final zPows = List<Fq2?>.filled(length, null);
    zPows[0] = pow(BigInt.zero) as Fq2;
    zPows[1] = pow(BigInt.two) as Fq2;
    for (var i = 2; i < zPows.length; i++) {
      assert(zPows[i - 1] != null, 'zPows[${i - 1}] must be non-null');
      assert(zPows[1] != null, 'zPows[1] must be non-null');
      zPows[i] = zPows[i - 1]! * zPows[1] as Fq2;
    }
    return zPows.cast();
  }
}
