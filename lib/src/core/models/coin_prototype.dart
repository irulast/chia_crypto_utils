// ignore_for_file: lines_longer_than_80_chars

import 'dart:typed_data';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/core/models/serializable.dart';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

@immutable
class CoinPrototype implements Serializable{
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
    return Bytes(sha256
        .convert(
            parentCoinInfo.toUint8List() +
            puzzlehash.toUint8List() +
            intToBytesStandard(amount, Endian.big),
          )
        .bytes,
      );
  }

  Program toProgram() {
    return Program.list([
      Program.fromBytes(parentCoinInfo.toUint8List()),
      Program.fromBytes(puzzlehash.toUint8List()),
      Program.fromInt(amount),
    ]);
  }

  Map<String, dynamic> toJson() => <String, dynamic> {
      'parent_coin_info': parentCoinInfo.toHex(),
      'puzzle_hash': puzzlehash.toHex(),
      'amount': amount
  };

  @override
  Bytes toBytes() {
    return parentCoinInfo + puzzlehash + Bytes(intTo64Bytes(amount));
  }
  
  @override
  bool operator ==(Object other) =>
      other is CoinPrototype &&
      other.id == id;

  @override
  int get hashCode => id.toHex().hashCode;

  @override
  String toString() => 'Coin(id: $id, parentCoinInfo: $parentCoinInfo puzzlehash: $puzzlehash, amount: $amount)';
}

int calculateTotalCoinValue(List<CoinPrototype> coins) {
  final total = coins.fold(0, (int previousValue, coin) => previousValue + coin.amount);
  return total;
}
