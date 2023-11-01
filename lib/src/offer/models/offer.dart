import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/offer/models/offered_coin/offered_coin.dart';
import 'package:chia_crypto_utils/src/utils/bech32.dart';
import 'package:chia_crypto_utils/src/utils/compression.dart';
import 'package:meta/meta.dart';

@immutable
class Offer {
  Offer({
    required this.offeredSpendBundle,
    required this.driverDict,
    this.requestedPayments = const MixedNotarizedPayments({}),
  }) : nftWalletService = NftWalletService();

  factory Offer.fromBech32(String bech32String) {
    final decoded = bech32Decode(bech32String);
    final decompressed = decompressObjectWithPuzzles(Bytes(decoded.program));
    final dummySpendBundle = SpendBundle.fromBytes(decompressed);
    return Offer.fromDummySpendBundle(dummySpendBundle);
  }

  factory Offer.fromDummySpendBundle(SpendBundle spendBundle) {
    return Offer(
      offeredSpendBundle: SpendBundle.withNullableSignatures(
        coinSpends: Offer.getLeftOverCoinSpends(spendBundle),
        signatures: {spendBundle.aggregatedSignature},
      ),
      requestedPayments: Offer.getRequestedPayments(spendBundle),
      driverDict: Offer.getDriverDict(spendBundle),
    );
  }
  final NftWalletService nftWalletService;
  final SpendBundle offeredSpendBundle;
  final MixedNotarizedPayments requestedPayments;
  final Map<Bytes?, PuzzleInfo> driverDict;

  static final defaultSettlementProgram = settlementPaymentsProgram;

  static Offer? tryParse(String bech32String) {
    try {
      return Offer.fromBech32(bech32String);
    } catch (e) {
      LoggingContext().error('Error parsing offer $bech32String: $e');
      return null;
    }
  }

  static Future<Offer> fromBech32Async(String bech32String) async {
    final dummyBundle = await spawnAndWaitForIsolate(
      taskArgument: bech32String,
      isolateTask: _decodeBech32Task,
      handleTaskCompletion: SpendBundle.fromJson,
    );
    return Offer.fromDummySpendBundleAsync(dummyBundle);
  }

  static Map<String, dynamic> _decodeBech32Task(String bech32) {
    final decoded = bech32Decode(bech32);
    final decompressed = decompressObjectWithPuzzles(Bytes(decoded.program));
    final dummySpendBundle = SpendBundle.fromBytes(decompressed);
    return dummySpendBundle.toJson();
  }

  Offer withAdditionalBundle(SpendBundle spendBundle) {
    return Offer(
      offeredSpendBundle: offeredSpendBundle + spendBundle,
      driverDict: driverDict,
      requestedPayments: requestedPayments,
    );
  }

  static Future<Offer> fromDummySpendBundleAsync(
      SpendBundle spendBundle) async {
    return Offer(
      offeredSpendBundle: SpendBundle.withNullableSignatures(
        coinSpends: Offer.getLeftOverCoinSpends(spendBundle),
        signatures: {spendBundle.aggregatedSignature},
      ),
      requestedPayments: await Offer.getRequestedPaymentsAsync(spendBundle),
      driverDict: await Offer.getDriverDictAsync(spendBundle),
    );
  }

  /// throws [UnsupportedCoinException], [CoinParseException]
  List<OfferedCoin> get generalOfferedCoins {
    final offeredCoins = <OfferedCoin>[];
    var expectedOfferedCoinCount = 0;

    for (final coinSpend in offeredSpendBundle.coinSpends) {
      final puzzleDriver = PuzzleInfo.match(coinSpend.puzzleReveal);
      if (puzzleDriver == null) {
        throw UnsupportedCoinException(coinSpend);
      }
      final p2Payments = puzzleDriver.driver.getP2Payments(coinSpend);
      for (final payment in p2Payments) {
        if ({
          settlementPaymentsProgram.hash(),
          settlementPaymentsProgramOld.hash(),
        }.contains(payment.puzzlehash)) {
          expectedOfferedCoinCount++;
        }
      }

      for (final addition in coinSpend.additions) {
        final offeredCoin =
            puzzleDriver.makeOfferedCoinFromParentSpend(addition, coinSpend);
        if (offeredCoin != null) {
          offeredCoins.add(offeredCoin);
        }
      }
    }

    if (expectedOfferedCoinCount != offeredCoins.length) {
      throw CoinParseException(expectedOfferedCoinCount, offeredCoins.length);
    }

    final removalIds = offeredSpendBundle.removals.map((e) => e.id).toSet();

    return offeredCoins
        .where((element) => !removalIds.contains(element.coin.id))
        .toList();
  }

  MixedCoins get offeredCoins =>
      MixedCoins.fromOfferedCoins(generalOfferedCoins);

