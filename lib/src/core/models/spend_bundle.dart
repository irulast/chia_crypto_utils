// ignore_for_file: lines_longer_than_80_chars

import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/utils/serialization.dart';
import 'package:meta/meta.dart';

@immutable
class SpendBundle with ToBytesMixin {
  final List<CoinSpend> coinSpends;
  final JacobianPoint? aggregatedSignature;

  bool get isSigned => aggregatedSignature != null;

  List<Program> get outputConditions {
    final conditions = <Program>[];
    for (final spend in coinSpends) {
      final spendOutput = spend.puzzleReveal.run(spend.solution).program;
      conditions.addAll(spendOutput.toList());
    }
    return conditions;
  }

  List<CoinPrototype> get additions {
    return coinSpends.fold(
      <CoinPrototype>[],
      (previousValue, coinSpend) => previousValue + coinSpend.additions,
    );
  }

  List<CoinPrototype> get coins => coinSpends.map((cs) => cs.coin).toList();

  SpendBundle({
    required this.coinSpends,
    this.aggregatedSignature,
  });

  // ignore: prefer_constructors_over_static_methods
  static SpendBundle get empty => SpendBundle(coinSpends: const []);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'coin_spends': coinSpends.map((e) => e.toJson()).toList(),
        'aggregated_signature': aggregatedSignature?.toHex(),
      };
  SpendBundle.fromJson(Map<String, dynamic> json)
      : coinSpends = (json['coin_solutions'] as Iterable)
            .map((dynamic e) => CoinSpend.fromJson(e as Map<String, dynamic>))
            .toList(),
        aggregatedSignature = JacobianPoint.fromHexG2(json['aggregated_signature'] as String);

  SpendBundle operator +(SpendBundle other) {
    final signatures = <JacobianPoint>[];
    if (aggregatedSignature != null) {
      signatures.add(aggregatedSignature!);
    }
    if (other.aggregatedSignature != null) {
      signatures.add(other.aggregatedSignature!);
    }
    return SpendBundle(
      coinSpends: coinSpends + other.coinSpends,
      aggregatedSignature: (signatures.isNotEmpty) ? AugSchemeMPL.aggregate(signatures) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! SpendBundle) {
      return false;
    }
    if (other.coinSpends.length != coinSpends.length) {
      return false;
    }
    final otherHexCoinSpends = other.coinSpends.map((cs) => cs.toHex()).toList();
    for (final coinSpend in coinSpends) {
      if (!otherHexCoinSpends.contains(coinSpend.toHex())) {
        return false;
      }
    }
    if (aggregatedSignature != other.aggregatedSignature) {
      return false;
    }
    return true;
  }

  SpendBundle addSignature(JacobianPoint signature) {
    final signatures = <JacobianPoint>[signature];
    if (aggregatedSignature != null) {
      signatures.add(aggregatedSignature!);
    }
    final newAggregatedSignature = AugSchemeMPL.aggregate(signatures);

    return SpendBundle(
      coinSpends: coinSpends,
      aggregatedSignature: newAggregatedSignature,
    );
  }

  @override
  Bytes toBytes() {
    return serializeListChia(coinSpends) + Bytes(aggregatedSignature?.toBytes() ?? []);
  }

  factory SpendBundle.fromBytes(Bytes bytes) {
    final iterator = bytes.toList().iterator;

    // length of list is encoded with 32 bits
    final coinSpendsLengthBytes = iterator.extractBytesAndAdvance(4);
    final coinSpendsLength = bytesToInt(coinSpendsLengthBytes, Endian.big);

    final coinSpends = <CoinSpend>[];
    for (var i = 0; i < coinSpendsLength; i++) {
      coinSpends.add(CoinSpend.fromStream(iterator));
    }

    final signatureExists = iterator.moveNext();
    if (!signatureExists) {
      return SpendBundle(coinSpends: coinSpends);
    }

    final firstSignatureByte = iterator.current;
    final restOfSignatureBytes = iterator.extractBytesAndAdvance(JacobianPoint.g2BytesLength - 1);

    final signature = JacobianPoint.fromBytesG2(
      [firstSignatureByte, ...restOfSignatureBytes],
    );

    return SpendBundle(coinSpends: coinSpends, aggregatedSignature: signature);
  }

  void debug() {
    for (final spend in coinSpends) {
      print('---------');
      print('coin: ${spend.coin.toJson()}');
      print('puzzle reveal: ${spend.puzzleReveal}');
      print('solution: ${spend.solution}');
      print('result: ${spend.puzzleReveal.run(spend.solution).program}');
    }
  }

  @override
  String toString() =>
      'SpendBundle(coinSpends: $coinSpends, aggregatedSignature: $aggregatedSignature)';

  @override
  int get hashCode {
    var hc = coinSpends.fold(
      0,
      (int previousValue, cs) => previousValue ^ cs.hashCode,
    );
    if (aggregatedSignature != null) {
      hc = hc ^ aggregatedSignature.hashCode;
    }
    return hc;
  }
}
