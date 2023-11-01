import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class OfferWalletService {
  OfferWalletService(this.catWalletService);
  final StandardWalletService standardWalletService = StandardWalletService();
  final NftWalletService nftWalletService = NftWalletService();
  final CatWalletService catWalletService;

  static CatWalletService getCatWalletServiceForCat(CatCoin cat) {
    if (cat.catProgram == cat2Program) return Cat2WalletService();
    return Cat1WalletService();
  }

  void _validateCats(MixedCoins coinsForOffer) {
    final cats = coinsForOffer.cats;

    if (cats.isEmpty) {
      return;
    }
    for (final cat in cats) {
      if (!catWalletService.validateCat(cat)) {
        throw InvalidCatException(
          message:
              'Tried to make offer with CAT${cat.catVersion} coin ${cat.id} using CAT${catWalletService.catVersion} wallet',
        );
      }
    }
  }

  Offer makeOffer({
    MixedCoins coinsForOffer = const MixedCoins(),
    OfferedMixedAmounts offeredAmounts = const OfferedMixedAmounts(),
    RequestedMixedPayments? requestedPayments,
    Puzzlehash? changePuzzlehash,
    WalletKeychain? keychain,
    List<AggSigMeCondition> additionalAggSigMeConditions = const [],
    int fee = 0,
    bool payRoyalties = true,
  }) {
    _validateCats(coinsForOffer);
    if (coinsForOffer.nfts.any((element) => element.doesSupportDid) &&
        payRoyalties) {
      return _makeNft1Offer(
        coinsForOffer: coinsForOffer,
        offeredAmounts: offeredAmounts.toMixedAmounts(),
        requestedPayments:
            requestedPayments?.toMixedPayments() ?? const MixedPayments({}),
        changePuzzlehash: changePuzzlehash,
        keychain: keychain,
        requestedNfts: requestedPayments?.nft.values
                .map((e) => e.single.nftRecord)
                .toList() ??
            [],
        fee: fee,
        settlementProgram: Offer.defaultSettlementProgram,
        additionalAggSigMeConditions: additionalAggSigMeConditions,
      );
    }
    return _makeOffer(
      offeredCoins: coinsForOffer,
      offeredAmounts: offeredAmounts.toMixedAmounts(),
      requestedPayments:
          requestedPayments?.toMixedPayments() ?? const MixedPayments({}),
      changePuzzlehash: changePuzzlehash,
      keychain: keychain,
      requestedNfts: requestedPayments?.nft.values
              .map((e) => e.single.nftRecord)
              .toList() ??
          [],
      fee: fee,
      settlementProgram: Offer.defaultSettlementProgram,
      additionalAggSigMeConditions: additionalAggSigMeConditions,
    );
  }

  Offer _makeOffer({
    MixedCoins offeredCoins = const MixedCoins(),
    MixedAmounts offeredAmounts = MixedAmounts.empty,
    MixedPayments requestedPayments = const MixedPayments({}),
    Puzzlehash? changePuzzlehash,
    WalletKeychain? keychain,
    List<NftRecord> requestedNfts = const [],
    List<AggSigMeCondition> additionalAggSigMeConditions = const [],
    required Program settlementProgram,
    int fee = 0,
  }) {
    validateAmounts(offeredAmounts, offeredCoins);

    if ((offeredCoins.allCoins.isNotEmpty || !offeredAmounts.isZero) &&
        keychain == null) {
      throw Exception('keychain is needed if offering coins');
    }

    var additionalConditions = additionalAggSigMeConditions;

    final driverDict = Offer.getDriverDictFromInput(
      offeredCoins,
      requestedPayments,
      requestedNfts,
      catWalletService.catProgram,
    );

    final nonce = createNonce(offeredCoins.allCoins);
    final notarizedMixedPayments =
        requestedPayments.toMixedNotarizedPayments(nonce);
    final announcements = calculateAnnouncements(
      notarizedMixedPayments,
      driverDict,
      settlementProgram,
    );
    final offerPuzzlehash = settlementProgram.hash();

    var offeredSpendBundle = SpendBundle.empty;
    offeredAmounts.cat.forEach((assetId, amount) {
      final catCoins = offeredCoins.cats.where((c) => c.assetId == assetId);

      final catWalletService = getCatWalletServiceForCat(catCoins.first);

      final catSpendBundle = catWalletService.createSpendBundle(
        payments: [CatPayment(amount, offerPuzzlehash)],
        catCoinsInput: catCoins.toList(),
        keychain: keychain!,
        changePuzzlehash: changePuzzlehash,
        puzzleAnnouncementsToAssert: announcements,
        additionalConditions: additionalConditions,
      );
      additionalConditions = [];

      offeredSpendBundle += catSpendBundle;
    });

    if (offeredAmounts.standard > 0) {
      final standardSpendBundle = standardWalletService.createSpendBundle(
        payments: [Payment(offeredAmounts.standard, offerPuzzlehash)],
        coinsInput: offeredCoins.standardCoins,
        keychain: keychain!,
        changePuzzlehash: changePuzzlehash,
        puzzleAnnouncementsToAssert: announcements,
        fee: fee,
        additionalConditions: additionalConditions,
      );
      additionalConditions = [];

      offeredSpendBundle += standardSpendBundle;
    } else if (fee > 0) {
      final feeBundle = standardWalletService.createFeeSpendBundle(
        fee: fee,
        standardCoins: offeredCoins.standardCoins,
        keychain: keychain!,
        changePuzzlehash: changePuzzlehash,
        puzzleAnnouncementsToAssert: announcements,
        additionalConditions: additionalConditions,
      );
      additionalConditions = [];

      offeredSpendBundle += feeBundle;
    }

    for (final nft in offeredCoins.nfts) {
      final nftSpendBundle = nftWalletService.createSpendBundle(
        targetPuzzlehash: offerPuzzlehash,
        nftCoin: nft,
        keychain: keychain!,
        puzzleAnnouncementsToAssert: announcements,
        additionalConditions: additionalConditions,
      );
      additionalConditions = [];

      offeredSpendBundle += nftSpendBundle;
    }

    return Offer(
      offeredSpendBundle: offeredSpendBundle,
      requestedPayments: notarizedMixedPayments,
      driverDict: driverDict,
    );
  }

  Offer _makeNft1Offer({
    MixedCoins coinsForOffer = const MixedCoins(),
    MixedAmounts offeredAmounts = MixedAmounts.empty,
    MixedPayments requestedPayments = const MixedPayments({}),
    Puzzlehash? changePuzzlehash,
    WalletKeychain? keychain,
    List<AggSigMeCondition> additionalAggSigMeConditions = const [],
    int fee = 0,
    List<NftRecord> requestedNfts = const [],
    required Program settlementProgram,
  }) {
    validateAmounts(offeredAmounts, coinsForOffer);

    if ((coinsForOffer.allCoins.isNotEmpty || !offeredAmounts.isZero) &&
        keychain == null) {
      throw Exception('keychain is needed if offering coins');
    }

    var additionalConditions = additionalAggSigMeConditions;

    final driverDict = Offer.getDriverDictFromInput(
      coinsForOffer,
      requestedPayments,
      requestedNfts,
      catWalletService.catProgram,
    );

    final requestedRoyaltyEnabledNftRecords = <NftRecord>[];
    final offeredRoyaltyEnabledNftRecords = <NftRecord>[];

    for (final requestedNft in requestedNfts) {
      if (requestedNft.doesSupportDid) {
        requestedRoyaltyEnabledNftRecords.add(requestedNft);
      }
    }

    for (final offeredNft in coinsForOffer.nfts) {
      if (offeredNft.doesSupportDid) {
        offeredRoyaltyEnabledNftRecords.add(offeredNft);
      }
    }

    final offerSideRoyaltySplit = coinsForOffer.nfts.length;
    final requestSideRoyaltySplit = requestedPayments.nft.length;

    final tradePrices = <TradePrice>[];

    requestedPayments.map.forEach((type, value) {
      if (type == GeneralCoinType.nft) {
        return;
      }
      for (final entry in value.entries) {
        final assetId = entry.key;
        final payments = entry.value;
        for (final requestedPayment in payments) {
          final settlementPuzzleHash = driverDict[assetId]!
              .getNewFullPuzzleForP2Puzzle(Offer.defaultSettlementProgram)
              .hash();
          if (requestedPayment.amount > 0 && offerSideRoyaltySplit > 0) {
            tradePrices.add(
              TradePrice(requestedPayment.amount ~/ offerSideRoyaltySplit,
                  settlementPuzzleHash),
            );
          }
        }
      }
    });

    final royaltyInfos = <RoyaltyInfo>[];

    for (final requestedRoyaltyEnabledNft
        in requestedRoyaltyEnabledNftRecords) {
      royaltyInfos.add(
        RoyaltyInfo(
          launcherId: requestedRoyaltyEnabledNft.launcherId,
          royaltyPuzzleHash:
              requestedRoyaltyEnabledNft.ownershipLayerInfo!.royaltyPuzzleHash!,
          royaltyPercentage: requestedRoyaltyEnabledNft
              .ownershipLayerInfo!.royaltyPercentagePoints,
        ),
      );
    }

    final offeredRoyaltyInfos = offeredRoyaltyEnabledNftRecords.map(
      (e) => RoyaltyInfo(
        launcherId: e.launcherId,
        royaltyPuzzleHash: e.ownershipLayerInfo!.royaltyPuzzleHash!,
        royaltyPercentage: e.ownershipLayerInfo!.royaltyPercentagePoints,
      ),
    );

    // standard royalty payments

    final royaltyPayments =
        <GeneralCoinType, Map<Bytes?, List<RoyaltyPaymentWithLauncherId>>>{};

    offeredAmounts.map.forEach((type, assetAmountMap) {
      royaltyPayments[type] = assetAmountMap.map((assetId, offeredAmount) {
        final assetRoyaltyPayments = <RoyaltyPaymentWithLauncherId>[];

        for (final royaltyInfo in royaltyInfos) {
          final extraRoyaltyAmount =
              ((offeredAmount ~/ requestSideRoyaltySplit) *
                      (royaltyInfo.royaltyPercentage / 10000))
                  .floor();
          assetRoyaltyPayments.add(
            RoyaltyPaymentWithLauncherId(
              Payment(
                extraRoyaltyAmount,
                royaltyInfo.royaltyPuzzleHash,
                memos: <Bytes>[royaltyInfo.royaltyPuzzleHash],
              ),
              royaltyInfo.launcherId,
            ),
          );
        }

        return MapEntry(assetId, assetRoyaltyPayments);
      });
    });

    final nonce = createNonce(coinsForOffer.allCoins);
    final notarizedMixedPayments =
        requestedPayments.toMixedNotarizedPayments(nonce);
    final announcements = calculateAnnouncements(
      notarizedMixedPayments,
      driverDict,
      settlementProgram,
    );

    royaltyPayments.forEach((type, assetPaymentType) {
      assetPaymentType.forEach((assetId, payments) {
        final settlementHash = driverDict[assetId]!
            .getNewFullPuzzleForP2Puzzle(Offer.defaultSettlementProgram)
            .hash();
        for (final payment in payments) {
          if (payment.amount > 0) {
            announcements.add(
              AssertPuzzleAnnouncementCondition(
                AssertCoinAnnouncementCondition(
                  settlementHash,
                  Program.cons(
                    payment.launcherId,
                    Program.list([payment.payment.toProgram()]),
                  ).hash(),
                ).announcementId,
              ),
            );
          }
        }
      });
    });

    final offerPuzzlehash = settlementProgram.hash();

    var offeredSpendBundle = SpendBundle.empty;

    offeredAmounts.cat.forEach((assetId, amount) {
      final catCoins = coinsForOffer.cats.where((c) => c.assetId == assetId);

      final catRoyaltyPayments = royaltyPayments[GeneralCoinType.cat]
              ?[assetId] ??
          <RoyaltyPaymentWithLauncherId>[];

      final royaltyPaymentsSum = catRoyaltyPayments.sum();

      final catSpendBundle = catWalletService.createSpendBundle(
        payments: [
          CatPayment(amount, offerPuzzlehash),
          if (royaltyPaymentsSum > 0)
            CatPayment(royaltyPaymentsSum, offerPuzzlehash),
        ],
        catCoinsInput: catCoins.toList(),
        keychain: keychain!,
        changePuzzlehash: changePuzzlehash,
        puzzleAnnouncementsToAssert: announcements,
        additionalConditions: additionalConditions,
      );
      additionalConditions = [];
      offeredSpendBundle += catSpendBundle;

      if (royaltyPaymentsSum > 0) {
        final royaltyBundle = makeRoyaltySpendBundle(
            driverDict[assetId]!
                .getNewFullPuzzleForP2Puzzle(Offer.defaultSettlementProgram),
            catRoyaltyPayments,
            catSpendBundle, (coin, parentSpend, innerRoyaltySolution) {
          final catProgram =
              parentSpend.type == SpendType.cat ? cat2Program : cat1Program;
          final catCoin = CatCoin.fromParentSpend(
            parentCoinSpend: parentSpend,
            coin: coin,
          );
          final spendableCat = SpendableCat(
            coin: catCoin,
            innerPuzzle: Offer.defaultSettlementProgram,
            innerSolution: innerRoyaltySolution,
          );

          return CatWalletService.fromCatProgram(catProgram)
              .makeUnsignedSpendBundleForSpendableCats([spendableCat])
              .coinSpends[0]
              .solution;
        });
        offeredSpendBundle += royaltyBundle;
      }
    });

    if (offeredAmounts.standard > 0) {
      final standardRoyaltyPayments = royaltyPayments[GeneralCoinType.standard]
              ?[null] ??
          <RoyaltyPaymentWithLauncherId>[];

      final royaltySum = standardRoyaltyPayments.sum();
      final standardSpendBundle = standardWalletService.createSpendBundle(
        payments: [
          Payment(offeredAmounts.standard, offerPuzzlehash),
          if (royaltySum > 0) Payment(royaltySum, offerPuzzlehash),
        ],
        coinsInput: coinsForOffer.standardCoins,
        keychain: keychain!,
        fee: fee,
        changePuzzlehash: changePuzzlehash,
        puzzleAnnouncementsToAssert: announcements,
        additionalConditions: additionalConditions,
      );
      additionalConditions = [];

      offeredSpendBundle += standardSpendBundle;

      if (royaltySum > 0) {
        final royaltyBundle = makeRoyaltySpendBundle(
          Offer.defaultSettlementProgram,
          standardRoyaltyPayments,
          standardSpendBundle,
          (coin, parentSpend, innerRoyaltySolution) => innerRoyaltySolution,
        );
        offeredSpendBundle += royaltyBundle;
      }
    } else if (fee > 0) {
      final feeBundle = standardWalletService.createFeeSpendBundle(
        fee: fee,
        standardCoins: coinsForOffer.standardCoins,
        keychain: keychain!,
        changePuzzlehash: changePuzzlehash,
        puzzleAnnouncementsToAssert: announcements,
        additionalConditions: additionalConditions,
      );
      additionalConditions = [];

      offeredSpendBundle += feeBundle;
    }

    for (final nft in coinsForOffer.nfts) {
      final nftSpendBundle = nftWalletService.createSpendBundle(
        targetPuzzlehash: offerPuzzlehash,
        nftCoin: nft,
        keychain: keychain!,
        tradePricesList: tradePrices
            .where(
              (element) =>
                  element.amount *
                      (offeredRoyaltyInfos
                              .singleWhere((element) =>
                                  element.launcherId == nft.launcherId)
                              .royaltyPercentage /
                          10000) >
                  0,
            )
            .toList(),
        puzzleAnnouncementsToAssert: announcements,
        additionalConditions: additionalConditions,
      );
      additionalConditions = [];

      offeredSpendBundle += nftSpendBundle;
    }

    return Offer(
      offeredSpendBundle: offeredSpendBundle,
      driverDict: driverDict,
      requestedPayments: notarizedMixedPayments,
    );
  }

  SpendBundle makeRoyaltySpendBundle(
    Program offerPuzzle,
    List<RoyaltyPaymentWithLauncherId> royaltyPayments_,
    SpendBundle mainSpendBundle,
    Program Function(
      CoinPrototype coin,
      CoinSpend parentSpend,
      Program innerRoyaltySolution,
    )
        makeSolutionFromInnerSolution,
  ) {
    var royaltyPayments =
        List<RoyaltyPaymentWithLauncherId>.from(royaltyPayments_);
    CoinPrototypeWithParentSpend? royaltyCoinWithParentSpend;
    final royaltyPuzzleHash = offerPuzzle.hash();
    var totalBundle = SpendBundle.empty;
    while (true) {
      final duplicatePayments = <RoyaltyPaymentWithLauncherId>[];
      final deDuplicatedPayments = <RoyaltyPaymentWithLauncherId>[];
      for (final royaltyPayment in royaltyPayments) {
        if (deDuplicatedPayments
            .map((e) => e.payment)
            .contains(royaltyPayment.payment)) {
          duplicatePayments.add(royaltyPayment);
        } else {
          deDuplicatedPayments.add(royaltyPayment);
        }
      }
      var innerRoyaltySolution =
          Program.list(deDuplicatedPayments.map((e) => e.toProgram()).toList());

      if (duplicatePayments.isNotEmpty) {
        innerRoyaltySolution = Program.cons(
          Program.cons(
            Program.nil,
            Program.list([
              Payment(
                duplicatePayments.sum(),
                Offer.defaultSettlementProgram.hash(),
              ).toProgram(),
            ]),
          ),
          innerRoyaltySolution,
        );
      }

      royaltyCoinWithParentSpend = () {
        for (final coin in mainSpendBundle.additions) {
          final royaltyPaymentAmount = royaltyPayments.sum();
          if (coin.amount == royaltyPaymentAmount &&
              coin.puzzlehash == royaltyPuzzleHash) {
            final royaltyCoin = coin;
            final coinSpend = mainSpendBundle.coinSpends.singleWhere(
                (element) => element.coin.id == royaltyCoin.parentCoinInfo);

            return CoinPrototypeWithParentSpend.fromCoin(
                royaltyCoin, coinSpend);
          }
        }
      }();

      final newCoinSpend = CoinSpend(
        coin: royaltyCoinWithParentSpend!,
        puzzleReveal: offerPuzzle,
        solution: makeSolutionFromInnerSolution(
          royaltyCoinWithParentSpend,
          royaltyCoinWithParentSpend.parentSpend!,
          innerRoyaltySolution,
        ),
      );

      totalBundle += SpendBundle(
        coinSpends: [newCoinSpend],
      );

      if (duplicatePayments.isNotEmpty) {
        royaltyPayments = duplicatePayments;
        royaltyCoinWithParentSpend = CoinPrototypeWithParentSpend.fromCoin(
          newCoinSpend.additions
              .firstWhere((a) => a.puzzlehash == royaltyPuzzleHash),
          newCoinSpend,
        );
        throw Exception('ha');
      } else {
        break;
      }
    }

    return totalBundle;
  }

  void validateAmounts(MixedAmounts amounts, MixedCoins coins) {
    if (amounts.standard > coins.standardCoins.totalValue) {
      throw Exception(
        'Total value of standard coins does not meet amount required. ${coins.standardCoins.totalValue} < ${amounts.standard}',
      );
    }
    if (amounts.standard < 0) {
      throw Exception(
        'Can not offer amount less than zero: ${amounts.standard}}',
      );
    }

    amounts.cat.forEach((assetId, amount) {
      final catCoins = coins.cats.where((c) => c.assetId == assetId).toList();
      if (amount > catCoins.totalValue) {
        throw Exception(
          'Value of Cat Coins with asset id($assetId) does not meet amount required. ${catCoins.totalValue} < $amount',
        );
      }
      if (amount < 0) {
        throw Exception(
          'Can not offer amount less than zero: $amount',
        );
      }
    });
  }

  Offer takeOffer({
    required Offer askOffer,
    MixedCoins coinsForOffer = const MixedCoins(),
    Puzzlehash? puzzlehash,
    Puzzlehash? changePuzzlehash,
    WalletKeychain? keychain,
    int fee = 0,
  }) {
    validateAmounts(askOffer.requestedAmounts, coinsForOffer);

    final takeOfferRequestedAmounts = askOffer.offeredAmounts;
    final takeOfferOfferedAmounts = askOffer.requestedAmounts;

    if (!takeOfferRequestedAmounts.isZero && puzzlehash == null) {
      throw Exception(
        'Must supply puzzlehash if ask offer has non zero offer amounts',
      );
    }
    final offeredNfts = askOffer.offeredCoins.nfts;

    final takeOfferRequestedPayments = takeOfferRequestedAmounts.isZero
        ? const MixedPayments({})
        : takeOfferRequestedAmounts.toPayments(puzzlehash!);

    final bidOffer = () {
      if (offeredNfts.any((element) => element.doesSupportDid)) {
        return _makeNft1Offer(
          coinsForOffer: coinsForOffer,
          offeredAmounts: takeOfferOfferedAmounts,
          requestedPayments: takeOfferRequestedPayments,
          keychain: keychain,
          changePuzzlehash: changePuzzlehash ?? puzzlehash,
          requestedNfts: offeredNfts,
          fee: fee,
          settlementProgram: askOffer.requestedPaymentsSettlementProgram ??
              Offer.defaultSettlementProgram,
        );
      }
      return _makeOffer(
        offeredCoins: coinsForOffer,
        offeredAmounts: takeOfferOfferedAmounts,
        requestedPayments: takeOfferRequestedPayments,
        keychain: keychain,
        changePuzzlehash: changePuzzlehash ?? puzzlehash,
        requestedNfts: offeredNfts,
        fee: fee,
        settlementProgram: askOffer.requestedPaymentsSettlementProgram ??
            Offer.defaultSettlementProgram,
      );
    }();

    return askOffer + bidOffer;
  }

  Bytes createNonce(List<CoinPrototype> coins) {
    final sortedCoins = List<CoinPrototype>.from(coins)
      ..sort(
        (a, b) => a.id.compareTo(b.id),
      );

    return Program.list(sortedCoins.map((c) => c.toProgram()).toList()).hash();
  }

  static List<AssertPuzzleAnnouncementCondition> calculateAnnouncements(
    MixedNotarizedPayments notarizedMixedPayments,
    Map<Bytes?, PuzzleInfo> driverDict,
    Program settlementProgram,
  ) {
    final announcements = <AssertPuzzleAnnouncementCondition>[];

    notarizedMixedPayments.toGeneralizedMap().forEach((assetId, payments) {
      if (payments.isEmpty) {
        return;
      }
      final settlementPuzzlehash = driverDict[assetId]!
          .getNewFullPuzzleForP2Puzzle(settlementProgram)
          .hash();
      final message = Program.cons(
        Program.fromAtom(payments[0].nonce),
        Program.list(payments.map((p) => p.toProgram()).toList()),
      ).hash();

      announcements.add(
        AssertPuzzleAnnouncementCondition(
          AssertCoinAnnouncementCondition(settlementPuzzlehash, message)
              .announcementId,
        ),
      );
    });

    return announcements;
  }

  static Future<ParsedOffer> parseOffer(
    Offer offer, {
    TailDatabaseApi? tailDatabaseApi,
    NftStorageApi? nftStorageApi,
  }) async {
    return parseAmounts(
      offeredAmounts: offer.offeredAmounts,
      requestedAmounts: offer.requestedAmounts,
      offeredNfts: offer.offeredCoins.nfts,
      tailDatabaseApi: tailDatabaseApi,
      nftStorageApi: nftStorageApi,
    );
  }

  static Future<ParsedOffer> parseAmounts({
    required MixedAmounts offeredAmounts,
    required MixedAmounts requestedAmounts,
    required List<NftRecord> offeredNfts,
    TailDatabaseApi? tailDatabaseApi,
    NftStorageApi? nftStorageApi,
  }) async {
    final fetchTailDatabaseInfo = tailDatabaseApi != null;

    final offeredParsedCatInfos = <ParsedCatInfo>[];
    for (final mapEntry in offeredAmounts.cat.entries) {
      final assetId = mapEntry.key;
      final amount = mapEntry.value;

      String? catName;
      String? ticker;
      String? description;
      if (fetchTailDatabaseInfo) {
        final tailInfo = await tailDatabaseApi.getTailInfo(assetId);
        catName = tailInfo.name;
        ticker = tailInfo.code;
        description = tailInfo.description;
      }
      offeredParsedCatInfos.add(
        ParsedCatInfo(
          amountMojos: amount,
          assetId: assetId.toHex(),
          name: catName,
          ticker: ticker,
          description: description,
        ),
      );
    }

    final requestedParsedCatInfos = <ParsedCatInfo>[];
    for (final mapEntry in requestedAmounts.cat.entries) {
      final assetId = mapEntry.key;
      final amount = mapEntry.value;

      String? catName;
      String? ticker;
      String? description;
      if (fetchTailDatabaseInfo) {
        final tailInfo = await tailDatabaseApi.getTailInfo(assetId);
        catName = tailInfo.name;
        ticker = tailInfo.code;
        description = tailInfo.description;
      }
      requestedParsedCatInfos.add(
        ParsedCatInfo(
          amountMojos: amount,
          assetId: assetId.toHex(),
          name: catName,
          ticker: ticker,
          description: description,
        ),
      );
    }

    final offeredParsedNftInfos = <ParsedNftInfo>[];

    for (final nft in offeredNfts) {
      if (nftStorageApi != null) {
        final hydratedNft = await nft.hydrate(nftStorageApi);
        if (hydratedNft != null) {
          offeredParsedNftInfos.add(ParsedNftInfo.fromHydratedNft(hydratedNft));
        } else {
          offeredParsedNftInfos.add(ParsedNftInfo.fromNft(nft));
        }
      } else {
        offeredParsedNftInfos.add(ParsedNftInfo.fromNft(nft));
      }
    }

    return ParsedOffer(
      offeredAmounts: ParsedMixedAmounts(
        standard: offeredAmounts.standard,
        cats: offeredParsedCatInfos,
        nfts: offeredParsedNftInfos,
      ),
      requestedAmounts: ParsedMixedAmounts(
        standard: requestedAmounts.standard,
        cats: requestedParsedCatInfos,
      ),
    );
  }
}

class TradePrice {
  const TradePrice(this.amount, this.settlementPuzzleHash);

  final int amount;
  final Puzzlehash settlementPuzzleHash;

  Program toProgram() => Program.list([
        Program.fromInt(amount),
        settlementPuzzleHash.toProgram(),
      ]);
}

class RoyaltyInfo {
  const RoyaltyInfo({
    required this.launcherId,
    required this.royaltyPuzzleHash,
    required this.royaltyPercentage,
  });
  final Bytes launcherId;
  final Puzzlehash royaltyPuzzleHash;
  final int royaltyPercentage;
}

class RoyaltyPaymentWithLauncherId implements Summable {
  RoyaltyPaymentWithLauncherId(this.payment, this.launcherId);

  final Payment payment;
  final Bytes launcherId;

  Program toProgram() {
    return Program.cons(launcherId, Program.list([payment.toProgram()]));
  }

  @override
  int get amount => payment.amount;
}
