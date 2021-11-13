import 'dart:math';
import 'dart:typed_data';

import 'package:chia_utils/src/bls/private_key.dart';
import 'package:chia_utils/src/clvm/bytes.dart';
import 'package:chia_utils/src/clvm/cost.dart';
import 'package:chia_utils/src/clvm/keywords.dart';
import 'package:chia_utils/src/clvm/program.dart';
import 'package:crypto/crypto.dart';

typedef Operator = Output Function(Program args);

Map<BigInt, Operator> operators = {
  keywords['i']!: (args) {
    var list = args.toList(size: 3, suffix: 'in i');
    return Output(list[0].isNull ? list[2] : list[1], Cost.ifCost);
  },
  keywords['c']!: (args) {
    var list = args.toList(size: 2, suffix: 'in c');
    return Output(Program.cons(list[0], list[1]), Cost.consCost);
  },
  keywords['f']!: (args) {
    var list = args.toConsList(size: 1, suffix: 'in f');
    return Output(list[0].first(), Cost.firstCost);
  },
  keywords['r']!: (args) {
    var list = args.toConsList(size: 1, suffix: 'in r');
    return Output(list[0].rest(), Cost.restCost);
  },
  keywords['l']!: (args) {
    var list = args.toList(size: 1, suffix: 'in l');
    return Output(Program.bool(list[0].isCons), Cost.listpCost);
  },
  keywords['x']!: (args) {
    throw StateError('$args${args.positionSuffix}');
  },
  keywords['=']!: (args) {
    var list = args.toAtomList(size: 2, suffix: 'in =');
    return Output(
        Program.bool(bytesEqual(list[0].atom, list[1].atom)),
        Cost.eqBaseCost +
            (list[0].atom.length + list[1].atom.length) * Cost.eqCostPerByte);
  },
  keywords['sha256']!: (args) {
    var list = args.toAtomList(suffix: 'in sha256');
    var cost = Cost.sha256BaseCost;
    List<int> bytes = [];
    for (var arg in list) {
      if (arg.isCons) {
        throw StateError('Cannot perform sha256 on a list.');
      }
      bytes.addAll(arg.atom);
      cost += Cost.sha256CostPerArg;
    }
    cost += bytes.length * Cost.concatCostPerByte;
    return mallocCost(Output(
        Program.atom(Uint8List.fromList(sha256.convert(bytes).bytes)), cost));
  },
  keywords['+']!: (args) {
    var list = args.toAtomList(suffix: 'in +');
    var total = BigInt.zero;
    var cost = Cost.arithBaseCost;
    var argSize = 0;
    for (var arg in list) {
      total += arg.toBigInt();
      argSize += arg.atom.length;
      cost += Cost.arithCostPerArg;
    }
    cost += argSize * Cost.arithCostPerByte;
    return mallocCost(Output(Program.bigint(total), cost));
  },
  keywords['-']!: (args) {
    var list = args.toAtomList(suffix: 'in -');
    var total = BigInt.zero;
    var cost = Cost.arithBaseCost;
    var sign = BigInt.one;
    var argSize = 0;
    for (var arg in list) {
      total += sign * arg.toBigInt();
      sign = -BigInt.one;
      argSize += arg.atom.length;
      cost += Cost.arithCostPerArg;
    }
    cost += argSize * Cost.arithCostPerByte;
    return mallocCost(Output(Program.bigint(total), cost));
  },
  keywords['*']!: (args) {
    var list = args.toAtomList(suffix: 'in *');
    var cost = Cost.mulBaseCost;
    if (list.isEmpty) {
      return mallocCost(Output(Program.int(1), cost));
    }
    var value = list[0].toBigInt();
    var size = list[0].atom.length;
    for (var arg in list) {
      cost += Cost.mulCostPerOp +
          (arg.atom.length + size) * Cost.mulLinearCostPerByte +
          (args.atom.length * size) ~/ Cost.mulSquareCostPerByteDivider;
      value *= arg.toBigInt();
      size = limbsForInt(value);
    }
    return mallocCost(Output(Program.bigint(value), cost));
  },
  keywords['divmod']!: (args) {
    var list = args.toAtomList(size: 2, suffix: 'in divmod');
    var cost = Cost.divmodBaseCost;
    var numerator = list[0].toBigInt();
    var denominator = list[1].toBigInt();
    if (denominator == BigInt.zero) {
      throw IntegerDivisionByZeroException();
    }
    cost +=
        (list[0].atom.length + list[1].atom.length) * Cost.divmodCostPerByte;
    var quotient = Program.bigint(numerator ~/ denominator);
    var remainder = Program.bigint(numerator % denominator);
    cost +=
        (quotient.atom.length + remainder.atom.length) * Cost.mallocCostPerByte;
    return Output(Program.cons(quotient, remainder), cost);
  },
  keywords['/']!: (args) {
    var list = args.toAtomList(size: 2, suffix: 'in /');
    var cost = Cost.divBaseCost;
    var numerator = list[0].toBigInt();
    var denominator = list[1].toBigInt();
    if (denominator == BigInt.zero) {
      throw IntegerDivisionByZeroException();
    }
    cost += (list[0].atom.length + list[1].atom.length) * Cost.divCostPerByte;
    var quotient = Program.bigint(numerator ~/ denominator);
    return mallocCost(Output(quotient, cost));
  },
  keywords['>']!: (args) {
    var list = args.toAtomList(size: 2, suffix: 'in >');
    var cost = Cost.grBaseCost;
    cost += (list[0].atom.length + list[1].atom.length) * Cost.grCostPerByte;
    return mallocCost(
        Output(Program.bool(list[0].toBigInt() > list[1].toBigInt()), cost));
  },
  keywords['>s']!: (args) {
    var list = args.toAtomList(size: 2, suffix: 'in >s');
    var cost = Cost.grsBaseCost;
    cost += (list[0].atom.length + list[1].atom.length) * Cost.grsCostPerByte;
    return mallocCost(Output(
        Program.bool(list[0].toString().compareTo(list[1].toString()) == 1),
        cost));
  },
  keywords['pubkey_for_exp']!: (args) {
    var list = args.toAtomList(size: 1, suffix: 'in pubkey_for_exp');
    var exponent =
        PrivateKey.fromBytes(bigIntToBytes(list[0].toBigInt(), 32, Endian.big));
    var cost = Cost.pubkeyBaseCost;
    cost += list[0].atom.length * Cost.pubkeyCostPerByte;
    return mallocCost(Output(Program.atom(exponent.getG1().toBytes()), cost));
  },
  keywords['point_add']!: (args) {
    //var cost = Cost.pointAddBaseCost;
    //var p =
    throw UnimplementedError('');
  },
  keywords['strlen']!: (args) {
    throw UnimplementedError('Unimplemented.');
  },
  keywords['substr']!: (args) {
    throw UnimplementedError('Unimplemented.');
  },
  keywords['concat']!: (args) {
    throw UnimplementedError('Unimplemented.');
  },
  keywords['ash']!: (args) {
    throw UnimplementedError('Unimplemented.');
  },
  keywords['lsh']!: (args) {
    throw UnimplementedError('Unimplemented.');
  },
  keywords['logand']!: (args) {
    throw UnimplementedError('Unimplemented.');
  },
  keywords['logior']!: (args) {
    throw UnimplementedError('Unimplemented.');
  },
  keywords['logxor']!: (args) {
    throw UnimplementedError('Unimplemented.');
  },
  keywords['lognot']!: (args) {
    throw UnimplementedError('Unimplemented.');
  },
  keywords['not']!: (args) {
    throw UnimplementedError('Unimplemented.');
  },
  keywords['any']!: (args) {
    throw UnimplementedError('Unimplemented.');
  },
  keywords['all']!: (args) {
    throw UnimplementedError('Unimplemented.');
  }
};

