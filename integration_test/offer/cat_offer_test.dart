import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

Future<void> main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  for (final catOfferService in [
    CatOfferWalletService(),
    Cat1OfferWalletService(),
  ]) {
    final nathan = ChiaEnthusiast(fullNodeSimulator,
        catWalletService: catOfferService.catWalletService);
    await nathan.farmCoins();
    await nathan.issueMultiIssuanceCat();

    final grant = ChiaEnthusiast(fullNodeSimulator,
        catWalletService: catOfferService.catWalletService);
    await grant.farmCoins();
    await grant.issueMultiIssuanceCat();

    final ian = ChiaEnthusiast(fullNodeSimulator,
        catWalletService: catOfferService.catWalletService);
    await ian.farmCoins();
    await ian.issueMultiIssuanceCat();

    final catType =
        catOfferService.catWalletService.spendType.name.toUpperCase();

    final nathanCoinAssetId = nathan.catCoinMap.keys.first;
    final grantCoinAssetId = grant.catCoinMap.keys.first;
    final ianCoinAssetId = ian.catCoinMap.keys.first;
    test('should complete and submit a $catType offer', () async {
      final nathanStartingStandardBalance = nathan.standardCoins.totalValue;
      final nathanStartingCatBalance = nathan.catCoins.totalValue;
      final grantStartingStandardBalance = grant.standardCoins.totalValue;
      final grantStartingCatBalance = grant.catCoins.totalValue;

      final offeredAmounts = MixedAmounts(cat: {nathanCoinAssetId: 1000});
      final requestedPayments = RequestedMixedPayments(
          standard: [Payment(1000, nathan.firstPuzzlehash)]);

      // sell cat
      final offer = await nathan.offerService.createOffer(
        offeredAmounts: offeredAmounts,
        requestedPayments: requestedPayments,
        changePuzzlehash: nathan.firstPuzzlehash,
      );

      final serialized = offer.toBech32();

      final deserialized = await Offer.fromBech32Async(serialized);

      expect(serialized, deserialized.toBech32());

      expect(offer.isComplete, false);

      final acceptedOffer =
          await grant.offerService.createTakeOfferAsync(deserialized, fee: 0);

      expect(acceptedOffer.isComplete, true);

      await fullNodeSimulator
          .pushTransaction(await acceptedOffer.toSpendBundleAsync());
      await fullNodeSimulator.moveToNextBlock();

      await grant.refreshCoins();
      await nathan.refreshCoins();

      final nathanEndingStandardBalance = nathan.standardCoins.totalValue;
      final nathanEndingCatBalance = nathan.catCoins.totalValue;
      final grantEndingStandardBalance = grant.standardCoins.totalValue;
      final grantEndingCatBalance = grant.catCoins.totalValue;

      expect(
        nathanEndingStandardBalance,
        equals(nathanStartingStandardBalance + 1000),
      );
      expect(nathanEndingCatBalance, equals(nathanStartingCatBalance - 1000));

      expect(grantEndingStandardBalance,
          equals(grantStartingStandardBalance - 1000));
      expect(grantEndingCatBalance, equals(grantStartingCatBalance + 1000));
    });

    test('should complete and submit a $catType offer with left over value',
        () async {
      final nathanStartingStandardBalance = nathan.standardCoins.totalValue;
      final nathanStartingCatBalance = nathan.catCoins.totalValue;
      final grantStartingStandardBalance = grant.standardCoins.totalValue;
      final grantStartingCatBalance = grant.catCoins.totalValue;
      final ianStartingStandardBalance = ian.standardCoins.totalValue;
      final ianStartingCatBalance = ian.catCoins.totalValue;

      final nathanCoinAssetId = nathan.catCoinMap.keys.first;

      // sell cat
      final askOffer = await nathan.offerService.createOffer(
        offeredAmounts: MixedAmounts(cat: {nathanCoinAssetId: 1000}),
        changePuzzlehash: nathan.firstPuzzlehash,
        requestedPayments: RequestedMixedPayments(
            standard: [Payment(1000, nathan.firstPuzzlehash)]),
      );
      expect(askOffer.isComplete, false);

      final bidOffer = catOfferService.makeOffer(
        coinsForOffer: MixedCoins(
          standardCoins: grant.standardCoins,
        ),
        requestedPayments: RequestedMixedPayments(
          cat: {
            nathanCoinAssetId: [CatPayment(900, grant.firstPuzzlehash)],
          },
        ),
        offeredAmounts: const OfferedMixedAmounts(standard: 1100),
        keychain: grant.keychain,
        changePuzzlehash: grant.firstPuzzlehash,
      );
      expect(bidOffer.isComplete, false);

      final completedOffer = askOffer + bidOffer;
      expect(completedOffer.isComplete, true);

      await fullNodeSimulator
          .pushTransaction(completedOffer.toSpendBundle(ian.firstPuzzlehash));
      await fullNodeSimulator.moveToNextBlock();

      await grant.refreshCoins();
      await nathan.refreshCoins();
      await ian.refreshCoins();

      final nathanEndingStandardBalance = nathan.standardCoins.totalValue;
      final nathanEndingCatBalance = nathan.catCoins.totalValue;
      final grantEndingStandardBalance = grant.standardCoins.totalValue;
      final grantEndingCatBalance = grant.catCoins.totalValue;
      final ianEndingStandardBalance = ian.standardCoins.totalValue;
      final ianEndingCatBalance = ian.catCoins.totalValue;

      expect(
        nathanEndingStandardBalance,
        equals(nathanStartingStandardBalance + 1000),
      );
      expect(nathanEndingCatBalance, equals(nathanStartingCatBalance - 1000));

      expect(grantEndingStandardBalance,
          equals(grantStartingStandardBalance - 1100));
      expect(grantEndingCatBalance, equals(grantStartingCatBalance + 900));

      expect(
          ianEndingStandardBalance, equals(ianStartingStandardBalance + 100));
      expect(ianEndingCatBalance, equals(ianStartingCatBalance + 100));
    });

    test('should model a personal check using $catType', () async {
      final grantStartingStandardBalance = grant.standardCoins.totalValue;
      final grantStartingCatBalance = grant.catCoins.totalValue;
      final ianStartingStandardBalance = ian.standardCoins.totalValue;
      final ianStartingCatBalance = ian.catCoins.totalValue;

      final checkOffer = await grant.offerService.createOffer(
        offeredAmounts:
            MixedAmounts(cat: {grantCoinAssetId: 1000}, standard: 500),
        requestedPayments: null,
        changePuzzlehash: grant.firstPuzzlehash,
      );
      expect(checkOffer.isComplete, true);

      final checkCashingOffer = await ian.offerService.createTakeOffer(
        Offer.fromBech32(checkOffer.toBech32()),
        fee: 50,
        targetPuzzlehash: ian.firstPuzzlehash,
      );
      expect(checkCashingOffer.isComplete, true);

      await fullNodeSimulator
          .pushTransaction(checkCashingOffer.toSpendBundle());
      await fullNodeSimulator.moveToNextBlock();

      await grant.refreshCoins();
      await ian.refreshCoins();

      final grantEndingStandardBalance = grant.standardCoins.totalValue;
      final grantEndingCatBalance = grant.catCoins.totalValue;
      final ianEndingStandardBalance = ian.standardCoins.totalValue;
      final ianEndingCatBalance = ian.catCoins.totalValue;

      expect(grantEndingStandardBalance,
          equals(grantStartingStandardBalance - 500));
      expect(grantEndingCatBalance, equals(grantStartingCatBalance - 1000));

      expect(ianEndingStandardBalance,
          equals(ianStartingStandardBalance + 500 - 50));
      expect(ianEndingCatBalance, equals(ianStartingCatBalance + 1000));
    });

    test('should model an invoice using $catType', () async {
      final grantStartingStandardBalance = grant.standardCoins.totalValue;
      final grantStartingCatBalance = grant.catCoins.totalValue;
      final ianStartingStandardBalance = ian.standardCoins.totalValue;
      final ianStartingCatBalance = ian.catCoins.totalValue;

      final invoiceOffer = catOfferService.makeOffer(
        requestedPayments: RequestedMixedPayments(
          cat: {
            ianCoinAssetId: [CatPayment(1000, grant.firstPuzzlehash)],
          },
          standard: [Payment(500, grant.firstPuzzlehash)],
        ),
      );
      expect(invoiceOffer.isComplete, false);

      const fee = 500;
      final invoicePaymentOffer = await ian.offerService.createTakeOffer(
        Offer.fromBech32(invoiceOffer.toBech32()),
        changePuzzlehash: ian.firstPuzzlehash,
        fee: fee,
      );
      expect(invoicePaymentOffer.isComplete, true);

      await fullNodeSimulator
          .pushTransaction(invoicePaymentOffer.toSpendBundle());
      await fullNodeSimulator.moveToNextBlock();

      await grant.refreshCoins();
      await ian.refreshCoins();

      final grantEndingStandardBalance = grant.standardCoins.totalValue;
      final grantEndingCatBalance = grant.catCoins.totalValue;
      final ianEndingStandardBalance = ian.standardCoins.totalValue;
      final ianEndingCatBalance = ian.catCoins.totalValue;

      expect(grantEndingStandardBalance,
          equals(grantStartingStandardBalance + 500));
      expect(grantEndingCatBalance, equals(grantStartingCatBalance + 1000));

      expect(ianEndingStandardBalance,
          equals(ianStartingStandardBalance - 500 - fee));
      expect(ianEndingCatBalance, equals(ianStartingCatBalance - 1000));
    });

    test('should complete and submit a $catType offer with three parties',
        () async {
      final nathanStartingStandardBalance = nathan.standardCoins.totalValue;
      final nathanStartingCatBalance = nathan.catCoins.totalValue;
      final grantStartingStandardBalance = grant.standardCoins.totalValue;
      final grantStartingCatBalance = grant.catCoins.totalValue;
      final ianStartingStandardBalance = ian.standardCoins.totalValue;
      final ianStartingCatBalance = ian.catCoins.totalValue;
      // sell cat
      final askOffer = catOfferService.makeOffer(
        coinsForOffer: MixedCoins(cats: nathan.catCoins),
        offeredAmounts: OfferedMixedAmounts(cat: {nathanCoinAssetId: 1000}),
        changePuzzlehash: nathan.firstPuzzlehash,
        requestedPayments: RequestedMixedPayments(
            standard: [Payment(1000, nathan.firstPuzzlehash)]),
        keychain: nathan.keychain,
      );
      expect(askOffer.isComplete, false);

      final bidOfferOne = catOfferService.makeOffer(
        coinsForOffer: MixedCoins(standardCoins: grant.standardCoins),
        keychain: grant.keychain,
        requestedPayments: RequestedMixedPayments(
          cat: {
            nathanCoinAssetId: [CatPayment(500, grant.firstPuzzlehash)],
          },
        ),
        offeredAmounts: const OfferedMixedAmounts(standard: 250),
        changePuzzlehash: grant.firstPuzzlehash,
      );

      var aggregateOffer = askOffer + bidOfferOne;
      expect(aggregateOffer.isComplete, false);

      final bidOfferToo = catOfferService.makeOffer(
        coinsForOffer: MixedCoins(
          standardCoins: ian.standardCoins,
        ),
        keychain: ian.keychain,
        requestedPayments: RequestedMixedPayments(
          cat: {
            nathanCoinAssetId: [CatPayment(500, ian.firstPuzzlehash)],
          },
        ),
        offeredAmounts: const OfferedMixedAmounts(standard: 750),
        changePuzzlehash: ian.firstPuzzlehash,
      );
      aggregateOffer += bidOfferToo;
      expect(aggregateOffer.isComplete, true);

      await fullNodeSimulator.pushTransaction(aggregateOffer.toSpendBundle());
      await fullNodeSimulator.moveToNextBlock();

      await grant.refreshCoins();
      await nathan.refreshCoins();
      await ian.refreshCoins();

      final nathanEndingStandardBalance = nathan.standardCoins.totalValue;
      final nathanEndingCatBalance = nathan.catCoins.totalValue;
      final grantEndingStandardBalance = grant.standardCoins.totalValue;
      final grantEndingCatBalance = grant.catCoins.totalValue;
      final ianEndingStandardBalance = ian.standardCoins.totalValue;
      final ianEndingCatBalance = ian.catCoins.totalValue;

      expect(
        nathanEndingStandardBalance,
        equals(nathanStartingStandardBalance + 1000),
      );
      expect(nathanEndingCatBalance, equals(nathanStartingCatBalance - 1000));

      expect(grantEndingStandardBalance,
          equals(grantStartingStandardBalance - 250));
      expect(grantEndingCatBalance, equals(grantStartingCatBalance + 500));

      expect(
          ianEndingStandardBalance, equals(ianStartingStandardBalance - 750));
      expect(ianEndingCatBalance, equals(ianStartingCatBalance + 500));
    });

    test('should fail on incomplete $catType offer', () async {
      final askOffer = catOfferService.makeOffer(
        coinsForOffer: MixedCoins(cats: nathan.catCoins),
        offeredAmounts: OfferedMixedAmounts(cat: {nathanCoinAssetId: 1000}),
        changePuzzlehash: nathan.firstPuzzlehash,
        requestedPayments: RequestedMixedPayments(
            standard: [Payment(1000, nathan.firstPuzzlehash)]),
        keychain: nathan.keychain,
      );
      expect(askOffer.isComplete, false);

      final bidOfferRequestedAmounts = askOffer.offeredAmounts;

      final payments =
          bidOfferRequestedAmounts.toPayments(grant.firstPuzzlehash);

      final bidOffer = catOfferService.makeOffer(
        coinsForOffer: MixedCoins(
          standardCoins: grant.standardCoins,
        ),
        requestedPayments: RequestedMixedPayments(
          cat: payments.cat.map(
            (key, value) => MapEntry(key,
                value.map((e) => CatPayment(e.amount, e.puzzlehash)).toList()),
          ),
          standard: payments.standard,
        ),
        keychain: grant.keychain,
        changePuzzlehash: grant.firstPuzzlehash,
      );

      final acceptedOffer = bidOffer + askOffer;
      expect(acceptedOffer.isComplete, false);

      expect(
        () async {
          await fullNodeSimulator.pushTransaction(
              acceptedOffer.toSpendBundle(ian.firstPuzzlehash));
        },
        throwsA(isA<AssertAnnouncementConsumeFailedException>()),
      );

      await fullNodeSimulator.moveToNextBlock();
    });
  }
}
