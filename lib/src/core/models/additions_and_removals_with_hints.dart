import 'package:chia_crypto_utils/src/core/models/coin_with_hint.dart';

class AdditionsAndRemovalsWithHints {
  AdditionsAndRemovalsWithHints({
    required this.additions,
    required this.removals,
  });

  final List<CoinWithHint> additions;
  final List<CoinWithHint> removals;
}
