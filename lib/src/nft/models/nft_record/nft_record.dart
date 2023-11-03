import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/exceptions/keychain_mismatch_exception.dart';
import 'package:deep_pick/deep_pick.dart';
import 'package:meta/meta.dart';

@immutable
abstract class NftRecord {
  factory NftRecord({
    required Bytes launcherId,
    required Puzzlehash p2Puzzlehash,
    required CoinPrototype coin,
    required LineageProof lineageProof,
    required int? latestHeight,
    required Puzzlehash nftModuleHash,
    required Program stateLayer,
    required Program singletonStruct,
    required Puzzlehash singletonModHash,
    required Puzzlehash metadataUpdaterHash,
    required NftMetadata metadata,
    required NftOwnershipLayerInfo? ownershipLayerInfo,
  }) {
    if (ownershipLayerInfo != null) {
      return DidNftRecord(
        launcherId: launcherId,
        p2Puzzlehash: p2Puzzlehash,
        coin: coin,
        lineageProof: lineageProof,
        latestHeight: latestHeight,
        nftModuleHash: nftModuleHash,
        stateLayer: stateLayer,
        singletonStruct: singletonStruct,
        singletonModHash: singletonModHash,
        metadataUpdaterHash: metadataUpdaterHash,
        metadata: metadata,
        ownershipLayerInfo: ownershipLayerInfo,
      );
    }
    return StandardNftRecord(
      launcherId: launcherId,
      p2Puzzlehash: p2Puzzlehash,
      coin: coin,
      lineageProof: lineageProof,
      latestHeight: latestHeight,
      nftModuleHash: nftModuleHash,
      stateLayer: stateLayer,
      singletonStruct: singletonStruct,
      singletonModHash: singletonModHash,
      metadataUpdaterHash: metadataUpdaterHash,
      metadata: metadata,
    );
  }

  static NftRecord fromUncurriedNft(
    CoinSpend parentSpend,
    UncurriedNftPuzzle uncurriedNft,
    CoinPrototype singletonCoin, {
    int? latestHeight,
  }) {
    final parentInnerPuzzleHash = uncurriedNft.stateLayer.hash();
    final lineageProof = LineageProof(
      parentCoinInfo: parentSpend.coin.parentCoinInfo,
      innerPuzzlehash: parentInnerPuzzleHash,
      amount: parentSpend.coin.amount,
    );

    final innerResult = uncurriedNft.getInnerResult(parentSpend.solution);

    // get new p2 puzzle hash from resulting conditions
    final createCoinConditions = BaseWalletService.extractConditionsFromResult(
      innerResult,
      CreateCoinCondition.isThisCondition,
      CreateCoinCondition.fromProgram,
    );

    final nftOutputConditions = createCoinConditions.where(
      (element) =>
          element.amount == 1 &&
          element.memos != null &&
          element.memos!.isNotEmpty,
    );

    if (nftOutputConditions.isEmpty) {
      throw Exception('No nft output condtions to find inner puzzle hash with');
    }

    if (nftOutputConditions.length > 1) {
      throw Exception('more than one nft output condition');
    }

    final p2PuzzleHash = Puzzlehash(nftOutputConditions.single.memos!.first);

    // get new did from resulting conditions
    final didMagicConditions = BaseWalletService.extractConditionsFromResult(
      innerResult,
      NftDidMagicConditionCondition.isThisCondition,
      NftDidMagicConditionCondition.fromProgram,
    );

    if (didMagicConditions.length > 1) {
      throw Exception('more than one nft didMagicConditions condition');
    }

    final currentOwnershipLayerInfo = uncurriedNft.ownershipLayerInfo;

    final ownershipLayerInfo = didMagicConditions.isNotEmpty
        ? currentOwnershipLayerInfo?.copyWith(
            newDid: didMagicConditions.single.targetDidOwner,
          )
        : currentOwnershipLayerInfo;

    if (ownershipLayerInfo != null) {
      return DidNftRecord(
        launcherId: uncurriedNft.launcherId,
        coin: singletonCoin,
        lineageProof: lineageProof,
        metadata: uncurriedNft.metadata,
        latestHeight: latestHeight,
        nftModuleHash: uncurriedNft.nftModuleHash,
        stateLayer: uncurriedNft.stateLayer,
        singletonStruct: uncurriedNft.singletonStruct,
        singletonModHash: uncurriedNft.singletonModHash,
        metadataUpdaterHash: uncurriedNft.metadataUpdaterHash,
        p2Puzzlehash: p2PuzzleHash,
        ownershipLayerInfo: ownershipLayerInfo,
      );
    }

    return StandardNftRecord(
      launcherId: uncurriedNft.launcherId,
      coin: singletonCoin,
      lineageProof: lineageProof,
      metadata: uncurriedNft.metadata,
      latestHeight: latestHeight,
      nftModuleHash: uncurriedNft.nftModuleHash,
      stateLayer: uncurriedNft.stateLayer,
      singletonStruct: uncurriedNft.singletonStruct,
      singletonModHash: uncurriedNft.singletonModHash,
      metadataUpdaterHash: uncurriedNft.metadataUpdaterHash,
      p2Puzzlehash: p2PuzzleHash,
    );
  }

