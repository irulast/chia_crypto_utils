import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class Cat1OfferWalletService extends OfferWalletService {
  Cat1OfferWalletService()
      : super(
          Cat1WalletService(),
        );

  static Future<ParsedOffer> parseOffer(
    Offer offer, {
    TailDatabaseApi? tailDatabaseApi,
  }) async {
    return OfferWalletService.parseOffer(
      offer,
      tailDatabaseApi: tailDatabaseApi,
    );
  }
}
