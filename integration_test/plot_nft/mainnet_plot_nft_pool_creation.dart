@Skip('interacts with mainnet')
import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/pool/pool_http_rest.dart';
import 'package:chia_crypto_utils/src/api/pool/pool_interface.dart';
import 'package:chia_crypto_utils/src/api/pool/service/pool_service.dart';
import 'package:chia_crypto_utils/src/core/models/singleton_wallet_vector.dart';
import 'package:test/scaffolding.dart';

Future<void> main() async {
  const poolUrl = 'https://xch-us-west.flexpool.io';
  const fullNodeUrl = 'https://chia.irulast-prod.com';

  final certificateBytes =
      Bytes(File('/Users/nvjoshi/code/work/irulast/mozilla-ca/cacert.pem').readAsBytesSync());

  const fullNodeRpc = FullNodeHttpRpc(
    fullNodeUrl,
  );

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  const fullNode = ChiaFullNodeInterface(fullNodeRpc);
  final poolHttpRest = PoolHttpREST(poolUrl, certBytes: certificateBytes);
  final poolInterface = PoolInterface(poolHttpRest);

  final poolService = PoolService(poolInterface, fullNode);

  final mnemonic =
      'organ puppy mandate during obscure insane yard clever vacuum human barely wire slogan road crack dad fitness mutual typical orchard sunny cool stereo noodle'
          .split(' ');
  print('mnemonic: ${mnemonic.join(' ')}');
  final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);
  print(keychainSecret.fingerprint);
  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 20; i++) {
    final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final keychain = WalletKeychain.fromWalletSets(walletsSetList);

  final singletonWalletVector =
      SingletonWalletVector.fromMasterPrivateKey(keychainSecret.masterPrivateKey, 20);

  final coins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

  final delayPh = keychain.puzzlehashes[10];
  LoggingContext().setLogLevel(LogLevel.low);

  // final launcherId = await poolService.createPlotNftForPool(
  //   p2SingletonDelayedPuzzlehash: delayPh,
  //   singletonWalletVector: singletonWalletVector,
  //   coins: [coins[0]],
  //   keychain: keychain,
  //   changePuzzlehash: keychain.puzzlehashes[3],
  // );
  // print(launcherId);
  final launcherId =
      Bytes.fromHex('e63a91ac5c23070ee99bd7919ec3c57842c852f98856ccd16ec12a87f9230b1d');
  final launcherCoin = await fullNode.getCoinById(launcherId);
  print(launcherCoin);
  final plotNft = await fullNode.getPlotNftByLauncherId(launcherId);
  // // print(plotNft);
  // // print('payout_address: ${chiaPayoutAddress.address}');
  //   LoggingContext().setLogLevel(LogLevel.low);

  // await poolService.getFarmerInfo(
  //   launcherId: launcherId,
  //   authenticationPrivateKey: singletonWalletVector.poolingAuthenticationPrivateKey,
  // );

  // final chiaPayoutAddress =
  //     Address('xch1z630wrqdz5976xfnpeq9lgy2yuk3zqhga2s6xpfjqk0y8zmugwlqymglyr');

  // final chiaPayoutPuzzlehash = chiaPayoutAddress.toPuzzlehash();
  await poolService.registerAsFarmerWithPool(
    plotNft: plotNft,
    singletonWalletVector: singletonWalletVector,
    payoutPuzzlehash: keychain.puzzlehashes[19],
  );

  // test('get chia plot nft', () async {
  //   // final chiaLauncherId =
  //   //     Bytes.fromHex('876adf3ef717d4a7735d6e3fcdc582811a1be11656aec5e6dcd868f6ee69457c');
  //   // final lauchercoin = await fullNode.getCoinById(chiaLauncherId);
  //   // final genesisCoin = await fullNode.getCoinById(lauchercoin!.parentCoinInfo);
  //   // // final launcherCoin = await fullNode.getCoinById(chiaLauncherId);

  //   // final chiaPlotNft = await fullNode.getPlotNftByLauncherId(chiaLauncherId);
  //   // print(chiaPlotNft);
  // });
}
