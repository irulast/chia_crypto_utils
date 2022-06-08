import 'dart:math';

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
  final keychain = WalletKeychain.fromCoreSecret(keychainSecret, walletSize: 50);
  final fullNodeUtils = FullNodeUtils(Network.testnet10);
  FullNodeContext().setCertificateBytes(fullNodeUtils.certBytes);
  FullNodeContext().setKeyBytes(fullNodeUtils.keyBytes);
  ChiaNetworkContextWrapper().registerNetworkContext(Network.testnet10);

  final fullNode = ChiaFullNodeInterface.fromContext();

  final walletService = StandardWalletService();

  print(keychain.puzzlehashes.length);

  var coins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);

  final startingNumberOfCoins = coins.length;

  const desiredMinimumNumberOfCoins = 10000;

  final numberOfSplits = (log(desiredMinimumNumberOfCoins / startingNumberOfCoins) / log(2)).ceil();

  for (var i = 0; i < numberOfSplits; i++) {
    final numberOfCoinsToCreate = coins.length * 2;
    final fee = numberOfCoinsToCreate * 1000;
    print('fee: $fee');
    print('number of coins created in split: $numberOfCoinsToCreate');
    final payments = <Payment>{};
    for (final coin in coins) {
      final paymentPuzzleHash = keychain.puzzlehashes[Random().nextInt(50)];

      final childCoinOneAmount = coin.amount ~/ 2;
      final childCoinTwoAmount = coin.amount - childCoinOneAmount - (fee / coins.length).ceil();

      final uniquePaymentOne = getUniquePayment(childCoinOneAmount, paymentPuzzleHash, payments);
      payments.add(uniquePaymentOne);

      final uniquePaymentTwo = getUniquePayment(childCoinTwoAmount, paymentPuzzleHash, payments);
      payments.add(uniquePaymentTwo);
    }

    final spendBundle = walletService.createSpendBundle(
      payments: payments.toList(),
      coinsInput: coins,
      keychain: keychain,
      changePuzzlehash: Program.fromInt(2).hash(),
      fee: fee,
    );

    await fullNode.pushTransaction(spendBundle);

    final addition = spendBundle.additions.first;
    while ((await fullNode.getCoinById(addition.id)) == null) {
      await Future<void>.delayed(const Duration(seconds: 19));
      print('waiting for spend bundle to be include...');
    }
    coins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes);
    print('${((i / numberOfSplits) * 100).round()}% done');
  }

  print('done splitting. ${coins.length} coins created');
}

Payment getUniquePayment(int amount, Puzzlehash puzzlehash, Set<Payment> otherPayments) {
  var payment = Payment(amount, puzzlehash);
  while (otherPayments.contains(payment)) {
    payment = Payment(amount - 1, puzzlehash);
  }
  return payment;
}
