import 'dart:typed_data';

import 'package:chia_utils/src/bls/bls12381.dart';
import 'package:chia_utils/src/bls/failed_op.dart';
import 'package:chia_utils/src/bls/field.dart';
import 'package:chia_utils/src/bls/field_base.dart';
import 'package:hex/hex.dart';
import 'package:quiver/collection.dart';
import 'package:quiver/core.dart';
import 'package:quiver/iterables.dart';

var rv1 = BigInt.parse(
    '0x6AF0E0437FF400B6831E36D6BD17FFE48395DABC2D3435E77F76E17009241C5EE67992F72EC05F4C81084FBEDE3CC09');

var rootsOfUnity = [
  Fq2(q, [Fq(q, BigInt.one), Fq(q, BigInt.zero)]),
  Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.one)]),
  Fq2(q, [Fq(q, rv1), Fq(q, rv1)]),
  Fq2(q, [Fq(q, rv1), Fq(q, q - rv1)])
];

var frobCoeffs = {
  [2, 1, 1]: Fq(q, -BigInt.one),
  [6, 1, 1]: Fq2(q, [
    Fq(q, BigInt.zero),
    Fq(
      q,
      BigInt.parse(
          '0x1A0111EA397FE699EC02408663D4DE85AA0D857D89759AD4897D29650FB85F9B409427EB4F49FFFD8BFD00000000AAAC'),
    )
  ]),
  [6, 1, 2]: Fq2(q, [
    Fq(
      q,
      BigInt.parse(
          '0x1A0111EA397FE699EC02408663D4DE85AA0D857D89759AD4897D29650FB85F9B409427EB4F49FFFD8BFD00000000AAAD'),
    ),
    Fq(q, BigInt.zero)
  ]),
  [6, 2, 1]: Fq2(q, [
    Fq(
      q,
      BigInt.parse(
          '0x5F19672FDF76CE51BA69C6076A0F77EADDB3A93BE6F89688DE17D813620A00022E01FFFFFFFEFFFE'),
    ),
    Fq(q, BigInt.zero)
  ]),
  [6, 2, 2]: Fq2(q, [
    Fq(
      q,
      BigInt.parse(
          '0x1A0111EA397FE699EC02408663D4DE85AA0D857D89759AD4897D29650FB85F9B409427EB4F49FFFD8BFD00000000AAAC'),
    ),
    Fq(q, BigInt.zero)
  ]),
  [6, 3, 1]: Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.one)]),
  [6, 3, 2]: Fq2(q, [
    Fq(
      q,
      BigInt.parse(
          '0x1A0111EA397FE69A4B1BA7B6434BACD764774B84F38512BF6730D2A0F6B0F6241EABFFFEB153FFFFB9FEFFFFFFFFAAAA'),
    ),
    Fq(q, BigInt.zero)
  ]),
  [6, 4, 1]: Fq2(q, [
    Fq(
      q,
      BigInt.parse(
          '0x1A0111EA397FE699EC02408663D4DE85AA0D857D89759AD4897D29650FB85F9B409427EB4F49FFFD8BFD00000000AAAC'),
    ),
    Fq(q, BigInt.zero)
  ]),
  [6, 4, 2]: Fq2(q, [
    Fq(
      q,
      BigInt.parse(
          '0x5F19672FDF76CE51BA69C6076A0F77EADDB3A93BE6F89688DE17D813620A00022E01FFFFFFFEFFFE'),
    ),
    Fq(q, BigInt.zero)
  ]),
  [6, 5, 1]: Fq2(q, [
    Fq(q, BigInt.zero),
    Fq(
      q,
      BigInt.parse(
          '0x5F19672FDF76CE51BA69C6076A0F77EADDB3A93BE6F89688DE17D813620A00022E01FFFFFFFEFFFE'),
    )
  ]),
  [6, 5, 2]: Fq2(q, [
    Fq(
      q,
      BigInt.parse(
          '0x5F19672FDF76CE51BA69C6076A0F77EADDB3A93BE6F89688DE17D813620A00022E01FFFFFFFEFFFF'),
    ),
    Fq(q, BigInt.zero),
  ]),
  [12, 1, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
            '0x1904D3BF02BB0667C231BEB4202C0D1F0FD603FD3CBD5F4F7B2443D784BAB9C4F67EA53D63E7813D8D0775ED92235FB8'),
      ),
      Fq(
        q,
        BigInt.parse(
            '0xFC3E2B36C4E03288E9E902231F9FB854A14787B6C7B36FEC0C8EC971F63C5F282D5AC14D6C7EC22CF78A126DDC4AF3'),
      )
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 2, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
            '0x5F19672FDF76CE51BA69C6076A0F77EADDB3A93BE6F89688DE17D813620A00022E01FFFFFFFEFFFF'),
      ),
      Fq(q, BigInt.zero),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 3, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
            '0x135203E60180A68EE2E9C448D77A2CD91C3DEDD930B1CF60EF396489F61EB45E304466CF3E67FA0AF1EE7B04121BDEA2'),
      ),
      Fq(
        q,
        BigInt.parse(
            '0x6AF0E0437FF400B6831E36D6BD17FFE48395DABC2D3435E77F76E17009241C5EE67992F72EC05F4C81084FBEDE3CC09'),
      ),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 4, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
            '0x5F19672FDF76CE51BA69C6076A0F77EADDB3A93BE6F89688DE17D813620A00022E01FFFFFFFEFFFE'),
      ),
      Fq(q, BigInt.zero),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 5, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
            '0x144E4211384586C16BD3AD4AFA99CC9170DF3560E77982D0DB45F3536814F0BD5871C1908BD478CD1EE605167FF82995'),
      ),
      Fq(
        q,
        BigInt.parse(
            '0x5B2CFD9013A5FD8DF47FA6B48B1E045F39816240C0B8FEE8BEADF4D8E9C0566C63A3E6E257F87329B18FAE980078116'),
      ),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 6, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
            '0x1A0111EA397FE69A4B1BA7B6434BACD764774B84F38512BF6730D2A0F6B0F6241EABFFFEB153FFFFB9FEFFFFFFFFAAAA'),
      ),
      Fq(q, BigInt.zero),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 7, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
            '0xFC3E2B36C4E03288E9E902231F9FB854A14787B6C7B36FEC0C8EC971F63C5F282D5AC14D6C7EC22CF78A126DDC4AF3'),
      ),
      Fq(
        q,
        BigInt.parse(
            '0x1904D3BF02BB0667C231BEB4202C0D1F0FD603FD3CBD5F4F7B2443D784BAB9C4F67EA53D63E7813D8D0775ED92235FB8'),
      ),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 8, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
            '0x1A0111EA397FE699EC02408663D4DE85AA0D857D89759AD4897D29650FB85F9B409427EB4F49FFFD8BFD00000000AAAC'),
      ),
      Fq(q, BigInt.zero),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 9, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
            '0x6AF0E0437FF400B6831E36D6BD17FFE48395DABC2D3435E77F76E17009241C5EE67992F72EC05F4C81084FBEDE3CC09'),
      ),
      Fq(
        q,
        BigInt.parse(
            '0x135203E60180A68EE2E9C448D77A2CD91C3DEDD930B1CF60EF396489F61EB45E304466CF3E67FA0AF1EE7B04121BDEA2'),
      ),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 10, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
            '0x1A0111EA397FE699EC02408663D4DE85AA0D857D89759AD4897D29650FB85F9B409427EB4F49FFFD8BFD00000000AAAD'),
      ),
      Fq(q, BigInt.zero),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 11, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
            '0x5B2CFD9013A5FD8DF47FA6B48B1E045F39816240C0B8FEE8BEADF4D8E9C0566C63A3E6E257F87329B18FAE980078116'),
      ),
      Fq(
        q,
        BigInt.parse(
            '0x144E4211384586C16BD3AD4AFA99CC9170DF3560E77982D0DB45F3536814F0BD5871C1908BD478CD1EE605167FF82995'),
      ),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
};

