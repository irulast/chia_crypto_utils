// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/utils/serialization.dart';
import 'package:meta/meta.dart';

@immutable
class Coin extends CoinPrototype with ToBytesMixin {
  const Coin({
    required this.confirmedBlockIndex,
    required this.spentBlockIndex,
    required this.coinbase,
    required this.timestamp,
    required super.parentCoinInfo,
    required super.puzzlehash,
    required super.amount,
  });

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

  factory Coin.fromBytes(Bytes bytes) {
    var length = decodeInt(bytes.sublist(0, 4));
    var left = 4;
    var right = left + length;

    final confirmedBlockIndex = decodeInt(bytes.sublist(left, right));

    length = decodeInt(bytes.sublist(right, right + 4));
    left = right + 4;
    right = left + length;
    final spentBlockIndex = decodeInt(bytes.sublist(left, right));

    length = decodeInt(bytes.sublist(right, right + 4));
    left = right + 4;
    right = left + length;
    assert(
      bytes.sublist(left, right).length == 1,
      'bool should have only one byte',
    );
    final coinbase = bytes.sublist(left, right)[0] == 1;

    length = decodeInt(bytes.sublist(right, right + 4));
    left = right + 4;
    right = left + length;
    final timestamp = decodeInt(bytes.sublist(left, right));

    length = decodeInt(bytes.sublist(right, right + 4));
    left = right + 4;
    right = left + length;
    final coinPrototype = CoinPrototype.fromBytes(bytes.sublist(left, right));

    return Coin(
      confirmedBlockIndex: confirmedBlockIndex,
      spentBlockIndex: spentBlockIndex,
      coinbase: coinbase,
      timestamp: timestamp,
      parentCoinInfo: coinPrototype.parentCoinInfo,
      puzzlehash: coinPrototype.puzzlehash,
      amount: coinPrototype.amount,
    );
  }

  factory Coin.fromJson(Map<String, dynamic> json) {
    final coinPrototype = CoinPrototype.fromJson(json);
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
  final int confirmedBlockIndex;
  final int spentBlockIndex;
  final bool coinbase;
  final int timestamp;

  Map<String, dynamic> toFullJson() {
    final json = toJson()
      ..addAll(<String, dynamic>{
        'confirmed_block_index': confirmedBlockIndex,
        'spent_block_index': spentBlockIndex,
        'coinbase': coinbase,
        'timestamp': timestamp,
      });
    return json;
  }

  @override
  String toString() =>
      'Coin(id: $id, parentCoinInfo: $parentCoinInfo puzzlehash: $puzzlehash, amount: $amount, confirmedBlockIndex: $confirmedBlockIndex), spentBlockIndex: $spentBlockIndex, coinbase: $coinbase, timestamp: $timestamp';
}

extension CoinFunctionality on Coin {
  DateTime get dateConfirmed => DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

  SpendSafety getSpendSafety(int currentBlockHeight) {
    if (isSpent) {
      return SpendSafety.unsafe;
    }

    return SpendSafety.fromBlockDepth(currentBlockHeight - confirmedBlockIndex);
  }

  bool get isSpent => spentBlockIndex != 0;
  bool get isNotSpent => !isSpent;

  double get amountXch => amount / mojosPerXch;

  CoinPrototype toCoinPrototype() => CoinPrototype(
        parentCoinInfo: parentCoinInfo,
        puzzlehash: puzzlehash,
        amount: amount,
      );

  Bytes toCoinBytes() {
    final coinPrototypeBytes = toBytes();
    final coinPrototypeBytesLength = coinPrototypeBytes.length;
    return serializeList(<dynamic>[
          confirmedBlockIndex,
          spentBlockIndex,
          coinbase,
          timestamp,
        ]) +
        [...intTo32Bits(coinPrototypeBytesLength), ...coinPrototypeBytes];
  }
}

enum SpendSafety {
  totallySafe,
  safe,
  unsafe;

  factory SpendSafety.fromBlockDepth(int blockDepth) {
    if (blockDepth > 32) {
      return SpendSafety.totallySafe;
    }
    if (blockDepth > 6) {
      return SpendSafety.safe;
    }
    return SpendSafety.unsafe;
  }

  bool get isSafe {
    return this == totallySafe || this == safe;
  }
}
