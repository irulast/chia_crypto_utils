import 'dart:typed_data';

import 'package:chia_utils/src/bls/failed_op.dart';
import 'package:chia_utils/src/bls/field.dart';
import 'package:chia_utils/src/clvm/bytes.dart';
import 'package:quiver/core.dart';
import 'package:quiver/iterables.dart';

class Fq implements Field {
  @override
  BigInt Q;
  @override
  int extension = 1;

  BigInt value;

  Fq(this.Q, BigInt value) : value = value % Q;
  Fq.nil()
      : Q = BigInt.zero,
        value = BigInt.zero;

  @override
  Fq myFromBytes(Uint8List bytes, BigInt Q) {
    assert(bytes.length == 48);
    return Fq(Q, bytesToBigInt(bytes, Endian.big));
  }

  @override
  Field operator +(other) {
    try {
      return add(other);
    } on FailedOp {
      return other.add(this);
    }
  }

  @override
  Field operator *(other) {
    try {
      return multiply(other);
    } on FailedOp {
      return other.multiply(this);
    }
  }

  @override
  Fq operator -() => Fq(Q, -value);

  @override
  Field operator -(other) =>
      other is Fq ? Fq(Q, value - other.value) : this + -other;

  @override
  bool operator ==(Object other) => equal(other);

  @override
  int get hashCode => hash2(value, Q);

  @override
  bool operator <(Fq other) => value < other.value;

  @override
  bool operator >(Fq other) => value > other.value;

  bool operator <=(Fq other) => value <= other.value;

  bool operator >=(Fq other) => value >= other.value;

  @override
  Fq add(other) {
    if (other is! Fq) {
      throw FailedOp();
    }
    return Fq(Q, value + other.value);
  }

  @override
  Fq multiply(other) {
    if (other is! Fq) {
      throw FailedOp();
    }
    return Fq(Q, value * other.value);
  }

  @override
  bool equal(other) => other is Fq && value == other.value && Q == other.Q;

  @override
  String toString() {
    var hex = value.toRadixString(16);
    return 'Fq(0x${hex.length > 10 ? '${hex.substring(0, 5)}..${hex.substring(hex.length - 5, hex.length)}' : hex})';
  }

  @override
  Uint8List toBytes() => bigIntToBytes(value, 48, Endian.big);
  @override
  Fq pow(BigInt other) => other == BigInt.zero
      ? Fq(Q, BigInt.one)
      : other == BigInt.one
          ? Fq(Q, value)
          : other % BigInt.two == BigInt.zero
              ? Fq(Q, value * value).pow(other ~/ BigInt.two)
              : Fq(Q, value * value).pow(other ~/ BigInt.two) * this as Fq;
  @override
  Fq qiPower(int i) => this;

  @override
  Fq operator ~() {
    var x0 = BigInt.one, x1 = BigInt.zero, y0 = BigInt.zero, y1 = BigInt.one;
    var a = Q;
    var b = value;
    while (a != BigInt.zero) {
      var q = b ~/ a;
      var tempB = b;
      b = a;
      a = tempB % a;
      var tempX0 = x0;
      x0 = x1;
      x1 = tempX0 - q * x1;
      var tempY0 = y0;
      y0 = y1;
      y1 = tempY0 - q * y1;
    }
    return Fq(Q, x0);
  }

  @override
  Field operator ~/(other) {
    if (other is BigInt) {
      other = Fq(Q, other);
    } else if (other is! Fq) {
      throw ArgumentError('Can only divide by Fq or int objects.');
    }
    return this * ~(other as Fq);
  }

  @override
  Field operator /(other) => this ~/ other;

  Fq modSqrt() {
    if (value == BigInt.zero) {
      return Fq(Q, BigInt.zero);
    } else if (value.pow((Q.toInt() - 1) ~/ 2) % Q != BigInt.one) {
      throw ArgumentError('No sqrt exists.');
    } else if (Q.toInt() % 4 == 3) {
      return Fq(Q, value.pow((Q.toInt() + 1) ~/ 4) % Q);
    } else if (Q.toInt() % 8 == 5) {
      return Fq(Q, value.pow((Q.toInt() + 3) ~/ 8) % Q);
    }
    var S = BigInt.zero;
    var q = Q - BigInt.one;
    while (q.toInt() % 2 == 0) {
      q ~/= BigInt.two;
      S += BigInt.one;
    }
    var z = BigInt.zero;
    for (var i in range(Q.toInt())) {
      var euler = BigInt.from(i).pow((Q.toInt() - 1) ~/ 2) % Q;
      if (euler == BigInt.from(-1) % Q) {
        z = BigInt.from(i);
        break;
      }
    }
    var M = S;
    var c = z.pow(q.toInt()) % Q;
    var t = value.pow(q.toInt()) % Q;
    var R = value.pow((q.toInt() + 1) ~/ 2) % Q;
    while (true) {
      if (t == BigInt.zero) {
        return Fq(Q, BigInt.zero);
      } else if (t == BigInt.one) {
        return Fq(Q, R);
      }
      var i = BigInt.zero;
      var f = t;
      while (f != BigInt.one) {
        f = f.pow(2) % Q;
        i += BigInt.one;
      }
      var b =
          c.pow((BigInt.two.pow((M - i - BigInt.one).toInt()) % Q).toInt()) % Q;
      M = i;
      c = b.pow(2) % Q;
      t = (t * c) % Q;
      R = (R * b) % Q;
    }
  }

  @override
  Fq deepcopy() => Fq(Q, value);
  @override
  Fq myZero(BigInt Q) => Fq(Q, BigInt.zero);
  @override
  Fq myOne(BigInt Q) => Fq(Q, BigInt.one);
  @override
  Fq myFromFq(BigInt Q, Fq fq) => fq;
  @override
  bool toBool() => true;

  factory Fq.zero(BigInt Q) => Fq(Q, BigInt.zero);
  factory Fq.one(BigInt Q) => Fq(Q, BigInt.one);
  factory Fq.fromFq(BigInt Q, Fq fq) => fq;
  factory Fq.fromBytes(Uint8List bytes, BigInt Q) =>
      Fq.nil().myFromBytes(bytes, Q);
}
