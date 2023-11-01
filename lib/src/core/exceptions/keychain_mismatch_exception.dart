import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class KeychainMismatchException implements Exception {
  KeychainMismatchException([this.requestedPuzzleHash]);

  final Puzzlehash? requestedPuzzleHash;

  @override
  String toString() {
    return 'Requested puzzle hash does not belong to keychain keychain${requestedPuzzleHash != null ? ': $requestedPuzzleHash' : ''}';
  }
}
