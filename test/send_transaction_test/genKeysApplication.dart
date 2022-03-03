import 'package:bip39/bip39.dart';
import 'package:chia_utils/chia_crypto_utils.dart';

void main() async{
  var hardMnemonic = 'guilt rail green junior loud track cupboard citizen begin play west adapt myself panda eye finger nuclear someone update light dance exotic expect layer';
  var seed = mnemonicToSeed(hardMnemonic);
  var masterSk = PrivateKey.fromSeed(seed);
 
  
  final privateKey = masterSkToWalletSk(masterSk, 0);
  final publicKey = privateKey.getG1();

  final puzzle = getPuzzleFromPk(publicKey);
  // synthetic pub key: [160, 97, 17, 193, 104, 65, 127, 101, 41, 213, 151, 159, 219, 65, 179, 199, 204, 43, 36, 32, 165, 37, 226, 235, 142, 110, 224, 80, 95, 38, 127, 55, 142, 200, 205, 106, 233, 157, 232, 12, 86, 152, 200, 250, 101, 216, 38, 149]

  final synthSecretKey = calculateSyntheticPrivateKey(privateKey);
  final syntheticPublicKeyFromSecretKey = synthSecretKey.getG1().toBytes();
  print(syntheticPublicKeyFromSecretKey);
  // synehtetic pub key [175, 62, 253, 46, 191, 236, 125, 29, 198, 184, 51, 5, 61, 201, 81, 151, 54, 48, 149, 73, 203, 117, 89, 106, 1, 232, 209, 204, 54, 3, 71, 164, 225, 17, 235, 170, 35, 56, 127, 153, 141, 146, 77, 151, 193, 95, 65, 164]
}