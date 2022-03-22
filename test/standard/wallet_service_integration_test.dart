// ignore_for_file: lines_longer_than_80_chars

@Skip('Integration test')
import 'package:chia_utils/src/api/full_node.dart';
import 'package:chia_utils/src/context/context.dart';
import 'package:chia_utils/src/core/models/address.dart';
import 'package:chia_utils/src/core/models/bytes.dart';
import 'package:chia_utils/src/core/models/coin.dart';
import 'package:chia_utils/src/core/models/master_key_pair.dart';
import 'package:chia_utils/src/core/models/wallet_keychain.dart';
import 'package:chia_utils/src/core/models/wallet_set.dart';
import 'package:chia_utils/src/networks/chia/chia_blockckahin_network_loader.dart';
import 'package:chia_utils/src/networks/network_factory.dart';
import 'package:chia_utils/src/standard/service/wallet.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

Future<void> main() async {
  const fullNode = FullNode('http://localhost:4000');
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

  final unhardenedPuzzlehashes = walletKeychain.unhardenedMap.values.map((vec) => vec.puzzlehash).toList();

  final coins = await fullNode.getCoinRecordsByPuzzleHashes(unhardenedPuzzlehashes);


  test('Should push transaction with fee', () async {
    const amountToSend = 10000;
    const fee = 10000;
    const totalAmount = amountToSend + fee;

    final coinsToSpend = selectCoinsToSpend(coins, totalAmount);

    coins.removeWhere(coinsToSpend.contains);

    final spendBundle = walletService.createSpendBundle(
        coinsToSpend,
        amountToSend,
        destinationPuzzlehash,
        walletKeychain.unhardenedMap.values.toList()[0].puzzlehash,
        walletKeychain,
        fee: fee,
    );

    await fullNode.pushTransaction(spendBundle);
  });

  test('Should push transaction without fee', () async {
    const amountToSend = 10000;

    final coinsToSpend =
        selectCoinsToSpend(coins, amountToSend);
    
    coins.removeWhere(coinsToSpend.contains);

    final spendBundle = walletService.createSpendBundle(
        coinsToSpend,
        amountToSend,
        destinationPuzzlehash,
        walletKeychain.unhardenedMap.values.toList()[0].puzzlehash,
        walletKeychain,
    );

    await fullNode.pushTransaction(spendBundle);
  });

  test('Should push transaction with origin', () async {
    const amountToSend = 10000;

    final coinsToSpend =
        selectCoinsToSpend(coins, amountToSend);

    coins.removeWhere(coinsToSpend.contains);

    final spendBundle = walletService.createSpendBundle(
        coinsToSpend,
        amountToSend,
        destinationPuzzlehash,
        walletKeychain.unhardenedMap.values.toList()[0].puzzlehash,
        walletKeychain,
        originId: coinsToSpend[coinsToSpend.length - 1].id,
    );

    await fullNode.pushTransaction(spendBundle);
  });

  test('Should fail when given originId not in coins', () async {
    final coinsForThisTest = coins.sublist(coins.length ~/ 2);
    const amountToSend = 10000;

    final coinsToSpend =
        selectCoinsToSpend(coinsForThisTest, amountToSend);

    coins.removeWhere(coinsToSpend.contains);

    expect(() => walletService.createSpendBundle(
          coinsToSpend,
          amountToSend,
          destinationPuzzlehash,
          walletKeychain.unhardenedMap.values.toList()[0].puzzlehash,
          walletKeychain,
          originId: Bytes.fromHex('ff8'),
      ), throwsException,
    );
  });
}

List<Coin> selectCoinsToSpend(List<Coin> allCoins, int amount) {
  final coins = allCoins.where((element) => element.spentBlockIndex == 0).toList()
    ..sort((a, b) => b.amount - a.amount);

  final spendCoins = <Coin>[];
  var spendAmount = 0;
  
  calculator:
  while (coins.isNotEmpty && spendAmount < amount) {
    for (var i = 0; i < coins.length; i++) {
      if (spendAmount + coins[i].amount <= amount) {
        final record = coins.removeAt(i--);
        spendCoins.add(record);
        spendAmount += record.amount;
        continue calculator;
      }
    }
    final record = coins.removeAt(0);
    spendCoins.add(record);
    spendAmount += record.amount;
  }
  if (spendAmount < amount) {
    throw Exception('Insufficient funds.');
  }

  return spendCoins;
}
