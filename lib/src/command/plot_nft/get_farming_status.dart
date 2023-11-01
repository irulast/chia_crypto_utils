import 'package:chia_crypto_utils/chia_crypto_utils.dart';

Future<GetFarmerResponse> getFarmingStatus(
  PlotNft plotNft,
  KeychainCoreSecret keychainSecret,
  WalletKeychain keychain,
  PoolService poolService,
  ChiaFullNodeInterface fullNode,
) async {
  final singletonWalletVector =
      await keychain.addSingletonWalletVectorForSingletonOwnerPublicKeyAsync(
    plotNft.poolState.ownerPublicKey,
    keychainSecret.masterPrivateKey,
  );
  final farmerInfo = await poolService.getFarmerInfo(
    authenticationPrivateKey: singletonWalletVector.poolingAuthenticationPrivateKey,
    launcherId: plotNft.launcherId,
  );

  return farmerInfo;
}
