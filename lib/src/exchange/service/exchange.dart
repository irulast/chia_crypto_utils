import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/puzzles/p2_delayed_or_preimage./p2_delayed_or_preimage.clvm.hex.dart';

class BtcExchangeService {
  final BaseWalletService baseWalletService = BaseWalletService();

  SpendBundle createExchangeSpendBundle({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    required int clawbackDelaySeconds,
    required PrivateKey privateKey,
    required JacobianPoint clawbackPublicKey,
    required Puzzlehash sweepReceiptHash,
    required JacobianPoint sweepPublicKey,
    Bytes? sweepPreimage,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    return baseWalletService.createSpendBundleBase(
      payments: payments,
      coinsInput: coinsInput,
      transformStandardSolution: (standardSolution) {
        final totalPublicKey = sweepPublicKey + clawbackPublicKey;

        return clawbackOrSweepSolution(
          totalPublicKey: totalPublicKey,
          clawbackDelaySeconds: clawbackDelaySeconds,
          clawbackPublicKey: clawbackPublicKey,
          sweepReceiptHash: sweepReceiptHash,
          sweepPublicKey: sweepPublicKey,
          delegatedSolution: standardSolution,
          sweepPreimage: sweepPreimage,
        );
      },
      makePuzzleRevealFromPuzzlehash: (puzzlehash) {
        return generateHoldingAddressPuzzle(
          clawbackDelaySeconds: clawbackDelaySeconds,
          clawbackPublicKey: clawbackPublicKey,
          sweepReceiptHash: sweepReceiptHash,
          sweepPublicKey: sweepPublicKey,
        );
      },
      makeSignatureForCoinSpend: (coinSpend) {
        return baseWalletService.makeSignature(privateKey, coinSpend, useSyntheticOffset: false);
      },
    );
  }

  Program generateHoldingAddressPuzzle({
    required int clawbackDelaySeconds,
    required JacobianPoint clawbackPublicKey,
    required Puzzlehash sweepReceiptHash,
    required JacobianPoint sweepPublicKey,
  }) {
    final hiddenPuzzleProgram = generateHiddenPuzzle(
      clawbackDelaySeconds: clawbackDelaySeconds,
      clawbackPublicKey: clawbackPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      sweepPublicKey: sweepPublicKey,
    );

    final totalPublicKey = sweepPublicKey + clawbackPublicKey;

    final puzzle = getPuzzleFromPkAndHiddenPuzzle(totalPublicKey, hiddenPuzzleProgram);

    return puzzle;
  }

  Program generateHiddenPuzzle({
    required int clawbackDelaySeconds,
    required JacobianPoint clawbackPublicKey,
    required Puzzlehash sweepReceiptHash,
    required JacobianPoint sweepPublicKey,
  }) {
    final hiddenPuzzleProgram = p2DelayedOrPreimageProgram.curry([
      Program.cons(
        Program.fromInt(clawbackDelaySeconds),
        Program.fromBytes(clawbackPublicKey.toBytes()),
      ),
      Program.cons(
        Program.fromBytes(sweepReceiptHash.toBytes()),
        Program.fromBytes(sweepPublicKey.toBytes()),
      )
    ]);

    return hiddenPuzzleProgram;
  }

  Program clawbackOrSweepSolution({
    required JacobianPoint totalPublicKey,
    required int clawbackDelaySeconds,
    required JacobianPoint clawbackPublicKey,
    required Puzzlehash sweepReceiptHash,
    required JacobianPoint sweepPublicKey,
    required Program delegatedSolution,
    Bytes? sweepPreimage,
  }) {
    Program? p2DelayedOrPreimageSolution;

    final hiddenPuzzleProgram = generateHiddenPuzzle(
      clawbackDelaySeconds: clawbackDelaySeconds,
      clawbackPublicKey: clawbackPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      sweepPublicKey: sweepPublicKey,
    );

    if (sweepPreimage != null) {
      p2DelayedOrPreimageSolution =
          Program.list([Program.fromBytes(sweepPreimage), delegatedSolution]);
    } else {
      p2DelayedOrPreimageSolution = Program.list([Program.fromInt(0), delegatedSolution]);
    }

    final solution = Program.list(
      [
        Program.fromBytes(totalPublicKey.toBytes()),
        hiddenPuzzleProgram,
        p2DelayedOrPreimageSolution
      ],
    );

    return solution;
  }
}
