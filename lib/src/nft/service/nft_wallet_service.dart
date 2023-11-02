import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/models/conditions/create_puzzle_announcement_condition.dart';
import 'package:chia_crypto_utils/src/nft/puzzles/nft_intermediate_launcher/nft_intermediate_launcher.clvm.hex.dart';
import 'package:compute/compute.dart';

class NftWalletService {
  static const nftAmount = 1;
  final standardWalletService = StandardWalletService();
  final DIDWalletService didWalletService = DIDWalletService();

  static List<Payment> getPaymentsForCoinSpend(CoinSpend coinSpend) {
    final unCurriedNft =
        UncurriedNftPuzzle.fromProgramSync(coinSpend.puzzleReveal);
    return BaseWalletService.extractPaymentsFromSolution(
      unCurriedNft!.getInnerSolution(coinSpend.solution),
    );
  }

  static Program createFullPuzzle({
    required Bytes singletonId,
    required NftMetadata metadata,
    required Puzzlehash metadataUpdaterPuzzlehash,
    required Program innerPuzzle,
  }) {
    final singletonStructure = Program.cons(
      Program.fromAtom(singletonTopLayerV1Program.hash()),
      Program.cons(
        Program.fromAtom(singletonId),
        Program.fromAtom(singletonLauncherProgram.hash()),
      ),
    );

    final singletonInnerPuzzle = createNftLayerPuzzleWithCurryPrams(
      metadata: metadata,
      metadataUpdaterPuzzlehash: metadataUpdaterPuzzlehash,
      innerPuzzle: innerPuzzle,
    );

    final fullPuzzle = singletonTopLayerV1Program
        .curry([singletonStructure, singletonInnerPuzzle]);

    return fullPuzzle;
  }

  static Program createNftLayerPuzzleWithCurryPrams({
    required NftMetadata metadata,
    required Puzzlehash metadataUpdaterPuzzlehash,
    required Program innerPuzzle,
  }) {
    return nftStateLayer.curry([
      Program.fromAtom(nftStateLayer.hash()),
      metadata.toProgram(),
      Program.fromAtom(metadataUpdaterPuzzlehash),
      innerPuzzle,
    ]);
  }

  static Program createOwnershipLayerPuzzle({
    required Bytes launcherId,
    required Bytes? did,
    required Program p2Puzzle,
    required int royaltyPercentage,
    Puzzlehash? royaltyPuzzleHash,
  }) {
    final singletonStructure = Program.cons(
      Program.fromAtom(singletonTopLayerV1Program.hash()),
      Program.cons(
        Program.fromAtom(launcherId),
        Program.fromAtom(singletonLauncherProgram.hash()),
      ),
    );

    final royaltyPuzzleHash_ = royaltyPuzzleHash ?? p2Puzzle.hash();
    final transferProgram = nftTransferDefaultProgram.curry([
      singletonStructure,
      royaltyPuzzleHash_.toProgram(),
      Program.fromInt(royaltyPercentage),
    ]);

    return constructOwnershipLayer(
      currentOwnerDid: did,
      transferProgram: transferProgram,
      innerPuzzle: p2Puzzle,
    );
  }

  static Program constructOwnershipLayer({
    required Bytes? currentOwnerDid,
    required Program transferProgram,
    required Program innerPuzzle,
  }) {
    return nftOwnershipLayerProgram.curry([
      nftOwnershipLayerProgram.hash().toProgram(),
      Program.fromAtomOrNil(currentOwnerDid),
      transferProgram,
      innerPuzzle,
    ]);
  }

