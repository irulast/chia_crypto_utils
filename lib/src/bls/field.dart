import 'dart:typed_data';

import 'package:chia_utils/src/bls/field_base.dart';

abstract class Field {
  abstract BigInt Q;
  abstract int extension;

  Field operator -();
  Field operator ~();
  Field operator +(other);
  Field operator -(other);
  Field operator *(other);
  Field operator ~/(other);
  Field operator /(other);
  bool operator <(covariant other);
  bool operator >(covariant other);

  Field add(other);
  Field multiply(other);
  bool equal(other);

  Uint8List toBytes();
  String toHex();
  bool toBool();
  Field pow(BigInt exponent);
  Field myZero(BigInt Q);
  Field myOne(BigInt Q);
  Field myFromFq(BigInt Q, Fq fq);
  Field myFromBytes(List<int> bytes, BigInt Q);
  Field myFromHex(String hex, BigInt Q);
  Field clone();
  Field qiPower(int i);

  @override
  bool operator ==(Object other);
  @override
  int get hashCode;
  @override
  String toString();
}
