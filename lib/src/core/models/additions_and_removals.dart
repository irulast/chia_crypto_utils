import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class AdditionsAndRemovals {
  AdditionsAndRemovals({
   required this.additions,
   required this.removals,
  });

  final List<Coin> additions;
  final List<Coin> removals;
}
