import 'package:meta/meta.dart';

@immutable
class ExchangeAmount {
  const ExchangeAmount({required this.type, required this.amount});

  final String type;
  final int amount;

  factory ExchangeAmount.fromJson(Map<String, dynamic> json) {
    return ExchangeAmount(
      type: json['type'] as String,
      amount: json['amount'] as int,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'amount': amount,
      };

  @override
  bool operator ==(Object other) {
    return other is ExchangeAmount && other.type == type && other.amount == amount;
  }

  @override
  int get hashCode => type.hashCode ^ amount.hashCode;
}
