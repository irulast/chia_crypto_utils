import 'dart:typed_data';

class SpendBundle {}

class CoinRecord {}

String createMnemonic() {
  throw UnimplementedError('Not implemented.');
}

Uint8List getSeed(String mnemonic) {
  throw UnimplementedError('Not implemented.');
}

Uint8List getPrivateKey(Uint8List seed) {
  throw UnimplementedError('Not implemented.');
}

Uint8List getPublicKey(Uint8List privateKey) {
  throw UnimplementedError('Not implemented.');
}

Uint8List sign(Uint8List privateKey, Uint8List message) {
  throw UnimplementedError('Not implemented.');
}

String toAddress(String puzzleHash) {
  throw UnimplementedError('Not implemented.');
}

String toPuzzleHash(String address) {
  throw UnimplementedError('Not implemented.');
}
