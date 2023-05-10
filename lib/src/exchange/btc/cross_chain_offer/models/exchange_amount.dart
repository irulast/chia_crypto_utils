import 'package:meta/meta.dart';

@immutable
class ExchangeAmount {
  const ExchangeAmount({required this.type, required this.amount});
  factory ExchangeAmount.fromJson(Map<String, dynamic> json) {
    return ExchangeAmount(
      type: ExchangeAmountType.values.firstWhere((type) => type.name == json['type'] as String),
      amount: json['amount'] as int,
    );
  }

  final ExchangeAmountType type;
  final int amount;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.name,
        'amount': amount,
      };

  @override
  bool operator ==(Object other) {
    return other is ExchangeAmount && other.type == type && other.amount == amount;
  }

  @override
  int get hashCode => type.hashCode ^ amount.hashCode;
}

// ignore: constant_identifier_names
enum ExchangeAmountType { XCH, BTC }
