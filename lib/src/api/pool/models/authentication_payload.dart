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

enum AuthenticationEndpoint {
  getFarmer('get_farmer'),
  getLogin('get_login');

  final String name;
  const AuthenticationEndpoint(this.name);
}
