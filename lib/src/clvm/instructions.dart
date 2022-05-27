import 'package:chia_crypto_utils/src/clvm/bytes_utils.dart';
import 'package:chia_crypto_utils/src/clvm/cost.dart';
import 'package:chia_crypto_utils/src/clvm/environment.dart';
import 'package:chia_crypto_utils/src/clvm/keywords.dart';
import 'package:chia_crypto_utils/src/clvm/operators.dart';
import 'package:chia_crypto_utils/src/clvm/program.dart';

/// An [Instruction] describe the interface for functions like:
/// - [swap]
/// - [cons]
/// - [eval]
/// - [apply]
typedef Instruction = BigInt Function(
  List<dynamic> instructions,
  List<Program> stack,
  RunOptions options,
);

BigInt swap(
  List<dynamic> instructions,
  List<Program> stack,
  RunOptions options,
) {
  final second = stack.removeLast();
  final first = stack.removeLast();
  stack
    ..add(second)
    ..add(first);
  return BigInt.zero;
}

BigInt cons(
  List<dynamic> instructions,
  List<Program> stack,
  RunOptions options,
) {
  final first = stack.removeLast();
  final second = stack.removeLast();
  stack.add(Program.cons(first, second));
  return BigInt.zero;
}

BigInt eval(
  List<dynamic> instructions,
  List<Program> stack,
  RunOptions options,
) {
  final pair = stack.removeLast();
  final program = pair.first();
  final args = pair.rest();
  if (program.isAtom) {
    final output = traversePath(program, args);
    stack.add(output.program);
    return output.cost;
  }
  final op = program.first();
  if (op.isCons) {
    final newOperator = op.first();
    final mustBeNil = op.rest();
    if (newOperator.isCons || !mustBeNil.isNull) {
      throw StateError(
        'Operators that are lists must contain a '
        'single atom${op.positionSuffix}.',
      );
    }
    final newOperandList = program.rest();
    stack
      ..add(newOperator)
      ..add(newOperandList);
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
    instructions
      ..add(cons)
      ..add(eval)
      ..add(swap);
    operandList = operandList.rest();
  }
  stack.add(Program.nil);
  return BigInt.one;
}

BigInt apply(
  List<dynamic> instructions,
  List<Program> stack,
  RunOptions options,
) {
  final operandList = stack.removeLast();
  final op = stack.removeLast();
  if (op.isCons) {
    throw StateError('An internal error occurred${op.positionSuffix}.');
  }
  if (bytesEqual(op.atom, encodeBigInt(keywords['a']!))) {
    final args = operandList.toList(size: 2);
    stack.add(Program.cons(args[0], args[1]));
    instructions.add(eval);
    return Cost.applyCost;
  }
  final output = runOperator(op, operandList, options);
  stack.add(output.program);
  return output.cost;
}
