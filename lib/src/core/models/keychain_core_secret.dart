import 'dart:math';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/utils/serialization.dart';
import 'package:meta/meta.dart';

@immutable
class KeychainCoreSecret with ToBytesMixin {
  const KeychainCoreSecret(this.mnemonic, this.masterPrivateKey);

  factory KeychainCoreSecret.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;
    final mnemonicAsString = stringfromStream(iterator);
    final masterPrivateKey = PrivateKey.fromStream(iterator);

    return KeychainCoreSecret(
      mnemonicAsString.split(mnemonicWordSeperator),
      masterPrivateKey,
    );
  }

  factory KeychainCoreSecret.fromMnemonicString(String mnemonic) {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final privateKey = PrivateKey.fromSeed(seed);

    return KeychainCoreSecret(
      mnemonic.split(mnemonicWordSeperator),
      privateKey,
    );
  }

  factory KeychainCoreSecret.fromMnemonic(List<String> mnemonic) {
    final seed = bip39.mnemonicToSeed(mnemonic.join(mnemonicWordSeperator));
    final privateKey = PrivateKey.fromSeed(seed);

    return KeychainCoreSecret(
      mnemonic,
      privateKey,
    );
  }

  factory KeychainCoreSecret.generate() {
    final mnemonic = generateMnemonic();
    final seed = bip39.mnemonicToSeed(mnemonic.join(mnemonicWordSeperator));
    final masterPrivateKey = PrivateKey.fromSeed(seed);

    return KeychainCoreSecret(mnemonic, masterPrivateKey);
  }

  static Future<KeychainCoreSecret> generateAsync() async {
    final mnemonic = await generateMnemonicAsync();
    final seed = await generateSeedFromMnemonicAsync(mnemonic);
    final masterPrivateKey = PrivateKey.fromSeed(seed);

    return KeychainCoreSecret(mnemonic, masterPrivateKey);
  }

  static Future<KeychainCoreSecret> fromMnemonicAsync(List<String> mnemonic) async {
    final seed = await generateSeedFromMnemonicAsync(mnemonic);
    final privateKey = PrivateKey.fromSeed(seed);

    return KeychainCoreSecret(
      mnemonic,
      privateKey,
    );
  }

  @override
  Bytes toBytes() {
    return serializeItem(mnemonic.join(mnemonicWordSeperator)) + masterPrivateKey.toBytes();
  }

  static const mnemonicWordSeperator = ' ';

  final List<String> mnemonic;
  String get mnemonicString => mnemonic.join(mnemonicWordSeperator);
  final PrivateKey masterPrivateKey;
  JacobianPoint get masterPublicKey => masterPrivateKey.getG1();

  PrivateKey get farmerPrivateKey => masterSkToFarmerSk(masterPrivateKey);
  JacobianPoint get farmerPublicKey => farmerPrivateKey.getG1();

  PrivateKey get poolPrivateKey => masterSkToPoolSk(masterPrivateKey);
  JacobianPoint get poolPublicKey => poolPrivateKey.getG1();

  int get fingerprint => masterPublicKey.getFingerprint();

  static List<String> generateMnemonic({int strength = 256}) {
    return bip39
        .generateMnemonic(strength: strength, randomBytes: _randomBytes)
        .split(mnemonicWordSeperator);
  }

  static Map<String, dynamic> _generateMnemonicTask(int strength) {
    final mnemonic = generateMnemonic(strength: strength);
    return <String, dynamic>{
      'mnemonic': mnemonic,
    };
  }

  static Future<List<String>> generateMnemonicAsync({int strength = 256}) {
    return spawnAndWaitForIsolate(
      taskArgument: strength,
      isolateTask: _generateMnemonicTask,
      handleTaskCompletion: (taskResultJson) =>
          List<String>.from(taskResultJson['mnemonic'] as Iterable),
    );
  }

  static Map<String, dynamic> _generatesSeedFromMnemonicTask(List<String> mnemonic) {
    final seed = bip39.mnemonicToSeed(mnemonic.join(mnemonicWordSeperator));
    return <String, dynamic>{
      'seed': Bytes(seed).toHex(),
    };
  }

  static Future<Bytes> generateSeedFromMnemonicAsync(List<String> mnemonic) async {
    return spawnAndWaitForIsolate(
      taskArgument: mnemonic,
      isolateTask: _generatesSeedFromMnemonicTask,
      handleTaskCompletion: (taskResultJson) => Bytes.fromHex(taskResultJson['seed'] as String),
    );
  }

  static Uint8List _randomBytes(int size) {
    final rng = Random.secure();
    final bytes = Uint8List(size);
    for (var i = 0; i < size; i++) {
      bytes[i] = rng.nextInt(_maxRandomByte);
    }
    return bytes;
  }

  static const _maxRandomByte = 256;
}
