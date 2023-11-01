import 'dart:async';
import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:http/http.dart' as http;

abstract class NftStorageApi {
  factory NftStorageApi() => _NftStorageApi();
  FutureOr<NftData0007> getNftData(String url);
}

class _NftStorageApi implements NftStorageApi {
  final _client = http.Client();
  @override
  Future<NftData0007> getNftData(String url) async {
    final response = await _client.get(
      Uri.parse(url),
    );
    final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);

    return NftData0007.fromJson(jsonDecode(decodedBody) as Map<String, dynamic>);
  }
}

extension GetNftRecordsWithData on Iterable<NftRecord> {
  Future<List<HydratedNftRecord>> hydrate(
    NftStorageApi nftStorageApi, [
    ChiaFullNodeInterface? fullNode,
  ]) async {
    final hydratedRecordFutures = <Future<HydratedNftRecord?>>[];
    for (final record in this) {
      hydratedRecordFutures.add(
        record.hydrate(nftStorageApi),
      );
    }

    final records = await Future.wait(hydratedRecordFutures);
    return List<HydratedNftRecord>.from(records.where((element) => element != null));
  }

  Future<List<HydratedNftRecord>> hydrateAndFetchMintInfo(
    NftStorageApi nftStorageApi,
    ChiaFullNodeInterface fullNode,
  ) async {
    final hydratedRecordFutures = <Future<HydratedNftRecord?>>[];
    for (final record in this) {
      hydratedRecordFutures.add(
        record.hydrateAndFetchMintInfo(nftStorageApi, fullNode),
      );
    }

    final records = await Future.wait(hydratedRecordFutures);
    return List<HydratedNftRecord>.from(records.where((element) => element != null));
  }
}
