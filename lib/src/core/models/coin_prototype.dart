import 'dart:typed_data';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/core/models/puzzlehash.dart';
import 'package:crypto/crypto.dart';

class CoinPrototype {
  Puzzlehash parentCoinInfo;
  Puzzlehash puzzlehash;
  int amount;

  CoinPrototype({
    required this.parentCoinInfo,
    required this.puzzlehash,
    required this.amount,
  });

  CoinPrototype.fromJson(Map<String, dynamic> json)
      : parentCoinInfo = Puzzlehash.fromHex(json['parent_coin_info']),
        puzzlehash = Puzzlehash.fromHex(json['puzzle_hash']),
        amount = json['amount'];

  Puzzlehash get id {
    return Puzzlehash(sha256
        .convert(
          parentCoinInfo.bytes +
          puzzlehash.bytes +
          intToBytesStandard(amount, Endian.big))
        .bytes);
  }

  Map<String, dynamic> toJson() => {
        'parent_coin_info': parentCoinInfo.hex,
        'puzzle_hash': puzzlehash.hex,
        'amount': amount
      };
}