  MixedAmounts get offeredAmounts {
    final offeredCoins = this.offeredCoins;

    return MixedAmounts.fromMap({
      GeneralCoinType.standard: {null: offeredCoins.standardCoins.totalValue},
      GeneralCoinType.cat: offeredCoins.catMap
          .map((assetId, coins) => MapEntry(assetId, coins.totalValue)),
      GeneralCoinType.nft: offeredCoins.nftMap
          .map((launcherId, nft) => MapEntry(launcherId, nft.coin.amount)),
    });
  }

  MixedAmounts get requestedAmounts {
    return MixedAmounts.fromMap({
      for (final entry in requestedPayments.map.entries)
        entry.key:
            entry.value.map((key, value) => MapEntry(key, value.totalValue)),
    });
  }

  MixedAmounts arbitrage() {
    return offeredAmounts - requestedAmounts;
  }

  bool get isComplete {
    final arbitrageAmounts = arbitrage();
    if (arbitrageAmounts.standard < 0) {
      return false;
    }
    if (arbitrageAmounts.nft.isNotEmpty) {
      return false;
    }

    return arbitrageAmounts.cat.values.every((v) => v >= 0);
  }

  SpendBundle toSpendBundle([Puzzlehash? arbitragePuzzlehash]) {
    final arbitrageAmounts = arbitrage().toGeneralizedMap();
    if (arbitrageAmounts.values.any((element) => element != 0) &&
        arbitragePuzzlehash == null) {
      throw ArgumentError(
        'If there are left over coins, and arbitrage puzzlehash must be specified: $arbitrageAmounts',
      );
    }
    final rawOfferedCoins = generalOfferedCoins;

    final completionCoinSpends = <CoinSpend>[];

    requestedPayments.toGeneralizedMap().forEach((assetId, payments) {
      final offeredCoinsForThisAsset =
          rawOfferedCoins.where((element) => element.assetId == assetId);
      final allPayments = List<NotarizedPayment>.of(payments);

      final arbitrageAmountForThisAsset = arbitrageAmounts[assetId];
      if (arbitrageAmountForThisAsset != null &&
          arbitrageAmountForThisAsset > 0) {
        // TODO(nvjoshi2): add hint for nft
        allPayments.add(
          NotarizedPayment.withDefaultNonce(
              arbitrageAmountForThisAsset, arbitragePuzzlehash!),
        );
      }

      for (final offeredCoin in offeredCoinsForThisAsset) {
        final innerSolutions = <Program>[];
        if (offeredCoin == offeredCoinsForThisAsset.first) {
          innerSolutions.addAll(_getInnerSolutions(allPayments));
        }
        completionCoinSpends.add(offeredCoin.toOfferSpend(innerSolutions));
      }
    });

    return SpendBundle(coinSpends: completionCoinSpends) + offeredSpendBundle;
  }

  Future<SpendBundle> toSpendBundleAsync(
      [Puzzlehash? arbitragePuzzlehash]) async {
    return spawnAndWaitForIsolate(
      taskArgument: ToSpendBundleArgs(
        offer: this,
        arbitragePuzzlehash: arbitragePuzzlehash,
        network:
            stringToNetwork(ChiaNetworkContextWrapper().blockchainNetwork.name),
      ),
      isolateTask: _toSpendBundleTask,
      handleTaskCompletion: SpendBundle.fromJson,
    );
  }

  Map<String, dynamic> _toSpendBundleTask(ToSpendBundleArgs args) {
    ChiaNetworkContextWrapper().registerNetworkContext(args.network);

    return args.offer.toSpendBundle(args.arbitragePuzzlehash).toJson();
  }

  SpendBundle toDummySpendBundle() {
    final dummyCoinSpends = <CoinSpend>[];

    requestedPayments.toGeneralizedMap().forEach((assetId, payments) {
      final driver = driverDict[assetId]!;
      final puzzleReveal =
          driver.getNewFullPuzzleForP2Puzzle(defaultSettlementProgram);
      dummyCoinSpends.add(
        CoinSpend(
          coin: CoinPrototype(
            parentCoinInfo: Puzzlehash.zeros(),
            puzzlehash: puzzleReveal.hash(),
            amount: 0,
          ),
          puzzleReveal: puzzleReveal,
          solution: Program.list(_getInnerSolutions(payments)),
        ),
      );
    });

    return offeredSpendBundle + SpendBundle(coinSpends: dummyCoinSpends);
  }

  String toBech32() {
    final spendBundleBytes = toDummySpendBundle().toBytes();
    final compressed = compressObjectWithPuzzlesOptimized(spendBundleBytes);
    final encoded = bech32Encode('offer', compressed);
    return encoded;
  }

