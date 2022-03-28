// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/simulator_full_node_interface.dart';
import 'package:chia_utils/src/api/simulator_http_rpc.dart';
import 'package:chia_utils/src/cat/service/wallet.dart';
import 'package:chia_utils/src/core/models/payment.dart';
import 'package:test/test.dart';

import '../simulator/simulator_utils.dart';
import 'cat_test_utils.dart';

Future<void> main() async {
  if(!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }
  final configurationProvider = ConfigurationProvider()
    ..setConfig(NetworkFactory.configId, {
      'yaml_file_path': 'lib/src/networks/chia/mainnet/config.yaml'
    }
  );

  final context = Context(configurationProvider);
  final blockchainNetworkLoader = ChiaBlockchainNetworkLoader();
  context.registerFactory(NetworkFactory(blockchainNetworkLoader.loadfromLocalFileSystem));
  final catWalletService = CatWalletService(context);
  final simulatorHttpRpc = SimulatorHttpRpc(SimulatorUtils.simulatorUrl,
    certBytes: SimulatorUtils.certBytes,
    keyBytes: SimulatorUtils.keyBytes,
  );
  final fullNodeSimulator = SimulatorFullNodeInterface(simulatorHttpRpc);

  const nateCoinAssetIdHex = '625c2184e97576f5df1be46c15b2b8771c79e4e6f0aa42d3bfecaebe733f4b8c';
  final nateCoinAssetId = Puzzlehash.fromHex(nateCoinAssetIdHex);

  const testMnemonic = [
      'elder', 'quality', 'this', 'chalk', 'crane', 'endless',
      'machine', 'hotel', 'unfair', 'castle', 'expand', 'refuse',
      'lizard', 'vacuum', 'embody', 'track', 'crash', 'truth',
      'arrow', 'tree', 'poet', 'audit', 'grid', 'mesh',
  ];

  final masterKeyPair = MasterKeyPair.fromMnemonic(testMnemonic);

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 11; i++) {
    final set1 = WalletSet.fromPrivateKey(masterKeyPair.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final walletKeychain = WalletKeychain(walletsSetList)
    ..addOuterPuzzleHashesForAssetId(nateCoinAssetId);

  final outerPuzzleHashesToSearchFor = walletKeychain.getOuterPuzzleHashesForAssetId(nateCoinAssetId);
  
  final senderPuzzlehash = walletKeychain.unhardenedMap.values.toList()[0].puzzlehash;
  final senderOuterPuzzlehash = WalletKeychain.makeOuterPuzzleHash(senderPuzzlehash, nateCoinAssetId);
  final senderAddress = Address.fromPuzzlehash(
    senderPuzzlehash, 
    catWalletService.blockchainNetwork.addressPrefix,
  );

  final receiverPuzzlehash = walletKeychain.unhardenedMap.values.toList()[1].puzzlehash;
  final receiverOuterPuzzlehash = WalletKeychain.makeOuterPuzzleHash(receiverPuzzlehash, nateCoinAssetId);
  
  await fullNodeSimulator.farmCoins(senderAddress);
  await fullNodeSimulator.farmCoins(senderAddress);
  await fullNodeSimulator.farmCoins(senderAddress);
  await fullNodeSimulator.moveToNextBlock();
  
  final nateCoinMintSpendBundle = CatTestUtils.makeNateCoinSpendbundle();

  await fullNodeSimulator.pushTransaction(nateCoinMintSpendBundle);
  await fullNodeSimulator.moveToNextBlock();

  final initialCatCoin = (await fullNodeSimulator.getCatCoinsByOuterPuzzleHashes(outerPuzzleHashesToSearchFor))[0];

  // make more cat coins to use in test
  final payments = <Payment>[];
  for (var i = 0; i < 10; i++) {
    // to avoid duplicate coins amounts must differ
    payments.add(Payment(990 + i, senderPuzzlehash));
  }

  final spendBundle = catWalletService.createSpendBundle(payments, [initialCatCoin], senderPuzzlehash, walletKeychain);
  await fullNodeSimulator.pushTransaction(spendBundle);
  await fullNodeSimulator.moveToNextBlock();

  final nateCoins = await fullNodeSimulator.getCatCoinsByOuterPuzzleHashes([senderOuterPuzzlehash]);
  final standardCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([senderPuzzlehash]);

  test('spends multiple cat coins correctly', () async {
    final nateCoinsToSend = nateCoins.sublist(0, 2);
    nateCoins.removeWhere(nateCoinsToSend.contains);
    
    final senderStartingBalance = await fullNodeSimulator.getBalance([senderOuterPuzzlehash]);

    final receiverStartingBalance = await fullNodeSimulator.getBalance([receiverOuterPuzzlehash]);
    
    final totalNateCoinValue = nateCoinsToSend.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    final amountToSend = (totalNateCoinValue * 0.8).round();
    final payment = Payment(amountToSend, receiverPuzzlehash);

    final spendBundle = catWalletService.createSpendBundle([payment], nateCoinsToSend, senderPuzzlehash, walletKeychain);
    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final senderEndingBalance = await fullNodeSimulator.getBalance([senderOuterPuzzlehash]);
    expect(senderEndingBalance, senderStartingBalance - amountToSend);

    final receiverEndingBalance = await fullNodeSimulator.getBalance([receiverOuterPuzzlehash]);
    expect(receiverEndingBalance, receiverStartingBalance + amountToSend);
  });

  test('Spends multiple cats with fee correctly', () async {
    final nateCoinsToSend = nateCoins.sublist(0, 2);
    nateCoins.removeWhere(nateCoinsToSend.contains);

    final standardCoinsForFee = standardCoins.sublist(0, 2);
    standardCoins.removeWhere(standardCoinsForFee.contains);

    final senderStartingNateCoinBalance = await fullNodeSimulator.getBalance([senderOuterPuzzlehash]);
    final senderStartingStandardCoinBalance = await fullNodeSimulator.getBalance([senderPuzzlehash]);

    final receiverStartingNateCoinBalance = await fullNodeSimulator.getBalance([receiverOuterPuzzlehash]);
    
    final totalNateCoinValue = nateCoinsToSend.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    final amountToSend = (totalNateCoinValue * 0.8).round();
    const fee = 1000;
    final payment = Payment(amountToSend, receiverPuzzlehash);

    final spendBundle = catWalletService.createSpendBundle([payment], nateCoinsToSend, senderPuzzlehash, walletKeychain, fee: fee, standardCoinsForFee: standardCoinsForFee);
    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final senderEndingStandardCoinBalance = await fullNodeSimulator.getBalance([senderPuzzlehash]);
    expect(senderEndingStandardCoinBalance, senderStartingStandardCoinBalance - fee);

    final senderEndingNateCoinBalance = await fullNodeSimulator.getBalance([senderOuterPuzzlehash]);
    expect(senderEndingNateCoinBalance, senderStartingNateCoinBalance - amountToSend);

    final receiverEndingNateCoinBalance = await fullNodeSimulator.getBalance([receiverOuterPuzzlehash]);
    expect(receiverEndingNateCoinBalance, receiverStartingNateCoinBalance + amountToSend);
  });

  test('Produces valid spendbundle with fee, multiple payments, and memos', () async {
    final nateCoinsToSend = nateCoins.sublist(0, 2);
    nateCoins.removeWhere(nateCoinsToSend.contains);

    final standardCoinsForFee = standardCoins.sublist(0, 2);
    standardCoins.removeWhere(standardCoinsForFee.contains);

    final senderStartingNateCoinBalance = await fullNodeSimulator.getBalance([senderOuterPuzzlehash]);
    final senderStartingStandardCoinBalance = await fullNodeSimulator.getBalance([senderPuzzlehash]);

    final receiverStartingNateCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([receiverOuterPuzzlehash]);
    final receiverStartingNateCoinBalance = receiverStartingNateCoins.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    
    final totalNateCoinValue = nateCoinsToSend.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    final sendAmounts = [(totalNateCoinValue * 0.4).round(), (totalNateCoinValue * 0.3).round()];
    final totalAmountToSend = sendAmounts.fold(0, (int previousValue, amount) => previousValue + amount);
    final payments = [
      Payment(
        sendAmounts[0], 
        receiverPuzzlehash,
        memos: 'Chia is cool',
      ),
      Payment(
        sendAmounts[1], 
        receiverPuzzlehash,
        memos: 1000,
      ),
    ];

    const fee = 1000;

    final spendBundle = catWalletService.createSpendBundle(payments, nateCoinsToSend, senderPuzzlehash, walletKeychain, fee: fee, standardCoinsForFee: standardCoinsForFee);
    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final senderEndingStandardCoinBalance = await fullNodeSimulator.getBalance([senderPuzzlehash]);
    expect(senderEndingStandardCoinBalance, senderStartingStandardCoinBalance - fee);

    final senderEndingNateCoinBalance = await fullNodeSimulator.getBalance([senderOuterPuzzlehash]);
    expect(senderEndingNateCoinBalance, senderStartingNateCoinBalance - totalAmountToSend);

    final receiverEndingNateCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([receiverOuterPuzzlehash]);
    final receiverEndingNateCoinBalance = receiverEndingNateCoins.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    expect(receiverEndingNateCoinBalance, receiverStartingNateCoinBalance + totalAmountToSend);

    final newCoins = receiverEndingNateCoins.where((coin) => !receiverStartingNateCoins.contains(coin)).toList();
    expect(newCoins.length, 2);
    expect(() {
      newCoins
      // throws exception
      ..singleWhere((coin) => coin.amount == sendAmounts[0])
      ..singleWhere((coin) => coin.amount == sendAmounts[1]);
    }, returnsNormally,);
  });
}
