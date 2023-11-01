import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/spend_bundle_validation/failed_signature_verification.dart';
import 'package:test/test.dart';

Future<void> main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  final catOfferService = CatOfferWalletService();

  final ian = ChiaEnthusiast(fullNodeSimulator);
  await ian.farmCoins();
  await ian.issueMultiIssuanceCat();

  final acs = Program.fromInt(1);
  final acsPh = acs.hash();

  final acsCoinParent = ian.standardCoins.first;

  final spendBundle = catOfferService.standardWalletService.createSpendBundle(
    payments: [Payment(100, acsPh)],
    coinsInput: [acsCoinParent],
    changePuzzlehash: ian.firstPuzzlehash,
    keychain: ian.keychain,
  );
  await fullNodeSimulator.pushTransaction(spendBundle);
  await fullNodeSimulator.moveToNextBlock();

  // "Anyone Can Spend" coin to use for the malicious offers
  final acsCoin = CoinPrototype(
    parentCoinInfo: acsCoinParent.id,
    puzzlehash: acsPh,
    amount: 100,
  );

  final honestCoinSpend = CoinSpend(
    coin: acsCoin,
    puzzleReveal: acs,
    solution: Program.list([
      Program.list([
        Program.fromInt(51),
        Program.fromAtom(Offer.defaultSettlementProgram.hash()),
        Program.fromInt(acsCoin.amount),
      ]),
    ]),
  );

  test('should fail on bad aggregated signature', () async {
    final badAggSigSpend = CoinSpend(
      coin: acsCoin,
      puzzleReveal: acs,
      solution: Program.list([
        Program.list([
          Program.fromInt(51),
          Program.fromAtom(Offer.defaultSettlementProgram.hash()),
          Program.fromInt(acsCoin.amount),
        ]),
        Program.list([
          Program.fromInt(50),
          Program.fromAtom(
            JacobianPoint.generateG1().toBytes(),
          ),
          Program.fromInt(acsCoin.amount),
        ]),
      ]),
    );

    final badSpendBundle = SpendBundle(
      coinSpends: [badAggSigSpend],
      signatures: {JacobianPoint.generateG2()},
    );

    expect(
      () async {
        catOfferService.standardWalletService
            .validateSpendBundle(badSpendBundle);
      },
      throwsA(isA<FailedSignatureVerificationException>()),
    );
    await fullNodeSimulator.moveToNextBlock();
  });

  test('should fail on negative coin amount', () async {
    final negativeSpend = CoinSpend(
      coin: acsCoin,
      puzzleReveal: acs,
      solution: Program.list([
        Program.list([
          Program.fromInt(51),
          Program.fromAtom(Offer.defaultSettlementProgram.hash()),
          Program.fromInt(-1),
        ]),
      ]),
    );

    final negativeBundle = SpendBundle(
        coinSpends: [negativeSpend], signatures: {JacobianPoint.generateG2()});
    expect(
      () async {
        await fullNodeSimulator.pushTransaction(negativeBundle);
      },
      throwsA(isA<BadRequestException>()),
    );
    await fullNodeSimulator.moveToNextBlock();
  });

  test('should fail on more than maximum amount', () async {
    // one more than the maximum value for uint64 (2^64 - 1)
    final overSize = BigInt.from(2).pow(64);
    final tooLargeSpend = CoinSpend(
      coin: acsCoin,
      puzzleReveal: acs,
      solution: Program.list([
        Program.list([
          Program.fromInt(51),
          Program.fromAtom(Offer.defaultSettlementProgram.hash()),
          Program.fromBigInt(overSize),
        ]),
      ]),
    );
    expect(
      () async {
        await fullNodeSimulator.pushTransaction(
          SpendBundle(
              coinSpends: [tooLargeSpend],
              signatures: {JacobianPoint.generateG2()}),
        );
      },
      throwsA(isA<BadRequestException>()),
    );
    await fullNodeSimulator.moveToNextBlock();
  });

  test('should fail on duplicate outputs', () async {
    final duplicateOutputSpend = CoinSpend(
      coin: acsCoin,
      puzzleReveal: acs,
      solution: Program.list([
        Program.list([
          Program.fromInt(51),
          Program.fromAtom(Offer.defaultSettlementProgram.hash()),
          Program.fromInt(1),
        ]),
        Program.list([
          Program.fromInt(51),
          Program.fromAtom(Offer.defaultSettlementProgram.hash()),
          Program.fromInt(1),
        ]),
      ]),
    );
    expect(
      () async {
        await fullNodeSimulator.pushTransaction(
          SpendBundle(
            coinSpends: [duplicateOutputSpend],
            signatures: {JacobianPoint.generateG2()},
          ),
        );
      },
      throwsA(isA<BadRequestException>()),
    );
    await fullNodeSimulator.moveToNextBlock();
  });

  test('should fail on double spend', () async {
    final doubleSpendBundle = SpendBundle(
      coinSpends: [honestCoinSpend, honestCoinSpend],
      signatures: {JacobianPoint.generateG2()},
    );
    expect(
      () async {
        await fullNodeSimulator.pushTransaction(doubleSpendBundle);
      },
      throwsA(
        isA<DoubleSpendException>(),
      ),
    );
    await fullNodeSimulator.moveToNextBlock();
  });

  test('should fail on double spend with a duplicate coin recreation',
      () async {
    final doubleSpend = CoinSpend(
      coin: acsCoinParent,
      puzzleReveal: acs,
      solution: Program.list([
        Program.list([
          Program.fromInt(51),
          Program.fromAtom(Offer.defaultSettlementProgram.hash()),
          Program.fromInt(acsCoin.amount),
        ]),
      ]),
    );

    final doubleBundle = SpendBundle(
      coinSpends: [doubleSpend],
      signatures: {JacobianPoint.generateG2()},
    );
    expect(
      () async {
        await fullNodeSimulator.pushTransaction(doubleBundle);
      },
      throwsA(isA<BadRequestException>()),
    );

    await fullNodeSimulator.moveToNextBlock();
  });

  test('should fail on minting value', () async {
    final mintingSpend = CoinSpend(
      coin: acsCoin,
      puzzleReveal: acs,
      solution: Program.list([
        Program.list([
          Program.fromInt(51),
          Program.fromAtom(Offer.defaultSettlementProgram.hash()),
          Program.fromInt(acsCoin.amount + 1),
        ]),
      ]),
    );

    expect(
      () async {
        await fullNodeSimulator.pushTransaction(
          SpendBundle(
            coinSpends: [mintingSpend],
            signatures: {JacobianPoint.generateG2()},
          ),
        );
      },
      throwsA(isA<BadRequestException>()),
    );

    await fullNodeSimulator.moveToNextBlock();
  });

  test('should fail on invalid fee reservation', () async {
    final badReserveFeeSpend = CoinSpend(
      coin: acsCoin,
      puzzleReveal: acs,
      solution: Program.list([
        Program.list([
          Program.fromInt(51),
          Program.fromAtom(Offer.defaultSettlementProgram.hash()),
          Program.fromInt(acsCoin.amount),
        ]),
        Program.list([
          Program.fromInt(52),
          Program.fromInt(1),
        ]),
      ]),
    );

    expect(
      () async {
        await fullNodeSimulator.pushTransaction(
          SpendBundle(
            coinSpends: [badReserveFeeSpend],
            signatures: {JacobianPoint.generateG2()},
          ),
        );
      },
      throwsA(isA<BadRequestException>()),
    );

    await fullNodeSimulator.moveToNextBlock();
  });

  test('should fail on unknown unspent', () async {
    final acsReplacement = CoinPrototype(
      amount: acsCoin.amount,
      parentCoinInfo: Puzzlehash.zeros(),
      puzzlehash: acsCoin.puzzlehash,
    );
    final unknownUnspentSpend = CoinSpend(
      coin: acsReplacement,
      puzzleReveal: acs,
      solution: Program.list([
        Program.list([
          Program.fromInt(51),
          Program.fromAtom(Offer.defaultSettlementProgram.hash()),
          Program.fromInt(acsCoin.amount),
        ]),
      ]),
    );

    expect(
      () async {
        await fullNodeSimulator.pushTransaction(
          SpendBundle(
            coinSpends: [unknownUnspentSpend],
            signatures: {JacobianPoint.generateG2()},
          ),
        );
      },
      throwsA(isA<BadRequestException>()),
    );

    await fullNodeSimulator.moveToNextBlock();
  });

  test('should fail on incorrect puzzle reveal', () async {
    final acsReplacement = CoinPrototype(
      parentCoinInfo: acsCoin.parentCoinInfo,
      puzzlehash: Puzzlehash.zeros(),
      amount: acsCoin.amount,
    );
    final wrongPhSpend = CoinSpend(
      coin: acsReplacement,
      puzzleReveal: acs,
      solution: Program.list([
        Program.list([
          Program.fromInt(51),
          Program.fromAtom(Offer.defaultSettlementProgram.hash()),
          Program.fromInt(acsCoin.amount),
        ]),
      ]),
    );

    expect(
      () async {
        await fullNodeSimulator.pushTransaction(
          SpendBundle(
            coinSpends: [wrongPhSpend],
            signatures: {JacobianPoint.generateG2()},
          ),
        );
      },
      throwsA(isA<BadRequestException>()),
    );

    await fullNodeSimulator.moveToNextBlock();
  });

  test('should fail with poor coin id', () async {
    final assertMyCoinIDSpend = CoinSpend(
      coin: acsCoin,
      puzzleReveal: acs,
      solution: Program.list([
        Program.list([
          Program.fromInt(51),
          Program.fromAtom(Offer.defaultSettlementProgram.hash()),
          Program.fromInt(acsCoin.amount),
        ]),
        Program.list([
          Program.fromInt(70),
          Program.fromAtom(Bytes(List.filled(32, 0))),
        ]),
      ]),
    );

    expect(
      () async {
        await fullNodeSimulator.pushTransaction(
          SpendBundle(
            coinSpends: [assertMyCoinIDSpend],
            signatures: {JacobianPoint.generateG2()},
          ),
        );
      },
      throwsA(isA<BadRequestException>()),
    );
    await fullNodeSimulator.moveToNextBlock();
  });

  test('should fail with poor parent id', () async {
    final assertMyCoinIDSpend = CoinSpend(
      coin: acsCoin,
      puzzleReveal: acs,
      solution: Program.list([
        Program.list([
          Program.fromInt(51),
          Program.fromAtom(Offer.defaultSettlementProgram.hash()),
          Program.fromInt(acsCoin.amount),
        ]),
        Program.list([
          Program.fromInt(71),
          Program.fromAtom(Bytes(List.filled(32, 0))),
        ]),
      ]),
    );

    expect(
      () async {
        await fullNodeSimulator.pushTransaction(
          SpendBundle(
            coinSpends: [assertMyCoinIDSpend],
            signatures: {JacobianPoint.generateG2()},
          ),
        );
      },
      throwsA(isA<BadRequestException>()),
    );
    await fullNodeSimulator.moveToNextBlock();
  });
}