  SpendBundle createGenerateNftSpendBundle({
    required Puzzlehash minterPuzzlehash,
    Puzzlehash? targetPuzzlehash,
    Puzzlehash? changePuzzlehash,
    required NftMetadata metadata,
    required int fee,
    required List<CoinPrototype> coins,
    Bytes? originCoinId,
    required WalletKeychain keychain,
    Puzzlehash? royaltyPuzzleHash,
    int royaltyPercentagePoints = 0,
    DidInfo? targetDidInfo,
    PrivateKey? didPrivateKey,
  }) {
    if ((royaltyPercentagePoints != 0 || royaltyPuzzleHash != null) &&
        targetDidInfo == null) {
      throw Exception('Royalty info is provided without initial DID');
    }
    final did = targetDidInfo?.did;
    final originCoin = originCoinId != null
        ? coins.singleWhere((element) => element.id == originCoinId)
        : coins.first;

    final originCoinId_ = originCoin.id;

    final launcherCoin = makeLauncherCoin(originCoin.id);
    final launcherCoinId = launcherCoin.id;

    final minterPublicKey =
        keychain.getWalletVector(minterPuzzlehash)?.childPublicKey;
    if (minterPublicKey == null) {
      throw Exception('Minter puzzle hash is not in keychain');
    }
    final p2InnerPuzzle = getPuzzleFromPk(minterPublicKey);

    late final Program innerPuzzle;
    if (did != null) {
      innerPuzzle = createOwnershipLayerPuzzle(
        launcherId: launcherCoinId,
        did: null,
        p2Puzzle: p2InnerPuzzle,
        royaltyPercentage: royaltyPercentagePoints,
        royaltyPuzzleHash: royaltyPuzzleHash,
      );
    } else {
      innerPuzzle = p2InnerPuzzle;
    }

    final fullPuzzle = NftWalletService.createFullPuzzle(
      singletonId: launcherCoinId,
      metadata: metadata,
      metadataUpdaterPuzzlehash: nftMetadataUpdaterDefault.hash(),
      innerPuzzle: innerPuzzle,
    );

    final eveCoin = CoinPrototype(
      parentCoinInfo: launcherCoinId,
      puzzlehash: fullPuzzle.hash(),
      amount: nftAmount,
    );

    final nftCoin = Nft.fromFullPuzzle(
      singletonCoin: eveCoin,
      lineageProof: LineageProof(
        parentCoinInfo: launcherCoin.parentCoinInfo,
        innerPuzzlehash: null,
        amount: launcherCoin.amount,
      ),
      fullPuzzle: fullPuzzle,
    );

    final genesisLauncherSolution = Program.list(
      [
        Program.fromAtom(eveCoin.puzzlehash),
        Program.fromInt(nftAmount),
        Program.list([])
      ],
    );

    final announcements = [
      AssertCoinAnnouncementCondition(
        launcherCoinId,
        genesisLauncherSolution.hash(),
      ),
    ];

    var originSpendBundle = standardWalletService.createSpendBundle(
      payments: [Payment(nftAmount, singletonLauncherProgram.hash())],
      coinsInput: coins,
      fee: fee,
      originId: originCoinId_,
      keychain: keychain,
      changePuzzlehash: changePuzzlehash,
      coinAnnouncementsToAssert: announcements,
    );

    if (targetDidInfo != null) {
      final privateKeyToUse = didPrivateKey ??
          keychain
              .getWalletVectorOrThrow(targetDidInfo.p2Puzzle.hash())
              .childPrivateKey;
      final didApprovalInfo = getDidApprovalInfo(
        didInfo: targetDidInfo,
        launcherIds: [launcherCoinId],
        privateKey: privateKeyToUse,
      );
      originSpendBundle += didApprovalInfo.messageSpendBundle;
    }

    final launcherCoinSpend = CoinSpend(
      coin: launcherCoin,
      puzzleReveal: singletonLauncherProgram,
      solution: genesisLauncherSolution,
    );
    final launcherSpendBundle = SpendBundle(coinSpends: [launcherCoinSpend]);

    final nftSpendBundle = createSpendBundle(
      targetPuzzlehash: targetPuzzlehash ?? minterPuzzlehash,
      coinsForFee: [],
      nftCoin: nftCoin,
      keychain: keychain,
      targetDidInfo: targetDidInfo,
    );

    return originSpendBundle + launcherSpendBundle + nftSpendBundle;
  }

  static void _validateNftDatas(List<NftMintingDataWithHashes> nftDatas) {
    var hasUneditioned = false;
    var hasEditioned = false;

    final mintNumberSet = <int>{};

    for (final nftData in nftDatas) {
      final mintNumber = nftData.mintNumber;
      mintNumberSet.add(mintNumber);

      if (nftData.isEditioned) {
        hasEditioned = true;
      } else {
        hasUneditioned = true;
      }
      if (hasUneditioned && hasEditioned) {
        throw InvalidNftDataException(
          'Either all or none of the NFTs must have edition numbers',
        );
      }
    }

    if (mintNumberSet.length != nftDatas.length) {
      throw InvalidNftDataException('Mint numbers must be unique');
    }
  }

