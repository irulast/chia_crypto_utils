// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/utils/serialization.dart';
import 'package:collection/collection.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:meta/meta.dart';

@immutable
class SpendBundle with ToBytesMixin, ToJsonMixin {
  SpendBundle({
    required this.coinSpends,
    Set<JacobianPoint> signatures = const {},
  }) : _signatures = signatures;
  factory SpendBundle.aggregate(List<SpendBundle> bundles) {
    var totalBundle = SpendBundle.empty;

    for (final bundle in bundles) {
      totalBundle += bundle;
    }
    return totalBundle;
  }

  factory SpendBundle.fromHex(String hex) {
    return SpendBundle.fromBytes(Bytes.fromHex(hex));
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
    final restOfSignatureBytes =
        iterator.extractBytesAndAdvance(JacobianPoint.g2BytesLength - 1);

    final signature = JacobianPoint.fromBytesG2(
      [firstSignatureByte, ...restOfSignatureBytes],
    );

    return SpendBundle(coinSpends: coinSpends, signatures: {signature});
  }

  factory SpendBundle.withNullableSignatures({
    required List<CoinSpend> coinSpends,
    required Set<JacobianPoint?> signatures,
  }) {
    return SpendBundle(
      coinSpends: coinSpends,
      signatures: signatures.whereNotNull().toSet(),
    );
  }

  factory SpendBundle.fromJson(Map<String, dynamic> json) {
    final coinSpends = (json['coin_spends'] as Iterable)
        .map((dynamic e) => CoinSpend.fromJson(e as Map<String, dynamic>))
        .toList();

    final aggregatedSignature = pick(json, 'aggregated_signature')
        .letStringOrNull(JacobianPoint.fromHexG2);

    return SpendBundle(
      coinSpends: coinSpends,
      signatures: {
        if (aggregatedSignature != null) aggregatedSignature,
      },
    );
  }

  factory SpendBundle.fromCamelJson(Map<String, dynamic> json) {
    final coinSpends = ((json['coinSpends'] ?? json['coinSolutions'])
            as Iterable)
        .map((dynamic e) => CoinSpend.fromCamelJson(e as Map<String, dynamic>))
        .toList();

    final aggregatedSignature = pick(json, 'aggregatedSignature')
        .letStringOrNull(JacobianPoint.fromHexG2);

    return SpendBundle.withNullableSignatures(
      coinSpends: coinSpends,
      signatures: {aggregatedSignature},
    );
  }

  SpendBundle withSignature(JacobianPoint signature) {
    return SpendBundle(
      coinSpends: coinSpends,
      signatures: {
        ..._signatures,
        signature,
      },
    );
  }

  Bytes get id => toBytes().sha256Hash();

  final List<CoinSpend> coinSpends;

  final Set<JacobianPoint> _signatures;
  JacobianPoint? get aggregatedSignature {
    if (_signatures.isEmpty) {
      return null;
    }

    return AugSchemeMPL.aggregate(_signatures.toList());
  }

  bool get isSigned => aggregatedSignature != null;

  static Future<SpendBundle?> ofCoin(
    Bytes coinId,
    ChiaFullNodeInterface fullNode,
  ) {
    return constructSpendBundleOfCoin(coinId, fullNode);
  }

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

  List<CoinPrototype> get removals {
    return coinSpends.map((e) => e.coin).toList();
  }

  List<CoinPrototype> get netAdditions {
    final removals_ = removals.toSet();

    return additions.where((a) => !removals_.contains(a)).toList();
  }

  Map<Bytes, CoinSpend> get coinSpendMap {
    final coinIdToSpendMap = <Bytes, CoinSpend>{};

    for (final coinSpend in coinSpends) {
      coinIdToSpendMap[coinSpend.coin.id] = coinSpend;
    }
    return coinIdToSpendMap;
  }

  List<CoinPrototypeWithParentSpend> get netAdditonWithParentSpends {
    final coinIdToSpendMap = coinSpendMap;

    final result = <CoinPrototypeWithParentSpend>[];

    for (final coin in netAdditions) {
      result.add(
        CoinPrototypeWithParentSpend(
          delegate: coin,
          parentSpend: coinIdToSpendMap[coin.parentCoinInfo],
        ),
      );
    }
    return result;
  }

  Future<List<CoinPrototype>> get additionsAsync async {
    final additions = <CoinPrototype>[];
    for (final coinSpend in coinSpends) {
      additions.addAll(await coinSpend.additionsAsync);
    }
    return additions;
  }

  List<CoinPrototype> get coins => coinSpends.map((cs) => cs.coin).toList();

  int get fee {
    return coinSpends.fold(
      0,
      (previousValue, coinSpend) => previousValue + coinSpend.fee,
    );
  }

  // ignore: prefer_constructors_over_static_methods
  static SpendBundle get empty => SpendBundle(coinSpends: const []);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'coin_spends': coinSpends.map((e) => e.toJson()).toList(),
        'aggregated_signature': aggregatedSignature?.toHexWithPrefix(),
      };

  Map<String, dynamic> toCamelJson() => <String, dynamic>{
        'coinSpends': coinSpends.map((e) => e.toCamelJson()).toList(),
        'aggregatedSignature': aggregatedSignature?.toHexWithPrefix(),
      };

  SpendBundle operator +(SpendBundle other) {
    return SpendBundle(
      coinSpends: coinSpends + other.coinSpends,
      signatures: {
        ..._signatures,
        ...other._signatures,
      },
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
    final otherHexCoinSpends =
        other.coinSpends.map((cs) => cs.toHex()).toList();
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

  SpendBundleSignResult sign(
    WalletKeychain keychain, {
    bool Function(CoinSpend coinSpend)? filterCoinSpends,
  }) {
    return BaseWalletService().signSpendBundle(
      this,
      keychain,
      filterCoinSpends: filterCoinSpends,
    );
  }

  SpendBundleSignResult signWithPrivateKey(
    PrivateKey privateKey, {
    bool Function(CoinSpend coinSpend)? filterCoinSpends,
  }) {
    return BaseWalletService().signSpendBundleWithPrivateKey(
      this,
      privateKey,
      filterCoinSpends: filterCoinSpends,
    );
  }

  SpendBundle signPerCoinSpend(
    JacobianPoint? Function(CoinSpend coinSpend) makeSignatureForCoinSpend,
  ) {
    final signatures = <JacobianPoint>{};
    for (final coinSpend in coinSpends) {
      final signature = makeSignatureForCoinSpend(coinSpend);
      if (signature != null) {
        signatures.add(signature);
      }
    }

    if (signatures.isEmpty) {
      throw SignException('No signatures were created');
    }

    return SpendBundle(
      coinSpends: coinSpends,
      signatures: signatures,
    );
  }

  @override
  Bytes toBytes() {
    return serializeListChia(coinSpends) +
        Bytes(aggregatedSignature?.toBytes() ?? []);
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
    final coinSpendsHashCode = coinSpends.fold(
      0,
      (int previousValue, cs) => previousValue ^ cs.hashCode,
    );

    return coinSpendsHashCode ^ aggregatedSignature.hashCode;
  }
}

class SignException implements Exception {
  SignException(this.message);
  final String message;

  @override
  String toString() {
    return 'SignException{message: $message}';
  }
}
