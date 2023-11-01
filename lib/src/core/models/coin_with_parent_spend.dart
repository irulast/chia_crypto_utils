import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class CoinPrototypeWithParentSpend with CoinPrototypeDecoratorMixin implements CoinPrototype {
  CoinPrototypeWithParentSpend({
    required this.delegate,
    required this.parentSpend,
  });

  factory CoinPrototypeWithParentSpend.fromCoin(CoinPrototype coin, CoinSpend parentSpend) {
    return CoinPrototypeWithParentSpend(
      delegate: coin,
      parentSpend: parentSpend,
    );
  }

  @override
  final CoinPrototype delegate;

  final CoinSpend? parentSpend;
}

class CoinWithParentSpend with CoinPrototypeDecoratorMixin implements Coin {
  CoinWithParentSpend({
    required this.delegate,
    required this.parentSpend,
  });

  factory CoinWithParentSpend.fromJson(Map<String, dynamic> json) {
    final coin = Coin.fromJson(json);

    final parentSpend = pick(json, 'parent_coin_spend').letJsonOrNull(CoinSpend.fromJson);

    return CoinWithParentSpend.fromCoin(coin, parentSpend);
  }

  factory CoinWithParentSpend.fromCoin(Coin coin, CoinSpend? parentSpend) {
    return CoinWithParentSpend(
      delegate: coin,
      parentSpend: parentSpend,
    );
  }

  @override
  final Coin delegate;

  final CoinSpend? parentSpend;

  @override
  bool get coinbase => delegate.coinbase;

  @override
  int get confirmedBlockIndex => delegate.confirmedBlockIndex;

  @override
  int get spentBlockIndex => delegate.spentBlockIndex;

  @override
  int get timestamp => delegate.timestamp;

  @override
  Map<String, dynamic> toFullJson() {
    return {
      ...delegate.toFullJson(),
      'parent_coin_spend': parentSpend?.toJson(),
    };
  }
}
