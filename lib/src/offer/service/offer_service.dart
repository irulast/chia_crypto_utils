import 'package:chia_crypto_utils/chia_crypto_utils.dart';

/// Creates and takes offers for a [Wallet]
class OfferService {
  OfferService(this.wallet, this.walletService);

  static final settlementProgramHashes = {
    settlementPaymentsProgram.hash(),
    settlementPaymentsProgramOld.hash(),
  };

  static Set<Address> get settlementProgramAddresses => {
        ...settlementProgramHashes.map(
          (e) => e.toAddressWithContext(),
        ),
      };

  static Future<List<OfferedCoinLineage>> getLineagesFromOfferSpendBundle(
    SpendBundle takeOfferSpendBundle,
    ChiaFullNodeInterface fullNode,
  ) async {
    final coinSpendMap = <Bytes, CoinSpend>{};

    for (final coinSpend in takeOfferSpendBundle.coinSpends) {
      coinSpendMap[coinSpend.coin.id] = coinSpend;
    }

    // start by constructing OfferedCoinLineages which look like:
    // originCoin -> intermediate settlement payment owned coin -> output coins

    final intermediateCoinIdToAdditions = <Bytes, List<CoinPrototype>>{};

    for (final additionWithParentSpend
        in takeOfferSpendBundle.netAdditonWithParentSpends) {
      intermediateCoinIdToAdditions.update(
        additionWithParentSpend.parentSpend!.coin.id,
        (value) => [
          ...value,
          additionWithParentSpend.delegate,
        ],
        ifAbsent: () => [additionWithParentSpend.delegate],
      );
    }

    final intermediateCoinSpendsWithAdditions = <CoinSpendWithAdditions>[];

    for (final entry in intermediateCoinIdToAdditions.entries) {
      intermediateCoinSpendsWithAdditions
          .add(CoinSpendWithAdditions(coinSpendMap[entry.key]!, entry.value));
    }

    final offeredCoinLineages = <OfferedCoinLineage>[];

    final parentSpendIds = <Bytes>[];

    for (final intermediateSpendWithAdditions
        in intermediateCoinSpendsWithAdditions) {
      final originCoinSpend = coinSpendMap[
          intermediateSpendWithAdditions.coinSpend.coin.parentCoinInfo];
      if (originCoinSpend == null) {
        continue;
      }
      final parentSpendId = originCoinSpend.coin.parentCoinInfo;
      parentSpendIds.add(parentSpendId);
    }
    final parentSpends = await fullNode.getCoinSpendsByIds(parentSpendIds);

    for (final intermediateSpendWithAdditions
        in intermediateCoinSpendsWithAdditions) {
      final originCoinSpend = coinSpendMap[
          intermediateSpendWithAdditions.coinSpend.coin.parentCoinInfo];

      if (originCoinSpend == null) {
        continue;
      }

      final offeredCoinLineage = OfferedCoinLineage(
        parentSpends[originCoinSpend.coin.parentCoinInfo],
        originCoinSpend,
        intermediateSpendWithAdditions,
      )..validate();

      offeredCoinLineages.add(offeredCoinLineage);
    }
    return offeredCoinLineages;
  }

  final Wallet wallet;
  final OfferWalletService walletService;
  int get catVersion =>
      walletService.catWalletService.spendType == SpendType.cat ? 2 : 1;

  Future<Offer> createOffer({
    required MixedAmounts offeredAmounts,
    required RequestedMixedPayments? requestedPayments,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
  }) async {
    final keychain = await wallet.getKeychain();

    final offeredCoins = await wallet.getMixedCoinsForAmounts(offeredAmounts,
        catVersion: catVersion);

    return walletService.makeOffer(
      offeredAmounts: OfferedMixedAmounts(
        standard: offeredAmounts.standard,
        cat: offeredAmounts.cat,
      ),
      requestedPayments: requestedPayments,
      changePuzzlehash: changePuzzlehash ?? keychain.puzzlehashes.random,
      coinsForOffer: offeredCoins,
      keychain: keychain,
      fee: fee,
    );
  }

  Future<Offer> createOfferAsync({
    required MixedAmounts offeredAmounts,
    required RequestedMixedPayments? requestedPayments,
    Puzzlehash? changePuzzlehash,
    int fee = 0,
  }) async {
    final keychain = await wallet.getKeychain();

    final offeredCoins = await wallet.getMixedCoinsForAmounts(offeredAmounts,
        catVersion: catVersion);

    final dummyBundle = await spawnAndWaitForIsolate(
      taskArgument: CreateOfferArgs(
        network:
            stringToNetwork(ChiaNetworkContextWrapper().blockchainNetwork.name),
        offerWalletService: walletService,
        offeredAmounts: offeredAmounts,
        offeredCoins: offeredCoins,
        requestedPayments: requestedPayments,
        changePuzzlehash: changePuzzlehash,
        keychain: keychain,
        fee: fee,
      ),
      isolateTask: _createOfferDummySpendBundle,
      handleTaskCompletion: SpendBundle.fromJson,
    );

    return Offer.fromDummySpendBundleAsync(dummyBundle);
  }

  static Map<String, dynamic> _createOfferDummySpendBundle(
      CreateOfferArgs args) {
    ChiaNetworkContextWrapper().registerNetworkContext(args.network);
    return args.offerWalletService
        .makeOffer(
          offeredAmounts: OfferedMixedAmounts(
            standard: args.offeredAmounts.standard,
            cat: args.offeredAmounts.cat,
          ),
          requestedPayments: args.requestedPayments,
          coinsForOffer: args.offeredCoins,
          changePuzzlehash:
              args.changePuzzlehash ?? args.keychain.puzzlehashes.random,
          keychain: args.keychain,
          fee: args.fee,
        )
        .toDummySpendBundle()
        .toJson();
  }

