import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/chia_full_node_interface.dart';
import 'package:chia_utils/src/api/simulator_http_rpc.dart';

class SimulatorFullNodeInterface extends ChiaFullNodeInterface {
  const SimulatorFullNodeInterface(this.fullNode) : super(fullNode);
  
  @override
  // ignore: overridden_fields
  final SimulatorHttpRpc fullNode;

  // address used only to move to next block
  static const junkAddress = Address('xch1ye5dzd44kkatnxx2je4s2agpwtqds5lsm5mlyef7plum5danxalq2dnqap');

  Future<void> moveToNextBlock() async {
    await fullNode.farmTransactionBlock(junkAddress);
  }

  Future<void> farmCoins(Address address) async {
    await fullNode.farmTransactionBlock(address);
  }
}
