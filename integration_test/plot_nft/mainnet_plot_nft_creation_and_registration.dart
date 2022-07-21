@Skip('interacts with mainnet')
import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

import 'package:test/scaffolding.dart';

Future<void> main() async {
  const poolUrl = 'https://xch-us-west.flexpool.io';
  const fullNodeUrl = 'FULL_NODE_URL';

  // clone this for certificate chain: https://github.com/Chia-Network/mozilla-ca.git
  final certificateBytes = Bytes(File('CERTIFICATE_BYTES_PATH').readAsBytesSync());

  const fullNodeRpc = FullNodeHttpRpc(
    fullNodeUrl,
  );

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  const fullNode = ChiaFullNodeInterface(fullNodeRpc);
  final poolHttpRest = PoolHttpREST(poolUrl, certBytes: certificateBytes);
  final poolInterface = PoolInterface(poolHttpRest);

  final poolService = PoolServiceImpl(poolInterface, fullNode);

  final mnemonic =
      'organ puppy mandate during obscure insane yard clever vacuum human barely wire slogan road crack dad fitness mutual typical orchard sunny cool stereo noodle'
          .split(' ');

  final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);
  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 5; i++) {
    final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final keychain = WalletKeychain.fromWalletSets(walletsSetList);

  final singletonWalletVector =
      SingletonWalletVector.fromMasterPrivateKey(keychainSecret.masterPrivateKey, 20);

  final coins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

  final delayPh = keychain.puzzlehashes[4];

  final launcherId = await poolService.createPlotNftForPool(
    p2SingletonDelayedPuzzlehash: delayPh,
    singletonWalletVector: singletonWalletVector,
    coins: coins,
    fee: 50,
    keychain: keychain,
    changePuzzlehash: keychain.puzzlehashes[3],
  );

  var launcherCoin = await fullNode.getCoinById(launcherId);

  while (launcherCoin == null) {
    print('waiting for plot nft to be created...');
    await Future<void>.delayed(const Duration(seconds: 15));
    launcherCoin = await fullNode.getCoinById(launcherId);
  }

  final plotNft = await fullNode.getPlotNftByLauncherId(launcherId);

  await poolService.registerAsFarmerWithPool(
    plotNft: plotNft!,
    singletonWalletVector: singletonWalletVector,
    payoutPuzzlehash: keychain.puzzlehashes[1],
  );
}
