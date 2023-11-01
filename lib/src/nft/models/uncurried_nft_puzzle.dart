import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// utility class for deconstructing NFT full puzzle
@immutable
class UncurriedNftPuzzle {
  const UncurriedNftPuzzle({
    required this.nftModuleHash,
    required this.stateLayer,
    required this.singletonStruct,
    required this.singletonModHash,
    required this.metadataUpdaterHash,
    required this.metadata,
    required this.innerPuzzle,
    required this.launcherId,
    required this.ownershipLayerInfo,
  });

  static Future<UncurriedNftPuzzle?> fromProgram(Program program) async {
    final programAndArguments = await program.uncurryAsync();
    if (programAndArguments.mod != singletonTopLayerV1Program) {
      return null;
    }
    final arguments = programAndArguments.arguments;

    final singletonStructure = arguments[0];
    final nftStateLayerProgram = arguments[1];
    final singletonModHash = singletonStructure.first().atom;
    final singletonLauncherId = singletonStructure.rest().first().atom;
    // final launcherPuzzleHash = singletonStructure.rest().rest();

    final nftStateLayerUncurried = nftStateLayerProgram.uncurry();

    if (nftStateLayerUncurried.mod != nftStateLayer) {
      return null;
    }
    final innerPuzzleArguments = nftStateLayerUncurried.arguments;
    final nftModHash = innerPuzzleArguments[0].atom;
    final metadataProgram = innerPuzzleArguments[1];
    final metadata = NftMetadata.fromProgram(metadataProgram);

    final metadataUpdaterHash = innerPuzzleArguments[2].atom;
    final innerPuzzle = innerPuzzleArguments[3];

    final uncurriedInnerPuzzle = await innerPuzzle.uncurryAsync();

    if (uncurriedInnerPuzzle.mod == nftOwnershipLayerProgram) {
      final innerPuzzleArguments = uncurriedInnerPuzzle.arguments;
      final currentDid = innerPuzzleArguments[1].maybeAtom;
      final transferProgram = innerPuzzleArguments[2];

      final uncurriedTransferProgramArguments =
          (await transferProgram.uncurryAsync()).arguments;
      final royaltyAddress = uncurriedTransferProgramArguments[1].maybeAtom;

      final royaltyPercentage = uncurriedTransferProgramArguments[2].toInt();

      final p2Puzzle = innerPuzzleArguments[3];

      final ownershipLayerInfo = NftOwnershipLayerInfo(
        transferProgram: transferProgram,
        currentDid: currentDid,
        royaltyPuzzleHash: Puzzlehash.maybe(royaltyAddress),
        royaltyPercentagePoints: royaltyPercentage,
        ownershipLayerP2Puzzle: p2Puzzle,
      );

      return UncurriedNftPuzzle(
        nftModuleHash: Puzzlehash(nftModHash),
        stateLayer: nftStateLayerProgram,
        singletonStruct: singletonStructure,
        singletonModHash: Puzzlehash(singletonModHash),
        metadataUpdaterHash: Puzzlehash(metadataUpdaterHash),
        metadata: metadata,
        innerPuzzle: innerPuzzle,
        launcherId: singletonLauncherId,
        ownershipLayerInfo: ownershipLayerInfo,
      );
    }

    return UncurriedNftPuzzle(
      nftModuleHash: Puzzlehash(nftModHash),
      stateLayer: nftStateLayerProgram,
      singletonStruct: singletonStructure,
      singletonModHash: Puzzlehash(singletonModHash),
      metadataUpdaterHash: Puzzlehash(metadataUpdaterHash),
      metadata: metadata,
      innerPuzzle: innerPuzzle,
      launcherId: singletonLauncherId,
      ownershipLayerInfo: null,
    );
  }

  static UncurriedNftPuzzle? fromProgramSync(Program program) {
    final programAndArguments = program.uncurry();
    return fromUnCurriedProgram(programAndArguments);
  }

