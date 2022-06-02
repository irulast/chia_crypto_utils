@Skip('interacts with mainnet')
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/scaffolding.dart';

Future<void> main() async {
  const fullNodeRpc = FullNodeHttpRpc(
    'https://chia.irulast-prod.com',
  );

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  const fullNode = ChiaFullNodeInterface(fullNodeRpc);

  final mnemonic =
      'leader fresh forest lady decline soup twin crime remember doll push hip fox future arctic easy rent roast ketchup skin hip crane dilemma whip'
          .split(' ');
  print('mnemonic: ${mnemonic.join(' ')}');
  final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 3; i++) {
    final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final keychain = WalletKeychain(walletsSetList);

  final targetPuzzleHash = keychain.unhardenedMap.values.first.puzzlehash;

  final targetAddress = Address.fromPuzzlehash(
    targetPuzzleHash,
    NetworkContext().blockchainNetwork.addressPrefix,
  );
  print(targetAddress.address);

  final coins = await fullNode
      .getCoinsByPuzzleHashes([targetPuzzleHash]);
  print(coins);

  coins.sort(
    (a, b) => b.spentBlockIndex.compareTo(a.spentBlockIndex),
  );

  final poolWalletService = PlotNftWalletService();

  final p2SingletonDelayedPuzzlehash = keychain.puzzlehashes[2];
  const p2SingletonDelayedTime = 604800;
  final genesisCoin = coins[0];

  final initialTargetState = PoolState(
    poolSingletonState: PoolSingletonState.farmingToPool,
    targetPuzzlehash: Puzzlehash.fromHex(
      '6bde1e0c6f9d3b93dc5e7e878723257ede573deeed59e3b4a90f5c86de1a0bd3',
    ),
    ownerPublicKey: keychain.unhardenedMap.values.first.childPublicKey,
    relativeLockHeight: 100,
    poolUrl: 'https://xch-us-west.flexpool.io',
  );

  // final plotNftSpendBundle = poolWalletService.createPoolNftSpendBundle(
  //   initialTargetState: initialTargetState,
  //   keychain: keychain,
  //   coins: [genesisCoin],
  //   p2SingletonDelayedPuzzlehash: p2SingletonDelayedPuzzlehash,
  //   changePuzzlehash: keychain.puzzlehashes[0],
  //   genesisCoinId: genesisCoin.id,
  // );
  // await fullNode.pushTransaction(plotNftSpendBundle);

  // final launcherCoinPrototype =
  //     PlotNftWalletService.makeLauncherCoin(genesisCoin.id);
  final launcherId =
      Bytes.fromHex('9204dfdc12a9b896a7c143bd905fabf5a4910f4ea844ea7e9540c662a40dd594');

  // print('launcher_id: ${launcherId}');

      final plotNft = await fullNode.getPlotNftByLauncherId(launcherId);
      print('plot NFT: ');
      print(plotNft);


    print('singleton_puzzle_hash: ${plotNft.singletonCoin.puzzlehash}');
    print('pool_state:');
    print(
      plotNft.extraData.poolState
    );

  final poolPuzzlehash = poolWalletService.launcherIdToP2Puzzlehash(
    launcherId,
    p2SingletonDelayedTime,
    p2SingletonDelayedPuzzlehash,
  );
  // print('pool_puzzle_hash: $poolPuzzlehash');
  // print(
  //   'pool_address: ${Address.fromPuzzlehash(poolPuzzlehash, poolWalletService.blockchainNetwork.addressPrefix).address}',
  // );
  // print(
  //   'xch_payout_address: ${Address.fromPuzzlehash(keychain.hardenedMap.values.first.puzzlehash, poolWalletService.blockchainNetwork.addressPrefix).address}',
  // );

}
