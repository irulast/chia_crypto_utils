@Skip('interacts with mainnet')

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() async {
  final launcherId = Bytes.fromHex('a08ddff5d78e5fb0fb950142da46f4645a054d0c9c64118a523533eea9e34838');

  const fullNodeUrl = 'https://chia.irulast-prod.com';

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
