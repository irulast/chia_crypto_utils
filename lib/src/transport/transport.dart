import 'package:chia_utils/src/core/models/spend_bundle.dart';

abstract class Transport {
  sendSpendBundle(SpendBundle spendBundle);
}
