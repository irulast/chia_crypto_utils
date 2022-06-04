@Skip('interacts with mainnet')

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() async {
  final launcherId = Bytes.fromHex('LAUNCHER_ID');

  const fullNodeUrl = 'FULL_NODE_URL';

  const fullNodeRpc = FullNodeHttpRpc(
    fullNodeUrl,
  );

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  const fullNode = ChiaFullNodeInterface(fullNodeRpc);

  test('should find plot nft', () async {
    final plotNft = await fullNode.getPlotNftByLauncherId(launcherId);
    expect(plotNft != null, true);
  });
}
