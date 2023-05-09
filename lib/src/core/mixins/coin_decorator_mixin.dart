import 'package:chia_crypto_utils/chia_crypto_utils.dart';

mixin CoinFieldsDecoratorMixin implements Coin {
  Coin get delegate;
  @override
  int get confirmedBlockIndex => delegate.confirmedBlockIndex;
  @override
  int get spentBlockIndex => delegate.spentBlockIndex;
  @override
  bool get coinbase => delegate.coinbase;
  @override
  int get timestamp => delegate.timestamp;

  @override
  Map<String, dynamic> toFullJson() => delegate.toFullJson();
}
