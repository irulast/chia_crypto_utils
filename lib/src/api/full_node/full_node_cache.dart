import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

abstract class FullNodeCache {
  Future<void> addParentSpend(Bytes coinId, CoinSpend? callResult);

  FutureOr<CoinSpend?> getParentSpend(Bytes coinId);
}
