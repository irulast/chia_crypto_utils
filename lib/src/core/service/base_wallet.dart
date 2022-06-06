// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/clvm/keywords.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/spend_bundle_validation/duplicate_coin_exception.dart';
import 'package:chia_crypto_utils/src/standard/exceptions/spend_bundle_validation/failed_signature_verification.dart';
import 'package:get_it/get_it.dart';

class BaseWalletService {
  BlockchainNetwork get blockchainNetwork => GetIt.I.get<BlockchainNetwork>();

  JacobianPoint makeSignature(
    PrivateKey privateKey,
    CoinSpend coinSpend,
  ) {
    final result = coinSpend.puzzleReveal.run(coinSpend.solution);

    final addsigmessage = getAddSigMeMessageFromResult(result.program, coinSpend.coin);

    final synthSecretKey = calculateSyntheticPrivateKey(privateKey);
    final signature = AugSchemeMPL.sign(synthSecretKey, addsigmessage);

    return signature;
  }

  Bytes getAddSigMeMessageFromResult(Program result, CoinPrototype coin) {
    final aggSigMeCondition = result.toList().singleWhere(AggSigMeCondition.isThisCondition);
    return Bytes(aggSigMeCondition.toList()[2].atom) +
        coin.id +
        Bytes.fromHex(
          blockchainNetwork.aggSigMeExtraData,
        );
  }

  static Program makeSolutionFromConditions(List<Condition> conditions) {
    return makeSolutionFromProgram(
      Program.list([
        Program.fromBigInt(keywords['q']!),
        ...conditions.map((condition) => condition.program).toList()
      ]),
    );
  }

  static List<T> extractConditionsFromSolution<T>(
    Program solution,
    ConditionChecker<T> conditionChecker,
    ConditionFromProgramConstructor<T> conditionFromProgramConstructor,
  ) {
    return extractConditionsFromResult(
      solution.toList()[1],
      conditionChecker,
      conditionFromProgramConstructor,
    );
  }

  static List<T> extractConditionsFromResult<T>(
    Program result,
    ConditionChecker<T> conditionChecker,
    ConditionFromProgramConstructor<T> conditionFromProgramConstructor,
  ) {
    return result
        .toList()
        .where(conditionChecker)
        .map((p) => conditionFromProgramConstructor(p))
        .toList();
  }

  static Program makeSolutionFromProgram(Program program) {
    return Program.list([
      Program.nil,
      program,
      Program.nil,
    ]);
  }

  void validateSpendBundleSignature(SpendBundle spendBundle) {
    final publicKeys = <JacobianPoint>[];
    final messages = <List<int>>[];
    for (final spend in spendBundle.coinSpends) {
      final outputConditions = spend.puzzleReveal.run(spend.solution).program.toList();

      // look for assert agg sig me condition
      final aggSigMeProgram = outputConditions.singleWhere(AggSigMeCondition.isThisCondition);

      final aggSigMeCondition = AggSigMeCondition.fromProgram(aggSigMeProgram);
      publicKeys.add(aggSigMeCondition.publicKey);
      messages.add(
        aggSigMeCondition.message +
            spend.coin.id +
            Bytes.fromHex(blockchainNetwork.aggSigMeExtraData),
      );
    }

    // validate signature
    if (!AugSchemeMPL.aggregateVerify(
      publicKeys,
      messages,
      spendBundle.aggregatedSignature!,
    )) {
      throw FailedSignatureVerificationException();
    }
  }

  static void checkForDuplicateCoins(List<CoinPrototype> coins) {
    final idSet = <String>{};
    for (final coin in coins) {
      final coinIdHex = coin.id.toHex();
      if (idSet.contains(coinIdHex)) {
        throw DuplicateCoinException(coinIdHex);
      } else {
        idSet.add(coinIdHex);
      }
    }
  }
}

class CoinSpendAndSignature {
  const CoinSpendAndSignature(this.coinSpend, this.signature);

  final CoinSpend coinSpend;
  final JacobianPoint signature;
}
