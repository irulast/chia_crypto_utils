// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class SimulatorFullNodeInterface extends ChiaFullNodeInterface {
  SimulatorFullNodeInterface(this.fullNode) : super(fullNode);

  factory SimulatorFullNodeInterface.withDefaultUrl() {
    return SimulatorFullNodeInterface(
        SimulatorHttpRpc(SimulatorUtils.defaultUrl));
  }

  @override
  // ignore: overridden_fields
  final SimulatorHttpRpc fullNode;

  // address used only to move to next block
  static const utilAddress =
      Address('xch1ye5dzd44kkatnxx2je4s2agpwtqds5lsm5mlyef7plum5danxalq2dnqap');

  Future<void> moveToNextBlock(
      {int blocks = 1, bool makeCallForEachBlock = true}) async {
    if (makeCallForEachBlock) {
      for (var i = 0; i < blocks; i++) {
        await fullNode.farmTransactionBlocks(utilAddress);
      }
    } else {
      await fullNode.farmTransactionBlocks(utilAddress, blocks: blocks);
    }
  }

  Future<void> farmCoins(
    Address address, {
    int blocks = 1,
    bool transactionBlock = true,
  }) async {
    await fullNode.farmTransactionBlocks(
      address,
      blocks: blocks,
      transactionBlock: transactionBlock,
    );
  }

  Future<bool> getIsAutofarming() async {
    return fullNode.getAutofarmConfig().then((value) => value.isAutofarming);
  }

  Future<bool> setShouldAutofarm({required bool shouldAutofarm}) async {
    return fullNode
        .updateAutofarmConfig(shouldAutofarm: shouldAutofarm)
        .then((value) => value.isAutofarming);
  }

  Timer? blockCreationTimer;

  void run({Duration blockPeriod = const Duration(seconds: 19)}) {
    stop();
    blockCreationTimer = Timer.periodic(blockPeriod, (timer) {
      fullNode.farmTransactionBlocks(utilAddress);
    });
  }

  void stop() {
    blockCreationTimer?.cancel();
  }
}
