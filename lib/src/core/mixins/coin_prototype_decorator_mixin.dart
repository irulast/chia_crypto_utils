import 'package:chia_crypto_utils/chia_crypto_utils.dart';

mixin CoinPrototypeDecoratorMixin implements CoinPrototype {
  CoinPrototype get delegate;
  @override
  int get amount => delegate.amount;

  @override
  Bytes get id => delegate.id;

  @override
  Bytes get parentCoinInfo => delegate.parentCoinInfo;

  @override
  Puzzlehash get puzzlehash => delegate.puzzlehash;

  @override
  Bytes toBytes() => delegate.toBytes();

  @override
  String toHex() => delegate.toHex();

  @override
  String toHexWithPrefix() => delegate.toHexWithPrefix();

  @override
  Map<String, dynamic> toJson() => delegate.toJson();

  @override
  Program toProgram() => delegate.toProgram();

  @override
  bool operator ==(Object other) => other is CoinPrototype && other.id == id;

  @override
  int get hashCode => id.toHex().hashCode;
}
