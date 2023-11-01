import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class CatOfferWalletService extends OfferWalletService {
  CatOfferWalletService()
      : super(
          Cat2WalletService(),
        );
}
