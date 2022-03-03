

import 'record_response.dart';

class RecordsResponse {
  List<RecordResponse> records;

  RecordsResponse({required this.records});

  RecordsResponse.fromJson(Map<String, dynamic> json)
      : records = (json['records'] as List)
            .map((value) => RecordResponse.fromJson(value))
            .toList();

  Map<String, dynamic> toJson() =>
      {'records': records.map((value) => value.toJson()).toList()};
}
