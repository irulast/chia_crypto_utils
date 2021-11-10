import 'package:chia_utils/chia_utils.dart';
import 'package:chia_utils/src/clvm.dart';
import 'package:chia_utils/src/clvm/bytes.dart';
import 'package:chia_utils/src/clvm/cost.dart';
import 'package:chia_utils/src/clvm/environment.dart';
import 'package:chia_utils/src/clvm/keywords.dart';
import 'package:chia_utils/src/clvm/operators.dart';

int swap(List<dynamic> instructions, List<Program> stack) {
  var second = stack.removeLast();
  var first = stack.removeLast();
  stack.add(second);
  stack.add(first);
  return 0;
}

int cons(List<dynamic> instructions, List<Program> stack) {
  var first = stack.removeLast();
  var second = stack.removeLast();
  stack.add(Program.cons(first, second));
  return 0;
}

int eval(List<dynamic> instructions, List<Program> stack) {
  var pair = stack.removeLast();
  var program = pair.first();
  var args = pair.rest();
  if (program.isAtom) {
    var output = traversePath(program, args);
    stack.add(output.program);
    return output.cost;
  }
  var op = program.first();
  if (op.isCons) {
    var newOperator = op.first();
    var mustBeNil = op.rest();
    if (newOperator.isCons || !mustBeNil.isNull) {
      throw StateError(
          'Operators that are lists must contain a single atom${op.positionSuffix}');
    }
    var newOperandList = program.rest();
    stack.add(newOperator);
    stack.add(newOperandList);
    instructions.add(apply);
    return Cost.applyCost;
  }
  var operandList = program.rest();
  if (bytesEqual(op.atom, encodeBigInt(keywords['q']!))) {
    stack.add(operandList);
    return Cost.quoteCost;
  }
  instructions.add(apply);
  stack.add(op);
  while (!operandList.isNull) {
    stack.add(Program.cons(operandList.first(), args));
    instructions.add(cons);
    instructions.add(eval);
    instructions.add(swap);
    operandList = operandList.rest();
  }
  stack.add(Program.nil());
  return 1;
}

int apply(List<dynamic> instructions, List<Program> stack) {
  var operandList = stack.removeLast();
  var op = stack.removeLast();
  if (op.isCons) {
    throw StateError('An internal error occurred${op.positionSuffix}');
  }
  if (bytesEqual(op.atom, encodeBigInt(keywords['a']!))) {
    var args = operandList.toList(size: 2);
    stack.add(Program.cons(args[0], args[1]));
    instructions.add(eval);
    return Cost.applyCost;
  }
  var output = runOperator(op, operandList);
  stack.add(output.program);
  return output.cost;
}
