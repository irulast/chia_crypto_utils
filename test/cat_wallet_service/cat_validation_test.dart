import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/chia_full_node_interface.dart';
import 'package:chia_utils/src/api/full_node_http_rpc.dart';
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
  const fullNodeRpc = FullNodeHttpRpc('https://chia-rpc-stateless.bitsports-prod.co');
  const fullNode = ChiaFullNodeInterface(fullNodeRpc);

  // final assetId = Puzzlehash.fromHex('f67a4f4b1391b49821581d5095dfc9725874bf9e050f453c59947d59d5c867d3');
  // final mamaCoin = await fullNode.getCoinByName(Puzzlehash.fromHex('f05457e221cd0feb457bc62293b6cbf4a7cd45ef4d58eccfb2b41856f43e3bda'));
  // final mamaCoinSpend = await fullNode.getPuzzleAndSolution(mamaCoin.id, mamaCoin.spentBlockIndex);
  // final grandmaCoin = await fullNode.getCoinByName(mamaCoin.parentCoinInfo);
  // final grandmaCoinSpend = await fullNode.getPuzzleAndSolution(grandmaCoin.id, grandmaCoin.spentBlockIndex);
  // // print(const HexEncoder().convert(parentCoinSpend.puzzleReveal.uncurry().arguments));
  
  // final childCatCoin = await fullNode.getCoinByName(Puzzlehash.fromHex('d679a8bbfebde9478428bf249093f6dd9ca74a2ef0c08a2cec99e9e3f92c441e'));
  // final childCatCoinSpend = await fullNode.getPuzzleAndSolution(childCatCoin.id, childCatCoin.spentBlockIndex);
  // print(grandmaCoinSpend.puzzleReveal.uncurry().arguments);
  // CatCoin.fromCoin(childCatCoin, mamaCoinSpend, assetId);

  // CatCoin.fromCoin(mamaCoin, grandmaCoinSpend, assetId);
  final assetId = Puzzlehash.fromHex('d8b70b0813c0c125f3741df606b76c5fca9d76513765b4e8cd3a56d541006631');

  final firstCat = await fullNode.getCoinById(Puzzlehash.fromHex('39dc02c41fd5637b163b20aaee17cb79bef3a8be76797bac883d882093ef612b'));
  final firstCatParentCoin = await fullNode.getCoinById(firstCat!.parentCoinInfo);
  final firstCatParentCoinSpend = await fullNode.getCoinSpend(firstCat);
  // CatCoin.fromCoin(firstCat, firstCatParentCoinSpend, assetId);

  // first cat id
  // b10e55d91a6b9a19f611462c97c8ff27317d76fafff0800be96ca161e67b93b4

  // genesis id
  // 65a26df2eb14b5b1dd9cb40e76e8396575c8ccfd7d4675742f5ef7ba7e9ed8b3

  // public key used in tail
  //0xb1daa96d1fa197cbe77b16c9865acd72ed58cf675c5567942c1004e3c992a01fed8d756ab3c5b8da950b9aa922df98e3

  final genesisCoin = await fullNode.getCoinById(Puzzlehash.fromHex('65a26df2eb14b5b1dd9cb40e76e8396575c8ccfd7d4675742f5ef7ba7e9ed8b3'));
  final genesisCoinSpend = await fullNode.getCoinSpend(genesisCoin!);
  print('puzzle reveal:');
  print(genesisCoinSpend!.puzzleReveal);
  print('uncurried args:');
  print(genesisCoinSpend.puzzleReveal.uncurry().arguments);

  final firstCh21CatCoin = await fullNode.getCoinById(Puzzlehash.fromHex('b10e55d91a6b9a19f611462c97c8ff27317d76fafff0800be96ca161e67b93b4'));
  final firstCh21CatCoinSpend = await fullNode.getCoinSpend(firstCh21CatCoin!);
  print('puzzle reveal:');
  print(firstCh21CatCoinSpend!.puzzleReveal);
  print('uncurried args:');
  print(firstCh21CatCoinSpend.puzzleReveal.uncurry().arguments);


  final stadiaCatCoin = await fullNode.getCoinById(Puzzlehash.fromHex('39dc02c41fd5637b163b20aaee17cb79bef3a8be76797bac883d882093ef612b'));
  final stadiaCatCoinSpend = await fullNode.getCoinSpend(stadiaCatCoin!);
  print('puzzle reveal:');
  print(stadiaCatCoinSpend!.puzzleReveal);
  print('uncurried args:');
  print(stadiaCatCoinSpend.puzzleReveal.uncurry().arguments);

  //
}
