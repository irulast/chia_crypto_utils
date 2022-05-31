import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/utils/serialization.dart';

class PostFarmerPayload with ToBytesMixin{
  const PostFarmerPayload({
    required this.launcherId,
    required this.authenticationToken,
    required this.authenticationPublicKey,
    required this.payoutInstructions,
    this.suggestedDifficulty,
  });
  final Bytes launcherId;
  final int authenticationToken;
  final JacobianPoint authenticationPublicKey;
  final Address payoutInstructions;
  final int? suggestedDifficulty;

  @override
  Bytes toBytes() {
    var bytes = <int>[];
    bytes += launcherId;
    bytes += intTo64Bytes(authenticationToken);
    bytes += authenticationPublicKey.toBytes();
    bytes += serializeItem(payoutInstructions.address);
    if (suggestedDifficulty != null) {
      bytes += [1, ...intTo64Bytes(suggestedDifficulty!)];
    } else {
      bytes += [0];
    }
    return Bytes(bytes);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'launcher_id': launcherId.toHexWithPrefix(),
      'authentication_token': authenticationToken,
      'payout_instructions': payoutInstructions.address,
      'suggested_difficulty': suggestedDifficulty,
    };
  }
}
