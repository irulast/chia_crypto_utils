import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class Nft implements NftRecord {
  Nft({
    required NftRecord delegate,
    required this.fullPuzzle,
  }) : _delegate = delegate;

  factory Nft.fromFullPuzzle({
    required Program fullPuzzle,
    required CoinPrototype singletonCoin,
    required LineageProof lineageProof,
    int? latestHeight,
  }) {
    final uncurriedNft = UncurriedNftPuzzle.fromProgramSync(fullPuzzle);

    if (uncurriedNft == null) {
      throw InvalidNftException();
    }

    final nftRecord = NftRecord(
      launcherId: uncurriedNft.launcherId,
      p2Puzzlehash: uncurriedNft.p2Puzzle.hash(),
      coin: singletonCoin,
      lineageProof: lineageProof,
      latestHeight: latestHeight,
      nftModuleHash: uncurriedNft.nftModuleHash,
      stateLayer: uncurriedNft.stateLayer,
      singletonStruct: uncurriedNft.singletonStruct,
      singletonModHash: uncurriedNft.singletonModHash,
      metadataUpdaterHash: uncurriedNft.metadataUpdaterHash,
      metadata: uncurriedNft.metadata,
      ownershipLayerInfo: uncurriedNft.ownershipLayerInfo,
    );

    return Nft(
      delegate: nftRecord,
      fullPuzzle: fullPuzzle,
    );
  }
  final Program fullPuzzle;

  final NftRecord _delegate;

  @override
  Program getFullPuzzleWithNewP2Puzzle(Program newP2Puzzle) =>
      _delegate.getFullPuzzleWithNewP2Puzzle(newP2Puzzle);

  @override
  Nft toNft(WalletKeychain keychain) => this;

  @override
  CoinPrototype get coin => _delegate.coin;

  @override
  bool get doesSupportDid => _delegate.doesSupportDid;

  @override
  int? get latestHeight => _delegate.latestHeight;

  @override
  Bytes get launcherId => _delegate.launcherId;

  @override
  LineageProof get lineageProof => _delegate.lineageProof;

  @override
  NftMetadata get metadata => _delegate.metadata;

  @override
  Puzzlehash get metadataUpdaterHash => _delegate.metadataUpdaterHash;

  @override
  Puzzlehash get nftModuleHash => _delegate.nftModuleHash;

  @override
  NftOwnershipLayerInfo? get ownershipLayerInfo => _delegate.ownershipLayerInfo;

  @override
  Puzzlehash get p2Puzzlehash => _delegate.p2Puzzlehash;

  @override
  Puzzlehash get singletonModHash => _delegate.singletonModHash;

  @override
  Program get singletonStruct => _delegate.singletonStruct;

  @override
  Program get stateLayer => _delegate.stateLayer;

  CoinSpend toSpendWithInnerSolution(Program innermostSolution) {
    final innerSolution = makeInnerSolution(innermostSolution);

    final nftLayerSolution = Program.list([innerSolution]);
    final singletonSolution = Program.list([
      lineageProof.toProgram(),
      Program.fromInt(coin.amount),
      nftLayerSolution,
    ]);

    final coinSpend = CoinSpend(
      coin: coin,
      puzzleReveal: fullPuzzle,
      solution: singletonSolution,
    );

    return coinSpend;
  }

  @override
  Program makeInnerSolution(Program innermostSolution) =>
      _delegate.makeInnerSolution(innermostSolution);
}
