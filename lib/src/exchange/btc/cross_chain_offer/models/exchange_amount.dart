import 'package:meta/meta.dart';

@immutable
class ExchangeAmount {
  const ExchangeAmount({required this.type, required this.value});

  final ExchangeAmountType type;
  final double value;

  factory ExchangeAmount.fromJson(Map<String, dynamic> json) {
    return ExchangeAmount(
      type: ExchangeAmountType.values.firstWhere((type) => type.name == json['type'] as String),
      value: json['amount'] as double,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.name,
        'amount': value,
      };

  @override
  bool operator ==(Object other) {
    return other is ExchangeAmount && other.type == type && other.value == value;
  }

  @override
  int get hashCode => type.hashCode ^ value.hashCode;
}

// ignore: constant_identifier_names
enum ExchangeAmountType { XCH, BTC }