Output mallocCost(Output output) {
  return Output(output.program,
      output.cost + output.program.atom.length * Cost.mallocCostPerByte);
}

int limbsForInt(BigInt value) {
  return (value.bitLength + 7) >> 3;
}

Output runOperator(Program op, Program args) {
  var value = op.toBigInt();
  if (operators.containsKey(value)) {
    try {
      return operators[value]!(args);
    } catch (error) {
      throw StateError('$error${op.positionSuffix}');
    }
  }
  if (op.atom.isEmpty ||
      bytesEqual(op.atom.sublist(0, 2), Uint8List.fromList([0xff, 0xff]))) {
    throw StateError('Reserved operator');
  }
  if (op.atom.length > 5) {
    throw StateError('Invalid operator');
  }
  var costFunction = (op.atom[op.atom.length - 1] & 0xc0) >> 6;
  var costMultiplier =
      bytesToInt(op.atom.sublist(0, op.atom.length - 1), Endian.big) + 1;
  int cost;
  if (costFunction == 0) {
    cost = 1;
  } else if (costFunction == 1) {
    cost = Cost.arithBaseCost;
    var argSize = 0;
    for (var arg in args.toList()) {
      if (arg.isCons) {
        throw StateError('Expected int arguments.');
      }
      argSize += arg.atom.length;
      cost += Cost.arithCostPerArg;
    }
    cost += argSize * Cost.arithCostPerByte;
  } else if (costFunction == 2) {
    cost = Cost.mulBaseCost;
    var argList = args.toList();
    if (argList.isNotEmpty) {
      var first = argList[0];
      if (first.isCons) {
        throw StateError('Expected int arguments.');
      }
      var current = first.atom.length;
      for (var item in argList) {
        if (item.isCons) {
          throw StateError('Expected int arguments.');
        }
        cost += Cost.mulCostPerOp +
            (item.atom.length + current) * Cost.mulLinearCostPerByte +
            (item.atom.length + current) ~/ Cost.mulSquareCostPerByteDivider;
        current += item.atom.length;
      }
    }
  } else if (costFunction == 3) {
    cost = Cost.concatBaseCost;
    var length = 0;
    for (var arg in args.toList()) {
      if (arg.isCons) {
        throw StateError('Unknown op on list.');
      }
      cost += Cost.concatCostPerArg;
      length += arg.atom.length;
    }
    cost += length * Cost.concatCostPerByte;
  } else {
    throw StateError('Unknown cost function.');
  }
  cost *= costMultiplier;
  if (cost >= pow(2, 32)) {
    throw StateError('Invalid operator.');
  }
  return Output(Program.nil(), cost);
}