  static Future<NftRecord?> fromParentCoinSpendAsync(
    CoinSpend parentSpend,
    CoinPrototype singletonCoin, {
    int? latestHeight,
  }) async {
    final uncurriedNft =
        await UncurriedNftPuzzle.fromProgram(parentSpend.puzzleReveal);
    if (uncurriedNft == null) {
      return null;
    }
    return NftRecord.fromUncurriedNft(
      parentSpend,
      uncurriedNft,
      singletonCoin,
      latestHeight: latestHeight,
    );
  }

  static Address makeNftIdFromLauncherId(Puzzlehash launcherId) {
    return Address.fromPuzzlehash(Puzzlehash(launcherId), 'nft');
  }

  static NftRecord? fromParentCoinSpend(
    CoinSpend parentSpend,
    CoinPrototype singletonCoin, {
    int? latestHeight,
  }) {
    final uncurriedNft =
        UncurriedNftPuzzle.fromProgramSync(parentSpend.puzzleReveal);
    if (uncurriedNft == null) {
      return null;
    }
    return NftRecord.fromUncurriedNft(
      parentSpend,
      uncurriedNft,
      singletonCoin,
      latestHeight: latestHeight,
    );
  }

  Bytes get launcherId;

  Puzzlehash get p2Puzzlehash;

  /// current singleton coin of NFT
  CoinPrototype get coin;
  LineageProof get lineageProof;

  int? get latestHeight;

  Puzzlehash get nftModuleHash;
  Program get stateLayer;
  Program get singletonStruct;
  Puzzlehash get singletonModHash;
  Puzzlehash get metadataUpdaterHash;

  NftMetadata get metadata;

  bool get doesSupportDid;

  NftOwnershipLayerInfo? get ownershipLayerInfo;

  /// convert to [Nft] with keychain
  ///
  /// thows [KeychainMismatchException] if nft is not owned by keychain
  Nft toNft(WalletKeychain keychain);
  Program getFullPuzzleWithNewP2Puzzle(Program newP2Puzzle);
  Program makeInnerSolution(
    Program innermostSolution,
  );

  static Future<List<NftRecord>> nftRecordsFromSpendBundle(
    SpendBundle spendBundle,
  ) async {
    final nftRecords = <NftRecord>[];
    for (final coinWithParentSpend in spendBundle.netAdditonWithParentSpends) {
      if (coinWithParentSpend.parentSpend != null) {
        final nftRecord = await NftRecord.fromParentCoinSpendAsync(
          coinWithParentSpend.parentSpend!,
          coinWithParentSpend,
        );

        if (nftRecord != null) {
          nftRecords.add(nftRecord);
        }
      }
    }

    return nftRecords;
  }
}

