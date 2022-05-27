import 'package:chia_crypto_utils/src/core/models/spend_bundle.dart';

abstract class Transport {
  dynamic sendSpendBundle(SpendBundle spendBundle);
}
