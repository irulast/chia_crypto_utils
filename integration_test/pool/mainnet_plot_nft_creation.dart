import 'package:chia_utils/chia_crypto_utils.dart';

Future<void> main() async {
  const fullNodeRpc = FullNodeHttpRpc(
    'https://chia.irulast-prod.com',
  );
  // LoggingContext().setLogLevel(LogLevel.low);
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  const fullNode = ChiaFullNodeInterface(fullNodeRpc);
  

  final mnemonic =
      'leader fresh forest lady decline soup twin crime remember doll push hip fox future arctic easy rent roast ketchup skin hip crane dilemma whip'
          .split(' ');
  final masterKeyPair = MasterKeyPair.fromMnemonic(mnemonic);

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 2; i++) {
    final set1 = WalletSet.fromPrivateKey(masterKeyPair.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final keychain = WalletKeychain(walletsSetList);

  final targetPuzzleHash = keychain.unhardenedMap.values.first.puzzlehash;
  print(targetPuzzleHash);
  final targetAddress = Address.fromPuzzlehash(targetPuzzleHash, NetworkContext().blockchainNetwork.addressPrefix);
  print(targetAddress.address);
  // curl -d '{"address": "xch1p29w7ynqs3cmqfazh94z8ylz0sedv5pvgvymsryqqhnka876ceqslv7hma", "amount": 0.0000000001}' -H "Content-Type: application/json" -X POST https://chia-faucet.irulast-prod.com/api/request
  final coins =  await fullNode.getCoinsByPuzzleHashes([targetPuzzleHash]);
  print(coins);
}