  List<Program> _getInnerSolutions(List<NotarizedPayment> payments) {
    final innerSolutions = <Program>[];
    final nonces = payments.map((p) => p.nonce);
    for (final nonce in {...nonces}) {
      final paymentsForNonce = payments.where((p) => p.nonce == nonce);
      final innerSolution = Program.cons(
        Program.fromAtom(nonce),
        Program.list(paymentsForNonce.map((p) => p.toProgram()).toList()),
      );
      innerSolutions.add(innerSolution);
    }
    return innerSolutions;
  }

  static List<NotarizedPayment> getPaymentsFromPrograms(
      List<Program> programs) {
    final payments = <NotarizedPayment>[];
    for (final program in programs) {
      final programCons = program.cons;
      final nonce = programCons[0].atom;
      payments.addAll(
        programCons[1]
            .toList()
            .map((p) => Payment.fromProgram(p).toNotarizedPayment(nonce)),
      );
    }

    return payments;
  }

  Offer operator +(Offer other) {
    return Offer(
      offeredSpendBundle: offeredSpendBundle + other.offeredSpendBundle,
      requestedPayments: requestedPayments + other.requestedPayments,
      driverDict: driverDict..addAll(other.driverDict),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! Offer) {
      return false;
    }

    return toDummySpendBundle() == other.toDummySpendBundle();
  }

  @override
  int get hashCode => toDummySpendBundle().hashCode;

  static MixedNotarizedPayments getRequestedPayments(
    SpendBundle spendBundle,
  ) {
    final requestedCatPayments = <Puzzlehash, List<NotarizedPayment>>{};
    final requestedStandardPayments = <NotarizedPayment>[];
    final requestedNftPayments = <Puzzlehash, List<NotarizedPayment>>{};

    for (final coinSpend in spendBundle.coinSpends) {
      if (coinSpend.coin.parentCoinInfo != Puzzlehash.zeros()) {
        continue;
      }
      final puzzleInfo = PuzzleInfo.match(coinSpend.puzzleReveal);

      if (puzzleInfo == null) {
        throw Exception('Failed to match dummy payment spend puzzle');
      }
      final assetId = puzzleInfo.assetId;
      switch (puzzleInfo.type) {
        case SpendType.did:
          break;
        case SpendType.standard:
          requestedStandardPayments.addAll(
              Offer.getPaymentsFromPrograms(coinSpend.solution.toList()));
          break;
        case SpendType.cat:
        case SpendType.cat1:
          requestedCatPayments[assetId!] =
              Offer.getPaymentsFromPrograms(coinSpend.solution.toList());
          break;
        case SpendType.nft:
          requestedNftPayments[assetId!] =
              Offer.getPaymentsFromPrograms(coinSpend.solution.toList());
          break;
      }
    }

    return MixedNotarizedPayments({
      GeneralCoinType.standard: {null: requestedStandardPayments},
      GeneralCoinType.cat: requestedCatPayments,
      GeneralCoinType.nft: requestedNftPayments,
    });
  }

  static Future<MixedNotarizedPayments> getRequestedPaymentsAsync(
    SpendBundle spendBundle,
  ) async {
    final requestedCatPayments = <Puzzlehash, List<NotarizedPayment>>{};
    final requestedStandardPayments = <NotarizedPayment>[];
    final requestedNftPayments = <Puzzlehash, List<NotarizedPayment>>{};

    for (final coinSpend in spendBundle.coinSpends) {
      if (coinSpend.coin.parentCoinInfo != Puzzlehash.zeros()) {
        continue;
      }
      final driver = await PuzzleDriver.matchAsync(coinSpend.puzzleReveal);

      if (driver == null) {
        throw Exception('Failed to match dummy payment spend puzzle');
      }
      final puzzleInfo = PuzzleInfo(driver, coinSpend.puzzleReveal);

      final assetId = puzzleInfo.assetId;
      switch (puzzleInfo.type) {
        case SpendType.did:
          break;
        case SpendType.standard:
          requestedStandardPayments.addAll(
              Offer.getPaymentsFromPrograms(coinSpend.solution.toList()));
          break;
        case SpendType.cat:
        case SpendType.cat1:
          requestedCatPayments[assetId!] =
              Offer.getPaymentsFromPrograms(coinSpend.solution.toList());
          break;
        case SpendType.nft:
          requestedNftPayments[assetId!] =
              Offer.getPaymentsFromPrograms(coinSpend.solution.toList());
          break;
      }
    }

    return MixedNotarizedPayments({
      GeneralCoinType.standard: {null: requestedStandardPayments},
      GeneralCoinType.cat: requestedCatPayments,
      GeneralCoinType.nft: requestedNftPayments,
    });
  }

