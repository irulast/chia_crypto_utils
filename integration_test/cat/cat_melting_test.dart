// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

Future<void> main() async {
  const nTests = 3;

  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final simulatorHttpRpc = SimulatorHttpRpc(
    SimulatorUtils.simulatorUrl,
    certBytes: SimulatorUtils.certBytes,
    keyBytes: SimulatorUtils.keyBytes,
  );

  final fullNodeSimulator = SimulatorFullNodeInterface(simulatorHttpRpc);

  // set up context, services
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final catWalletService = CatWalletService();

  // set up keychain
  final keychainSecret = KeychainCoreSecret.generate();

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 1; i++) {
    final set = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
    walletsSetList.add(set);
  }

  final keychain = WalletKeychain.fromWalletSets(walletsSetList);

  final walletSet = keychain.unhardenedMap.values.first;

  final address = Address.fromPuzzlehash(
    walletSet.puzzlehash,
    catWalletService.blockchainNetwork.addressPrefix,
  );
  final puzzlehash = address.toPuzzlehash();

  for (var i = 0; i < nTests; i++) {
    await fullNodeSimulator.farmCoins(address);
  }
  await fullNodeSimulator.moveToNextBlock();

  final initialStandardCoins =
      await fullNodeSimulator.getCoinsByPuzzleHashes([address.toPuzzlehash()]);
  final originCoin = initialStandardCoins[0];

  // issue cat
  final curriedTail =
      delegatedTailProgram.curry([Program.fromBytes(walletSet.childPublicKey.toBytes())]);

  keychain.addOuterPuzzleHashesForAssetId(Puzzlehash(curriedTail.hash()));

  final outerPuzzlehash = WalletKeychain.makeOuterPuzzleHash(
    address.toPuzzlehash(),
    Puzzlehash(curriedTail.hash()),
  );

  final curriedMeltableGenesisByCoinIdPuzzle =
      meltableGenesisByCoinIdProgram.curry([Program.fromBytes(originCoin.id)]);
  final tailSolution = Program.list([curriedMeltableGenesisByCoinIdPuzzle, Program.nil]);

  final issuanceSignature = AugSchemeMPL.sign(
    walletSet.childPrivateKey,
    curriedMeltableGenesisByCoinIdPuzzle.hash(),
  );

  final spendBundle = catWalletService.makeIssuanceSpendbundle(
    tail: curriedTail,
    solution: tailSolution,
    standardCoins: [initialStandardCoins.firstWhere((coin) => coin.amount >= 10000)],
    destinationPuzzlehash: puzzlehash,
    changePuzzlehash: puzzlehash,
    amount: 10000,
    signature: issuanceSignature,
    keychain: keychain,
    originId: originCoin.id,
  );

  await fullNodeSimulator.pushTransaction(spendBundle);
  await fullNodeSimulator.moveToNextBlock();

  final initialCats = await fullNodeSimulator.getCatCoinsByOuterPuzzleHashes([outerPuzzlehash]);

  // split issued cat up for tests
  final payments = <Payment>[];
  for (var i = 0; i < 10; i++) {
    // to avoid duplicate coins amounts must differ
    payments.add(Payment(990 + i, puzzlehash));
  }

  final sendBundle = catWalletService.createSpendBundle(
    payments: payments,
    catCoinsInput: initialCats,
    changePuzzlehash: puzzlehash,
    keychain: keychain,
  );

  await fullNodeSimulator.pushTransaction(sendBundle);
  await fullNodeSimulator.moveToNextBlock();

  final catCoins = await fullNodeSimulator.getCatCoinsByOuterPuzzleHashes([outerPuzzlehash]);
  final standardCoins = await fullNodeSimulator.getCoinsByPuzzleHashes([puzzlehash]);

  test('should completely melt cat coin', () async {
    final standardCoinsForTest = standardCoins.sublist(0, 2);
    standardCoins.removeWhere(standardCoinsForTest.contains);

    final catCoinForTest = catCoins.removeAt(0);

    final initialXchBalance = await fullNodeSimulator.getBalance([puzzlehash]);
    final initialCatBalance = await fullNodeSimulator.getBalance([outerPuzzlehash]);

    final meltSpendBundle = catWalletService.makeMeltingSpendBundle(
      catCoinToMelt: catCoinForTest,
      standardCoinsForXchClaimingSpendBundle: standardCoinsForTest,
      puzzlehashToClaimXchTo: puzzlehash,
      tail: curriedTail,
      tailSolution: tailSolution,
      keychain: keychain,
      issuanceSignature: issuanceSignature,
    );

    await fullNodeSimulator.pushTransaction(meltSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final finalXchBalance = await fullNodeSimulator.getBalance([puzzlehash]);
    expect(finalXchBalance - initialXchBalance, equals(catCoinForTest.amount));

    final finalCatBalance = await fullNodeSimulator.getBalance([outerPuzzlehash]);
    expect(finalCatBalance, equals(initialCatBalance - catCoinForTest.amount));
  });

  test('should partially melt cat coin', () async {
    final standardCoinsForTest = standardCoins.sublist(0, 2);
    standardCoins.removeWhere(standardCoinsForTest.contains);

    final catCoinForTest = catCoins.removeAt(0);
    final amountToMelt = (catCoinForTest.amount / 2).round();

    final initialXchBalance = await fullNodeSimulator.getBalance([puzzlehash]);
    final initialCatBalance = await fullNodeSimulator.getBalance([outerPuzzlehash]);

    final meltSpendBundle = catWalletService.makeMeltingSpendBundle(
      catCoinToMelt: catCoinForTest,
      standardCoinsForXchClaimingSpendBundle: standardCoinsForTest,
      puzzlehashToClaimXchTo: puzzlehash,
      changePuzzlehash: puzzlehash,
      tail: curriedTail,
      tailSolution: tailSolution,
      keychain: keychain,
      issuanceSignature: issuanceSignature,
      inputAmountToMelt: amountToMelt,
    );

    await fullNodeSimulator.pushTransaction(meltSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final finalXchBalance = await fullNodeSimulator.getBalance([puzzlehash]);
    expect(finalXchBalance, equals(amountToMelt + initialXchBalance));

    final finalCatBalance = await fullNodeSimulator.getBalance([outerPuzzlehash]);
    expect(finalCatBalance, equals(initialCatBalance - amountToMelt));
  });

  test('should partially melt cat coin with fee', () async {
    final standardCoinsForTest = standardCoins.sublist(0, 2);
    standardCoins.removeWhere(standardCoinsForTest.contains);

    final catCoinForTest = catCoins.removeAt(0);
    final amountToMelt = (catCoinForTest.amount / 2).round();
    final fee = (amountToMelt * 0.2).round();

    final initialXchBalance = await fullNodeSimulator.getBalance([puzzlehash]);
    final initialCatBalance = await fullNodeSimulator.getBalance([outerPuzzlehash]);

    final meltSpendBundle = catWalletService.makeMeltingSpendBundle(
      catCoinToMelt: catCoinForTest,
      standardCoinsForXchClaimingSpendBundle: standardCoinsForTest,
      puzzlehashToClaimXchTo: puzzlehash,
      changePuzzlehash: puzzlehash,
      tail: curriedTail,
      tailSolution: tailSolution,
      keychain: keychain,
      issuanceSignature: issuanceSignature,
      inputAmountToMelt: amountToMelt,
      fee: fee,
    );

    await fullNodeSimulator.pushTransaction(meltSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final finalXchBalance = await fullNodeSimulator.getBalance([puzzlehash]);
    expect(finalXchBalance, equals(amountToMelt + initialXchBalance - fee));

    final finalCatBalance = await fullNodeSimulator.getBalance([outerPuzzlehash]);
    expect(finalCatBalance, equals(initialCatBalance - amountToMelt));
  });
}