  Future<Offer> createTakeOffer(
    Offer offer, {
    required int fee,
    Puzzlehash? targetPuzzlehash,
    Puzzlehash? changePuzzlehash,
  }) async {
    final requestedAmounts = offer.requestedAmounts;
    final keychain = await wallet.getKeychain();

    final coinsForOffer = await wallet.getMixedCoinsForAmounts(
      requestedAmounts.withAddedFee(fee),
      catVersion: catVersion,
    );

    final takeOffer = walletService.takeOffer(
      askOffer: offer,
      puzzlehash: targetPuzzlehash ?? keychain.puzzlehashes.random,
      changePuzzlehash: changePuzzlehash ?? keychain.puzzlehashes.random,
      coinsForOffer: coinsForOffer,
      fee: fee,
      keychain: keychain,
    );

    return takeOffer;
  }

  Future<Offer> createTakeOfferAsync(
    Offer offer, {
    required int fee,
    Puzzlehash? targetPuzzlehash,
    Puzzlehash? changePuzzlehash,
  }) async {
    final requestedAmounts = offer.requestedAmounts;
    final keychain = await wallet.getKeychain();

    final coinsForOffer = await wallet.getMixedCoinsForAmounts(
      requestedAmounts.withAddedFee(fee),
      catVersion: catVersion,
    );

    final dummyBundle = await spawnAndWaitForIsolate(
      taskArgument: TakeOfferArgs(
        network:
            stringToNetwork(ChiaNetworkContextWrapper().blockchainNetwork.name),
        offerWalletService: walletService,
        askOffer: offer,
        coinsForOffer: coinsForOffer,
        puzzlehash: targetPuzzlehash ?? keychain.puzzlehashes.random,
        changePuzzlehash: changePuzzlehash ?? keychain.puzzlehashes.random,
        keychain: keychain,
        fee: fee,
      ),
      isolateTask: _createTakeOfferDummyBundle,
      handleTaskCompletion: SpendBundle.fromJson,
    );
    return Offer.fromDummySpendBundleAsync(dummyBundle);
  }

  static Map<String, dynamic> _createTakeOfferDummyBundle(TakeOfferArgs args) {
    ChiaNetworkContextWrapper().registerNetworkContext(args.network);
    return args.offerWalletService
        .takeOffer(
          askOffer: args.askOffer,
          coinsForOffer: args.coinsForOffer,
          puzzlehash: args.puzzlehash,
          changePuzzlehash: args.changePuzzlehash,
          keychain: args.keychain,
          fee: args.fee,
        )
        .toDummySpendBundle()
        .toJson();
  }
}

class TakeOfferArgs {
  TakeOfferArgs({
    required this.network,
    required this.offerWalletService,
    required this.askOffer,
    required this.coinsForOffer,
    required this.puzzlehash,
    required this.changePuzzlehash,
    required this.keychain,
    required this.fee,
  });
  final Network network;
  final OfferWalletService offerWalletService;
  final Offer askOffer;
  final MixedCoins coinsForOffer;
  final Puzzlehash? puzzlehash;
  final Puzzlehash? changePuzzlehash;
  final WalletKeychain? keychain;
  final int fee;
}

class CreateOfferArgs {
  CreateOfferArgs({
    required this.network,
    required this.offerWalletService,
    required this.offeredAmounts,
    required this.offeredCoins,
    required this.requestedPayments,
    required this.changePuzzlehash,
    required this.keychain,
    required this.fee,
  });
  final Network network;
  final OfferWalletService offerWalletService;
  final MixedAmounts offeredAmounts;
  final MixedCoins offeredCoins;
  final RequestedMixedPayments? requestedPayments;
  final Puzzlehash? changePuzzlehash;
  final WalletKeychain keychain;
  final int fee;
}

class OfferedCoinLineage {
  OfferedCoinLineage(
    this.originalParentSpend,
    this.originalCoinSpend,
    this.intermediateSpendWithAdditions,
  );
  final CoinSpend? originalParentSpend;
  final CoinSpend originalCoinSpend;
  final CoinSpendWithAdditions intermediateSpendWithAdditions;

  void validate() {
    if (originalParentSpend != null &&
        originalParentSpend!.coin.id != originalCoinSpend.coin.parentCoinInfo) {
      throw Exception(
          'originalParentSpend.coin.id!= originalCoinSpend.coin.parentCoinInfo');
    }
    if (originalCoinSpend.coin.id !=
        intermediateSpendWithAdditions.coinSpend.coin.parentCoinInfo) {
      throw Exception(
        'originalCoinSpend.coin.id!= intermediateSpendWithAdditions.coinSpend.coin.parentCoinInfo',
      );
    }

    for (final addition in intermediateSpendWithAdditions.additions) {
      if (addition.parentCoinInfo !=
          intermediateSpendWithAdditions.coinSpend.coin.id) {
        throw Exception('addition.parentCoinInfo != originalCoinSpend.coin.id');
      }
    }
  }
}

class CoinSpendWithAdditions {
  CoinSpendWithAdditions(this.coinSpend, this.additions);

  final CoinSpend coinSpend;
  final List<CoinPrototype> additions;
}