  static UncurriedNftPuzzle? fromUnCurriedProgram(
      ModAndArguments programAndArguments) {
    if (programAndArguments.mod != singletonTopLayerV1Program) {
      return null;
    }
    final arguments = programAndArguments.arguments;

    final singletonStructure = arguments[0];
    final nftStateLayerProgram = arguments[1];
    final singletonModHash = singletonStructure.first().atom;
    final singletonLauncherId = singletonStructure.rest().first().atom;
    // final launcherPuzzleHash = singletonStructure.rest().rest();

    final nftStateLayerUncurried = nftStateLayerProgram.uncurry();

    if (nftStateLayerUncurried.mod != nftStateLayer) {
      return null;
    }
    final innerPuzzleArguments = nftStateLayerUncurried.arguments;
    final nftModHash = innerPuzzleArguments[0].atom;
    final metadataProgram = innerPuzzleArguments[1];
    final metadata = NftMetadata.fromProgram(metadataProgram);

    final metadataUpdaterHash = innerPuzzleArguments[2].atom;
    final innerPuzzle = innerPuzzleArguments[3];

    final uncurriedInnerPuzzle = innerPuzzle.uncurry();

    if (uncurriedInnerPuzzle.mod == nftOwnershipLayerProgram) {
      final innerPuzzleArguments = uncurriedInnerPuzzle.arguments;
      final currentDidAtom = innerPuzzleArguments[1].maybeAtom;
      final transferProgram = innerPuzzleArguments[2];

      final uncurriedTransferProgramArguments =
          transferProgram.uncurry().arguments;
      final royaltyAddress = uncurriedTransferProgramArguments[1].maybeAtom;

      final royaltyPercentage = uncurriedTransferProgramArguments[2].toInt();

      final p2Puzzle = innerPuzzleArguments[3];

      // ignore: use_if_null_to_convert_nulls_to_bools
      final currentDid =
          currentDidAtom?.isNotEmpty == true ? currentDidAtom : null;

      final ownershipLayerInfo = NftOwnershipLayerInfo(
        transferProgram: transferProgram,
        currentDid: currentDid,
        royaltyPuzzleHash: Puzzlehash.maybe(royaltyAddress),
        royaltyPercentagePoints: royaltyPercentage,
        ownershipLayerP2Puzzle: p2Puzzle,
      );

      return UncurriedNftPuzzle(
        nftModuleHash: Puzzlehash(nftModHash),
        stateLayer: nftStateLayerProgram,
        singletonStruct: singletonStructure,
        singletonModHash: Puzzlehash(singletonModHash),
        metadataUpdaterHash: Puzzlehash(metadataUpdaterHash),
        metadata: metadata,
        innerPuzzle: innerPuzzle,
        launcherId: singletonLauncherId,
        ownershipLayerInfo: ownershipLayerInfo,
      );
    }

    return UncurriedNftPuzzle(
      nftModuleHash: Puzzlehash(nftModHash),
      stateLayer: nftStateLayerProgram,
      singletonStruct: singletonStructure,
      singletonModHash: Puzzlehash(singletonModHash),
      metadataUpdaterHash: Puzzlehash(metadataUpdaterHash),
      metadata: metadata,
      innerPuzzle: innerPuzzle,
      launcherId: singletonLauncherId,
      ownershipLayerInfo: null,
    );
  }

  final Bytes launcherId;
  final Puzzlehash nftModuleHash;
  final Program stateLayer;
  final Program singletonStruct;
  final Puzzlehash singletonModHash;
  final Puzzlehash metadataUpdaterHash;
  final NftOwnershipLayerInfo? ownershipLayerInfo;
  final NftMetadata metadata;
  final Program innerPuzzle;

  bool get doesSupportDid => ownershipLayerInfo != null;

  Program get p2Puzzle =>
      ownershipLayerInfo?.ownershipLayerP2Puzzle ?? innerPuzzle;

  Program getFullPuzzleWithNewInnerPuzzle(Program newInnerPuzzle) {
    return NftWalletService.createFullPuzzle(
      singletonId: launcherId,
      metadata: metadata,
      metadataUpdaterPuzzlehash: metadataUpdaterHash,
      innerPuzzle: newInnerPuzzle,
    );
  }

  Program getInnerResult(Program spendSolution) {
    final innermostSolution = getInnerSolution(spendSolution);
    return p2Puzzle.run(innermostSolution).program;
  }

  Program getInnerSolution(Program spendSolution) {
    final stateLayerInnerSolution = spendSolution.rest().rest().first().first();

    final innermostSolution = doesSupportDid
        ? stateLayerInnerSolution.first()
        : stateLayerInnerSolution;
    return innermostSolution;
  }
}

@immutable
class NftOwnershipLayerInfo extends Equatable {
  const NftOwnershipLayerInfo({
    required this.transferProgram,
    required this.currentDid,
    required this.royaltyPuzzleHash,
    required this.royaltyPercentagePoints,
    required this.ownershipLayerP2Puzzle,
  });

  final Program transferProgram;
  final Bytes? currentDid;
  final Puzzlehash? royaltyPuzzleHash;
  final int royaltyPercentagePoints;
  final Program ownershipLayerP2Puzzle;

  NftOwnershipLayerInfo copyWith({Bytes? newDid}) => NftOwnershipLayerInfo(
        transferProgram: transferProgram,
        currentDid: newDid,
        royaltyPuzzleHash: royaltyPuzzleHash,
        royaltyPercentagePoints: royaltyPercentagePoints,
        ownershipLayerP2Puzzle: ownershipLayerP2Puzzle,
      );

  @override
  String toString() {
    return 'NftOwnershipLayerInfo(current: $currentDid)';
  }

  @override
  List<Object?> get props => [
        transferProgram,
        currentDid,
        royaltyPuzzleHash,
        royaltyPercentagePoints,
        ownershipLayerP2Puzzle,
      ];
}
