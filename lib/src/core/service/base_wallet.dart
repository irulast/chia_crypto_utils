// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/clvm/keywords.dart';
import 'package:chia_utils/src/core/models/conditions/agg_sig_me_condition.dart';
import 'package:chia_utils/src/core/models/conditions/condition.dart';
import 'package:chia_utils/src/standard/exceptions/spend_bundle_validation/duplicate_coin_exception.dart';
import 'package:chia_utils/src/standard/exceptions/spend_bundle_validation/failed_signature_verification.dart';
class BaseWalletService {
  Context context;

  BaseWalletService(this.context);

  BlockchainNetwork get blockchainNetwork {
    return context.get<BlockchainNetwork>();
  }
   // TODO
  JacobianPoint makeSignature(Program solution, Program puzzle, PrivateKey privateKey, CoinPrototype coin) {
    final result = puzzle.run(solution);

    final addsigmessage = getAddSigMeMessageFromResult(result.program, coin);

    final synthSecretKey = calculateSyntheticPrivateKey(privateKey);
    final signature = AugSchemeMPL.sign(synthSecretKey, addsigmessage.toUint8List());

    return signature;
  }

  Bytes getAddSigMeMessageFromResult(Program result, CoinPrototype coin) {
    final aggSigMeCondition = result.toList().singleWhere(AggSigMeCondition.isThisCondition);
    return Bytes(aggSigMeCondition.toList()[2].atom) +
      coin.id +
      Bytes.fromHex(blockchainNetwork.aggSigMeExtraData,
    );
  }

  static Program makeSolutionFromConditions(List<Condition> conditions) {
    return Program.list([
      Program.nil,
      Program.list([
        Program.fromBigInt(keywords['q']!),
        ...conditions.map((condition) => condition.program).toList()
      ]),
      Program.nil
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
      messages.add((aggSigMeCondition.message + spend.coin.id + Bytes.fromHex(blockchainNetwork.aggSigMeExtraData)).toUint8List());
    }

    // validate signature
    if(!AugSchemeMPL.aggregateVerify(publicKeys, messages, spendBundle.aggregatedSignature!)) {
      throw FailedSignatureVerificationException();
    }
  }


  static void checkForDuplicateCoins(List<CoinPrototype> coins) {
    final idSet = <String>{};
    for(final coin in coins) {
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
  CoinSpend coinSpend;
  JacobianPoint signature;

  CoinSpendAndSignature(this.coinSpend, this.signature);
}
