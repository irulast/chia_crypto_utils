import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class StandardWalletInfo with WalletInfoDecorator implements ChiaWalletInfo {
  StandardWalletInfo()
      : delegate = ChiaWalletInfoImp(
          id: 1,
          name: 'Chia Wallet',
          type: ChiaWalletType.standard,
          meta: {},
        );

  @override
  final ChiaWalletInfo delegate;
}
