import 'dart:typed_data';

import 'package:chia_crypto_utils/src/bls/ec/jacobian_point.dart';
import 'package:chia_crypto_utils/src/bls/private_key.dart';
import 'package:chia_crypto_utils/src/clvm/bytes_utils.dart';
import 'package:chia_crypto_utils/src/clvm/cost.dart';
import 'package:chia_crypto_utils/src/clvm/keywords.dart';
import 'package:chia_crypto_utils/src/clvm/program.dart';
import 'package:crypto/crypto.dart';

typedef Operator = Output Function(Program args);

Map<BigInt, Operator> operators = {
  keywords['i']!: (args) {
    final list = args.toList(size: 3, suffix: 'in i');
    return Output(list[0].isNull ? list[2] : list[1], Cost.ifCost);
  },
  keywords['c']!: (args) {
    final list = args.toList(size: 2, suffix: 'in c');
    return Output(Program.cons(list[0], list[1]), Cost.consCost);
  },
  keywords['f']!: (args) {
    final list = args.toConsList(size: 1, suffix: 'in f');
    return Output(list[0].first(), Cost.firstCost);
  },
  keywords['r']!: (args) {
    final list = args.toConsList(size: 1, suffix: 'in r');
    return Output(list[0].rest(), Cost.restCost);
  },
  keywords['l']!: (args) {
    final list = args.toList(size: 1, suffix: 'in l');
    return Output(Program.fromBool(list[0].isCons), Cost.listpCost);
  },
  keywords['x']!: (args) {
    throw StateError('$args${args.positionSuffix}.');
  },
  keywords['=']!: (args) {
    final list = args.toAtomList(size: 2, suffix: 'in =');
    return Output(
      Program.fromBool(bytesEqual(list[0].atom, list[1].atom)),
      Cost.eqBaseCost +
          (BigInt.from(list[0].atom.length) + BigInt.from(list[1].atom.length)) *
              Cost.eqCostPerByte,
    );
  },
  keywords['sha256']!: (args) {
    final list = args.toAtomList(suffix: 'in sha256');
    var cost = Cost.sha256BaseCost;
    var argLength = 0;
    final bytes = <int>[];
    for (final arg in list) {
      bytes.addAll(arg.atom);
      argLength += arg.atom.length;
      cost += Cost.sha256CostPerArg;
    }
    cost += BigInt.from(argLength) * Cost.sha256CostPerByte;
    return mallocCost(Output(Program.fromBytes(sha256.convert(bytes).bytes), cost));
  },
  keywords['+']!: (args) {
    final list = args.toAtomList(suffix: 'in +');
    var total = BigInt.zero;
    var cost = Cost.arithBaseCost;
    var argSize = 0;
    for (final arg in list) {
      total += arg.toBigInt();
      argSize += arg.atom.length;
      cost += Cost.arithCostPerArg;
    }
    cost += BigInt.from(argSize) * Cost.arithCostPerByte;
    return mallocCost(Output(Program.fromBigInt(total), cost));
  },
  keywords['-']!: (args) {
    var cost = Cost.arithBaseCost;
    if (args.isNull) {
      return mallocCost(Output(Program.fromInt(0), cost));
    }
    final list = args.toAtomList(suffix: 'in -');
    var total = BigInt.zero;
    var sign = BigInt.one;
    var argSize = 0;
    for (final arg in list) {
      total += sign * arg.toBigInt();
      sign = -BigInt.one;
      argSize += arg.atom.length;
      cost += Cost.arithCostPerArg;
    }
    cost += BigInt.from(argSize) * Cost.arithCostPerByte;
    return mallocCost(Output(Program.fromBigInt(total), cost));
  },
  keywords['*']!: (args) {
    final list = args.toAtomList(suffix: 'in *');
    var cost = Cost.mulBaseCost;
    if (list.isEmpty) {
      return mallocCost(Output(Program.fromInt(1), cost));
    }
    var value = list[0].toBigInt();
    var size = list[0].atom.length;
    for (final arg in list.sublist(1)) {
      cost += Cost.mulCostPerOp +
          (BigInt.from(arg.atom.length) + BigInt.from(size)) * Cost.mulLinearCostPerByte +
          (BigInt.from(arg.atom.length) * BigInt.from(size)) ~/ Cost.mulSquareCostPerByteDivider;
      value *= arg.toBigInt();
      size = limbsForInt(value);
    }
    return mallocCost(Output(Program.fromBigInt(value), cost));
  },
  keywords['divmod']!: (args) {
    final list = args.toAtomList(size: 2, suffix: 'in divmod');
    var cost = Cost.divmodBaseCost;
    final numerator = list[0].toBigInt();
    final denominator = list[1].toBigInt();
    if (denominator == BigInt.zero) {
      throw UnsupportedError('Dividing by zero');
    }
    cost += (BigInt.from(list[0].atom.length) + BigInt.from(list[1].atom.length)) *
        Cost.divmodCostPerByte;
    final positive = numerator.sign == denominator.sign;
    var quotientValue = numerator ~/ denominator;
    var remainderValue = numerator % denominator;
    if (!positive && remainderValue != BigInt.zero) {
      quotientValue -= BigInt.one;
    }
    if (denominator < BigInt.zero && remainderValue != BigInt.zero) {
      remainderValue += denominator;
    }
    final quotient = Program.fromBigInt(quotientValue);
    final remainder = Program.fromBigInt(remainderValue);
    cost += (BigInt.from(quotient.atom.length) + BigInt.from(remainder.atom.length)) *
        Cost.mallocCostPerByte;
    return Output(Program.cons(quotient, remainder), cost);
  },
  keywords['/']!: (args) {
    final list = args.toAtomList(size: 2, suffix: 'in /');
    var cost = Cost.divBaseCost;
    final numerator = list[0].toBigInt();
    final denominator = list[1].toBigInt();
    if (denominator == BigInt.zero) {
      throw UnsupportedError('Dividing by zero');
    }
    cost +=
        (BigInt.from(list[0].atom.length) + BigInt.from(list[1].atom.length)) * Cost.divCostPerByte;
    var quotientValue = numerator ~/ denominator;
    final remainderValue = numerator % denominator;
    if (numerator.sign != denominator.sign && remainderValue != BigInt.zero) {
      quotientValue -= BigInt.one;
    }
    final quotient = Program.fromBigInt(quotientValue);
    return mallocCost(Output(quotient, cost));
  },
  keywords['>']!: (args) {
    final list = args.toAtomList(size: 2, suffix: 'in >');
    var cost = Cost.grBaseCost;
    cost +=
        (BigInt.from(list[0].atom.length) + BigInt.from(list[1].atom.length)) * Cost.grCostPerByte;
    final result = Output(Program.fromBool(list[0].toBigInt() > list[1].toBigInt()), cost);
    return result;
  },
  keywords['>s']!: (args) {
    final list = args.toAtomList(size: 2, suffix: 'in >s');
    final cost = Cost.grsBaseCost +
        (BigInt.from(list[0].atom.length) + BigInt.from(list[1].atom.length)) * Cost.grsCostPerByte;
    return Output(Program.fromBool(list[0].toHex().compareTo(list[1].toHex()) == 1), cost);
  },
  keywords['pubkey_for_exp']!: (args) {
    final list = args.toAtomList(size: 1, suffix: 'in pubkey_for_exp');
    final value = list[0].toBigInt() %
        BigInt.parse('0x73EDA753299D7D483339D80809A1D80553BDA402FFFE5BFEFFFFFFFF00000001');
    final exponent = PrivateKey.fromBytes(bigIntToBytes(value, 32, Endian.big));
    var cost = Cost.pubkeyBaseCost;
    cost += BigInt.from(list[0].atom.length) * Cost.pubkeyCostPerByte;
    return mallocCost(Output(Program.fromBytes(exponent.getG1().toBytes()), cost));
  },
  keywords['point_add']!: (args) {
    var cost = Cost.pointAddBaseCost;
    var p = JacobianPoint.infinityG1();
    for (final item in args.toAtomList(suffix: 'in point_add')) {
      p += JacobianPoint.fromBytes(item.atom, false);
      cost += Cost.pointAddCostPerArg;
    }
    return mallocCost(Output(Program.fromBytes(p.toBytes()), cost));
  },
  keywords['strlen']!: (args) {
    final list = args.toAtomList(size: 1, suffix: 'in strlen');
    final size = list[0].atom.length;
    final cost = Cost.strlenBaseCost + BigInt.from(size) * Cost.strlenCostPerByte;
    return mallocCost(Output(Program.fromInt(size), cost));
  },
  keywords['substr']!: (args) {
    final list = args.toAtomList(min: 2, max: 3, suffix: 'in substr');
    final str = list[0].atom;
    if (list[1].atom.length > 4 || (list.length == 3 && list[2].atom.length > 4)) {
      throw ArgumentError('Expected 4 byte indices for substr.');
    }
    final from = list[1].toInt();
    final to = list.length == 3 ? list[2].toInt() : str.length;
    if (to > str.length || to < from || to < 0 || from < 0) {
      throw ArgumentError('Invalid indices for substr.');
    }
    return Output(Program.fromBytes(str.sublist(from, to)), BigInt.one);
  },
  keywords['concat']!: (args) {
    var cost = Cost.concatBaseCost;
    final bytes = <int>[];
    for (final item in args.toAtomList(suffix: 'in concat')) {
      bytes.addAll(item.atom);
      cost += Cost.concatCostPerArg;
    }
    cost += BigInt.from(bytes.length) * Cost.concatCostPerByte;
    return mallocCost(Output(Program.fromBytes(bytes), cost));
  },
  keywords['ash']!: (args) {
    final list = args.toAtomList(size: 2, suffix: 'in ash');
    var value = list[0].toBigInt();
    final shift = list[1].toInt();
    if (list[1].atom.length > 4) {
      throw ArgumentError('Shift must be 32 bits.');
    }
    if (shift.abs() > 65535) {
      throw ArgumentError('Shift too large.');
    }
    if (shift >= 0) {
      value <<= shift;
    } else {
      value >>= -shift;
    }
    final cost = Cost.ashiftBaseCost +
        (BigInt.from(list[0].atom.length) + BigInt.from(limbsForInt(value))) *
            Cost.ashiftCostPerByte;
    return mallocCost(Output(Program.fromBigInt(value), cost));
  },
  keywords['lsh']!: (args) {
    final list = args.toAtomList(size: 2, suffix: 'in ash');
    final shift = list[1].toInt();
    if (list[1].atom.length > 4) {
      throw ArgumentError('Shift must be 32 bits.');
    }
    if (shift.abs() > 65535) {
      throw ArgumentError('Shift too large.');
    }
    var value = bytesToBigInt(list[0].atom, Endian.big).abs();
    if (shift >= 0) {
      value <<= shift;
    } else {
      value >>= -shift;
    }
    final cost = Cost.lshiftBaseCost +
        (BigInt.from(list[0].atom.length) + BigInt.from(limbsForInt(value))) *
            Cost.lshiftCostPerByte;
    return mallocCost(Output(Program.fromBigInt(value), cost));
  },
  keywords['logand']!: (args) => binopReduction('logand', -BigInt.one, args, (a, b) => a & b),
  keywords['logior']!: (args) => binopReduction('logior', BigInt.zero, args, (a, b) => a | b),
  keywords['logxor']!: (args) => binopReduction('logxor', BigInt.zero, args, (a, b) => a ^ b),
  keywords['lognot']!: (args) {
    final items = args.toAtomList(size: 1, suffix: 'in lognot');
    final cost = Cost.lognotBaseCost + BigInt.from(items[0].atom.length) * Cost.lognotCostPerByte;
    return mallocCost(Output(Program.fromBigInt(~items[0].toBigInt()), cost));
  },
  keywords['not']!: (args) {
    final items = args.toList(size: 1, suffix: 'in not');
    final cost = Cost.boolBaseCost;
    return Output(Program.fromBool(items[0].isNull), cost);
  },
  keywords['any']!: (args) {
    final items = args.toList(suffix: 'in any');
    final cost = Cost.boolBaseCost + BigInt.from(items.length) * Cost.boolCostPerArg;
    var result = false;
    for (final value in items) {
      if (!value.isNull) {
        result = true;
        break;
      }
    }
    return Output(Program.fromBool(result), cost);
  },
  keywords['all']!: (args) {
    final items = args.toList(suffix: 'in all');
    final cost = Cost.boolBaseCost + BigInt.from(items.length) * Cost.boolCostPerArg;
    var result = true;
    for (final value in items) {
      if (value.isNull) {
        result = false;
        break;
      }
    }
    return Output(Program.fromBool(result), cost);
  },
  keywords['softfork']!: (args) {
    final list = args.toList(min: 1, suffix: 'in softfork');
    if (list[0].isCons) {
      throw ArgumentError('Expected atom argument in softfork.');
    }
    final cost = list[0].toBigInt();
    if (cost < BigInt.one) {
      throw ArgumentError('Cost must be greater than zero.');
    }
    return Output(Program.fromBool(false), cost);
  }
};

