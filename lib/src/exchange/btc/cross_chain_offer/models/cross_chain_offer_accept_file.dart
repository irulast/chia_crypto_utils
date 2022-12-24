import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/cross_chain_offer/models/cross_chain_offer_file.dart';

abstract class CrossChainOfferAcceptFile implements CrossChainOfferFile {
  Bytes get acceptedOfferHash;
}
