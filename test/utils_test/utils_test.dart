import 'dart:convert';
import 'dart:io';

import 'package:chia_utils/src/core/models/address.dart';
import 'package:chia_utils/src/core/models/master_key_pair.dart';
import 'package:chia_utils/src/core/models/wallet_set.dart';
import 'package:chia_utils/src/utils/index.dart';
import 'package:hex/hex.dart';
import 'package:test/test.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as path;

import 'resources/index.dart';

const testMnemonic = [
  'elder', 'quality', 'this', 'chalk', 'crane', 'endless',
  'machine', 'hotel', 'unfair', 'castle', 'expand', 'refuse',
  'lizard', 'vacuum', 'embody', 'track', 'crash', 'truth',
  'arrow', 'tree', 'poet', 'audit', 'grid', 'mesh',
];

// master public key generated by chia wallet from above mnemonic
const chiaFingerprint = 3109357790;
const chiaMasterPublicKeyHex = '901acd53bf61a63120f15442baf0f2a656267b08ba42c511b9bb543e31c32a9b49a0e0aa5e897bc81878d703fcd889f3';
const chiaFarmerPublicKeyHex = '8351d5afd1ab40bf37565d25600c9b147dcda344e19d413b2c468316d1efd312f61a1eca02a74f8d5f0d6e79911c23ca';
const chiaPoolPublicKeyHex = '926c9b71f4cfc3f8a595fc77d7edc509e2f426704489eaba6f86728bc391c628c402e00190ba3617931649d8c53b5520';
const chiaFirstAddress = 'txch1v8vergyvwugwv0tmxwnmeecuxh3tat5jaskkunnn79zjz0muds0qlg2szv';

void main() async {
  // get chia wallet sets generated from testMnemonic
  String filePath = path.join(path.current, 'test/utils_test/resources/chia_wallet_sets.csv');
  filePath = path.normalize(filePath);
  final input = File(filePath).openRead();
  final chiaWalletSetRows = await input.transform(utf8.decoder).transform(CsvToListConverter(eol: '\n')).toList();

  test('should generate correct puzzle hashes from mnemonic', () {
    const hexEncoder = HexEncoder();
    final masterKeyPair = MasterKeyPair.fromMnemonic(testMnemonic);
    final masterPrivateKey = masterKeyPair.masterPrivateKey;

    final fingerprint = masterKeyPair.masterPublicKey.getFingerprint();
    final masterPublicKeyHex = masterKeyPair.masterPublicKey.toHex();
    final farmerPublicKeyHex = masterSkToFarmerSk(masterPrivateKey).getG1().toHex();
    final poolPublicKeyHex = masterSkToPoolSk(masterPrivateKey).getG1().toHex();

    expect(fingerprint, chiaFingerprint);
    expect(masterPublicKeyHex, chiaMasterPublicKeyHex);
    expect(farmerPublicKeyHex, chiaFarmerPublicKeyHex);
    expect(poolPublicKeyHex, chiaPoolPublicKeyHex);

    String? firstAddress;
    for(var i = 0; i < 20; i++) {
      final chiaSet = ChiaWalletSet.fromRow(chiaWalletSetRows[i]);
      final set = WalletSet.fromPrivateKey(masterKeyPair.masterPrivateKey, i);

      if(i == 0) {
        firstAddress = Address.fromPuzzlehash(set.hardened.puzzlehash, 'txch').address;
      }

      expect(chiaSet.hardened.puzzlehashHex, set.hardened.puzzlehash.hex);
      expect(chiaSet.hardened.childPublicKeyHex, hexEncoder.convert(set.hardened.childPublicKey.toBytes()));
      expect(chiaSet.unhardened.puzzlehashHex, set.unhardened.puzzlehash.hex);
      expect(chiaSet.unhardened.childPublicKeyHex, hexEncoder.convert(set.unhardened.childPublicKey.toBytes()));
      expect(firstAddress, chiaFirstAddress);
    }

    print('Fingerprint: $fingerprint');
    print('Master public key (m): $masterPublicKeyHex');
    print('Farmer public key (m/$blsSpecNumber/$chiaBlockchanNumber/$farmerPathNumber/0): $farmerPublicKeyHex');
    print('Pool public key (m/$blsSpecNumber/$chiaBlockchanNumber/$poolPathNumber/0: $poolPublicKeyHex');
    print('First wallet address: $firstAddress');
  });
}
