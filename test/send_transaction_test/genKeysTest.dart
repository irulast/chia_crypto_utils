import 'package:chia_utils/chia_crypto_utils.dart';


void main() async{
  //transaction info
  const privateKeyBites = [46, 107, 246, 196, 224, 141, 227, 202, 73, 66, 31, 241, 210, 66, 123, 41, 45, 1, 93, 38, 182, 54, 13, 90, 40, 245, 52, 88, 116, 225, 178, 75];
  //                      [112, 75, 48, 216, 155, 153, 152, 41, 16, 25, 4, 64, 246, 89, 118, 197, 145, 67, 185, 73, 25, 62, 108, 48, 32, 73, 98, 157, 123, 76, 67, 170]
 

  final privateKey = PrivateKey.fromBytes(privateKeyBites);
  final publicKey = privateKey.getG1();

  final puzzle = getPuzzleFromPk(publicKey);
  // synth pub key: [151, 169, 173, 109, 184, 5, 219, 202, 75, 177, 251, 133, 37, 151, 15, 179, 45, 94, 209, 231, 195, 160, 243, 195, 164, 154, 77, 236, 83, 111, 71, 216, 212, 17, 28, 182, 255, 226, 104, 145, 12, 254, 159, 163, 141, 91, 165, 13]

  final synthSecretKey = calculateSyntheticPrivateKey(privateKey);
  final syntheticPublicKeyFromSecretKey = synthSecretKey.getG1().toBytes();
  print(syntheticPublicKeyFromSecretKey);
  // synth pub key: [151, 169, 173, 109, 184, 5, 219, 202, 75, 177, 251, 133, 37, 151, 15, 179, 45, 94, 209, 231, 195, 160, 243, 195, 164, 154, 77, 236, 83, 111, 71, 216, 212, 17, 28, 182, 255, 226, 104, 145, 12, 254, 159, 163, 141, 91, 165, 13]
}