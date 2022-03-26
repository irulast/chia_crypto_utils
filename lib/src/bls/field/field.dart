import 'dart:typed_data';

import 'package:chia_utils/src/bls/field/field_base.dart';
import 'package:meta/meta.dart';

@immutable
abstract class Field {
  const Field(this.Q, {required this.extension});

  final BigInt Q;
  final int extension;

  Field operator -();
  Field operator ~();
  Field operator +(dynamic other);
  Field operator -(dynamic other);
  Field operator *(dynamic other);
  Field operator ~/(dynamic other);
  Field operator /(dynamic other);
  bool operator <(covariant dynamic other);
  bool operator >(covariant dynamic other);

  Field add(dynamic other);
  Field multiply(dynamic other);
  bool equal(dynamic other);

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
