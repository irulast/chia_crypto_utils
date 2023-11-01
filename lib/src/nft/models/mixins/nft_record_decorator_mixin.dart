import 'package:chia_crypto_utils/chia_crypto_utils.dart';

mixin NftRecordDecoratorMixin implements NftRecord {
  NftRecord get delegate;

  @override
  Program getFullPuzzleWithNewP2Puzzle(Program newP2Puzzle) =>
      delegate.getFullPuzzleWithNewP2Puzzle(newP2Puzzle);

  @override
  Nft toNft(WalletKeychain keychain) => delegate.toNft(keychain);

  @override
  CoinPrototype get coin => delegate.coin;

  @override
  bool get doesSupportDid => delegate.doesSupportDid;

  @override
  int? get latestHeight => delegate.latestHeight;

  @override
  Bytes get launcherId => delegate.launcherId;

  @override
  LineageProof get lineageProof => delegate.lineageProof;

  @override
  NftMetadata get metadata => delegate.metadata;

  @override
  Puzzlehash get metadataUpdaterHash => delegate.metadataUpdaterHash;

  @override
  Puzzlehash get nftModuleHash => delegate.nftModuleHash;

  @override
  NftOwnershipLayerInfo? get ownershipLayerInfo => delegate.ownershipLayerInfo;

  @override
  Puzzlehash get p2Puzzlehash => delegate.p2Puzzlehash;

  @override
  Puzzlehash get singletonModHash => delegate.singletonModHash;

  @override
  Program get singletonStruct => delegate.singletonStruct;

  @override
  Program get stateLayer => delegate.stateLayer;

  @override
  Program makeInnerSolution(Program innermostSolution) =>
      delegate.makeInnerSolution(innermostSolution);
}
