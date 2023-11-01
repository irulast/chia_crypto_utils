import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class MixedNotarizedPayments with MixedTypeMixin<List<NotarizedPayment>, MixedNotarizedPayments> {
  const MixedNotarizedPayments(this.map);

  @override
  final Map<GeneralCoinType, Map<Puzzlehash?, List<NotarizedPayment>>> map;

  @override
  List<NotarizedPayment> get defaultValue => [];

  @override
  String toString() {
    return 'MixedNotarizedPayments($map)';
  }

  void debug() {
    final catString = jsonEncode(
      cat.map((key, value) => MapEntry(key.toString(), value.map((e) => e.toString()).toList())),
    );
    print('{');
    print(' standard: $standard,');
    print(' cat: $catString');
    print('}');
  }

  @override
  List<NotarizedPayment> add(List<NotarizedPayment> first, List<NotarizedPayment> second) {
    return first + second;
  }

  @override
  MixedNotarizedPayments clone(Map<GeneralCoinType, Map<Puzzlehash?, List<NotarizedPayment>>> map) {
    return MixedNotarizedPayments(map);
  }

  @override
  List<NotarizedPayment> subtract(List<NotarizedPayment> first, List<NotarizedPayment> second) {
    throw UnimplementedError();
  }
}
