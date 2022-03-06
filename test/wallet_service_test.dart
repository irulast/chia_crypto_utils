@Skip("Integration test")
import 'package:chia_utils/src/api/full_node.dart';
import 'package:chia_utils/src/context/configuration_provider.dart';
import 'package:chia_utils/src/context/context.dart';
import 'package:chia_utils/src/core/models/address.dart';
import 'package:chia_utils/src/core/models/master_key_pair.dart';
import 'package:chia_utils/src/core/models/wallet_keychain.dart';
import 'package:chia_utils/src/core/models/wallet_set.dart';
import 'package:chia_utils/src/networks/network_factory.dart';
import 'package:chia_utils/src/standard/service/wallet.dart';
import 'package:test/scaffolding.dart';

void main() async {
  final fullNode = FullNode('http://localhost:4000');
  final configurationProvider = ConfigurationProvider();
  configurationProvider.setConfig(NetworkFactory.configId, {
    'name': 'TestNet10',
    'address_prefix': 'txch',
    'agg_sig_me_extra_data': 'ae83525ba8d1dd3f09b277de18ca3e43fc0af20d20c4b3e92ef2a48bd291ccb2'
  });
  final context = Context(configurationProvider);
  context.registerFactory(NetworkFactory());
  final walletService = WalletService(fullNode, context);

  final destinationAddress = Address('txch1pdar6hnj8c9sgm74r72u40ed8cnpduzan5vr86qkvpftg0v52jksxp6hy3');

  const testMnemonic = [
      'elder', 'quality', 'this', 'chalk', 'crane', 'endless',
      'machine', 'hotel', 'unfair', 'castle', 'expand', 'refuse',
      'lizard', 'vacuum', 'embody', 'track', 'crash', 'truth',
      'arrow', 'tree', 'poet', 'audit', 'grid', 'mesh',
  ];

  final masterKeyPair = MasterKeyPair.fromMnemonic(testMnemonic);

  List<WalletSet> walletsSetList = [];
  for (var i = 0; i < 20; i++) {
    final set1 = WalletSet.fromPrivateKey(masterKeyPair.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final walletKeychain = WalletKeychain(walletsSetList);

  final unhardenedPuzzlehashes = walletKeychain.unhardenedMap.values.map((vec) => vec.puzzlehash).toList();

  final coins = await fullNode.getCoinRecordsByPuzzleHashes(unhardenedPuzzlehashes);

  test('Should push transaction with fee', () async {
    final coinsForThisTest = coins.sublist(0, coins.length ~/ 2);
    final amountToSend = 10000;
    final fee = 100;
    final totalAmount = amountToSend + fee;

    final coinsToSpend = WalletService.selectCoinsToSpend(coinsForThisTest, totalAmount);

    final spendBundle = await walletService.createSpendBundle(
        coinsToSpend,
        amountToSend,
        destinationAddress,
        walletKeychain.unhardenedMap.values.toList()[0].puzzlehash,
        walletKeychain,
        fee: fee);

    await fullNode.pushTransaction(spendBundle);
  });

  test('Should push transaction without fee', () async {
    final coinsForThisTest = coins.sublist(coins.length ~/ 2);
    final amountToSend = 10000;

    final coinsToSpend =
        WalletService.selectCoinsToSpend(coinsForThisTest, amountToSend);

    final spendBundle = await walletService.createSpendBundle(
        coinsToSpend,
        amountToSend,
        destinationAddress,
        walletKeychain.unhardenedMap.values.toList()[0].puzzlehash,
        walletKeychain);

    await fullNode.pushTransaction(spendBundle);
  });
}