extension SharedFunctionality on NftRecord {
  /// convert to [Nft] by providing the correct inner puzzle
  Nft toNftWithInnerPuzzle(Program innerPuzzle) {
    final fullPuzzle = NftWalletService.createFullPuzzle(
      singletonId: launcherId,
      metadata: metadata,
      metadataUpdaterPuzzlehash: metadataUpdaterHash,
      innerPuzzle: innerPuzzle,
    );
    if (coin.puzzlehash != fullPuzzle.hash()) {
      throw Exception(
        'NFT coin puzzle hash does not match constructed full puzzle',
      );
    }
    return Nft(
      delegate: this,
      fullPuzzle: fullPuzzle,
    );
  }

  Future<HydratedNftRecord?> hydrate(
    NftStorageApi nftStorageApi, {
    Map<String, NftCollectionOverride>? collectionOverrides,
    Set<String> whitelistedAuthorities = const {},
  }) async {
    final recordMetadataUrls = metadata.metaUris;
    if (recordMetadataUrls == null ||
        recordMetadataUrls.isEmpty ||
        metadata.dataUris.isEmpty) {
      return null;
    }

    final metadataUrl = recordMetadataUrls.first;
    final dataUrl = metadata.dataUris.first;

    final metadataUri = Uri.tryParse(metadataUrl);
    final dataUri = Uri.tryParse(dataUrl);

    if (metadataUri == null || dataUri == null) {
      return null;
    }
    if (whitelistedAuthorities.isNotEmpty) {
      if (![metadataUri, dataUri].validate(whitelistedAuthorities)) {
        return null;
      }
    }

    try {
      final data = await nftStorageApi.getNftData(metadataUrl);
      final collectionId = data.collection.id;
      if (collectionOverrides != null &&
          collectionOverrides.containsKey(collectionId)) {
        return HydratedNftRecord(
          delegate: this,
          data: data.withCollectionOverride(collectionOverrides[collectionId]!),
          mintInfo: null,
        );
      }

      return HydratedNftRecord(
        delegate: this,
        data: data,
        mintInfo: null,
      );
    } on PickException catch (e, st) {
      LoggingContext().error(
        'error fetching nft($launcherId}) data: $e, $st. meta uris: $recordMetadataUrls',
      );
      return null;
    } on FormatException catch (e, st) {
      LoggingContext().error('error fetching nft($launcherId}) data: $e, $st');
      return null;
    }
  }

  Future<HydratedNftRecord?> hydrateAndFetchMintInfo(
    NftStorageApi nftStorageApi,
    ChiaFullNodeInterface fullNode, {
    Set<Bytes> whitelistedDIDs = const {},
    Set<Bytes> blacklistedDIDs = const {},
    Set<String> whitelistedAuthorities = const {},
  }) async {
    final mintInfo = await fullNode.getNftMintInfoForLauncherId(launcherId);
    if (mintInfo == null) {
      return null;
    }
    if (whitelistedDIDs.isNotEmpty &&
        !whitelistedDIDs.contains(mintInfo.minterDid)) {
      return null;
    }

    if (blacklistedDIDs.contains(mintInfo.minterDid)) {
      return null;
    }

    final hydrated = await hydrate(
      nftStorageApi,
      whitelistedAuthorities: whitelistedAuthorities,
    );

    if (hydrated == null) {
      return null;
    }

    return hydrated.withMintInfo(mintInfo);
  }

  Future<NftRecordWithMintInfo?> fetchMintInfo(
    ChiaFullNodeInterface fullNode,
  ) async {
    final mintInfo = await fullNode.getNftMintInfoForLauncherId(launcherId);
    if (mintInfo == null) {
      return null;
    }

    return NftRecordWithMintInfo(delegate: this, mintInfo: mintInfo);
  }

  NftId get nftId => NftId.fromLauncherId(launcherId);

  ProofOfNft getProofOfNft(WalletKeychain keychain) {
    return ProofOfNft.fromNft(this, keychain);
  }
}

extension WhiteListValidation on Iterable<Uri> {
  bool validate(Set<String> whitelistedAuthorities) {
    for (final uriToValidate in this) {
      if (!whitelistedAuthorities.any(
        (whiteListedAuthority) =>
            uriToValidate.authority.endsWith(whiteListedAuthority),
      )) {
        return false;
      }
    }
    return true;
  }
}
