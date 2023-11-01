import 'package:chia_crypto_utils/src/bls/field/extensions/fq2.dart';
import 'package:chia_crypto_utils/src/bls/field/field.dart';
import 'package:chia_crypto_utils/src/bls/field/field_base.dart';
import 'package:chia_crypto_utils/src/bls/field/field_ext.dart';

class Fq6 extends FieldExtBase<Fq6> {
  Fq6(BigInt Q, List<Field> args, {Field? root})
      : super(
          Q,
          args,
          root: root ?? Fq2(Q, [Fq.one(Q), Fq.one(Q)]),
          extension: 6,
          embedding: 3,
        );

  Fq6.nil()
      : this(
          BigInt.zero,
          [Fq2.nil(), Fq2.nil(), Fq2.nil()],
          root: Fq2.nil(),
        );

  @override
  Fq6 operator ~() {
    final a = elements[0];
    final b = elements[1];
    final c = elements[2];
    final g0 = a * a - b * (c as Fq2).mulByNonResidue();
    final g1 = (c * c as Fq2).mulByNonResidue() - a * b;
    final g2 = b * b - a * c;
    final factor = ~(g0 * a + (g1 * c + g2 * b as Fq2).mulByNonResidue());
    return Fq6(Q, [g0 * factor, g1 * factor, g2 * factor]);
  }

  Fq6 mulByNonResidue() {
    final a = elements[0];
    final b = elements[1];
    final c = elements[2];
    return Fq6(Q, [c * root, a, b]);
  }

  @override
  Fq6 construct(BigInt Q, List<Field> args, Field? root) => Fq6(Q, args, root: root);

  factory Fq6.fromFq(BigInt Q, Fq fq) => Fq6.nil().myFromFq(Q, fq);
  factory Fq6.fromBytes(List<int> bytes, BigInt Q) => Fq6.nil().myFromBytes(bytes, Q) as Fq6;
  factory Fq6.fromHex(String hex, BigInt Q) => Fq6.nil().myFromHex(hex, Q) as Fq6;
  factory Fq6.zero(BigInt Q) => Fq6.nil().myZero(Q);
  factory Fq6.one(BigInt Q) => Fq6.nil().myOne(Q);
}
