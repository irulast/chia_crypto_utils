import 'dart:typed_data';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/models/puzzlehash.dart';
import 'package:crypto/crypto.dart';

class Coin {
  Coin? parentCoin;
  Puzzlehash parentCoinId;
  Puzzlehash puzzlehash;
  int amount;

  Coin(this.parentCoinId, this.puzzlehash, this.amount);

  Puzzlehash get id {
    return Puzzlehash(sha256.convert(parentCoinId.bytes + puzzlehash.bytes + intToBytes(amount, (amount.bitLength + 8) >> 3, Endian.big)).bytes);
  }

}