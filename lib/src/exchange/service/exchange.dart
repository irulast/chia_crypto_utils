import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/puzzles/p2_delayed_or_preimage/p2_delayed_or_preimage.clvm.hex.dart';
import 'package:chia_crypto_utils/src/exchange/exceptions/bad_signature_on_public_key.dart';

class BtcExchangeService {
  final BaseWalletService baseWalletService = BaseWalletService();

  SpendBundle createExchangeSpendBundle({
    required List<Payment> payments,
    required List<CoinPrototype> coinsInput,
    required WalletKeychain requestorKeychain,
    Puzzlehash? changePuzzlehash,
    required int clawbackDelaySeconds,
    required Puzzlehash sweepReceiptHash,
    required JacobianPoint fulfillerPublicKey,
    Bytes? sweepPreimage,
    int fee = 0,
    Bytes? originId,
    List<AssertCoinAnnouncementCondition> coinAnnouncementsToAssert = const [],
    List<AssertPuzzleAnnouncementCondition> puzzleAnnouncementsToAssert = const [],
  }) {
    final walletVector = requestorKeychain.unhardenedWalletVectors.first;
    final requestorPrivateKey = walletVector.childPrivateKey;
    final requestorPublicKey = requestorPrivateKey.getG1();

    final JacobianPoint clawbackPublicKey;
    final JacobianPoint sweepPublicKey;

    if (sweepPreimage == null) {
      clawbackPublicKey = requestorPublicKey;
      sweepPublicKey = fulfillerPublicKey;
    } else {
      clawbackPublicKey = fulfillerPublicKey;
      sweepPublicKey = requestorPublicKey;
    }

    return baseWalletService.createSpendBundleBase(
      payments: payments,
      coinsInput: coinsInput,
      changePuzzlehash: changePuzzlehash,
      fee: fee,
      originId: originId,
      coinAnnouncementsToAssert: coinAnnouncementsToAssert,
      puzzleAnnouncementsToAssert: puzzleAnnouncementsToAssert,
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
        return generateChiaswapPuzzle(
          clawbackDelaySeconds: clawbackDelaySeconds,
          clawbackPublicKey: clawbackPublicKey,
          sweepReceiptHash: sweepReceiptHash,
          sweepPublicKey: sweepPublicKey,
        );
      },
      makeSignatureForCoinSpend: (coinSpend) {
        return baseWalletService.makeSignature(
          requestorPrivateKey,
          coinSpend,
          useSyntheticOffset: false,
        );
      },
    );
  }

  String createSignedPublicKey(WalletKeychain keychain) {
    final walletVector = keychain.unhardenedWalletVectors.first;
    final privateKey = walletVector.childPrivateKey;
    print(privateKey);
    final publicKey = privateKey.getG1();

    final message = 'I own this key.'.toBytes();

    final signature = AugSchemeMPL.sign(privateKey, message);

    return '${publicKey.toHex()}_${signature.toHex()}';
  }

  JacobianPoint parseSignedPublicKey(String signedPublicKey) {
    final splitString = signedPublicKey.split('_');
    final publicKey = JacobianPoint.fromHexG1(splitString[0]);
    final signature = JacobianPoint.fromHexG2(splitString[1]);

    final message = 'I own this key.'.toBytes();

    final verification = AugSchemeMPL.verify(publicKey, message, signature);

    if (verification == true) {
      return publicKey;
    } else {
      throw BadSignatureOnPublicKeyException();
    }
  }

  Program generateChiaswapPuzzle({
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
