import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/utils/serialization.dart';

class PostFarmerPayload with ToBytesMixin {
  const PostFarmerPayload({
    required this.launcherId,
    required this.authenticationToken,
    required this.authenticationPublicKey,
    required this.payoutPuzzlehash,
    this.suggestedDifficulty,
  });
  final Bytes launcherId;
  final int authenticationToken;
  final JacobianPoint authenticationPublicKey;
  final Puzzlehash payoutPuzzlehash;
  final int? suggestedDifficulty;

  @override
  Bytes toBytes() {
    var bytes = <int>[];
    bytes += launcherId;
    bytes += intTo64Bits(authenticationToken);
    bytes += authenticationPublicKey.toBytes();
    bytes += serializeItem(payoutPuzzlehash.toHexWithPrefix());
    if (suggestedDifficulty != null) {
      bytes += [1, ...intTo64Bits(suggestedDifficulty!)];
    } else {
      bytes += [0];
    }
    return Bytes(bytes);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'launcher_id': launcherId.toHexWithPrefix(),
      'authentication_token': authenticationToken,
      'authentication_public_key': authenticationPublicKey.toHexWithPrefix(),
      'payout_instructions': payoutPuzzlehash.toHexWithPrefix(),
      'suggested_difficulty': suggestedDifficulty,
    };
  }
}
