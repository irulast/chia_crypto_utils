import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/client.dart';
import 'package:chia_utils/src/models/coin.dart';


class FullNode {
  late Client client;

  FullNode(String url) {
    client = Client(url);
  }

  sendCoins(List<Coin> coins, int amount, String destinationAddress, String changeAddress, WalletKeychain keychain) {

  }
}