Field getFrobCoeff(List<int> key) {
  for (var item in frobCoeffs.entries) {
    if (listsEqual(item.key, key)) {
      return item.value;
    }
  }
  throw StateError('Unknown frob coeff');
}

abstract class FieldExtBase implements Field {
  @override
  abstract int extension;
  abstract int embedding;
  abstract Field root;

  late List<Field> elements;
  late Field basefield;

  @override
  BigInt Q;

  FieldExtBase(this.Q, this.elements) {
    if (elements.length != embedding) {
      throw ArgumentError('Expected $embedding elements.');
    }
    var childExtension = extension ~/ embedding;
    for (var item in elements) {
      if (item.extension != childExtension) {
        throw ArgumentError('Expected extension of $childExtension.');
      }
    }
    basefield = elements[0];
  }

  FieldExtBase construct(BigInt Q, List<Field> args);

  @override
  bool toBool() =>
      !elements.map((element) => element.toBool()).toList().contains(false);

  @override
  FieldExtBase operator -() {
    var result = construct(Q, elements.map((element) => -element).toList());
    result.root = root;
    return result;
  }

  @override
  FieldExtBase add(other) {
    dynamic otherNew;
    if (other.runtimeType != runtimeType) {
      if (other is! BigInt && other.extension > extension) {
        throw FailedOp();
      }
      otherNew = elements.map((element) => basefield.myZero(Q)).toList();
      otherNew[0] += other;
    } else {
      otherNew = other.elements;
    }
    var result = construct(
        Q,
        zip([elements, otherNew as List<Field>])
            .map((element) => element[0] + element[1])
            .toList());
    result.root = root;
    return result;
  }

