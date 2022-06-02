// class AuthenticationPayload(Streamable):
//     method_name: str
//     launcher_id: bytes32
//     target_puzzle_hash: bytes32
//     authentication_token: uint64

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/utils/serialization.dart';

class AuthenticationPayload {
  const AuthenticationPayload({
    required this.methodName,
    required this.launcherId,
    required this.targetPuzzlehash,
    required this.authenticationToken,
  });
  
  final String methodName;
  final Bytes launcherId;
  final Puzzlehash targetPuzzlehash;
  final int authenticationToken;

  Bytes toBytes() {
    return serializeItem(methodName) +
        launcherId +
        targetPuzzlehash +
        intTo64Bytes(authenticationToken);
  }
}
