import 'dart:convert';
import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/full_node.dart';


void main() {
  final fullNode = FullNode('http://localhost:4000');
  final configurationProvider = ConfigurationProvider()
    ..setConfig(NetworkFactory.configId, {
      'yaml_file_path': 'lib/src/networks/chia/testnet10/config.yaml'
    }
  );

  final context = Context(configurationProvider);
  final blockcahinNetworkLoader = ChiaBlockchainNetworkLoader();
  context.registerFactory(NetworkFactory(blockcahinNetworkLoader.loadfromLocalFileSystem));
  final walletService = WalletService(fullNode, context);

  final destinationAddress = Address('txch1pdar6hnj8c9sgm74r72u40ed8cnpduzan5vr86qkvpftg0v52jksxp6hy3');

  const testMnemonic = [
      'elder', 'quality', 'this', 'chalk', 'crane', 'endless',
      'machine', 'hotel', 'unfair', 'castle', 'expand', 'refuse',
      'lizard', 'vacuum', 'embody', 'track', 'crash', 'truth',
      'arrow', 'tree', 'poet', 'audit', 'grid', 'mesh',
  ];

  final masterKeyPair = MasterKeyPair.fromMnemonic(testMnemonic);

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 20; i++) {
    final set1 = WalletSet.fromPrivateKey(masterKeyPair.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final walletKeychain = WalletKeychain(walletsSetList);
  const assetId = "625c2184e97576f5df1be46c15b2b8771c79e4e6f0aa42d3bfecaebe733f4b8c";
  const coinJson = '{"coin": {"amount": 5000, "parent_coin_info": "0x8f8db805b6b4c17271c842a06bd880ffe17bbb6d7b536ff57b522063fcc52a49", "puzzle_hash": "0x5db372b6e7577013035b4ee3fced2a7466d6ff1d3716b182afe520d83ee3427a"}, "coinbase": false, "confirmed_block_index": 669890, "spent": false, "spent_block_index": 0, "timestamp": 1646850434}';
  final coin = Coin.fromChiaCoinRecordJson(jsonDecode(coinJson) as Map<String, dynamic>);

  final walletVector = walletKeychain.getWalletVector(coin.puzzlehash);
  print((walletVector != null).toString());
  
}
