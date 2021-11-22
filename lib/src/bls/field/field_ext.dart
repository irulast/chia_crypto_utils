import 'dart:typed_data';

import 'package:chia_utils/src/bls/bls12381.dart';
import 'package:chia_utils/src/bls/failed_op.dart';
import 'package:chia_utils/src/bls/field/extensions/fq12.dart';
import 'package:chia_utils/src/bls/field/extensions/fq2.dart';
import 'package:chia_utils/src/bls/field/extensions/fq6.dart';
import 'package:chia_utils/src/bls/field/field.dart';
import 'package:chia_utils/src/bls/field/field_base.dart';
import 'package:chia_utils/src/bls/field/field_constants.dart';
import 'package:hex/hex.dart';
import 'package:quiver/collection.dart';
import 'package:quiver/core.dart';
import 'package:quiver/iterables.dart';

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
