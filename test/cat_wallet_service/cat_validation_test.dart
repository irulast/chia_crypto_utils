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
  const fullNode = FullNode('https://chia-rpc-stateless.bitsports-prod.co');

  final assetId = Puzzlehash.fromHex('f67a4f4b1391b49821581d5095dfc9725874bf9e050f453c59947d59d5c867d3');
  final mamaCoin = await fullNode.getCoinByName(Puzzlehash.fromHex('f05457e221cd0feb457bc62293b6cbf4a7cd45ef4d58eccfb2b41856f43e3bda'));
  final mamaCoinSpend = await fullNode.getPuzzleAndSolution(mamaCoin.id, mamaCoin.spentBlockIndex);
  final grandmaCoin = await fullNode.getCoinByName(mamaCoin.parentCoinInfo);
  final grandmaCoinSpend = await fullNode.getPuzzleAndSolution(grandmaCoin.id, grandmaCoin.spentBlockIndex);
  // print(const HexEncoder().convert(parentCoinSpend.puzzleReveal.uncurry().arguments));
  
  final childCatCoin = await fullNode.getCoinByName(Puzzlehash.fromHex('d679a8bbfebde9478428bf249093f6dd9ca74a2ef0c08a2cec99e9e3f92c441e'));
  final childCatCoinSpend = await fullNode.getPuzzleAndSolution(childCatCoin.id, childCatCoin.spentBlockIndex);
  print(grandmaCoinSpend.puzzleReveal.uncurry().arguments);
  // CatCoin.fromCoin(childCatCoin, mamaCoinSpend, assetId);

  // CatCoin.fromCoin(mamaCoin, grandmaCoinSpend, assetId);
}
