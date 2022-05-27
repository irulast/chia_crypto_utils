import 'package:chia_crypto_utils/chia_crypto_utils.dart';

abstract class Condition {
  Program get program;
}

typedef ConditionChecker<T> = bool Function(Program program);
typedef ConditionFromProgramConstructor<T> = T Function(Program program);
