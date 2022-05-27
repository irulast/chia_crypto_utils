// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class SimulatorFullNodeInterface extends ChiaFullNodeInterface {
  const SimulatorFullNodeInterface(this.fullNode) : super(fullNode);

  @override
  // ignore: overridden_fields
  final SimulatorHttpRpc fullNode;

  // address used only to move to next block
  static const utilAddress =
      Address('xch1ye5dzd44kkatnxx2je4s2agpwtqds5lsm5mlyef7plum5danxalq2dnqap');

  Future<void> moveToNextBlock() async {
    await fullNode.farmTransactionBlock(utilAddress);
  }

  Future<void> farmCoins(Address address) async {
    await fullNode.farmTransactionBlock(address);
  }
}