  @override
  Field operator -(other) => this + -other;

  @override
  FieldExtBase multiply(other) {
    if (other is BigInt) {
      var result =
          construct(Q, elements.map((element) => element * other).toList());
      result.root = root;
      return result;
    }
    if (extension < other.extension) {
      throw FailedOp();
    }
    var buf = elements.map((_) => basefield.myZero(Q)).toList();
    for (var x in enumerate(elements)) {
      if (extension == other.extension) {
        for (IndexedValue<Field> y in enumerate(other.elements)) {
          if (x.value.toBool() && y.value.toBool()) {
            var i = (x.index + y.index) % embedding;
            if (x.index + y.index >= embedding) {
              buf[i] = buf[i] + x.value * y.value * root;
            } else {
              buf[i] = buf[i] + x.value * y.value;
            }
          }
        }
      } else if (x.value.toBool()) {
        buf[x.index] = x.value * other;
      }
    }
    var result = construct(Q, buf);
    result.root = root;
    return result;
  }

  @override
  Field operator ~/(other) => this * ~other;
  @override
  Field operator /(other) => this ~/ other;

  @override
  FieldExtBase operator +(other) {
    try {
      return add(other);
    } on FailedOp {
      return other.add(this);
    }
  }

  @override
  FieldExtBase operator *(other) {
    try {
      return multiply(other);
    } on FailedOp {
      return other.multiply(this);
    }
  }

  @override
  bool equal(other) {
    if (other.runtimeType != runtimeType) {
      if (other is FieldExtBase || other is BigInt) {
        if (other is! FieldExtBase || extension > other.extension) {
          for (var i in range(1, embedding)) {
            if (elements[i.toInt()] != root.myZero(Q)) {
              return false;
            }
          }
          return elements[0] == other;
        }
        throw FailedOp();
      }
      throw FailedOp();
    } else if (other is FieldExtBase) {
      return listsEqual(elements, other.elements) && Q == other.Q;
    } else {
      throw FailedOp();
    }
  }

  @override
  bool operator ==(other) {
    try {
      return equal(other);
    } on FailedOp {
      return (other as dynamic).equal(this);
    }
  }

  @override
  int get hashCode => hash4(extension, embedding, elements, Q);

  @override
  bool operator <(FieldExtBase other) {
    for (var item in zip([elements.reversed, other.elements.reversed])) {
      if (item[0] < item[1]) {
        return true;
      } else if (item[0] > item[1]) {
        return false;
      }
    }
    return false;
  }

  @override
  bool operator >(FieldExtBase other) {
    for (var item in zip([elements, other.elements])) {
      if (item[0] > item[1]) {
        return true;
      } else if (item[0] < item[1]) {
        return false;
      }
    }
    return false;
  }

  @override
  String toString() => 'Fq$extension(${elements.join(', ')})';

  @override
  Uint8List toBytes() {
    List<int> bytes = [];
    for (var item in elements.reversed) {
      bytes.addAll(item.toBytes());
    }
    return Uint8List.fromList(bytes);
  }

  @override
  String toHex() => HexEncoder().convert(toBytes());

  @override
  FieldExtBase myFromBytes(List<int> bytes, BigInt Q) {
    if (bytes.length != extension * 48) {
      throw ArgumentError('Invalid byte length.');
    }
    var embeddedSize = 48 * (extension ~/ embedding);
    List<List<int>> tup = [];
    for (var i in range(embedding)) {
      tup.add(bytes.sublist((i as int) * embeddedSize, (i + 1) * embeddedSize));
    }
    return construct(Q,
        tup.reversed.map((bytes) => basefield.myFromBytes(bytes, Q)).toList());
  }

  @override
  FieldExtBase myFromHex(String hex, BigInt Q) =>
      myFromBytes(HexDecoder().convert(hex), Q);

  @override
  FieldExtBase pow(BigInt exponent) {
    assert(exponent >= BigInt.zero);
    var result = myOne(Q);
    result.root = root;
    var base = this;
    while (exponent != BigInt.zero) {
      if (exponent & BigInt.one != BigInt.zero) {
        result = result * base;
      }
      base = base * base;
      exponent >>= 1;
    }
    return result;
  }

  @override
  FieldExtBase myZero(BigInt Q) => myFromFq(Q, Fq(Q, BigInt.zero));
  @override
  FieldExtBase myOne(BigInt Q) => myFromFq(Q, Fq(Q, BigInt.one));

