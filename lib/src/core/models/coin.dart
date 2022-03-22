// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes, lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/core/models/bytes.dart';


// ignore: must_be_immutable
class Coin extends CoinPrototype {
  final int confirmedBlockIndex;
  final int spentBlockIndex;
  final bool coinbase;
  final int timestamp;

  const Coin({
    required this.confirmedBlockIndex,
    required this.spentBlockIndex,
    required this.coinbase,
    required this.timestamp,
    required Bytes parentCoinInfo,
    required Puzzlehash puzzlehash,
    required int amount,
  }) : super(
            puzzlehash: puzzlehash,
            amount: amount,
            parentCoinInfo: parentCoinInfo,
    );

  factory Coin.fromChiaCoinRecordJson(Map<String, dynamic> json) {
    final coinPrototype = CoinPrototype.fromJson(json['coin'] as Map<String, dynamic>);
    return Coin(
      confirmedBlockIndex: json['confirmed_block_index'] as int,
      spentBlockIndex: json['spent_block_index'] as int,
      coinbase: json['coinbase'] as bool,
      timestamp: json['timestamp'] as int,
      parentCoinInfo: coinPrototype.parentCoinInfo,
      puzzlehash: coinPrototype.puzzlehash,
      amount: coinPrototype.amount,
    );
  }

  Program toProgram() {
    return Program.list([
    Program.fromBytes(parentCoinInfo.toUint8List()),
    Program.fromBytes(puzzlehash.toUint8List()),
    Program.fromInt(amount),
  ]);
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic> {
      'confirmed_block_index': confirmedBlockIndex,
      'spent_block_index': spentBlockIndex,
      'coinbase': coinbase,
      'timestamp': timestamp,
      'parent_coin_info': parentCoinInfo.toHex(),
      'puzzle_hash': puzzlehash.toHex(),
      'amount': amount,
    };
  }
}
