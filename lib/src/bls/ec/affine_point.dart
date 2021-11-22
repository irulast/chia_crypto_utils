import 'package:chia_utils/src/bls/ec/ec.dart';
import 'package:chia_utils/src/bls/ec/jacobian_point.dart';
import 'package:chia_utils/src/bls/field.dart';
import 'package:chia_utils/src/bls/field_base.dart';
import 'package:chia_utils/src/bls/field_ext.dart';
import 'package:quiver/core.dart';

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

  AffinePoint untwist() {
    var f = Fq12.one(ec.q);
    var wsq = Fq12(ec.q, [f.root, Fq6.zero(ec.q)]);
    var wcu = Fq12(ec.q, [Fq6.zero(ec.q), f.root]);
    return AffinePoint(x / wsq, y / wcu, false, ec: ec);
  }

  AffinePoint twist() {
    var f = Fq12.one(ec.q);
    var wsq = Fq12(ec.q, [f.root, Fq6.zero(ec.q)]);
    var wcu = Fq12(ec.q, [Fq6.zero(ec.q), f.root]);
    var newX = x * wsq;
    var newY = y * wcu;
    return AffinePoint(newX, newY, false, ec: ec);
  }

  AffinePoint double() {
    var left = x * x * Fq(ec.q, BigInt.from(3)) + ec.a;
    var s = left / (y * Fq(ec.q, BigInt.two));
    var newX = s * s - x - x;
    var newY = s * (x - newX) - y;
    return AffinePoint(newX, newY, false, ec: ec);
  }

  AffinePoint operator +(AffinePoint other) {
    assert(isOnCurve);
    assert(other.isOnCurve);
    if (infinity) {
      return other;
    } else if (other.infinity) {
      return this;
    } else if (this == other) {
      return double();
    }
    var x1 = x;
    var y1 = y;
    var x2 = other.x;
    var y2 = other.y;
    var s = (y2 - y1) / (x2 - x1);
    var newX = s * s - x1 - x2;
    var newY = s * (x1 - newX) - y1;
    return AffinePoint(newX, newY, false, ec: ec);
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

  AffinePoint clone() => AffinePoint(x.clone(), y.clone(), infinity, ec: ec);

  @override
  String toString() => 'AffinePoint(x=$x, y=$y, i=$infinity)';

  @override
  bool operator ==(Object other) => other is AffinePoint
      ? x == other.x && y == other.y && infinity == other.infinity
      : false;

  @override
  int get hashCode => hash3(x, y, infinity);
}
