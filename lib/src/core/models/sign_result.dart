import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class SpendBundleSignResult {
  SpendBundleSignResult(
    this.signedBundle, {
    required this.aggSigMeConditionWithMessages,
  });

  final SpendBundle signedBundle;

  final List<AggSigMeConditionWithFullMessage> aggSigMeConditionWithMessages;

  /// Returns true if the signature is complete and valid
  ///
  /// Expensive operation
  bool get signatureIsComplete {
    if (aggSigMeConditionWithMessages.isEmpty) {
      return true;
    }
    final signature = signedBundle.aggregatedSignature;
    if (signature == null) {
      return false;
    }
    final messages = <Bytes>[];
    final publicKeys = <JacobianPoint>[];
    for (final conditionWithMessage in aggSigMeConditionWithMessages) {
      messages.add(conditionWithMessage.fullMessage);
      publicKeys.add(conditionWithMessage.condition.publicKey);
    }

    return AugSchemeMPL.aggregateVerify(publicKeys, messages, signature);
  }
}
