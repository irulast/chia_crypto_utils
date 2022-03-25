import 'dart:convert';
import 'dart:io';

import 'package:chia_utils/src/core/models/bytes.dart';

class Client {
  Client(this.baseURL, {Bytes? certBytes, Bytes? keyBytes}) {
    final context = (certBytes != null && keyBytes != null) ? 
      (SecurityContext.defaultContext
          ..usePrivateKeyBytes(keyBytes.toUint8List())
          ..useCertificateChainBytes(certBytes.toUint8List()))
      :
      null;
    final httpClient = HttpClient(context: context)
    ..badCertificateCallback = (cert, host, port) => true;

    this.httpClient = httpClient;
  }

  late HttpClient httpClient;
  final String baseURL;

  Future<Response> sendRequest(Uri url, Object requestBody) async {
    final request = await httpClient.postUrl(Uri.parse('$baseURL/$url'));

    request.headers.contentType =
      ContentType('application', 'json', charset: 'utf-8');
    request.write(jsonEncode(requestBody));

    final response = await request.close();
    final stringData = await response.transform(utf8.decoder).join();

    return Response(stringData, response.statusCode);
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

class Response {
  Response(this.body, this.statusCode);

  String body;
  int statusCode;
}
