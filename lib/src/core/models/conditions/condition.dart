import 'package:chia_crypto_utils/chia_crypto_utils.dart';

abstract class Condition implements ToProgramMixin {
  int get code;
  @override
  Program toProgram();
}

typedef ConditionChecker<T> = bool Function(Program program);
typedef ConditionFromProgramConstructor<T> = T Function(Program program);

extension ToProgram on Iterable<Condition> {
  Program toProgram() =>
      Program.list(map((condition) => condition.toProgram()).toList());
}

extension ConditionArguments on Condition {
  List<Program> get arguments => toProgram().toList().sublist(1);
}

class GeneralCondition implements Condition {
  GeneralCondition(this.conditionProgram);

  final Program conditionProgram;

  @override
  int get code => conditionProgram.toList()[0].toInt();

  @override
  Program toProgram() {
    return conditionProgram;
  }
}
