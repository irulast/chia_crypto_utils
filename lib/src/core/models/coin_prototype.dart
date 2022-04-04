import 'dart:typed_data';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

@immutable
class CoinPrototype {
  final Bytes parentCoinInfo;
  final Puzzlehash puzzlehash;
  final int amount;

  const CoinPrototype({
    required this.parentCoinInfo,
    required this.puzzlehash,
    required this.amount,
  });

  CoinPrototype.fromJson(Map<String, dynamic> json)
      : parentCoinInfo = Bytes.fromHex(json['parent_coin_info'] as String),
        puzzlehash = Puzzlehash.fromHex(json['puzzle_hash'] as String),
        amount = json['amount'] as int;

  Bytes get id {
    return Bytes(
      sha256
          .convert(
            parentCoinInfo.toBytes() +
                puzzlehash.toBytes() +
                intToBytesStandard(amount, Endian.big),
          )
          .bytes,
    );
  }

  Program toProgram() {
    return Program.list([
      Program.fromBytes(parentCoinInfo.toBytes()),
      Program.fromBytes(puzzlehash.toBytes()),
      Program.fromInt(amount),
    ]);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'parent_coin_info': parentCoinInfo.toHex(),
        'puzzle_hash': puzzlehash.toHex(),
        'amount': amount
      };

  @override
  bool operator ==(Object other) => other is CoinPrototype && other.id == id;

  @override
  int get hashCode => id.toHex().hashCode;
}
