import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:http/http.dart' as http;

abstract class UriHashProvider {
  factory UriHashProvider() => const _UriHashProvider();
  Future<Bytes> getHashForUri(String uri);
}

class CachedUriHashProvider implements UriHashProvider {
  CachedUriHashProvider([this.delegate = const _UriHashProvider()]);
  final UriHashProvider delegate;
  final _cache = <String, Bytes>{};
  @override
  Future<Bytes> getHashForUri(String uri) async {
    if (_cache.containsKey(uri)) {
      return _cache[uri]!;
    }
    final hash = await delegate.getHashForUri(uri);
    _cache[uri] = hash;
    return hash;
  }
}

class _UriHashProvider implements UriHashProvider {
  const _UriHashProvider();
  @override
  Future<Bytes> getHashForUri(String uri) async {
    final data = await http.get(Uri.parse(uri));
    if (data.statusCode != 200) {
      throw HttpException(
          'Error fetching uri $uri (code: ${data.statusCode}, msg: ${data.body})');
    }

    return Bytes(data.bodyBytes).sha256Hash();
  }
}

class MockUriHashProvider implements UriHashProvider {
  @override
  Future<Bytes> getHashForUri(String uri) async {
    return Program.fromString(uri).hash();
  }
}
