import 'package:chia_crypto_utils/chia_crypto_utils.dart';

void main() {
  final coreSecret = KeychainCoreSecret.fromMnemonic(
    'goat club mountain ritual rack same bar put fall anxiety minor theme enter card dog lawsuit rather pigeon manual tribe shield decline gentle install'
        .split(' '),
  );
  final keychain = WalletKeychain.fromCoreSecret(coreSecret);

  final inputMetadata = NftMetadata(
    dataUris: const [
      'https://www.chia.net/img/branding/chia-logo.svg',
    ],
    dataHash: Program.fromInt(0).hash(),
  );

  final did = Program.fromInt(3).hash();

  final senderWalletVector = keychain.unhardenedWalletVectors.first;
  final receiverWalletVector = keychain.unhardenedWalletVectors.last;

  final launcherCoin = CoinPrototype(
    parentCoinInfo: Program.fromInt(0).hash(),
    puzzlehash: Program.fromInt(1).hash(),
    amount: 1,
  );

  final senderP2Puzzle = getPuzzleFromPk(senderWalletVector.childPublicKey);

  final ownershipLayer = NftWalletService.createOwnershipLayerPuzzle(
    launcherId: launcherCoin.id,
    did: did,
    p2Puzzle: senderP2Puzzle,
    royaltyPercentage: 200,
  );

  final fullPuzzle = NftWalletService.createFullPuzzle(
    singletonId: launcherCoin.id,
    metadata: inputMetadata,
    metadataUpdaterPuzzlehash: nftMetadataUpdaterDefault.hash(),
    innerPuzzle: ownershipLayer,
  );

  final uncurriedNft = UncurriedNftPuzzle.fromProgramSync(fullPuzzle);

  // solution

  final standardInnerSolution = BaseWalletService.makeSolutionFromConditions([
    CreateCoinCondition(receiverWalletVector.puzzlehash, 1,
        memos: [senderWalletVector.puzzlehash]),
  ]);

  final magicCondition = NftDidMagicConditionCondition();

  final innerSolution = Program.list([
    Program.list([
      Program.list([]),
      Program.cons(
        Program.fromInt(1),
        Program.cons(magicCondition.toProgram(),
            standardInnerSolution.rest().first().rest()),
      ),
      Program.list([]),
    ]),
  ]);

  final nftLayerSolution = Program.list([innerSolution]);
  final singletonSolution = Program.list([
    LineageProof(
      parentCoinInfo: launcherCoin.id,
      innerPuzzlehash: uncurriedNft!.stateLayer.hash(),
      amount: 1,
    ).toProgram(),
    Program.fromInt(1),
    nftLayerSolution,
  ]);

  print(fullPuzzle.run(singletonSolution).program);

  final innerResult = uncurriedNft.getInnerResult(singletonSolution);

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

  // get new did from resulting conditions
  final didMagicConditions = BaseWalletService.extractConditionsFromResult(
    innerResult,
    NftDidMagicConditionCondition.isThisCondition,
    NftDidMagicConditionCondition.fromProgram,
  );

  if (didMagicConditions.length > 1) {
    throw Exception('more than one nft didMagicConditions condition');
  }

  // final innerPuzzleReveal = NftWalletService.constructOwnershipLayer(
  //       currentOwnerDid: null,
  //       transferProgram: uncurriedNft.ownershipLayerInfo!.transferProgram,
  //       innerPuzzle: ownershipInfo.ownershipLayerP2Puzzle,
  //     );
}
