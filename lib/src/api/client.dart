import 'dart:convert';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

@immutable
class Client {
  const Client(this.baseURL);

  final String baseURL;

  Future<Response> sendRequest(Uri url, Object request) {
    return post(
      Uri.parse('$baseURL/$url'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(request),
    );
  }

  @override
  String toString() => 'Client($baseURL)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Client &&
          runtimeType == other.runtimeType &&
          baseURL == other.baseURL;

  @override
  int get hashCode => runtimeType.hashCode ^ baseURL.hashCode;
}
