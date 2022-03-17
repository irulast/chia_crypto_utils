import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/full_node.dart';
import 'package:chia_utils/src/cat/models/cat_coin.dart';
import 'package:chia_utils/src/cat/puzzles/cat/cat.clvm.hex.dart';
import 'package:chia_utils/src/cat/service/wallet.dart';
import 'package:chia_utils/src/cat/transport/transport.dart';
import 'package:hex/hex.dart';

Future<void> main() async {
  final configurationProvider = ConfigurationProvider()
    ..setConfig(NetworkFactory.configId, {
      'yaml_file_path': 'lib/src/networks/chia/testnet10/config.yaml'
    }
  );

  // mama coin (xch) 
  // mama coin spend (has an asset id aka tail)
  // child cat coin (cat:assetId)
  // child cat coin spend (cat spend)
  // grandchild cat coin (cat:assetId)


  final context = Context(configurationProvider);
  final blockcahinNetworkLoader = ChiaBlockchainNetworkLoader();
  context.registerFactory(NetworkFactory(blockcahinNetworkLoader.loadfromLocalFileSystem));
  final catWalletService = CatWalletService(context);
  // const fullNode = FullNode('http://localhost:4000');
  const fullNode = FullNode('https://chia-rpc-stateful-1-3-0.bitsports-dev.co');



  final genesisCoin = await fullNode.getCoinByName(Puzzlehash.fromHex('16468acf73bd52b38ee43ab1462a03121672f5057bfd3f818abeb2eea66f34ecb'));
  print(genesisCoin.spentBlockIndex);
  // await printAllCoinInfo('6468acf73bd52b38ee43ab1462a03121672f5057bfd3f818abeb2eea66f34ecb', fullNode);

  // print('Nate2 coin');
  // printAllCoinInfo(coinIdHex, fullNode)
  // final nate2CatCoin = await fullNode.getCoinByName(Puzzlehash.fromHex('39dc02c41fd5637b163b20aaee17cb79bef3a8be76797bac883d882093ef612b'));
  // final nate2CatCoinSpend = await fullNode.getPuzzleAndSolution(stadiaCatCoin.id, stadiaCatCoin.spentBlockIndex);
  // print('puzzle reveal:');
  // print(stadiaCatCoinSpend.puzzleReveal);
  // print('uncurried args:');
  // print(stadiaCatCoinSpend.puzzleReveal.uncurry().arguments);


  //
}

Future<void> printAllCoinInfo(String coinIdHex, FullNode fullNode) async {
  final coin = await fullNode.getCoinByName(Puzzlehash.fromHex(coinIdHex));
  final coinSpend = await fullNode.getPuzzleAndSolution(coin.id, coin.spentBlockIndex);
  print('puzzle reveal:');
  print(coinSpend.puzzleReveal);
  print('uncurried args:');
  print(coinSpend.puzzleReveal.uncurry().arguments);
  print('solution:');
  print(coinSpend.solution);
}
