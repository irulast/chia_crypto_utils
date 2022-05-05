import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/full_node/full_node_utils.dart';

class SimulatorUtils extends FullNodeUtils {
  static const String defaultUrl = 'https://localhost:5000';

  SimulatorUtils({String url = defaultUrl}) : super(Network.testnet0, url: url);

  @override
  Future<void> checkIsRunning() async {
    final fullNodeRpc = SimulatorHttpRpc(
      url,
      certBytes: certBytes,
      keyBytes: keyBytes,
    );

    final simulator = SimulatorFullNodeInterface(fullNodeRpc);
    await simulator.getBlockchainState();
  }
}
