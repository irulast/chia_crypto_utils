import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class Cat2WalletService extends CatWalletService {
  Cat2WalletService() : super(cat2Program, SpendType.cat, null);
}