  /// throws [InvalidNftDataException]
  SpendBundle createDidNftBulkMintSpendBundle({
    required Puzzlehash targetPuzzlehash,
    Puzzlehash? minterPuzzlehash,
    Puzzlehash? changePuzzlehash,
    required List<NftMintingDataWithHashes> nftMintData,
    required int? editionTotal,
    required int fee,
    required List<CoinPrototype> coins,
    required WalletKeychain keychain,
    Puzzlehash? royaltyPuzzleHash,
    int royaltyPercentage = 0,
    required DidInfo targetDidInfo,
    PrivateKey? didPrivatKey,
  }) {
    final bundles = createUnsignedDidNftBulkMintSpendBundle(
      minterPuzzlehash: minterPuzzlehash,
      nftMintData: nftMintData,
      editionTotal: editionTotal,
      fee: fee,
      coins: coins,
      keychain: keychain,
      targetDidInfo: targetDidInfo,
      targetPuzzlehash: targetPuzzlehash,
      changePuzzlehash: changePuzzlehash,
      royaltyPuzzleHash: royaltyPuzzleHash,
      royaltyPercentage: royaltyPercentage,
    );

    final didPrivateKeyToUse = didPrivatKey ??
        keychain
            .getWalletVectorOrThrow(targetDidInfo.p2Puzzle.hash())
            .childPrivateKey;
    return bundles.totalBundle +
        bundles.unsignedDidSpendBundle
            .signWithPrivateKey(didPrivateKeyToUse)
            .signedBundle;
  }

