import 'package:chia_crypto_utils/src/bls/ec/ec.dart';
import 'package:chia_crypto_utils/src/bls/ec/helpers.dart';
import 'package:chia_crypto_utils/src/bls/ec/jacobian_point.dart';
import 'package:chia_crypto_utils/src/bls/field/extensions/fq12.dart';
import 'package:chia_crypto_utils/src/bls/field/extensions/fq2.dart';
import 'package:chia_crypto_utils/src/bls/field/extensions/fq6.dart';
import 'package:chia_crypto_utils/src/bls/field/field.dart';
import 'package:chia_crypto_utils/src/bls/field/field_base.dart';
import 'package:meta/meta.dart';
import 'package:quiver/core.dart';

@immutable
class AffinePoint {
  // ignore: avoid_positional_boolean_parameters
  AffinePoint(this.x, this.y, this.infinity, {EC? ec}) : ec = ec ?? defaultEc {
    if (x.runtimeType != y.runtimeType) {
      throw ArgumentError('Both x and y should be similar field instances.');
    }
  }

  final Field x;
  final Field y;
  final bool infinity;
  final EC ec;

  bool get isExtension => x is! Fq;
  bool get isOnCurve => infinity || y * y == x * x * x + ec.a * x + ec.b;

  AffinePoint untwist() {
    final f = Fq12.one(ec.q);
    final wsq = Fq12(ec.q, [f.root, Fq6.zero(ec.q)]);
    final wcu = Fq12(ec.q, [Fq6.zero(ec.q), f.root]);
    return AffinePoint(x / wsq, y / wcu, false, ec: ec);
  }

  AffinePoint twist() {
    final f = Fq12.one(ec.q);
    final wsq = Fq12(ec.q, [f.root, Fq6.zero(ec.q)]);
    final wcu = Fq12(ec.q, [Fq6.zero(ec.q), f.root]);
    final newX = x * wsq;
    final newY = y * wcu;
    return AffinePoint(newX, newY, false, ec: ec);
  }

  AffinePoint double() {
    final left = x * x * Fq(ec.q, BigInt.from(3)) + ec.a;
    final s = left / (y * Fq(ec.q, BigInt.two));
    final newX = s * s - x - x;
    final newY = s * (x - newX) - y;
    return AffinePoint(newX, newY, false, ec: ec);
  }

  AffinePoint operator +(AffinePoint other) {
    assert(isOnCurve, 'Point ($this) is not on curve.');
    assert(other.isOnCurve, 'Point ($other) is not on curve.');
    if (infinity) {
      return other;
    } else if (other.infinity) {
      return this;
    } else if (this == other) {
      return double();
    }
    final x1 = x;
    final y1 = y;
    final x2 = other.x;
    final y2 = other.y;
    final s = (y2 - y1) / (x2 - x1);
    final newX = s * s - x1 - x2;
    final newY = s * (x1 - newX) - y1;
    return AffinePoint(newX, newY, false, ec: ec);
  }

  AffinePoint operator *(Object other) {
    final c = other.extractBigInt();
    if (c == null) {
      throw ArgumentError('Must multiply AffinePoint with BigInt or Fq.');
    }
    return scalarMultJacobian(c, toJacobian(), ec: ec).toAffine();
  }

  AffinePoint operator -(AffinePoint other) => this + -other;
  AffinePoint operator -() => AffinePoint(x, -y, infinity, ec: ec);

  JacobianPoint toJacobian() => JacobianPoint(
        x,
        y,
        x is Fq ? Fq.one(ec.q) : Fq2.one(ec.q),
        infinity,
        ec: ec,
      );

  AffinePoint clone() => AffinePoint(x.clone(), y.clone(), infinity, ec: ec);

  @override
  String toString() => 'AffinePoint(x: $x, y: $y, i: $infinity)';

  @override
  bool operator ==(Object other) =>
      other is AffinePoint && x == other.x && y == other.y && infinity == other.infinity;

  @override
  int get hashCode => hash3(x, y, infinity);
}
