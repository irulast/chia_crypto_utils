import 'package:chia_crypto_utils/src/bls/field/extensions/fq2.dart';
import 'package:chia_crypto_utils/src/bls/field/extensions/fq6.dart';
import 'package:chia_crypto_utils/src/bls/field/field.dart';
import 'package:chia_crypto_utils/src/bls/field/field_base.dart';
import 'package:chia_crypto_utils/src/bls/field/field_ext.dart';

class Fq12 extends FieldExtBase<Fq12> {
  Fq12(BigInt Q, List<Field> args, {Field? root})
      : super(
          Q,
          args,
          root: root ?? Fq6(Q, [Fq2.zero(Q), Fq2.one(Q), Fq2.zero(Q)]),
          extension: 12,
          embedding: 2,
        );

  Fq12.nil()
      : this(
          BigInt.zero,
          [Fq6.nil(), Fq6.nil()],
          root: Fq6.nil(),
        );

  @override
  Fq12 operator ~() {
    final a = elements[0];
    final b = elements[1];
    final factor = ~(a * a - (b * b as Fq6).mulByNonResidue());
    return Fq12(Q, [a * factor, -b * factor]);
  }

  @override
  Fq12 construct(BigInt Q, List<Field> args, Field? root) => Fq12(Q, args, root: root);

  factory Fq12.fromFq(BigInt Q, Fq fq) => Fq12.nil().myFromFq(Q, fq);
  factory Fq12.fromBytes(List<int> bytes, BigInt Q) => Fq12.nil().myFromBytes(bytes, Q) as Fq12;
  factory Fq12.fromHex(String hex, BigInt Q) => Fq12.nil().myFromHex(hex, Q) as Fq12;
  factory Fq12.zero(BigInt Q) => Fq12.nil().myZero(Q);
  factory Fq12.one(BigInt Q) => Fq12.nil().myOne(Q);
}
