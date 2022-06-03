@Skip('interacts with mainnet')
import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/pool/pool_interface.dart';
import 'package:chia_crypto_utils/src/api/pool/service/pool_service.dart';
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
  final poolInterface = PoolInterface(poolUrl, certBytes: certificateBytes);

  final poolService = PoolService(poolInterface, fullNode);

  final mnemonic =
      'organ puppy mandate during obscure insane yard clever vacuum human barely wire slogan road crack dad fitness mutual typical orchard sunny cool stereo noodle'
          .split(' ');
  print('mnemonic: ${mnemonic.join(' ')}');
  final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);
  print(keychainSecret.fingerprint);
  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 6; i++) {
    final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final keychain = WalletKeychain.fromWalletSets(walletsSetList);
  print('masterPublicKey: ${keychainSecret.masterPublicKey}');

  // print('owner keys at index: ');
  // for (var i = 0; i < 10; i++) {
  //   final ownerPk = masterSkToSingletonOwnerSk(keychainSecret.masterPrivateKey, i).getG1();
  //   print('$i -> $ownerPk');
  // }

  // print('unhardenedPuzzlehashes at index:');
  // for (var i = 0; i < 5; i++) {
  //   final ph = keychain.puzzlehashes[i];
  //   print('$i -> $ph');
  // }

  final coins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);
  print(coins);
  // return;

  final chiaLauncherId =
      Bytes.fromHex('876adf3ef717d4a7735d6e3fcdc582811a1be11656aec5e6dcd868f6ee69457c');
  final lauchercoin = await fullNode.getCoinById(chiaLauncherId);
  final genesisCoin = await fullNode.getCoinById(lauchercoin!.parentCoinInfo);

  final chiaPayoutAddress =
      Address('xch1z630wrqdz5976xfnpeq9lgy2yuk3zqhga2s6xpfjqk0y8zmugwlqymglyr');

  final chiaPayoutPuzzlehash = chiaPayoutAddress.toPuzzlehash();
  // print('chia payout ph: $chiaPayoutPuzzlehash');

  // final genesisSpend = await fullNode.getCoinSpend(genesisCoin!);
  // print('chia genesis spend:');
  // print(genesisSpend);
  // print(' ');
  // print('-----------');
  // print(' ');

  // final launcherSpend = await fullNode.getCoinSpend(lauchercoin);
  // print('chia launcher spend:');
  // print(launcherSpend);
  // print(' ');
  // print('-----------');
  // print(' ');

  final delayPh = keychain.puzzlehashes[4];
  print('delayPh: $delayPh');
  final ownerSk = masterSkToSingletonOwnerSk(
    keychainSecret.masterPrivateKey,
    3,
  );
  final ownerPk = ownerSk.getG1();
  print('ownerPk: $ownerPk');

  LoggingContext().setLogLevel(LogLevel.low);

  // final launcherId = await poolService.createPlotNftForPool(
  //   p2SingletonDelayedPuzzlehash: delayPh,
  //   masterPrivateKey: keychainSecret.masterPrivateKey,
  //   singletonOwnerPrivateKeyDerivationIndex: 3,
  //   coins: [coins[0]],
  //   keychain: keychain,
  //   changePuzzlehash: keychain.puzzlehashes[3],
  // );
  // print(launcherId);
  final launcherId =
      Bytes.fromHex('9204dfdc12a9b896a7c143bd905fabf5a4910f4ea844ea7e9540c662a40dd594');
  // final launcherCoin = await fullNode.getCoinById(launcherId);
  // // print(launcherCoin);
  // final plotNft = await fullNode.getPlotNftByLauncherId(launcherId);
  // print(plotNft);
  // print('payout_address: ${chiaPayoutAddress.address}');

  await poolService.getFarmer(
    launcherId: launcherId,
    masterPrivateKey: keychainSecret.masterPrivateKey,
    singletonOwnerPrivateKeyDerivationIndex: 3,
);
  // await poolService.registerPlotNftWithPool(
  //   plotNft: plotNft,
  //   masterPrivateKey: keychainSecret.masterPrivateKey,
  //   singletonOwnerPrivateKeyDerivationIndex: 3,
  //   payoutPuzzlehash: chiaPayoutAddress.toPuzzlehash(),
  // );

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
