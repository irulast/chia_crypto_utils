import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  late ChiaEnthusiast offerMaker;
  late Puzzlehash assetId;

  late ChiaEnthusiast offerTaker;

  setUp(() async {
    offerMaker = ChiaEnthusiast(fullNodeSimulator, walletSize: 5);
    offerTaker = ChiaEnthusiast(fullNodeSimulator, walletSize: 5);

    await offerMaker.farmCoins();
    assetId = await offerMaker.issueMultiIssuanceCat();
    await offerTaker.farmCoins();
  });

  test('should parse offered coins from submitted offer', () async {
    final makeOffer = await offerMaker.offerService.createOffer(
      offeredAmounts: MixedAmounts(cat: {assetId: 5000}),
      requestedPayments: RequestedMixedPayments(
        standard: [Payment(500, offerMaker.firstPuzzlehash)],
      ),
    );

    print('offer maker first puzzlehash: ${offerMaker.firstPuzzlehash}');

    final takeOffer = await offerTaker.offerService
        .createTakeOffer(makeOffer, fee: 100, targetPuzzlehash: offerTaker.firstPuzzlehash);

    print('offer taker first puzzlehash: ${offerTaker.firstPuzzlehash}');

    final spendBundle = takeOffer.toSpendBundle();

    final additionsWithParents = spendBundle.netAdditonWithParentSpends;

    final settlementProgramHashes = [
      settlementPaymentsProgram.hash(),
      settlementPaymentsProgramOld.hash(),
    ];

    print('settlementProgramHashes: $settlementProgramHashes');

    for (final addition in additionsWithParents) {
      final puzzleDriver = PuzzleDriver.match(addition.parentSpend!.puzzleReveal);

      if (puzzleDriver == null) {
        print('null puzzle driver');
        continue;
      }

      final p2Payments = puzzleDriver.getP2Payments(addition.parentSpend!);
      print(p2Payments.map((e) => e.puzzlehash).toList());
    }
  });
}
