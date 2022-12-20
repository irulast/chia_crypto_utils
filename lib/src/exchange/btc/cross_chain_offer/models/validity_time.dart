import 'package:meta/meta.dart';

@immutable
class ValidityTime {
  ValidityTime({
    required this.type,
    required this.value,
  });

  final ValidityTimeType type;
  final int value;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.name,
        'value': value,
      };

  factory ValidityTime.fromJson(Map<String, dynamic> json) {
    return ValidityTime(
      type: ValidityTimeType.values.firstWhere((type) => type.name == json['type'] as String),
      value: json['value'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ValidityTime && other.type == type && other.value == value;
  }

  @override
  int get hashCode => type.hashCode ^ value.hashCode;
}

// ignore: constant_identifier_names
enum ValidityTimeType { unix_epoch, seconds }
