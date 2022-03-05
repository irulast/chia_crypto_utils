import 'dart:convert';
import 'package:http/http.dart';

class Client {
  String baseURL;

  Client(this.baseURL);

  Future<Response> sendRequest(Uri url, Object request, ) async {
    return await post(Uri.parse('$baseURL/$url'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(request));
  }
}