  /// throws [InvalidNftDataException]
  UnsignedDidSpendBundleWithTotalBundle
      createUnsignedDidNftBulkMintSpendBundle({
    required Puzzlehash targetPuzzlehash,
    Puzzlehash? minterPuzzlehash,
    Puzzlehash? changePuzzlehash,
    required List<NftMintingDataWithHashes> nftMintData,
    required int? editionTotal,
    required int fee,
    required List<CoinPrototype> coins,
    required WalletKeychain keychain,
    Puzzlehash? royaltyPuzzleHash,
    int royaltyPercentage = 0,
    required DidInfo targetDidInfo,
  }) {
    _validateNftDatas(nftMintData);
    final additionalDidPayments = <Payment>[];

    final minterPublicKey = keychain
        .getWalletVector(minterPuzzlehash ?? keychain.puzzlehashes.random)
        ?.childPublicKey;
    if (minterPublicKey == null) {
      throw Exception('Minter puzzle hash is not in keychain');
    }
    final p2InnerPuzzle = getPuzzleFromPk(minterPublicKey);

    final intermediateCoinSpends = <CoinSpend>[];
    final launcherCoinSpends = <CoinSpend>[];
    final eveSpendBundles = <SpendBundle>[];
    final launcherIds = <Bytes>[];

    final didAnnouncements = <AssertCoinAnnouncementCondition>[];

    final puzzleAssertions = <AssertPuzzleAnnouncementCondition>[];
    final totalNftsToMint = nftMintData.length;

    for (final metadata in nftMintData) {
      final uniqueMintNumber = metadata.mintNumber;
      final intermediateLauncherPuzzle = nftIntermediateLauncherProgram.curry([
        singletonLauncherProgram.hash(),
        Program.fromInt(uniqueMintNumber),
        Program.fromInt(totalNftsToMint),
      ]);

      final intermediateLauncherPuzzleHash = intermediateLauncherPuzzle.hash();

      additionalDidPayments.add(
        Payment(
          0,
          intermediateLauncherPuzzleHash,
          memos: <Bytes>[intermediateLauncherPuzzleHash],
        ),
      );
      final intermediateLauncherSolution = Program.list([]);
      final intermediateLauncherCoin = CoinPrototype(
        parentCoinInfo: targetDidInfo.coin.id,
        puzzlehash: intermediateLauncherPuzzleHash,
        amount: 0,
      );

      final intermediateCoinSpend = CoinSpend(
        coin: intermediateLauncherCoin,
        puzzleReveal: intermediateLauncherPuzzle,
        solution: intermediateLauncherSolution,
      );
      intermediateCoinSpends.add(intermediateCoinSpend);

      final intermediateAnnouncementMessage =
          (encodeInt(uniqueMintNumber) + encodeInt(totalNftsToMint))
              .sha256Hash();

      didAnnouncements.add(
        AssertCoinAnnouncementCondition(
          intermediateLauncherCoin.id,
          intermediateAnnouncementMessage,
        ),
      );

      final launcherCoin = CoinPrototype(
        parentCoinInfo: intermediateLauncherCoin.id,
        puzzlehash: singletonLauncherProgram.hash(),
        amount: 1,
      );

      final launcherId = launcherCoin.id;

      launcherIds.add(launcherId);

      late final Program innerPuzzle;
      innerPuzzle = createOwnershipLayerPuzzle(
        launcherId: launcherId,
        did: null,
        p2Puzzle: p2InnerPuzzle,
        royaltyPercentage: royaltyPercentage,
        royaltyPuzzleHash: royaltyPuzzleHash,
      );

      final fullPuzzle = NftWalletService.createFullPuzzle(
        singletonId: launcherId,
        metadata: metadata.toNftMetadata(editionTotal: editionTotal),
        metadataUpdaterPuzzlehash: nftMetadataUpdaterDefault.hash(),
        innerPuzzle: innerPuzzle,
      );

      final eveCoin = CoinPrototype(
        parentCoinInfo: launcherId,
        puzzlehash: fullPuzzle.hash(),
        amount: nftAmount,
      );

      final nftCoin = Nft.fromFullPuzzle(
        singletonCoin: eveCoin,
        lineageProof: LineageProof(
          parentCoinInfo: launcherCoin.parentCoinInfo,
          innerPuzzlehash: null,
          amount: launcherCoin.amount,
        ),
        fullPuzzle: fullPuzzle,
      );

      final genesisLauncherSolution = Program.list(
        [
          Program.fromAtom(eveCoin.puzzlehash),
          Program.fromInt(nftAmount),
          Program.list([])
        ],
      );

      didAnnouncements.add(
        AssertCoinAnnouncementCondition(
          launcherId,
          genesisLauncherSolution.hash(),
        ),
      );

      final launcherCoinSpend = CoinSpend(
        coin: launcherCoin,
        puzzleReveal: singletonLauncherProgram,
        solution: genesisLauncherSolution,
      );

      launcherCoinSpends.add(launcherCoinSpend);

      final nftSpendBundle = createSpendBundle(
        targetPuzzlehash: metadata.targetPuzzlehash ?? targetPuzzlehash,
        coinsForFee: [],
        nftCoin: nftCoin,
        keychain: keychain,
        targetDidInfo: targetDidInfo,
      );

      final conditionPrograms = nftSpendBundle.outputConditions;
      final createPuzzleAnnouncements =
          BaseWalletService.extractConditionsFromProgramList(
        conditionPrograms,
        CreatePuzzleAnnouncementCondition.isThisCondition,
        CreatePuzzleAnnouncementCondition.fromProgram,
      );
      final evePuzzleAnnouncement = createPuzzleAnnouncements.first;
      final announcementHash =
          (fullPuzzle.hash() + evePuzzleAnnouncement.message).sha256Hash();
      puzzleAssertions.add(AssertPuzzleAnnouncementCondition(announcementHash));
      eveSpendBundles.add(nftSpendBundle);
    }
    late Bytes standardMessage;

    final standardSpendBundle = standardWalletService.createSpendBundle(
      payments: [],
      surplus: eveSpendBundles.length,
      fee: fee,
      coinsInput: coins,
      changePuzzlehash: changePuzzlehash,
      keychain: keychain,
      coinIdsToAssert: [targetDidInfo.coin.id],
      useCoinMessage: (message) {
        standardMessage = message;
      },
    );

    final unsignedDidBundle = didWalletService.createUnsignedSpendBundle(
      didInfo: targetDidInfo,
      puzzlesToAnnounce: launcherIds,
      additionalPayments: additionalDidPayments,
      createCoinAnnouncements: [
        CreateCoinAnnouncementCondition(standardMessage)
      ],
      assertCoinAnnouncements: didAnnouncements,
      assertPuzzleAnnouncements: puzzleAssertions,
    );

    final unsignedBundle =
        SpendBundle(coinSpends: intermediateCoinSpends + launcherCoinSpends);

    final totalSpendBundle = standardSpendBundle +
        unsignedBundle +
        SpendBundle.aggregate(eveSpendBundles);

    return UnsignedDidSpendBundleWithTotalBundle(
      unsignedDidSpendBundle: unsignedDidBundle,
      totalBundle: totalSpendBundle,
    );
  }