  Program? get requestedPaymentsSettlementProgram {
    final assertPuzzleAnnouncements =
        BaseWalletService.extractConditionsFromProgramList(
      offeredSpendBundle.outputConditions,
      AssertPuzzleAnnouncementCondition.isThisCondition,
      AssertPuzzleAnnouncementCondition.fromProgram,
    );

    final bundleAnnouncementHashes =
        assertPuzzleAnnouncements.map((e) => e.announcementHash).toSet();

    Program? matchingSettlementProgram;

    for (final settlementProgram in [
      settlementPaymentsProgram,
      // settlementPaymentsProgram,
    ]) {
      final settlementProgramAnnouncementHashes =
          OfferWalletService.calculateAnnouncements(
        requestedPayments,
        driverDict,
        settlementProgram,
      ).map(
        (e) => e.announcementHash,
      );

      if (bundleAnnouncementHashes
          .any(settlementProgramAnnouncementHashes.contains)) {
        if (matchingSettlementProgram != null) {
          throw Exception(
              'Multiple settlement programs used in announcement creation');
        }
        matchingSettlementProgram = settlementProgram;
      }
    }

    return matchingSettlementProgram;
  }

  static Map<Bytes?, PuzzleInfo> getDriverDict(
    SpendBundle spendBundle,
  ) {
    final dictionary = <Bytes?, PuzzleInfo>{};
    for (final coinSpend in spendBundle.coinSpends) {
      final driver = PuzzleInfo.match(coinSpend.puzzleReveal);
      // overwrite with real assets, not dummy spends
      if (driver != null &&
          (dictionary[driver.assetId] == null ||
              coinSpend.coin.puzzlehash != Puzzlehash.zeros())) {
        dictionary[driver.assetId] = driver;
      }
    }
    dictionary[null] = PuzzleInfo(StandardPuzzleDriver(), Program.nil);

    return dictionary;
  }

  static Future<Map<Bytes?, PuzzleInfo>> getDriverDictAsync(
    SpendBundle spendBundle,
  ) async {
    final dictionary = <Bytes?, PuzzleInfo>{};
    for (final coinSpend in spendBundle.coinSpends) {
      final driver = await PuzzleDriver.matchAsync(coinSpend.puzzleReveal);
      if (driver == null) {
        continue;
      }
      final puzzleInfo = PuzzleInfo(driver, coinSpend.puzzleReveal);
      // overwrite with real assets, not dummy spends
      if (dictionary[puzzleInfo.assetId] == null ||
          coinSpend.coin.puzzlehash != Puzzlehash.zeros()) {
        dictionary[puzzleInfo.assetId] = puzzleInfo;
      }
    }
    dictionary[null] = PuzzleInfo(StandardPuzzleDriver(), Program.nil);

    return dictionary;
  }

  static Map<Bytes?, PuzzleInfo> getDriverDictFromInput(
    MixedCoins mixedCoins,
    MixedPayments requestedPayments,
    List<NftRecord> requestedNfts,
    Program catProgram,
  ) {
    final driverDict = <Bytes?, PuzzleInfo>{};
    for (final requestedNft in requestedNfts) {
      driverDict[requestedNft.launcherId] = PuzzleInfo.match(
          requestedNft.getFullPuzzleWithNewP2Puzzle(defaultSettlementProgram))!;
    }

    for (final requestedAssetId in requestedPayments.cat.keys) {
      driverDict[requestedAssetId] = PuzzleInfo(
        CatPuzzleDriver(catProgram),
        CatWalletService.makeCatPuzzleFromParts(
          catProgram: catProgram,
          innerPuzzle: defaultSettlementProgram,
          assetId: requestedAssetId,
        ),
      );
    }

    for (final offeredCat in mixedCoins.cats) {
      driverDict[offeredCat.assetId] =
          PuzzleInfo.match(offeredCat.parentCoinSpend.puzzleReveal)!;
    }

    for (final nft in mixedCoins.nfts) {
      driverDict[nft.launcherId] = PuzzleInfo.match(nft.fullPuzzle)!;
    }

    driverDict[null] = PuzzleInfo(StandardPuzzleDriver(), Program.nil);
    return driverDict;
  }

  static List<CoinSpend> getLeftOverCoinSpends(
    SpendBundle spendBundle,
  ) {
    final leftOverCoinSpends = <CoinSpend>[];
    for (final coinSpend in spendBundle.coinSpends) {
      if (coinSpend.coin.parentCoinInfo != Puzzlehash.zeros()) {
        leftOverCoinSpends.add(coinSpend);
      }
    }

    return leftOverCoinSpends;
  }

  Future<bool> validateCoins(ChiaFullNodeInterface fullNode) async {
    final hasSpentCoins =
        await fullNode.checkForSpentCoins(offeredSpendBundle.coins);

    return !hasSpentCoins;
  }
}

class ToSpendBundleArgs {
  ToSpendBundleArgs({
    required this.offer,
    required this.arbitragePuzzlehash,
    required this.network,
  });
  final Offer offer;
  final Puzzlehash? arbitragePuzzlehash;
  final Network network;
}
