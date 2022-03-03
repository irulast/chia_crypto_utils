import 'dart:convert';
import 'package:http/http.dart';

class Client {
  String url;

  Client(this.url);

  Future<Response> sendRequest(Object request) async {
    return await post(Uri.parse(url),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(request));
  }
}