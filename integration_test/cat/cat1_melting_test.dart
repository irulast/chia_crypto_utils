// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

Future<void> main() async {
  const nTests = 4;

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
  final cat1WalletService = Cat1WalletService();

  final secret = KeychainCoreSecret.generate();

  final keychain = WalletKeychain.fromCoreSecret(secret);

  final walletSet = keychain.unhardenedMap.values.first;

  final address = Address.fromPuzzlehash(
    walletSet.puzzlehash,
    cat1WalletService.blockchainNetwork.addressPrefix,
  );
  final puzzlehash = address.toPuzzlehash();

  for (var i = 0; i < nTests; i++) {
    await fullNodeSimulator.farmCoins(address);
  }
  await fullNodeSimulator.moveToNextBlock();

  final initialStandardCoins =
      await fullNodeSimulator.getCoinsByPuzzleHashes([address.toPuzzlehash()]);
  final originCoin = initialStandardCoins[0];

  final issuanceResult = cat1WalletService.makeMeltableMultiIssuanceCatSpendBundle(
    genesisCoinId: originCoin.id,
    standardCoins: [initialStandardCoins.firstWhere((coin) => coin.amount >= 10000)],
    privateKey: walletSet.childPrivateKey,
    destinationPuzzlehash: puzzlehash,
    changePuzzlehash: puzzlehash,
    amount: 10000,
    keychain: keychain,
  );

  final tailRunningInfo = issuanceResult.tailRunningInfo;

  keychain.addCat1OuterPuzzleHashesForAssetId(Puzzlehash(tailRunningInfo.assetId));

  final outerPuzzlehash = WalletKeychain.makeCat1OuterPuzzleHash(
    address.toPuzzlehash(),
    Puzzlehash(tailRunningInfo.assetId),
  );

  await fullNodeSimulator.pushTransaction(issuanceResult.spendBundle);
  await fullNodeSimulator.moveToNextBlock();

  final initialCats = await fullNodeSimulator.getCatCoinsByOuterPuzzleHashes([outerPuzzlehash]);

  // split issued cat up for tests
  final payments = <CatPayment>[];
  for (var i = 0; i < 10; i++) {
    // to avoid duplicate coins amounts must differ
    payments.add(CatPayment(990 + i, puzzlehash));
  }

  final sendBundle = cat1WalletService.createSpendBundle(
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

    final meltSpendBundle = cat1WalletService.makeMeltingSpendBundle(
      catCoinToMelt: catCoinForTest,
      standardCoinsForXchClaimingSpendBundle: standardCoinsForTest,
      puzzlehashToClaimXchTo: puzzlehash,
      keychain: keychain,
      tailRunningInfo: tailRunningInfo,
      changePuzzlehash: puzzlehash,
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

    final meltSpendBundle = cat1WalletService.makeMeltingSpendBundle(
      catCoinToMelt: catCoinForTest,
      standardCoinsForXchClaimingSpendBundle: standardCoinsForTest,
      puzzlehashToClaimXchTo: puzzlehash,
      changePuzzlehash: puzzlehash,
      keychain: keychain,
      tailRunningInfo: tailRunningInfo,
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

    final meltSpendBundle = cat1WalletService.makeMeltingSpendBundle(
      catCoinToMelt: catCoinForTest,
      standardCoinsForXchClaimingSpendBundle: standardCoinsForTest,
      puzzlehashToClaimXchTo: puzzlehash,
      changePuzzlehash: puzzlehash,
      keychain: keychain,
      tailRunningInfo: tailRunningInfo,
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