  DidApprovalInfo getDidApprovalInfo({
    required DidInfo didInfo,
    required List<Bytes> launcherIds,
    required PrivateKey privateKey,
  }) {
    final messageSpendBundle = didWalletService.createSpendBundleFromPrivateKey(
      didInfo: didInfo,
      puzzlesToAnnounce: launcherIds,
      privateKey: privateKey,
    );

    return DidApprovalInfo(messageSpendBundle, didInfo.innerPuzzle.hash());
  }

  Future<SpendBundle> createSpendBundleAsync({
    required Puzzlehash targetPuzzlehash,
    int fee = 0,
    List<CoinPrototype> coinsForFee = const [],
    List<Bytes> memos = const [],
    required Nft nftCoin,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    DidInfo? targetDidInfo,
    List<TradePrice>? tradePricesList,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert =
        const [],
  }) async {
    final result = await compute(
      _makeNftSpendBundleTask,
      CreateNftSpendBundleArgument(
        targetPuzzlehash: targetPuzzlehash,
        fee: fee,
        coinsForFee: coinsForFee,
        memos: memos,
        nftCoin: nftCoin,
        keychain: keychain,
        changePuzzlehash: changePuzzlehash,
        targetDidInfo: targetDidInfo,
        tradePricesList: tradePricesList,
        coinAnnouncementsToAssert: coinAnnouncementsToAssert,
        puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
        nftWalletService: this,
        network:
            stringToNetwork(ChiaNetworkContextWrapper().blockchainNetwork.name),
      ),
    );
    return SpendBundle.fromJson(result);
  }

  SpendBundle createSpendBundle({
    required Puzzlehash targetPuzzlehash,
    int fee = 0,
    List<CoinPrototype> coinsForFee = const [],
    List<Bytes> memos = const [],
    required Nft nftCoin,
    required WalletKeychain keychain,
    Puzzlehash? changePuzzlehash,
    DidInfo? targetDidInfo,
    List<TradePrice>? tradePricesList,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert =
        const [],
    List<Condition> additionalConditions = const [],
  }) {
    final createCoinAnnouncements = <CreateCoinAnnouncementCondition>[];
    SpendBundle? feeSpendBundle;
    if (fee > 0) {
      createCoinAnnouncements
          .add(CreateCoinAnnouncementCondition(nftCoin.coin.id));
      feeSpendBundle = standardWalletService.createFeeSpendBundle(
        fee: fee,
        standardCoins: coinsForFee,
        keychain: keychain,
        changePuzzlehash: changePuzzlehash,
      );
    }

    final standardInnerSolution = BaseWalletService.makeSolutionFromConditions([
      CreateCoinCondition(
        targetPuzzlehash,
        nftAmount,
        memos: [targetPuzzlehash, targetPuzzlehash, ...memos],
      ),
      CreateCoinAnnouncementCondition(nftCoin.launcherId),
      ...createCoinAnnouncements,
      ...coinAnnouncementsToAssert,
      ...puzzleAnnouncementsToAssert,
      ...additionalConditions,
    ]);
    late final Program innerSolution;
    if (nftCoin.doesSupportDid) {
      final magicCondition = NftDidMagicConditionCondition(
        targetDidOwner: targetDidInfo?.did,
        targetDidInnerHash: targetDidInfo?.innerPuzzle.hash(),
        tradePricesList: tradePricesList != null
            ? Program.list(tradePricesList.map((e) => e.toProgram()).toList())
            : null,
      );
      innerSolution = Program.list([
        Program.list([
          Program.list([]),
          Program.cons(
            Program.fromInt(1),
            Program.cons(
              magicCondition.toProgram(),
              standardInnerSolution.rest().first().rest(),
            ),
          ),
          Program.list([]),
        ]),
      ]);
    } else {
      innerSolution = standardInnerSolution;
    }

    final nftLayerSolution = Program.list([innerSolution]);
    final singletonSolution = Program.list([
      nftCoin.lineageProof.toProgram(),
      Program.fromInt(nftCoin.coin.amount),
      nftLayerSolution,
    ]);

    final coinSpend = CoinSpend(
      coin: nftCoin.coin,
      puzzleReveal: nftCoin.fullPuzzle,
      solution: singletonSolution,
    );

    final nftSpendBundle = SpendBundle(coinSpends: [coinSpend])
        .sign(
          keychain,
        )
        .signedBundle;
    if (feeSpendBundle == null) {
      return nftSpendBundle;
    }

    return nftSpendBundle + feeSpendBundle;
  }

