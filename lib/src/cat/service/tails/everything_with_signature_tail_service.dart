import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/cat/models/tail_info.dart';

class EverythingWithSignatureTailService {
  EverythingWithSignatureTailService([this._catWalletService]);

  final CatWalletService? _catWalletService;
  CatWalletService get catWalletService => _catWalletService ?? Cat2WalletService();

  StandardWalletService get standardWalletService => catWalletService.standardWalletService;

  static Program constructTail(PrivateKey privateKey) {
    final curriedTail = everythingWithSignatureProgram.curry(
      [privateKey.getG1().toBytes()],
    );

    return curriedTail;
  }

  static Program constructTailFromWalletKey(PrivateKey walletKey) {
    final syntheticPrivateKey = calculateSyntheticPrivateKey(walletKey);

    final curriedTail = everythingWithSignatureProgram.curry(
      [syntheticPrivateKey.getG1().toBytes()],
    );

    return curriedTail;
  }

  static Program makeSolution() => Program.nil;

  IssuanceResult makeIssuanceSpendBundle({
    required PrivateKey tailPrivateKey,
    required List<CoinPrototype> standardCoins,
    required Puzzlehash destinationPuzzlehash,
    required Puzzlehash changePuzzlehash,
    required int amount,
    required WalletKeychain keychain,
    Bytes? originId,
    int fee = 0,
  }) {
    // use synthetic key to avoid exposing public key
    final syntheticPrivateKey = calculateSyntheticPrivateKey(tailPrivateKey);
    final curriedTail = constructTail(syntheticPrivateKey);

    final solution = makeSolution();
    late final JacobianPoint signature;
    final spendBundle = catWalletService.makeIssuanceSpendbundle(
      tail: curriedTail,
      solution: solution,
      standardCoins: standardCoins,
      destinationPuzzlehash: destinationPuzzlehash,
      changePuzzlehash: changePuzzlehash,
      amount: amount,
      makeSignature: (eveCoin) {
        final sig = AugSchemeMPL.sign(
          syntheticPrivateKey,
          eveCoin.id +
              Bytes.fromHex(
                standardWalletService.blockchainNetwork.aggSigMeExtraData,
              ),
        );
        signature = sig;
        return sig;
      },
      keychain: keychain,
      fee: fee,
      originId: originId,
    );

    return IssuanceResult(
      spendBundle: spendBundle,
      tailRunningInfo: TailRunningInfo(
        tail: curriedTail,
        signature: signature,
        tailSolution: solution,
      ),
    );
  }

  SpendBundle makeMeltSpendBundle({
    required CatCoin catCoinToMelt,
    required Puzzlehash puzzlehashToClaimXchTo,
    required List<CoinPrototype> standardCoinsForXchClaimingSpendBundle,
    int? amountToMelt,
    required PrivateKey tailPrivateKey,
    required Puzzlehash changePuzzlehash,
    required WalletKeychain keychain,
    Bytes? originId,
    Bytes? standardOriginId,
    int fee = 0,
  }) {
    // use synthetic key to avoid exposing public key
    final syntheticPrivateKey = calculateSyntheticPrivateKey(tailPrivateKey);
    final curriedTail = constructTail(syntheticPrivateKey);

    final desiredAmountToMelt = amountToMelt ?? catCoinToMelt.amount;
    final solution = makeSolution();

    final message = encodeInt(-desiredAmountToMelt) +
        catCoinToMelt.id +
        Bytes.fromHex(
          standardWalletService.blockchainNetwork.aggSigMeExtraData,
        );

    final signature = AugSchemeMPL.sign(syntheticPrivateKey, message);

    return catWalletService.makeMeltingSpendBundle(
      inputAmountToMelt: desiredAmountToMelt,
      catCoinToMelt: catCoinToMelt,
      puzzlehashToClaimXchTo: puzzlehashToClaimXchTo,
      standardCoinsForXchClaimingSpendBundle: standardCoinsForXchClaimingSpendBundle,
      tailRunningInfo: TailRunningInfo(
        tail: curriedTail,
        signature: signature,
        tailSolution: solution,
      ),
      keychain: keychain,
      fee: fee,
      changePuzzlehash: changePuzzlehash,
      standardOriginId: standardOriginId,
    );
  }
}
