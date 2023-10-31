import 'package:chia_crypto_utils/chia_crypto_utils.dart';

void main() {
  final secret = KeychainCoreSecret.fromMnemonicString(
    'indoor inmate work assault teach drama once ship orient legend visa second noodle bus rebuild earth oyster prevent girl movie obscure appear social sad',
  );
  final keychain = WalletKeychain.fromCoreSecret(secret);

  final keyBundles = <KeyBundle>[];

  final signatures = <JacobianPoint>[];

  for (final entry in keychain.unhardenedWalletVectors.asMap().entries) {
    final index = entry.key;
    final walletVector = entry.value;
    final keyBundle = KeyBundle(
      Program.fromInt(index).hash(),
      walletVector.childPublicKey,
      walletVector.childPrivateKey,
    );

    final signature = keyBundle.sign();

    signatures.add(signature);
    keyBundles.add(keyBundle);
  }

  final aggregateSignature = AugSchemeMPL.aggregate(signatures);

  final messages = <List<int>>[];

  final pks = <JacobianPoint>[];

  for (final keyBundle in keyBundles) {
    messages.add(keyBundle.message);
    pks.add(keyBundle.publicKey);
  }

  print(AugSchemeMPL.aggregateVerify(pks, messages, aggregateSignature));

  print(
    AugSchemeMPL.aggregateVerify(
      [keyBundles.first.publicKey],
      messages,
      aggregateSignature,
    ),
  );
}

class KeyBundle {
  KeyBundle(this.message, this.publicKey, this.privateKey);
  final List<int> message;
  final JacobianPoint publicKey;
  final PrivateKey privateKey;

  JacobianPoint sign() {
    return AugSchemeMPL.sign(privateKey, message);
  }

  bool verify(JacobianPoint signature) {
    return AugSchemeMPL.verify(publicKey, message, signature);
  }
}
