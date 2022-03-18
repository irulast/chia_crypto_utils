import 'package:chia_utils/src/context/context.dart';
import 'package:chia_utils/src/core/models/models.dart';
import 'package:chia_utils/src/networks/chia/chia_blockckahin_network_loader.dart';
import 'package:chia_utils/src/networks/network_factory.dart';
import 'package:chia_utils/src/standard/service/wallet.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  final configurationProvider = ConfigurationProvider()
    ..setConfig(NetworkFactory.configId, {
      'yaml_file_path': 'lib/src/networks/chia/testnet10/config.yaml'
    }
  );

  final context = Context(configurationProvider);
  final blockcahinNetworkLoader = ChiaBlockchainNetworkLoader();
  context.registerFactory(NetworkFactory(blockcahinNetworkLoader.loadfromLocalFileSystem));
  final walletService = StandardWalletService(context);

  final destinationPuzzlehash = Address('txch1pdar6hnj8c9sgm74r72u40ed8cnpduzan5vr86qkvpftg0v52jksxp6hy3').toPuzzlehash();

  const testMnemonic = [
      'elder', 'quality', 'this', 'chalk', 'crane', 'endless',
      'machine', 'hotel', 'unfair', 'castle', 'expand', 'refuse',
      'lizard', 'vacuum', 'embody', 'track', 'crash', 'truth',
      'arrow', 'tree', 'poet', 'audit', 'grid', 'mesh',
  ];

  final masterKeyPair = MasterKeyPair.fromMnemonic(testMnemonic);

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 20; i++) {
    final set1 = WalletSet.fromPrivateKey(masterKeyPair.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final walletKeychain = WalletKeychain(walletsSetList);

  final coinPuzzlehash = walletKeychain.unhardenedMap.values.toList()[0].puzzlehash;
  final changePuzzlehash = walletKeychain.unhardenedMap.values.toList()[1].puzzlehash;

  const parentInfo0 = Puzzlehash([227, 176, 196, 66, 152, 252, 28, 20, 154, 251, 244, 200, 153, 111, 185, 36, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3]);
  const parentInfo1 = Puzzlehash([227, 176, 196, 66, 152, 252, 28, 20, 154, 251, 244, 200, 153, 111, 185, 36, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6]);
  const parentInfo2 = Puzzlehash([227, 176, 196, 66, 152, 252, 28, 20, 154, 251, 244, 200, 153, 111, 185, 36, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6]);
  final coin0 = Coin(spentBlockIndex: 0, confirmedBlockIndex: 100, coinbase: false, timestamp: 100177271, parentCoinInfo: parentInfo0, puzzlehash: coinPuzzlehash, amount: 100000);
  final coin1 = Coin(spentBlockIndex: 0, confirmedBlockIndex: 1000, coinbase: false, timestamp: 100177372, parentCoinInfo: parentInfo1, puzzlehash: coinPuzzlehash, amount: 500000);
  final coin2 = Coin(spentBlockIndex: 0, confirmedBlockIndex: 2000, coinbase: false, timestamp: 100179373, parentCoinInfo: parentInfo2, puzzlehash: coinPuzzlehash, amount: 200000);
  final coins = [coin0, coin1, coin2];
  test('Should create valid spendbundle', () {
    final spendBundle = walletService.createSpendBundle(
        coins,
        550000,
        destinationPuzzlehash,
        changePuzzlehash,
        walletKeychain,
    );

    walletService.validateSpendBundle(spendBundle);
  });

  test('Should create valid spendbundle with fee', () {
    final spendBundle = walletService.createSpendBundle(
        coins,
        550000,
        destinationPuzzlehash,
        changePuzzlehash,
        walletKeychain,
        fee: 10000,
    );

    walletService.validateSpendBundle(spendBundle);
  });

  test('Should create valid spendbundle with only fee', () {
    final spendBundle = walletService.createSpendBundle(
        coins,
        0,
        destinationPuzzlehash,
        changePuzzlehash,
        walletKeychain,
        fee: 10000,
    );

    walletService.validateSpendBundle(spendBundle);
  });

  test('Should create valid spendbundle with originId', () {
    final spendBundle = walletService.createSpendBundle(
        coins,
        550000,
        destinationPuzzlehash,
        changePuzzlehash,
        walletKeychain,
        originId: coin2.id,
    );

    walletService.validateSpendBundle(spendBundle);
  });

  test('Should create valid spendbundle with total amount less than coin value', () {
    final spendBundle = walletService.createSpendBundle(
        coins,
        3000,
        destinationPuzzlehash,
        changePuzzlehash,
        walletKeychain,
    );

    walletService.validateSpendBundle(spendBundle);
  });

   test('Should throw exception on duplicate coin', () {
    final spendBundle = walletService.createSpendBundle(
        [...coins, coin0],
        3000,
        destinationPuzzlehash,
        changePuzzlehash,
        walletKeychain,
    );
    expect(() => walletService.validateSpendBundle(spendBundle), throwsException);
  });
}
