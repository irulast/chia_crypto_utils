import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class Attestment {
  Attestment({
    required this.attestmentSpendBundle,
    required this.messageSpendBundle,
  });
  SpendBundle messageSpendBundle;
  SpendBundle attestmentSpendBundle;
}
