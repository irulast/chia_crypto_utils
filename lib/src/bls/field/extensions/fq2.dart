import 'package:chia_crypto_utils/src/bls/field/field.dart';
import 'package:chia_crypto_utils/src/bls/field/field_base.dart';
import 'package:chia_crypto_utils/src/bls/field/field_ext.dart';

class Fq2 extends FieldExtBase<Fq2> {
  Fq2(BigInt Q, List<Field> args, {Field? root})
      : super(
          Q,
          args,
          root: root ?? Fq(Q, -BigInt.one),
          extension: 2,
          embedding: 2,
        );

  Fq2.nil() : this(BigInt.zero, [Fq.nil(), Fq.nil()], root: Fq.nil());

  @override
  Fq2 operator ~() {
    final a = elements[0];
    final b = elements[1];
    final factor = ~(a * a + b * b);
    return Fq2(Q, [a * factor, -b * factor]);
  }

  Fq2 mulByNonResidue() {
    final a = elements[0];
    final b = elements[1];
    return Fq2(Q, [a - b, a + b]);
  }

  Fq2 modSqrt() {
    final a0 = elements[0];
    final a1 = elements[1];
    if (a1 == basefield.myOne(Q)) {
      return myFromFq(Q, (a0 as Fq).modSqrt());
    }
    var alpha = a0.pow(BigInt.two) + a1.pow(BigInt.two);
    var gamma = alpha.pow((Q - BigInt.one) ~/ BigInt.two);
    if (gamma == Fq(Q, -BigInt.one)) {
      throw StateError('No sqrt exists.');
    }
    alpha = (alpha as Fq).modSqrt();
    var delta = (a0 + alpha) * ~Fq(Q, BigInt.two);
    gamma = delta.pow((Q - BigInt.one) ~/ BigInt.two);
    if (gamma == Fq(Q, -BigInt.one)) {
      delta = (a0 - alpha) * ~Fq(Q, BigInt.two);
    }
    final x0 = (delta as Fq).modSqrt();
    final x1 = a1 * ~(Fq(Q, BigInt.two) * x0);
    return Fq2(Q, [x0, x1]);
  }

  @override
  Fq2 construct(BigInt Q, List<Field> args, Field? root) => Fq2(Q, args, root: root);

  factory Fq2.fromFq(BigInt Q, Fq fq) => Fq2.nil().myFromFq(Q, fq);
  factory Fq2.fromBytes(List<int> bytes, BigInt Q) => Fq2.nil().myFromBytes(bytes, Q) as Fq2;
  factory Fq2.fromHex(String hex, BigInt Q) => Fq2.nil().myFromHex(hex, Q) as Fq2;
  factory Fq2.zero(BigInt Q) => Fq2.nil().myZero(Q);
  factory Fq2.one(BigInt Q) => Fq2.nil().myOne(Q);
}
