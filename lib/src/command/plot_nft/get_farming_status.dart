import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/core/models/singleton_wallet_vector.dart';

Future<void> getFarmingStatus(
  String launcherIdHex,
  KeychainCoreSecret keychainSecret,
  WalletKeychain keychain,
  PoolService poolService,
  ChiaFullNodeInterface fullNode,
) async {
  final launcherId = Puzzlehash.fromHex(launcherIdHex);

  final singletonWalletVector =
      SingletonWalletVector.fromMasterPrivateKey(keychainSecret.masterPrivateKey, 20);

  final plotNft = await fullNode.getPlotNftByLauncherId(launcherId);
  print('${plotNft!}\n');

  final farmerInfo = await poolService.getFarmerInfo(
    authenticationPrivateKey: singletonWalletVector.poolingAuthenticationPrivateKey,
    launcherId: launcherId,
  );
  print(farmerInfo);
}
