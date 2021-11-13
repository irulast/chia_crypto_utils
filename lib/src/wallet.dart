import 'package:chia_utils/src/chia.dart';

SpendBundle createWalletSpendBundle(List<CoinRecord> records,
    List<int> privateKey, String destination, int amount, int fee) {
  throw UnimplementedError('Not implemented.');
}

String getArborWalletPuzzleReveal(String publicKey) {
  return 'ff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff0bff80808080ff80808080ff0b80ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0' +
      publicKey +
      'ff018080';
}
