// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';
import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class Client {
  Client(this.baseURL, {Bytes? certBytes, Bytes? keyBytes}) {
    final context = (certBytes != null && keyBytes != null)
        ? (SecurityContext.defaultContext
          ..usePrivateKeyBytes(keyBytes)
          ..useCertificateChainBytes(certBytes))
        : null;
    final httpClient = HttpClient(context: context)
      ..badCertificateCallback = (cert, host, port) => true;

    this.httpClient = httpClient;
  }

  late HttpClient httpClient;
  final String baseURL;

  Future<Response> get(
    Uri url, {
    Map<String, String> additionalHeaders = const {},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
  }) async {
    final requestUri = Uri.parse('$baseURL/$url').replace(
      queryParameters: queryParameters,
    );

    logRequest(requestUri);

    final request = await httpClient.getUrl(requestUri);

    additionalHeaders.forEach((key, value) {
      request.headers.add(key, value);
    });
    request.headers.contentType = ContentType('application', 'json', charset: 'utf-8');

    final response = await request.close();
    final stringData = await response.transform(utf8.decoder).join();

    logResponse(response, stringData);

    return Response(stringData, response.statusCode);
  }

  Future<Response> post(
    Uri url,
    Object requestBody, {
    Map<String, String> additionalHeaders = const {},
  }) async {
    try {
      final requestUri = Uri.parse('$baseURL/$url');

      logRequest(requestUri, requestBody);

      final request = await httpClient.postUrl(requestUri);

      additionalHeaders.forEach((key, value) {
        request.headers.add(key, value);
      });
      request.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
      request.write(jsonEncode(requestBody));

      final response = await request.close();
      final stringData = await response.transform(utf8.decoder).join();

      logResponse(response, stringData);

      return Response(stringData, response.statusCode);
    } on SocketException catch (e) {
      LoggingContext().error(e.toString());
      throw NotRunningException(baseURL);
    } on HttpException catch (e) {
      LoggingContext().error(e.toString());

      if (e.toString().contains('Connection closed before full header was received')) {
        throw BadAuthenticationException();
      }
      rethrow;
    } on Exception catch (e) {
      LoggingContext().error(e.toString());
      rethrow;
    }
  }

  void logRequest(Uri requestUri, [Object? requestBody]) {
    LoggingContext()
      ..api('Uri: $requestUri')
      ..api('request body: ')
      ..api(' ');
    if (requestBody != null) {
      LoggingContext().api(makePrettyJsonString(requestBody));
    }
  }

  void logResponse(HttpClientResponse response, String responseBody) {
    final loggingContext = LoggingContext();

    try {
      jsonDecode(responseBody);
    } on FormatException {
      loggingContext
        ..api('response: ')
        ..api(
          makePrettyJsonString(responseBody),
        )
        ..api('------------');
      return;
    }

    final lowLogLevelResponseJson = <String, dynamic>{
      'status_code': response.statusCode,
      'body': jsonDecode(responseBody),
    };

    final mediumLogLevelResponseJson = <String, dynamic>{
      'headers': <String, dynamic>{
        'content_type': response.headers.contentType?.value,
      },
      'status_code': response.statusCode,
      'connection_info': response.connectionInfo != null
          ? <String, dynamic>{
              'local_port': response.connectionInfo!.localPort,
              'remote_port': response.connectionInfo!.remotePort,
              'remote_address': response.connectionInfo!.remoteAddress.address,
            }
          : null,
      'body': jsonDecode(responseBody),
    };

    final highLogLevelResponseJson = <String, dynamic>{
      'headers': <String, dynamic>{
        'content_type': response.headers.contentType?.value,
      },
      'status_code': response.statusCode,
      'connection_info': response.connectionInfo != null
          ? <String, dynamic>{
              'local_port': response.connectionInfo!.localPort,
              'remote_port': response.connectionInfo!.remotePort,
              'remote_address': response.connectionInfo!.remoteAddress.address,
            }
          : null,
      'certificate': response.certificate != null
          ? <String, dynamic>{
              'end_validity': response.certificate!.endValidity.toIso8601String(),
              'issuer': response.certificate!.issuer,
              'pem': response.certificate!.pem,
            }
          : null,
      'body': jsonDecode(responseBody),
    };
    loggingContext
      ..api('response: ')
      ..api(
        makePrettyJsonString(lowLogLevelResponseJson),
        mediumLog: makePrettyJsonString(mediumLogLevelResponseJson),
        highLog: makePrettyJsonString(highLogLevelResponseJson),
      )
      ..api('------------');
  }

  static String makePrettyJsonString(Object jsonObject) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(jsonObject).replaceAll(r'\n', '\n');
  }

  @override
  String toString() => 'Client($baseURL, $httpClient)';
}

class Response {
  Response(this.body, this.statusCode);

  String body;
  int statusCode;

  @override
  String toString() => 'Response(body: ${body.trim()}, statusCode: $statusCode)';
}