  // needs to handle did nft
  static CoinSpend makeSpendForInnerSolution(Nft nft, Program innerSolution) {
    final singletonSolution = Program.list([
      nft.lineageProof.toProgram(),
      Program.fromInt(nft.coin.amount),
      Program.list([innerSolution]),
    ]);

    return CoinSpend(
      coin: nft.coin,
      puzzleReveal: nft.fullPuzzle,
      solution: singletonSolution,
    );
  }

  // SpendBundle signSpendBundle(
  //   SpendBundle spendBundle,
  //   WalletKeychain keychain,
  // ) {
  //   return spendBundle.signSync((coinSpend) {
  //     final puzzlehash = () {
  //       final unCurriedNftPuzzle = UncurriedNftPuzzle.fromProgramSync(coinSpend.puzzleReveal);
  //       if (unCurriedNftPuzzle != null) {
  //         return unCurriedNftPuzzle.p2Puzzle.hash();
  //       }
  //       return coinSpend.coin.puzzlehash;
  //     }();

  //     final privateKey = keychain.getWalletVector(puzzlehash)!.childPrivateKey;

  //     return standardWalletService.makeSignature(privateKey, coinSpend);
  //   });
  // }

  static CoinPrototype makeLauncherCoin(Bytes genesisCoinId) => CoinPrototype(
        parentCoinInfo: genesisCoinId,
        puzzlehash: singletonLauncherProgram.hash(),
        amount: nftAmount,
      );
}

class CreateNftSpendBundleArgument {
  CreateNftSpendBundleArgument({
    required this.targetPuzzlehash,
    required this.fee,
    required this.coinsForFee,
    required this.nftCoin,
    required this.keychain,
    required this.changePuzzlehash,
    required this.targetDidInfo,
    required this.tradePricesList,
    required this.coinAnnouncementsToAssert,
    required this.puzzleAnnouncementsToAssert,
    required this.nftWalletService,
    required this.network,
    required this.memos,
  });
  final Puzzlehash targetPuzzlehash;
  final int fee;
  final List<CoinPrototype> coinsForFee;
  final Nft nftCoin;
  final WalletKeychain keychain;
  final Puzzlehash? changePuzzlehash;
  final DidInfo? targetDidInfo;
  final List<TradePrice>? tradePricesList;
  final List<Bytes> memos;
  final List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert;
  final List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert;
  final NftWalletService nftWalletService;
  final Network network;
}

Map<String, dynamic> _makeNftSpendBundleTask(
  CreateNftSpendBundleArgument argument,
) {
  ChiaNetworkContextWrapper().registerNetworkContext(
    argument.network,
  );
  return argument.nftWalletService
      .createSpendBundle(
        targetPuzzlehash: argument.targetPuzzlehash,
        nftCoin: argument.nftCoin,
        keychain: argument.keychain,
        changePuzzlehash: argument.changePuzzlehash,
        coinAnnouncementsToAssert: argument.coinAnnouncementsToAssert,
        coinsForFee: argument.coinsForFee,
        fee: argument.fee,
        memos: argument.memos,
        puzzleAnnouncementsToAssert: argument.puzzleAnnouncementsToAssert,
        targetDidInfo: argument.targetDidInfo,
        tradePricesList: argument.tradePricesList,
      )
      .toJson();
}

class UnsignedDidSpendBundleWithTotalBundle {
  UnsignedDidSpendBundleWithTotalBundle({
    required this.unsignedDidSpendBundle,
    required this.totalBundle,
  });
  final SpendBundle unsignedDidSpendBundle;
  final SpendBundle totalBundle;
}
