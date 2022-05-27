import 'package:chia_crypto_utils/src/bls/field/field_base.dart';
import 'package:chia_crypto_utils/src/utils/to_bytes_mixin.dart';
import 'package:meta/meta.dart';

@immutable
abstract class Field with ToBytesMixin {
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