  @override
  FieldExtBase myFromFq(BigInt Q, Fq fq) {
    var y = basefield.myFromFq(Q, fq);
    var z = basefield.myZero(Q);
    var result =
        construct(Q, range(embedding).map((i) => i == 0 ? y : z).toList());
    if (runtimeType == Fq2) {
      result.root = Fq(Q, -BigInt.one);
    } else if (runtimeType == Fq6) {
      result.root = Fq2(Q, [Fq.one(Q), Fq.one(Q)]);
    } else if (runtimeType == Fq12) {
      result.root = Fq6(Q, [Fq2.zero(Q), Fq2.one(Q), Fq2.zero(Q)]);
    }
    return result;
  }

  @override
  FieldExtBase clone() {
    var result =
        construct(Q, elements.map((element) => element.clone()).toList());
    result.root = root;
    return result;
  }

  @override
  FieldExtBase qiPower(int i) {
    if (Q != q) {
      throw FailedOp();
    }
    i %= extension;
    if (i == 0) {
      return this;
    }
    var items = enumerate(elements)
        .map((element) => element.index == 0
            ? element.value.qiPower(i)
            : element.value.qiPower(i) *
                getFrobCoeff([extension, i, element.index]))
        .toList();
    var result = construct(Q, items);
    result.root = root;
    return result;
  }
}

class Fq2 extends FieldExtBase {
  @override
  int extension = 2;
  @override
  int embedding = 2;
  @override
  Field root;

  Fq2(BigInt Q, List<Field> args)
      : root = Fq(Q, -BigInt.one),
        super(Q, args);

  Fq2.nil()
      : root = Fq.nil(),
        super(BigInt.zero, [Fq.nil(), Fq.nil()]);

  @override
  Fq2 operator ~() {
    var a = elements[0];
    var b = elements[1];
    var factor = ~(a * a + b * b);
    return Fq2(Q, [a * factor, -b * factor]);
  }

  Fq2 mulByNonResidue() {
    var a = elements[0];
    var b = elements[1];
    return Fq2(Q, [a - b, a + b]);
  }

  Fq2 modSqrt() {
    var a0 = elements[0];
    var a1 = elements[1];
    if (a1 == basefield.myOne(Q)) {
      return myFromFq(Q, (a0 as Fq).modSqrt()) as Fq2;
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
    var x0 = (delta as Fq).modSqrt();
    var x1 = a1 * ~(Fq(Q, BigInt.two) * x0);
    return Fq2(Q, [x0, x1]);
  }

  @override
  Fq2 construct(BigInt Q, List<Field> args) => Fq2(Q, args);

  factory Fq2.fromFq(BigInt Q, Fq fq) => Fq2.nil().myFromFq(Q, fq) as Fq2;
  factory Fq2.fromBytes(List<int> bytes, BigInt Q) =>
      Fq2.nil().myFromBytes(bytes, Q) as Fq2;
  factory Fq2.fromHex(String hex, BigInt Q) =>
      Fq2.nil().myFromHex(hex, Q) as Fq2;
  factory Fq2.zero(BigInt Q) => Fq2.nil().myZero(Q) as Fq2;
  factory Fq2.one(BigInt Q) => Fq2.nil().myOne(Q) as Fq2;
}

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

class Fq12 extends FieldExtBase {
  @override
  int extension = 12;
  @override
  int embedding = 2;
  @override
  Field root;

  Fq12(BigInt Q, List<Field> args)
      : root = Fq6(Q, [Fq2.zero(Q), Fq2.one(Q), Fq2.zero(Q)]),
        super(Q, args);

  Fq12.nil()
      : root = Fq6.nil(),
        super(BigInt.zero, [Fq6.nil(), Fq6.nil()]);

  @override
  Fq12 operator ~() {
    var a = elements[0];
    var b = elements[1];
    var factor = ~(a * a - (b * b as Fq6).mulByNonResidue());
    return Fq12(Q, [a * factor, -b * factor]);
  }

  @override
  Fq12 construct(BigInt Q, List<Field> args) => Fq12(Q, args);

  factory Fq12.fromFq(BigInt Q, Fq fq) => Fq12.nil().myFromFq(Q, fq) as Fq12;
  factory Fq12.fromBytes(List<int> bytes, BigInt Q) =>
      Fq12.nil().myFromBytes(bytes, Q) as Fq12;
  factory Fq12.fromHex(String hex, BigInt Q) =>
      Fq12.nil().myFromHex(hex, Q) as Fq12;
  factory Fq12.zero(BigInt Q) => Fq12.nil().myZero(Q) as Fq12;
  factory Fq12.one(BigInt Q) => Fq12.nil().myOne(Q) as Fq12;
}
