import 'dart:math';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/coin_splitting/service/coin_splitting_service.dart';
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
  // print(coins.length);
  // print(coins.totalValue);

  final catWalletService = CatWalletService();

  final assetId =
      Puzzlehash.fromHex('9170b3a2214c1a017a2a9e953d541d4d15f163ef2a6f60e7c3335cba24f86401');
  keychain.addOuterPuzzleHashesForAssetId(assetId);

  // final makeCatSpendBundle = catWalletService.makeMultiIssuanceCatSpendBundle(
  //   genesisCoinId: coins[0].id,
  //   standardCoins: coins,
  //   privateKey: keychain.unhardenedWalletVectors.first.childPrivateKey,
  //   destinationPuzzlehash: keychain.puzzlehashes.first,
  //   changePuzzlehash: keychain.puzzlehashes.first,
  //   amount: 841657360,
  //   keychain: keychain,
  //   fee: 1000,
  // );

  // await fullNode.pushTransaction(makeCatSpendBundle);
  // await coinSplittingService.waitForTransactions([makeCatSpendBundle.additions.first.id]);
  // print('pushed');
  final catCoins = await fullNode
      .getCatCoinsByOuterPuzzleHashes(keychain.getOuterPuzzleHashesForAssetId(assetId));
print(catCoins.length);
  final sendCatSpendBundle = catWalletService.createSpendBundle(
    payments: [
      Payment(catCoins.totalValue, keychain.puzzlehashes.first),
    ],
    catCoinsInput: catCoins,
    standardCoinsForFee: coins,
    changePuzzlehash: keychain.puzzlehashes.first,
    keychain: keychain,
    fee: 1000,
  );

  await fullNode.pushTransaction(sendCatSpendBundle);

  await coinSplittingService.waitForTransactions([catCoins[0].id]);
  print('done joining cats');
  if (catCoins.length > 1) {
    throw Exception();
  }
  final catCoinToSplit = catCoins[0];
  print('starting split');

  await coinSplittingService.splitCoins(
    catCoinToSplit: catCoinToSplit,
    standardCoinsForFee: coins,
    keychain: keychain,
    splitWidth: 2,
    feePerCoin: 1000,
    desiredNumberOfCoins: 112,
    desiredAmountPerCoin: 101,
    changePuzzlehash: keychain.puzzlehashes.first,
  );

  final resultingCoins = await fullNode
      .getCatCoinsByOuterPuzzleHashes(keychain.getOuterPuzzleHashesForAssetId(assetId));
  print(resultingCoins.where((c) => c.amount == 101).length);
}
