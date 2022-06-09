import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/api/pool/models/pool_error_response_code.dart';
import 'package:chia_crypto_utils/src/core/models/singleton_wallet_vector.dart';

Future<void> createNewWalletWithPlotNFT(
  KeychainCoreSecret keychainSecret,
  WalletKeychain keychain,
  PoolService poolService,
  ChiaFullNodeInterface fullNode,
) async {
  final coins = await fullNode.getCoinsByPuzzleHashes(keychain.puzzlehashes,);

  final delayPh = keychain.puzzlehashes[4];
  final singletonWalletVector = SingletonWalletVector.fromMasterPrivateKey(
      keychainSecret.masterPrivateKey, 20,);

  final launcherId = await poolService.createPlotNftForPool(
    p2SingletonDelayedPuzzlehash: delayPh,
    singletonWalletVector: singletonWalletVector,
    coins: coins,
    keychain: keychain,
    changePuzzlehash: keychain.puzzlehashes[3],
  );

  var launcherCoin = await fullNode.getCoinById(launcherId);

  while (launcherCoin == null) {
    print('waiting for plot nft to be created...');
    await Future<void>.delayed(const Duration(seconds: 15));
    launcherCoin = await fullNode.getCoinById(launcherId);
  }

  final newPlotNft = await fullNode.getPlotNftByLauncherId(launcherId);
  print(newPlotNft);

  await poolService.registerAsFarmerWithPool(
    plotNft: newPlotNft!,
    singletonWalletVector: singletonWalletVector,
    payoutPuzzlehash: keychain.puzzlehashes[1],
  );

  GetFarmerResponse? farmerInfo;
  while (farmerInfo == null) {
    print('waiting for farmer information to become available...');
    try {
      await Future<void>.delayed(const Duration(seconds: 15));
      farmerInfo = await poolService.getFarmerInfo(
        authenticationPrivateKey:
            singletonWalletVector.poolingAuthenticationPrivateKey,
        launcherId: launcherId,
      );
    } on PoolResponseException catch (e) {
      if (e.poolErrorResponse.responseCode != PoolErrorState.farmerNotKnown) {
        rethrow;
      }
    }
  }

  print(farmerInfo);
}
