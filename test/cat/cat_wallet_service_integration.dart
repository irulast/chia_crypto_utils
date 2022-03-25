// ignore_for_file: lines_longer_than_80_chars

// @Skip('Integration test')

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/simulator_full_node_interface.dart';
import 'package:chia_utils/src/api/simulator_http_rpc.dart';
import 'package:chia_utils/src/cat/service/wallet.dart';
import 'package:chia_utils/src/core/models/payment.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'test_cat_utils.dart';

Future<void> main() async {
  final configurationProvider = ConfigurationProvider()
    ..setConfig(NetworkFactory.configId, {
      'yaml_file_path': 'lib/src/networks/chia/mainnet/config.yaml'
    }
  );

  final context = Context(configurationProvider);
  final blockcahinNetworkLoader = ChiaBlockchainNetworkLoader();
  context.registerFactory(NetworkFactory(blockcahinNetworkLoader.loadfromLocalFileSystem));
  final catWalletService = CatWalletService(context);
  final simulatorHttpRpc = SimulatorHttpRpc('https://localhost:5000',
    certPath: path.join(path.current, 'test/simulator/temp/config/ssl/full_node/private_full_node.crt'),
    keyPath: path.join(path.current, 'test/simulator/temp/config/ssl/full_node/private_full_node.key'),
  );
  final simulatorFullNode = SimulatorFullNodeInterface(simulatorHttpRpc);


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

  // final outerPuzzleHashesToSearchFor = walletKeychain.unhardenedMap.values
  //   .map((e) => e.assetIdtoOuterPuzzlehash[nateCoinAssetId]!).toList();
  final outerPuzzleHashesToSearchFor = walletKeychain.getOuterPuzzleHashesForAssetId(nateCoinAssetId);
  // final catCoins = await simulatorFullNode.getCatCoinsByOuterPuzzleHashes(outerPuzzleHashesToSearchFor);
  

  final senderAddress = Address.fromPuzzlehash(
    walletKeychain.unhardenedMap.values.toList()[0].puzzlehash, 
    catWalletService.blockchainNetwork.addressPrefix,
  );
  

  await simulatorFullNode.farmCoins(senderAddress);
  await simulatorFullNode.moveToNextBlock();
  
  final nathanCoinMintSpendBundle = TestCatUtils.makeNathanCoinSpendbundle();

  await simulatorFullNode.pushTransaction(nathanCoinMintSpendBundle);
  await simulatorFullNode.moveToNextBlock();

  final senderPuzzlehashes = walletKeychain.unhardenedMap.values.toList().sublist(1, 6).map((v) => v.puzzlehash,).toList();
  final receiverPuzzlehashes = walletKeychain.unhardenedMap.values.toList().sublist(6).map((v) => v.puzzlehash,).toList();


  final initialCatCoin = (await simulatorFullNode.getCatCoinsByOuterPuzzleHashes(outerPuzzleHashesToSearchFor))[0];
  // make more cat coins
  final payments = <Payment>[];
  for (final senderPuzzlehash in senderPuzzlehashes) {
    await simulatorFullNode.farmCoins(Address.fromPuzzlehash(senderPuzzlehash, catWalletService.blockchainNetwork.addressPrefix));
    await simulatorFullNode.moveToNextBlock();

    payments
      ..add(Payment(500, senderPuzzlehash))
      ..add(Payment(200, senderPuzzlehash))
      ..add(Payment(300, senderPuzzlehash));
  }
  final spendBundle = catWalletService.createSpendBundle(payments, [initialCatCoin], initialCatAddress.toPuzzlehash(), walletKeychain);
  await simulatorFullNode.pushTransaction(spendBundle);
  await simulatorFullNode.moveToNextBlock();

  
  test('spends multiple cat coins correctly', () async {
    final senderPuzzlehash = senderPuzzlehashes[0];
    final receiverPuzzlehash = receiverPuzzlehashes[0];
    
    final senderOuterPuzzlehash = WalletKeychain.makeOuterPuzzleHash(senderPuzzlehash, nateCoinAssetId);
    final senderNathanCoinsBefore = await simulatorFullNode.getCatCoinsByOuterPuzzleHashes([senderOuterPuzzlehash]);
    expect(senderNathanCoinsBefore.length > 1, true);
    final senderStartingBalance = senderNathanCoinsBefore.fold(0, (int previousValue, coin) => previousValue + coin.amount);

    final receiverOuterPuzzlehash = WalletKeychain.makeOuterPuzzleHash(receiverPuzzlehash, nateCoinAssetId);
    final receiverNathanCoinsBefore = await simulatorFullNode.getCatCoinsByOuterPuzzleHashes([receiverOuterPuzzlehash]);
    expect(receiverNathanCoinsBefore.length, 0);

    final amountToSend = (senderStartingBalance / 2).round();
    final payment = Payment(amountToSend, receiverPuzzlehash);
    final spendBundle = catWalletService.createSpendBundle([payment], senderNathanCoinsBefore, senderPuzzlehash, walletKeychain);
    await simulatorFullNode.pushTransaction(spendBundle);
    await simulatorFullNode.moveToNextBlock();

    final senderNathanCoinsAfter = await simulatorFullNode.getCatCoinsByOuterPuzzleHashes([senderOuterPuzzlehash]);
    final senderEndingBalance = senderNathanCoinsAfter.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    expect(senderEndingBalance, senderStartingBalance - amountToSend);

    final receiverNathanCoinsAfter = await simulatorFullNode.getCatCoinsByOuterPuzzleHashes([receiverOuterPuzzlehash]);
    expect(receiverNathanCoinsAfter.length, 1);
    expect(receiverNathanCoinsAfter[0].amount, amountToSend);
  });

  test('Spends multiple cats with fee correctly', () async {
    final senderPuzzlehash = senderPuzzlehashes[1];
    final receiverPuzzlehash = receiverPuzzlehashes[1];
    
    final senderOuterPuzzlehash = WalletKeychain.makeOuterPuzzleHash(senderPuzzlehash, nateCoinAssetId);
    final senderNathanCoinsBefore = await simulatorFullNode.getCatCoinsByOuterPuzzleHashes([senderOuterPuzzlehash]);
    expect(senderNathanCoinsBefore.length > 1, true);


    final senderStartingNathanCoinBalance = senderNathanCoinsBefore.fold(0, (int previousValue, coin) => previousValue + coin.amount);

    final receiverOuterPuzzlehash = WalletKeychain.makeOuterPuzzleHash(receiverPuzzlehash, nateCoinAssetId);
    final receiverNathanCoinsBefore = await simulatorFullNode.getCatCoinsByOuterPuzzleHashes([receiverOuterPuzzlehash]);
    expect(receiverNathanCoinsBefore.length, 0);

    final amountToSend = (senderStartingNathanCoinBalance / 2).round();
    final payment = Payment(amountToSend, receiverPuzzlehash);
    final spendBundle = catWalletService.createSpendBundle([payment], senderNathanCoinsBefore, senderPuzzlehash, walletKeychain);
    await simulatorFullNode.pushTransaction(spendBundle);
    await simulatorFullNode.moveToNextBlock();

    final senderNathanCoinsAfter = await simulatorFullNode.getCatCoinsByOuterPuzzleHashes([senderOuterPuzzlehash]);
    final senderEndingBalance = senderNathanCoinsAfter.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    expect(senderEndingBalance, senderStartingNathanCoinBalance - amountToSend);

    final receiverNathanCoinsAfter = await simulatorFullNode.getCatCoinsByOuterPuzzleHashes([receiverOuterPuzzlehash]);
    expect(receiverNathanCoinsAfter.length, 1);
    expect(receiverNathanCoinsAfter[0].amount, amountToSend);
  });

  // test('Produces valid spendbundle with fee and multiple payments', () async {
  //   final payment = Payment(200, targetPuzzlehash, memos: 'Chia is cool');
  //   final payment1 = Payment(100, targetPuzzlehash, memos: 1000);
  //   final spendBundle = catWalletService.createSpendBundle([payment, payment1], catCoins, changePuzzlehash, walletKeychain, fee: fee, standardCoinsForFee: [standardCoins.firstWhere((element) => element.amount >= fee)]);
  //   await simulatorFullNode.pushTransaction(spendBundle);
  // });
}
