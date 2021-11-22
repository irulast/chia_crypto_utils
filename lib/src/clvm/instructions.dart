import 'package:chia_utils/src/clvm/bytes.dart';
import 'package:chia_utils/src/clvm/cost.dart';
import 'package:chia_utils/src/clvm/environment.dart';
import 'package:chia_utils/src/clvm/keywords.dart';
import 'package:chia_utils/src/clvm/operators.dart';
import 'package:chia_utils/src/clvm/program.dart';

BigInt swap(
    List<dynamic> instructions, List<Program> stack, RunOptions options) {
  var second = stack.removeLast();
  var first = stack.removeLast();
  stack.add(second);
  stack.add(first);
  return BigInt.zero;
}

BigInt cons(
    List<dynamic> instructions, List<Program> stack, RunOptions options) {
  var first = stack.removeLast();
  var second = stack.removeLast();
  stack.add(Program.cons(first, second));
  return BigInt.zero;
}

BigInt eval(
    List<dynamic> instructions, List<Program> stack, RunOptions options) {
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
  return BigInt.one;
}

BigInt apply(
    List<dynamic> instructions, List<Program> stack, RunOptions options) {
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
  var output = runOperator(op, operandList, options);
  stack.add(output.program);
  return output.cost;
}
