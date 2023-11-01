import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class DidNftRecord implements NftRecord {
  const DidNftRecord({
    required this.launcherId,
    required this.p2Puzzlehash,
    required this.coin,
    required this.lineageProof,
    required this.latestHeight,
    required this.nftModuleHash,
    required this.stateLayer,
    required this.singletonStruct,
    required this.singletonModHash,
    required this.metadataUpdaterHash,
    required this.metadata,
    required this.ownershipLayerInfo,
  });
  @override
  final Bytes launcherId;

  @override
  final Puzzlehash p2Puzzlehash;

  @override

  /// current singleton coin of NFT
  final CoinPrototype coin;
  @override
  final LineageProof lineageProof;

  @override
  final int? latestHeight;

  @override
  final Puzzlehash nftModuleHash;
  @override
  final Program stateLayer;
  @override
  final Program singletonStruct;
  @override
  final Puzzlehash singletonModHash;
  @override
  final Puzzlehash metadataUpdaterHash;

  @override
  final NftMetadata metadata;

  @override
  bool get doesSupportDid => true;

  @override
  final NftOwnershipLayerInfo ownershipLayerInfo;

  /// convert to [Nft] with keychain
  @override
  Nft toNft(WalletKeychain keychain) {
    final publicKey = keychain.getWalletVectorOrThrow(p2Puzzlehash).childPublicKey;
    final p2Puzzle = getPuzzleFromPk(publicKey);
    final innerPuzzle = NftWalletService.constructOwnershipLayer(
      currentOwnerDid: ownershipLayerInfo.currentDid,
      transferProgram: ownershipLayerInfo.transferProgram,
      innerPuzzle: p2Puzzle,
    );
    return toNftWithInnerPuzzle(innerPuzzle);
  }

  @override
  Program getFullPuzzleWithNewP2Puzzle(Program newP2Puzzle) {
    return NftWalletService.createFullPuzzle(
      singletonId: launcherId,
      metadata: metadata,
      metadataUpdaterPuzzlehash: metadataUpdaterHash,
      innerPuzzle: NftWalletService.constructOwnershipLayer(
        currentOwnerDid: ownershipLayerInfo.currentDid,
        transferProgram: ownershipLayerInfo.transferProgram,
        innerPuzzle: newP2Puzzle,
      ),
    );
  }

  @override
  Program makeInnerSolution(Program innermostSolution) {
    return Program.list([innermostSolution]);
  }
}
