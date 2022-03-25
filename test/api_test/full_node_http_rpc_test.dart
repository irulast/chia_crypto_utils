import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/chia_full_node_interface.dart';
import 'package:chia_utils/src/api/full_node_http_rpc.dart';

Future<void> main() async {
  final testMnemonic = 'guilt rail green junior loud track cupboard citizen begin play west adapt myself panda eye finger nuclear someone update light dance exotic expect layer'.split(' ');

  final masterKeyPair = MasterKeyPair.fromMnemonic(testMnemonic);

  final walletsSetList = <WalletSet>[];
  for (var i = 20; i < 55; i++) {
    final set1 = WalletSet.fromPrivateKey(masterKeyPair.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final assetId = Puzzlehash.fromHex('e224fbe34909e0192800a3fe841013572975cac5d7c67ae5e79cef31efb6d808');

  final keychain = WalletKeychain(walletsSetList)
    ..addOuterPuzzleHashesForAssetId(assetId);
  const fullNodeRpc = FullNodeHttpRpc('http://localhost:4000');
  const fullNode = ChiaFullNodeInterface(fullNodeRpc);


  final catCoins = await fullNode.getCatCoinsByOuterPuzzleHashes(keychain.getOuterPuzzleHashesForAssetId(assetId));
  final c = catCoins[0];
  final parent = await fullNode.getCoinById(c.parentCoinInfo);
  final parentSpend = await fullNode.getCoinSpend(parent!);
  print(c.toJson());
  // print(parentSpend!.toJson());
  // await fullNodeRpc.(Puzzlehash.fromHex('6b3411074ffcb230e29871abdad2f7c996b67737f3277f178a6bec42cc8a0a5e'), 10000);
}
