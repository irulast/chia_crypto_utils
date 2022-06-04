import 'package:chia_crypto_utils/chia_crypto_utils.dart';

void main() async{
  final launcherId = Bytes.fromHex('bd44995c64a1bfdcff448d20bfd040e39c609a08e0955c3dd071fe282ab23d7b');

  const fullNodeUrl = 'https://chia.irulast-prod.com';

  const fullNodeRpc = FullNodeHttpRpc(
    fullNodeUrl,
  );

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  const fullNode = ChiaFullNodeInterface(fullNodeRpc);

  final plotNft =  await fullNode.getPlotNftByLauncherId(launcherId);
  print(plotNft);
}
