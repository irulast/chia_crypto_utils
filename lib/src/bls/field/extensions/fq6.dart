import 'package:chia_utils/src/bls/field/extensions/fq2.dart';
import 'package:chia_utils/src/bls/field/field.dart';
import 'package:chia_utils/src/bls/field/field_base.dart';
import 'package:chia_utils/src/bls/field/field_ext.dart';

class Fq6 extends FieldExtBase {
  @override
  int extension = 6;
  @override
  int embedding = 3;
  @override
  Field root;

  Fq6(BigInt Q, List<Field> args)
      : root = Fq2(Q, [Fq.one(Q), Fq.one(Q)]),
        super(Q, args);

  Fq6.nil()
      : root = Fq2.nil(),
        super(BigInt.zero, [Fq2.nil(), Fq2.nil(), Fq2.nil()]);

  @override
  Fq6 operator ~() {
    var a = elements[0];
    var b = elements[1];
    var c = elements[2];
    var g0 = a * a - b * (c as Fq2).mulByNonResidue();
    var g1 = (c * c as Fq2).mulByNonResidue() - a * b;
    var g2 = b * b - a * c;
    var factor = ~(g0 * a + (g1 * c + g2 * b as Fq2).mulByNonResidue());
    return Fq6(Q, [g0 * factor, g1 * factor, g2 * factor]);
  }

  Fq6 mulByNonResidue() {
    var a = elements[0];
    var b = elements[1];
    var c = elements[2];
    return Fq6(Q, [c * root, a, b]);
  }

  @override
  Fq6 construct(BigInt Q, List<Field> args) => Fq6(Q, args);

  factory Fq6.fromFq(BigInt Q, Fq fq) => Fq6.nil().myFromFq(Q, fq) as Fq6;
  factory Fq6.fromBytes(List<int> bytes, BigInt Q) =>
      Fq6.nil().myFromBytes(bytes, Q) as Fq6;
  factory Fq6.fromHex(String hex, BigInt Q) =>
      Fq6.nil().myFromHex(hex, Q) as Fq6;
  factory Fq6.zero(BigInt Q) => Fq6.nil().myZero(Q) as Fq6;
  factory Fq6.one(BigInt Q) => Fq6.nil().myOne(Q) as Fq6;
}
