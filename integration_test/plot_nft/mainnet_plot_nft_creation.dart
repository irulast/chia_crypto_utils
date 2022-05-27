@Skip('interacts with mainnet')
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/scaffolding.dart';

Future<void> main() async {
  const fullNodeRpc = FullNodeHttpRpc(
    'FULL_NODE_URL',
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
      .getCoinsByPuzzleHashes([targetPuzzleHash], includeSpentCoins: true);

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

  final plotNftSpendBundle = poolWalletService.createPoolNftSpendBundle(
    initialTargetState: initialTargetState,
    keychain: keychain,
    coins: [genesisCoin],
    p2SingletonDelayedPuzzlehash: p2SingletonDelayedPuzzlehash,
    changePuzzlehash: keychain.puzzlehashes[0],
    genesisCoinId: genesisCoin.id,
  );
  await fullNode.pushTransaction(plotNftSpendBundle);
  final launcherCoinPrototype =
      PlotNftWalletService.makeLauncherCoin(genesisCoin.id);

  print('launcher_id: ${launcherCoinPrototype.id}');
  print(
    'farmer_public_key: ${masterSkToFarmerSk(keychainSecret.masterPrivateKey).getG1().toHex()}',
  );
  final poolPuzzlehash = poolWalletService.launcherIdToP2Puzzlehash(
    launcherCoinPrototype.id,
    p2SingletonDelayedTime,
    p2SingletonDelayedPuzzlehash,
  );
  print('pool_puzzle_hash: $poolPuzzlehash');
  print(
    'pool_address: ${Address.fromPuzzlehash(poolPuzzlehash, poolWalletService.blockchainNetwork.addressPrefix).address}',
  );
  print(
    'xch_payout_address: ${Address.fromPuzzlehash(keychain.hardenedMap.values.first.puzzlehash, poolWalletService.blockchainNetwork.addressPrefix).address}',
  );

  final launcherCoin = await fullNode.getCoinById(launcherCoinPrototype.id);

  if (launcherCoin != null) {
    final launcherCoinSpend = await fullNode.getCoinSpend(launcherCoin);

    print('singleton_puzzle_hash: ${launcherCoinSpend!.solution.first()}');
    print('pool_state:');
    print(
      PlotNft.fromCoinSpend(launcherCoinSpend, launcherCoin.id)
          .extraData
          .poolState,
    );
  }
}
