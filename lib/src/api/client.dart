// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';
import 'dart:io';

import 'package:chia_utils/src/api/exceptions/bad_authentication_exception.dart';
import 'package:chia_utils/src/api/exceptions/not_running_exception.dart';
import 'package:chia_utils/src/core/models/bytes.dart';

class Client {
  Client(this.baseURL, {Bytes? certBytes, Bytes? keyBytes}) {
    final context = (certBytes != null && keyBytes != null)
        ? (SecurityContext.defaultContext
          ..usePrivateKeyBytes(keyBytes.toBytes())
          ..useCertificateChainBytes(certBytes.toBytes()))
        : null;
    final httpClient = HttpClient(context: context)
      ..badCertificateCallback = (cert, host, port) => true;

    this.httpClient = httpClient;
  }

  late HttpClient httpClient;
  final String baseURL;

  Future<Response> sendRequest(Uri url, Object requestBody) async {
    try {
      final request = await httpClient.postUrl(Uri.parse('$baseURL/$url'));

      request.headers.contentType =
          ContentType('application', 'json', charset: 'utf-8');
      request.write(jsonEncode(requestBody));

      final response = await request.close();
      final stringData = await response.transform(utf8.decoder).join();

      return Response(stringData, response.statusCode);
    } on SocketException {
      throw NotRunningException(baseURL);
    } on HttpException catch (e) {
      if (e
          .toString()
          .contains('Connection closed before full header was received')) {
        throw BadAuthenticationException();
      }
      rethrow;
    }
  }

  @override
  String toString() => 'Client($baseURL, $httpClient)';
}

class Response {
  Response(this.body, this.statusCode);

  String body;
  int statusCode;
}
