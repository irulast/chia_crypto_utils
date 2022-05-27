import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/bls/bls12381.dart';
import 'package:chia_crypto_utils/src/bls/failed_op.dart';
import 'package:chia_crypto_utils/src/bls/field/field_constants.dart';
import 'package:hex/hex.dart';
import 'package:quiver/collection.dart';
import 'package:quiver/core.dart';
import 'package:quiver/iterables.dart';

abstract class FieldExtBase<F extends FieldExtBase<F>> extends Field {
  FieldExtBase(
    BigInt Q,
    this.elements, {
    required this.root,
    required int extension,
    required this.embedding,
  })  : basefield = elements[0],
        super(Q, extension: extension) {
    if (elements.length != embedding) {
      throw ArgumentError('Expected $embedding elements.');
    }
    final childExtension = extension ~/ embedding;
    for (final item in elements) {
      if (item.extension != childExtension) {
        throw ArgumentError('Expected extension of $childExtension.');
      }
    }
  }

  final int embedding;
  final Field root;

  final List<Field> elements;
  final Field basefield;

  F construct(BigInt Q, List<Field> args, Field? root);

  @override
  bool toBool() => elements.every((element) => element.toBool());

  @override
  F operator -() {
    return construct(Q, elements.map((element) => -element).toList(), root);
  }

  @override
  F add(dynamic other) {
    List<Field> otherNew;

    if (other is FieldExtBase) {
      if (other.extension > extension) throw FailedOp();
      otherNew = other.elements;
    } else {
      otherNew = elements.map((element) => basefield.myZero(Q)).toList();
      otherNew[0] += other;
    }

    return construct(
      Q,
      zip([elements, otherNew]).map((element) => element[0] + element[1]).toList(),
      root,
    );
  }

  @override
  Field operator -(dynamic other) {
    if (other is BigInt) return this + -other;
    if (other is Field) return this + -other;
    throw FailedOp();
  }

  @override
  F multiply(dynamic other) {
    if (other is BigInt) {
      return construct(
        Q,
        elements.map((element) => element * other).toList(),
        root,
      );
    }

    if (other is! Field) throw FailedOp();
    if (extension < other.extension) throw FailedOp();

    final buf = elements.map((_) => basefield.myZero(Q)).toList();
    for (final x in enumerate(elements)) {
      if (other is FieldExtBase && extension == other.extension) {
        for (final y in enumerate(other.elements)) {
          if (x.value.toBool() && y.value.toBool()) {
            final i = (x.index + y.index) % embedding;
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
    return construct(Q, buf, root);
  }

  @override
  Field operator ~/(dynamic other) {
    if (other is BigInt) return this * ~other;
    if (other is Field) return this * ~other;
    throw FailedOp();
  }

  @override
  Field operator /(dynamic other) => this ~/ other;

  @override
  FieldExtBase<dynamic> operator +(dynamic other) {
    try {
      return add(other);
    } on FailedOp {
      if (other is! FieldExtBase) rethrow;
      return other.add(this);
    }
  }

  @override
  FieldExtBase<dynamic> operator *(dynamic other) {
    try {
      return multiply(other);
    } on FailedOp {
      if (other is! FieldExtBase) rethrow;
      return other.multiply(this);
    }
  }

  @override
  bool equal(dynamic other) {
    if (other.runtimeType != runtimeType) {
      if (other is FieldExtBase || other is BigInt) {
        if (other is! FieldExtBase || extension > other.extension) {
          for (final i in range(1, embedding)) {
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
  bool operator ==(dynamic other) {
    try {
      return equal(other);
    } on FailedOp {
      if (other is! Field) return false;
      return other.equal(this);
    }
  }

  @override
  int get hashCode => hash4(extension, embedding, elements, Q);

  @override
  bool operator <(FieldExtBase other) {
    for (final item in zip([elements.reversed, other.elements.reversed])) {
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
    for (final item in zip([elements, other.elements])) {
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
  Bytes toBytes() {
    return Bytes([
      for (final item in elements.reversed) ...item.toBytes(),
    ]);
  }

  @override
  String toHex() => const HexEncoder().convert(toBytes());

  @override
  FieldExtBase myFromBytes(List<int> bytes, BigInt Q) {
    if (bytes.length != extension * 48) {
      throw ArgumentError('Invalid byte length.');
    }
    final embeddedSize = 48 * (extension ~/ embedding);
    final tup = <List<int>>[];
    for (final i in range(embedding)) {
      tup.add(bytes.sublist((i as int) * embeddedSize, (i + 1) * embeddedSize));
    }
    return construct(
      Q,
      tup.reversed.map((bytes) => basefield.myFromBytes(bytes, Q)).toList(),
      null,
    );
  }

  @override
  FieldExtBase myFromHex(String hex, BigInt Q) => myFromBytes(const HexDecoder().convert(hex), Q);

  @override
  F pow(BigInt exponent) {
    assert(
      exponent >= BigInt.zero,
      'exponent must non-negative',
    );
    var _exponent = exponent;
    var result = myOne(Q, root);
    var base = this as F;
    while (_exponent != BigInt.zero) {
      if (_exponent & BigInt.one != BigInt.zero) {
        result = result * base as F;
      }
      base = base * base as F;
      _exponent >>= 1;
    }
    return result;
  }

  @override
  F myZero(BigInt Q) => myFromFq(Q, Fq(Q, BigInt.zero));
  @override
  F myOne(BigInt Q, [Field? root]) => myFromFq(Q, Fq(Q, BigInt.one), root);

  @override
  F myFromFq(BigInt Q, Fq fq, [Field? root]) {
    final y = basefield.myFromFq(Q, fq);
    final z = basefield.myZero(Q);

    final _root = () {
      if (root != null) {
        return root;
      }
      if (runtimeType == Fq2) {
        return Fq(Q, -BigInt.one);
      } else if (runtimeType == Fq6) {
        return Fq2(Q, [Fq.one(Q), Fq.one(Q)]);
      } else if (runtimeType == Fq12) {
        return Fq6(Q, [Fq2.zero(Q), Fq2.one(Q), Fq2.zero(Q)]);
      }
      return null;
    }();

    return construct(
      Q,
      range(embedding).map((i) => i == 0 ? y : z).toList(),
      _root,
    );
  }

  @override
  F clone() {
    return construct(
      Q,
      elements.map((element) => element.clone()).toList(),
      root,
    );
  }

  @override
  F qiPower(int i) {
    if (Q != q) {
      throw FailedOp();
    }

    final _i = i % extension;
    if (_i == 0) {
      return this as F;
    }
    final items = enumerate(elements)
        .map(
          (element) => element.index == 0
              ? element.value.qiPower(_i)
              : element.value.qiPower(_i) * getFrobCoeff([extension, _i, element.index]),
        )
        .toList();
    return construct(Q, items, root);
  }
}
