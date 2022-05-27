// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:chia_crypto_utils/src/api/full_node/full_node.dart';

class BlockchainAwaitUtil {
  BlockchainAwaitUtil(
    this.fullNode, {
    this.timeoutMilliseconds = defaultTimeout,
  });

  static const int defaultTimeout = 10000;

  int timeoutMilliseconds;
  FullNode fullNode;

  Future<void> awaitBlockChainStateChange(Function callback) async {
    final startHeight = await getHeight();

    // ignore: avoid_dynamic_calls
    await callback();

    final timer = Timer(
      Duration(milliseconds: timeoutMilliseconds),
      () => throw TimeoutException('Took too long to update state'),
    );

    var currentHeight = startHeight;
    while (currentHeight == startHeight) {
      currentHeight = await getHeight();
    }
    timer.cancel();
  }

  Future<int> getHeight() async {
    final response = await fullNode.getBlockchainState();
    return response.blockchainState!.peak?.height ?? -1;
  }
}
