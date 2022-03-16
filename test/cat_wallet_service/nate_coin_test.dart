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

  final mnemonic = 'guilt rail green junior loud track cupboard citizen begin play west adapt myself panda eye finger nuclear someone update light dance exotic expect layer'.split(' ');
  // const mnemonic = [
  //     'elder', 'quality', 'this', 'chalk', 'crane', 'endless',
  //     'machine', 'hotel', 'unfair', 'castle', 'expand', 'refuse',
  //     'lizard', 'vacuum', 'embody', 'track', 'crash', 'truth',
  //     'arrow', 'tree', 'poet', 'audit', 'grid', 'mesh',
  // ];
  // assert(mnemonic.length == testMnemonic.length);
  final assetId = Puzzlehash.fromHex('625c2184e97576f5df1be46c15b2b8771c79e4e6f0aa42d3bfecaebe733f4b8c');

  final masterKeyPair = MasterKeyPair.fromMnemonic(mnemonic);
  print('wallet fingerprint: ${masterKeyPair.masterPublicKey.getFingerprint()}');

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 50; i++) {
    final set1 = WalletSet.fromPrivateKey(masterKeyPair.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final walletKeychain = WalletKeychain(walletsSetList)
    ..addOuterPuzzleHashesForAssetId(assetId);

  // mama coin (xch) 
  // mama coin spend (has an asset id aka tail)
  // child cat coin (cat:assetId)
  // child cat coin spend (cat spend)
  // grandchild cat coin (cat:assetId)


  final context = Context(configurationProvider);
  final blockcahinNetworkLoader = ChiaBlockchainNetworkLoader();
  context.registerFactory(NetworkFactory(blockcahinNetworkLoader.loadfromLocalFileSystem));
  const fullNode = FullNode('http://localhost:4000');
  final catTransport = CatTransport(fullNode);

  

  final genesisId = Puzzlehash.fromHex('6b3411074ffcb230e29871abdad2f7c996b67737f3277f178a6bec42cc8a0a5e');

  final mamaCoin = await fullNode.getCoinByName(genesisId);
  final mamaCoinSpend = await fullNode.getPuzzleAndSolution(mamaCoin.id, mamaCoin.spentBlockIndex);
  // print(const HexEncoder().convert(mamaCoinSpend.puzzleReveal.hash()));
  print(mamaCoinSpend.);

  final childCatCoinMaybe = await fullNode.getCoinRecordsByPuzzleHashes([Puzzlehash.fromHex('0x97e714fb28d521a8dafbe8d727af5c4c3bb04f75300021efc28adffe1a8cd6eb')]);
  print(walletKeychain.getWalletVector(childCatCoinMaybe[0].puzzlehash));
  // CatCoin.fromCoin(mamaCoin, grandmaCoinSpend, assetId);
  // final outerPuzzleHashesToSearchFor = walletKeychain.unhardenedMap.values
  //   .map((e) => e.assetIdtoOuterPuzzlehash[assetId]!).toList();
  // final puzzleHashesToSearchFor = walletKeychain.unhardenedMap.values
  //   .map((e) => e.puzzlehash).toList();
  // final catCoins = await fullNode.getCoinRecordsByPuzzleHashes(outerPuzzleHashesToSearchFor);
  // print(catCoins);
}
