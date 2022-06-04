import 'package:chia_crypto_utils/chia_crypto_utils.dart';

void main() async{
  final launcherId = Bytes.fromHex('LAUNCHER_ID');

  const fullNodeUrl = 'https://chia.irulast-prod.com';

  const fullNodeRpc = FullNodeHttpRpc(
    fullNodeUrl,
  );

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  const fullNode = ChiaFullNodeInterface(fullNodeRpc);

  final plotNft =  await fullNode.getPlotNftByLauncherId(launcherId);
  print(plotNft);
}
