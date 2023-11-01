import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:meta/meta.dart';

@immutable
class StandardNftRecord implements NftRecord {
  const StandardNftRecord({
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
  bool get doesSupportDid => false;

  /// convert to [Nft] with keychain
  @override
  Nft toNft(WalletKeychain keychain) {
    final publicKey = keychain.getWalletVector(p2Puzzlehash)!.childPublicKey;
    final p2Puzzle = getPuzzleFromPk(publicKey);
    return toNftWithInnerPuzzle(p2Puzzle);
  }

  @override
  Program getFullPuzzleWithNewP2Puzzle(Program newP2Puzzle) {
    return NftWalletService.createFullPuzzle(
      singletonId: launcherId,
      metadata: metadata,
      metadataUpdaterPuzzlehash: metadataUpdaterHash,
      innerPuzzle: newP2Puzzle,
    );
  }

  @override
  Program makeInnerSolution(Program innermostSolution) {
    return innermostSolution;
  }

  @override
  NftOwnershipLayerInfo? get ownershipLayerInfo => null;
}
