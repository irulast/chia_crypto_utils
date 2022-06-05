// ignore_for_file: lines_longer_than_80_chars, unused_import

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/exceptions/change_puzzlehash_needed_exception.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/origin_id_not_in_coins_exception.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/spend_bundle_validation/duplicate_coin_exception.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/spend_bundle_validation/multiple_origin_coin_exception.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final walletService = StandardWalletService();

  final destinationPuzzlehash = const Address(
    'txch1pdar6hnj8c9sgm74r72u40ed8cnpduzan5vr86qkvpftg0v52jksxp6hy3',
  ).toPuzzlehash();

  const testMnemonic = [
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

  final keychainSecret = KeychainCoreSecret.fromMnemonic(testMnemonic);

  final walletsSetList = <WalletSet>[
    for (var i = 0; i < 20; i++) WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i),
  ];

  final walletKeychain = WalletKeychain.fromWalletSets(walletsSetList);

  final coinPuzzlehash = walletKeychain.unhardenedMap.values.toList()[0].puzzlehash;
  final changePuzzlehash = walletKeychain.unhardenedMap.values.toList()[1].puzzlehash;

  final parentInfo0 = Bytes([
    227,
    176,
    196,
    66,
    152,
    252,
    28,
    20,
    154,
    251,
    244,
    200,
    153,
    111,
    185,
    36,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    3
  ]);
  final parentInfo1 = Bytes([
    227,
    176,
    196,
    66,
    152,
    252,
    28,
    20,
    154,
    251,
    244,
    200,
    153,
    111,
    185,
    36,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    6
  ]);
  final parentInfo2 = Bytes([
    227,
    176,
    196,
    66,
    152,
    252,
    28,
    20,
    154,
    251,
    244,
    200,
    153,
    111,
    185,
    36,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    6
  ]);
  final coin0 = Coin(
    spentBlockIndex: 0,
    confirmedBlockIndex: 100,
    coinbase: false,
    timestamp: 100177271,
    parentCoinInfo: parentInfo0,
    puzzlehash: coinPuzzlehash,
    amount: 100000,
  );
  final coin1 = Coin(
    spentBlockIndex: 0,
    confirmedBlockIndex: 1000,
    coinbase: false,
    timestamp: 100177372,
    parentCoinInfo: parentInfo1,
    puzzlehash: coinPuzzlehash,
    amount: 500000,
  );
  final coin2 = Coin(
    spentBlockIndex: 0,
    confirmedBlockIndex: 2000,
    coinbase: false,
    timestamp: 100179373,
    parentCoinInfo: parentInfo2,
    puzzlehash: coinPuzzlehash,
    amount: 200000,
  );
  final coins = [coin0, coin1, coin2];

  test('Should create valid spendbundle', () {
    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(550000, destinationPuzzlehash)],
      coinsInput: coins,
      changePuzzlehash: changePuzzlehash,
      keychain: walletKeychain,
    );

    walletService.validateSpendBundle(spendBundle);
  });

  test('Should create valid spendbundle with fee', () {
    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(550000, destinationPuzzlehash)],
      coinsInput: coins,
      changePuzzlehash: changePuzzlehash,
      keychain: walletKeychain,
      fee: 10000,
    );

    walletService.validateSpendBundle(spendBundle);
  });

  test('Should create valid spendbundle with multiple payments', () {
    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(548000, destinationPuzzlehash), Payment(2000, destinationPuzzlehash)],
      coinsInput: coins,
      changePuzzlehash: changePuzzlehash,
      keychain: walletKeychain,
      fee: 10000,
    );

    walletService.validateSpendBundle(spendBundle);
  });

  test('Should create valid spendbundle with only fee', () {
    final spendBundle = walletService.createSpendBundle(
      payments: [],
      coinsInput: coins,
      changePuzzlehash: changePuzzlehash,
      keychain: walletKeychain,
      fee: 10000,
    );

    walletService.validateSpendBundle(spendBundle);
  });

  test('Should create valid spendbundle with originId', () {
    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(550000, destinationPuzzlehash)],
      coinsInput: coins,
      changePuzzlehash: changePuzzlehash,
      keychain: walletKeychain,
      originId: coin2.id,
    );

    walletService.validateSpendBundle(spendBundle);
  });

  test('Should fail when given originId not in coins', () async {
    expect(
      () => walletService.createSpendBundle(
        payments: [Payment(550000, destinationPuzzlehash)],
        coinsInput: coins,
        changePuzzlehash: changePuzzlehash,
        keychain: walletKeychain,
        originId: Bytes.fromHex('ff8'),
      ),
      throwsA(isA<OriginIdNotInCoinsException>()),
    );
  });

  test('Should create valid spendbundle with total amount less than coin value', () {
    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(3000, destinationPuzzlehash)],
      coinsInput: coins,
      changePuzzlehash: changePuzzlehash,
      keychain: walletKeychain,
    );

    walletService.validateSpendBundle(spendBundle);
  });

  test('Should throw exception on duplicate coin', () {
    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(3000, destinationPuzzlehash)],
      coinsInput: [...coins, coin0],
      changePuzzlehash: changePuzzlehash,
      keychain: walletKeychain,
    );
    expect(
      () => walletService.validateSpendBundle(spendBundle),
      throwsA(isA<DuplicateCoinException>()),
    );
  });

  test('Should create valid spendbundle without change puzzlehash when there is no change', () {
    final totalCoinsValue = coins.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(totalCoinsValue, destinationPuzzlehash)],
      coinsInput: coins,
      keychain: walletKeychain,
    );

    walletService.validateSpendBundle(spendBundle);
  });

  test('Should throw exception when change puzzlehash is not given and there is change', () {
    expect(
      () {
        walletService.createSpendBundle(
          payments: [Payment(100, destinationPuzzlehash)],
          coinsInput: [...coins, coin0],
          keychain: walletKeychain,
        );
      },
      throwsA(isA<ChangePuzzlehashNeededException>()),
    );
  });
}
