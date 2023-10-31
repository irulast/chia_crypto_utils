import 'package:chia_crypto_utils/chia_crypto_utils.dart';

abstract class Transport {
  dynamic sendSpendBundle(SpendBundle spendBundle);
}
