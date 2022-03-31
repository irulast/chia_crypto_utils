// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/simulator_full_node_interface.dart';
import 'package:chia_utils/src/api/simulator_http_rpc.dart';
import 'package:chia_utils/src/cat/puzzles/tails/delegated_tail/delegated_tail.clvm.hex.dart';
import 'package:chia_utils/src/cat/puzzles/tails/genesis_by_coin_id/genesis_by_coin_id.clvm.hex.dart';
import 'package:chia_utils/src/cat/service/wallet.dart';
import 'package:chia_utils/src/core/models/payment.dart';
import 'package:chia_utils/src/networks/network_context.dart';
import 'package:test/test.dart';

import '../simulator/simulator_utils.dart';

Future<void> main() async {
  const nTests = 3;

  if(!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }
  final context = NetworkContext.makeContext(Network.mainnet);
  final catWalletService = CatWalletService(context);
  final simulatorHttpRpc = SimulatorHttpRpc(SimulatorUtils.simulatorUrl,
    certBytes: SimulatorUtils.certBytes,
    keyBytes: SimulatorUtils.keyBytes,
  );
  final fullNodeSimulator = SimulatorFullNodeInterface(simulatorHttpRpc);

  final testMnemonic = WalletKeychain.generateMnemonic();

  final masterKeyPair = MasterKeyPair.fromMnemonic(testMnemonic);

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 2; i++) {
    final set = WalletSet.fromPrivateKey(masterKeyPair.masterPrivateKey, i);
    walletsSetList.add(set);
  }

  final keychain = WalletKeychain(walletsSetList);

  final senderWalletSet = keychain.unhardenedMap.values.first;
  final senderPuzzlehash = senderWalletSet.puzzlehash;
  final senderAddress = Address.fromPuzzlehash(senderPuzzlehash, catWalletService.blockchainNetwork.addressPrefix);

  for (var i = 0; i < nTests; i++) {
    await fullNodeSimulator.farmCoins(senderAddress);
  }
  await fullNodeSimulator.moveToNextBlock();

  var senderStandardCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([senderPuzzlehash]);
  final originCoin = senderStandardCoins[0];

  // mint cat
  final curriedTail = delegatedTailProgram.curry([Program.fromBytes(senderWalletSet.childPublicKey.toBytes())]);
  final assetId = Puzzlehash(curriedTail.hash());
  keychain.addOuterPuzzleHashesForAssetId(assetId);
  
  final curriedGenesisByCoinIdPuzzle = genesisByCoinIdProgram.curry([Program.fromBytes(originCoin.id.toUint8List())]);
  final tailSolution = Program.list([curriedGenesisByCoinIdPuzzle, Program.nil]);

  final signature = AugSchemeMPL.sign(senderWalletSet.childPrivateKey, curriedGenesisByCoinIdPuzzle.hash());

  final spendBundle = catWalletService.makeMintingSpendbundle(
    tail: curriedTail, 
    solution: tailSolution, 
    standardCoins: [senderStandardCoins.firstWhere((coin) => coin.amount >= 10000)], 
    destinationPuzzlehash: senderPuzzlehash, 
    changePuzzlehash: senderPuzzlehash, 
    amount: 10000, 
    signature: signature, 
    keychain: keychain,
    originId: originCoin.id,
  );

  await fullNodeSimulator.pushTransaction(spendBundle);
  await fullNodeSimulator.moveToNextBlock();

  var senderCatCoins = await fullNodeSimulator.getCatCoinsByOuterPuzzleHashes([WalletKeychain.makeOuterPuzzleHash(senderPuzzlehash, assetId)]);
  assert(senderCatCoins.isNotEmpty, true);

  senderStandardCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([senderPuzzlehash]);
  final payments = <Payment>[];
  for (var i = 0; i < 10; i++) {
    // to avoid duplicate coins amounts must differ
    payments.add(Payment(990 + i, senderPuzzlehash));
  }
  final sendBundle = catWalletService.createSpendBundle(payments, senderCatCoins, senderPuzzlehash, keychain);

  await fullNodeSimulator.pushTransaction(sendBundle);
  await fullNodeSimulator.moveToNextBlock();

  final senderOuterPuzzlehash = WalletKeychain.makeOuterPuzzleHash(senderPuzzlehash, assetId);

  final receiverWalletSet = keychain.unhardenedMap.values.toList()[1];
  final receiverPuzzlehash = receiverWalletSet.puzzlehash;
  final receiverOuterPuzzlehash = WalletKeychain.makeOuterPuzzleHash(receiverPuzzlehash, assetId);

  senderCatCoins = await fullNodeSimulator.getCatCoinsByOuterPuzzleHashes([senderOuterPuzzlehash]);
  senderStandardCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([senderPuzzlehash]);

  test('spends multiple cat coins correctly', () async {
    final catCoinsForThisTest = senderCatCoins.sublist(0, 2);
    senderCatCoins.removeWhere(catCoinsForThisTest.contains);
    
    final senderStartingBalance = await fullNodeSimulator.getBalance([senderOuterPuzzlehash]);

    final receiverStartingBalance = await fullNodeSimulator.getBalance([receiverOuterPuzzlehash]);
    
    final totalNateCoinValue = catCoinsForThisTest.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    final amountToSend = (totalNateCoinValue * 0.8).round();
    final payment = Payment(amountToSend, receiverPuzzlehash);

    final spendBundle = catWalletService.createSpendBundle([payment], catCoinsForThisTest, senderPuzzlehash, keychain);
    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final senderEndingBalance = await fullNodeSimulator.getBalance([senderOuterPuzzlehash]);
    expect(senderEndingBalance, senderStartingBalance - amountToSend);

    final receiverEndingBalance = await fullNodeSimulator.getBalance([receiverOuterPuzzlehash]);
    expect(receiverEndingBalance, receiverStartingBalance + amountToSend);
  });

  test('Spends multiple cats with fee correctly', () async {
    final catCoinsForThisTest = senderCatCoins.sublist(0, 2);
    senderCatCoins.removeWhere(catCoinsForThisTest.contains);

    final standardCoinsForTest = senderStandardCoins.sublist(0, 2);
    senderStandardCoins.removeWhere(standardCoinsForTest.contains);

    final senderStartingNateCoinBalance = await fullNodeSimulator.getBalance([senderOuterPuzzlehash]);
    final senderStartingStandardCoinBalance = await fullNodeSimulator.getBalance([senderPuzzlehash]);

    final receiverStartingNateCoinBalance = await fullNodeSimulator.getBalance([receiverOuterPuzzlehash]);
    
    final totalNateCoinValue = catCoinsForThisTest.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    final amountToSend = (totalNateCoinValue * 0.8).round();
    const fee = 1000;
    final payment = Payment(amountToSend, receiverPuzzlehash);

    final spendBundle = catWalletService.createSpendBundle([payment], catCoinsForThisTest, senderPuzzlehash, keychain, fee: fee, standardCoinsForFee: standardCoinsForTest);
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
    final catCoinsForThisTest = senderCatCoins.sublist(0, 2);
    senderCatCoins.removeWhere(catCoinsForThisTest.contains);

    final standardCoinsForTest = senderStandardCoins.sublist(0, 2);
    senderStandardCoins.removeWhere(standardCoinsForTest.contains);

    final senderStartingNateCoinBalance = await fullNodeSimulator.getBalance([senderOuterPuzzlehash]);
    final senderStartingStandardCoinBalance = await fullNodeSimulator.getBalance([senderPuzzlehash]);

    final receiverStartingCatCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([receiverOuterPuzzlehash]);
    final receiverStartingNateCoinBalance = receiverStartingCatCoins.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    
    final totalNateCoinValue = catCoinsForThisTest.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    final sendAmounts = [(totalNateCoinValue * 0.4).round(), (totalNateCoinValue * 0.3).round()];
    final totalAmountToSend = sendAmounts.fold(0, (int previousValue, amount) => previousValue + amount);
    final payments = [
      Payment(
        sendAmounts[0], 
        receiverPuzzlehash,
        memos: <String>['Chia is cool'],
      ),
      Payment(
        sendAmounts[1], 
        receiverPuzzlehash,
        memos: <int>[1000],
      ),
    ];

    const fee = 1000;

    final spendBundle = catWalletService.createSpendBundle(payments, catCoinsForThisTest, senderPuzzlehash, keychain, fee: fee, standardCoinsForFee: standardCoinsForTest);
    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final senderEndingStandardCoinBalance = await fullNodeSimulator.getBalance([senderPuzzlehash]);
    expect(senderEndingStandardCoinBalance, senderStartingStandardCoinBalance - fee);

    final senderEndingNateCoinBalance = await fullNodeSimulator.getBalance([senderOuterPuzzlehash]);
    expect(senderEndingNateCoinBalance, senderStartingNateCoinBalance - totalAmountToSend);

    final receiverEndingCatCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([receiverOuterPuzzlehash]);
    final receiverEndingNateCoinBalance = receiverEndingCatCoins.fold(0, (int previousValue, coin) => previousValue + coin.amount);
    expect(receiverEndingNateCoinBalance, receiverStartingNateCoinBalance + totalAmountToSend);

    final newCoins = receiverEndingCatCoins.where((coin) => !receiverStartingCatCoins.contains(coin)).toList();
    expect(newCoins.length, 2);
    expect(() {
      for (final newCoin in newCoins) {
        // throws exception if not found
        sendAmounts.singleWhere((a) => a == newCoin.amount);
      }
    }, returnsNormally,);
  });
}
