// ignore_for_file: constant_identifier_names

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/utils/serialization.dart';

class AuthenticationPayload {
  const AuthenticationPayload({
    required this.endpoint,
    required this.launcherId,
    required this.targetPuzzlehash,
    required this.authenticationToken,
  });

  final AuthenticationEndpoint endpoint;
  final Bytes launcherId;
  final Puzzlehash targetPuzzlehash;
  final int authenticationToken;

  Bytes toBytes() {
    return serializeItem(endpoint.name) +
        launcherId +
        targetPuzzlehash +
        intTo64Bits(authenticationToken);
  }
}

enum AuthenticationEndpoint { get_farmer, get_login }