Output binopReduction(
  String opName,
  BigInt initialValue,
  Program args,
  BigInt Function(BigInt, BigInt) opFunction,
) {
  var total = initialValue;
  var argSize = 0;
  var cost = Cost.logBaseCost;
  for (final item in args.toAtomList(suffix: 'in $opName')) {
    total = opFunction(total, item.toBigInt());
    argSize += item.atom.length;
    cost += Cost.logCostPerArg;
  }
  cost += BigInt.from(argSize) * Cost.logCostPerByte;
  return mallocCost(Output(Program.fromBigInt(total), cost));
}

Output mallocCost(Output output) {
  return Output(
    output.program,
    output.cost + BigInt.from(output.program.atom.length) * Cost.mallocCostPerByte,
  );
}

int limbsForInt(BigInt value) {
  return (value.bitLength + 7) >> 3;
}

Output runOperator(Program op, Program args, RunOptions options) {
  final value = op.toBigInt();
  if (operators.containsKey(value)) {
    return operators[value]!(args);
  }
  if (options.strict) {
    throw StateError('Unknown operator.');
  }
  if (op.atom.isEmpty || bytesEqual(op.atom.sublist(0, 2), [0xff, 0xff])) {
    throw StateError('Reserved operator.');
  }
  if (op.atom.length > 5) {
    throw StateError('Invalid operator.');
  }
  final costFunction = (op.atom[op.atom.length - 1] & 0xc0) >> 6;
  final costMultiplier = bytesToInt(op.atom.sublist(0, op.atom.length - 1), Endian.big) + 1;
  BigInt cost;
  if (costFunction == 0) {
    cost = BigInt.one;
  } else if (costFunction == 1) {
    cost = Cost.arithBaseCost;
    var argSize = 0;
    for (final arg in args.toList()) {
      if (arg.isCons) {
        throw StateError('Expected int arguments.');
      }
      argSize += arg.atom.length;
      cost += Cost.arithCostPerArg;
    }
    cost += BigInt.from(argSize) * Cost.arithCostPerByte;
  } else if (costFunction == 2) {
    cost = Cost.mulBaseCost;
    final argList = args.toList();
    if (argList.isNotEmpty) {
      final first = argList[0];
      if (first.isCons) {
        throw StateError('Expected int arguments.');
      }
      var current = first.atom.length;
      for (final item in argList.sublist(1)) {
        if (item.isCons) {
          throw StateError('Expected int arguments.');
        }
        cost += Cost.mulCostPerOp +
            (BigInt.from(item.atom.length) + BigInt.from(current)) * Cost.mulLinearCostPerByte +
            (BigInt.from(item.atom.length) * BigInt.from(current)) ~/
                Cost.mulSquareCostPerByteDivider;
        current += item.atom.length;
      }
    }
  } else if (costFunction == 3) {
    cost = Cost.concatBaseCost;
    var length = 0;
    for (final arg in args.toList()) {
      if (arg.isCons) {
        throw StateError('Unknown op on list.');
      }
      cost += Cost.concatCostPerArg;
      length += arg.atom.length;
    }
    cost += BigInt.from(length) * Cost.concatCostPerByte;
  } else {
    throw StateError('Unknown cost function.');
  }
  cost *= BigInt.from(costMultiplier);
  if (cost >= BigInt.two.pow(32)) {
    throw StateError('Invalid operator.');
  }
  return Output(Program.nil, cost);
}
