import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/full_node/full_node_utils.dart';

void main() async {
  const mnemonic = [
    'elder',
    'quality',
    'this',
    'chalk',
    'crane',
    'endless',
    'machine',
    'hotel',
    'unfair',
    'castle',
    'expand',
    'refuse',
    'lizard',
    'vacuum',
    'embody',
    'track',
    'crash',
    'truth',
    'arrow',
    'tree',
    'poet',
    'audit',
    'grid',
    'mesh',
  ];

  final keychainSecret = KeychainCoreSecret.fromMnemonic(mnemonic);

  print(keychainSecret.fingerprint);
  final keychain = WalletKeychain.fromCoreSecret(keychainSecret, walletSize: 50);
  final fullNodeUtils = FullNodeUtils(Network.testnet10);
  FullNodeContext().setCertificateBytes(fullNodeUtils.certBytes);
  FullNodeContext().setKeyBytes(fullNodeUtils.keyBytes);
  ChiaNetworkContextWrapper().registerNetworkContext(Network.testnet10);

  final fullNode = ChiaFullNodeInterface.fromContext();

  final coinSplittingService = CoinSplittingService(fullNode);

  final coins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

  final assetId =
      Puzzlehash.fromHex('a84ac773179db99448e22eb1929552f16da54b2261e487f6017f84ebf1e5a233');
  keychain.addOuterPuzzleHashesForAssetId(assetId);

  final catCoins = await fullNode
      .getCatCoinsByOuterPuzzleHashes(keychain.getOuterPuzzleHashesForAssetId(assetId));
  print(catCoins.map((e) => e.amount));

  final catCoinToSplit = catCoins[0];

  await coinSplittingService.splitCoins(
    catCoinToSplit: catCoinToSplit,
    standardCoinsForFee: coins,
    keychain: keychain,
    splitWidth: 3,
    feePerCoin: 10000,
    desiredNumberOfCoins: 91,
    desiredAmountPerCoin: 101,
    changePuzzlehash: keychain.puzzlehashes.first,
  );

  final resultingCoins = await fullNode
      .getCatCoinsByOuterPuzzleHashes(keychain.getOuterPuzzleHashesForAssetId(assetId));
  print(resultingCoins.where((c) => c.amount == 101).length);
}
