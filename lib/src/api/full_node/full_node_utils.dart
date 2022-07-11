// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class FullNodeUtils {
  FullNodeUtils(this.network, {this.url = defaultUrl});

  final String url;
  final Network network;

  static const String defaultUrl = 'https://localhost:8555';

  String get checkNetworkMessage => 'Check if your full node is runing on $network';

  String get sslPath =>
      '${Platform.environment['HOME']}/.chia/${network.name}/config/ssl/full_node';

  Bytes get certBytes {
    return _getAuthFileBytes('$sslPath/private_full_node.crt');
  }

  Bytes get keyBytes {
    return _getAuthFileBytes('$sslPath/private_full_node.key');
  }

  static Bytes _getAuthFileBytes(String pathToFile) {
    LoggingContext()
      ..info(null, highLog: 'auth file loaded: $pathToFile')
      ..info(null, highLog: 'file contents:')
      ..info(null, highLog: File(pathToFile).readAsStringSync());
    return Bytes(File(pathToFile).readAsBytesSync());
  }

  Future<void> checkIsRunning() async {
    final fullNodeRpc = FullNodeHttpRpc(
      url,
      certBytes: certBytes,
      keyBytes: keyBytes,
    );

    final fullNode = ChiaFullNodeInterface(fullNodeRpc);
    await fullNode.getBlockchainState();
  }
}
