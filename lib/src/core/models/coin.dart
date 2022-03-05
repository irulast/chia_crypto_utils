import 'dart:typed_data';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/models/coin_record.dart';
import 'package:chia_utils/src/models/coin_spend.dart';
import 'package:crypto/crypto.dart';

class Coin {
  Puzzlehash parentCoinInfo;
  Puzzlehash puzzlehash;
  int amount;
  
  CoinSpend? parentCoinSpend;
  CoinRecord? coinRecord;

  Coin({
    this.parentCoinSpend,
    required this.parentCoinInfo,
    required this.puzzlehash,
    required this.amount
  });

  Puzzlehash get id {
    return Puzzlehash(sha256.convert(parentCoinInfo.bytes + puzzlehash.bytes + intToBytesStandard(amount, Endian.big)).bytes);
  }

  Coin.fromJson(Map<String, dynamic> json)
    : parentCoinInfo = Puzzlehash.fromHex(json['parent_coin_info']),
      puzzlehash = Puzzlehash.fromHex(json['puzzle_hash']),
      amount = json['amount'];

  Map<String, dynamic> toJson() => {
    'parent_coin_info': parentCoinInfo.hex,
    'puzzle_hash': puzzlehash.hex,
    'amount': amount
  };

}