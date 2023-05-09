import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:deep_pick/deep_pick.dart';

class CoinPrototypeWithParentSpend with CoinPrototypeDecoratorMixin implements CoinPrototype {
  CoinPrototypeWithParentSpend({
    required this.delegate,
    required this.parentSpend,
  });

  @override
  final CoinPrototype delegate;

  factory CoinPrototypeWithParentSpend.fromCoin(CoinPrototype coin, CoinSpend parentSpend) {
    return CoinPrototypeWithParentSpend(
      delegate: coin,
      parentSpend: parentSpend,
    );
  }

  final CoinSpend? parentSpend;
}

class CoinWithParentSpend with CoinPrototypeDecoratorMixin implements Coin {
  CoinWithParentSpend({
    required this.delegate,
    required this.parentSpend,
  });

  @override
  final Coin delegate;

  factory CoinWithParentSpend.fromCoin(Coin coin, CoinSpend? parentSpend) {
    return CoinWithParentSpend(
      delegate: coin,
      parentSpend: parentSpend,
    );
  }

  factory CoinWithParentSpend.fromJson(Map<String, dynamic> json) {
    final coin = Coin.fromJson(json);

    final parentSpend = pick(json, 'parent_coin_spend').letJsonOrNull(CoinSpend.fromJson);

    return CoinWithParentSpend.fromCoin(coin, parentSpend);
  }

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
