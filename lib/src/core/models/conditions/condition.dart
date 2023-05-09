import 'package:chia_crypto_utils/chia_crypto_utils.dart';

abstract class Condition implements ToProgramMixin {
  @override
  Program toProgram();
}

typedef ConditionChecker<T> = bool Function(Program program);
typedef ConditionFromProgramConstructor<T> = T Function(Program program);

extension ToProgram on Iterable<Condition> {
  Program toProgram() => Program.list(map((condition) => condition.toProgram()).toList());
}
