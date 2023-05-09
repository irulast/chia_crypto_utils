import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class Cat1WalletService extends CatWalletService {
  Cat1WalletService() : super(cat1Program, SpendType.cat1, Bytes.fromHex('ca'));
}
