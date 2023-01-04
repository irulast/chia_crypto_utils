import 'package:chia_crypto_utils/chia_crypto_utils.dart';

final plotNftWalletService = PlotNftWalletService();

class PlotNFTDetails {
  const PlotNFTDetails({
    required this.contractAddress,
    required this.payoutAddress,
    required this.launcherId,
  });

  final Address contractAddress;
  final Address payoutAddress;
  final Bytes launcherId;
}

Future<PlotNFTDetails> createNewWalletWithPlotNFT(
  KeychainCoreSecret keychainSecret,
  WalletKeychain keychain,
  PoolService? poolService,
  Puzzlehash? selfPoolingPuzzlehash,
  ChiaFullNodeInterface fullNode,
) async {
  final coins = await fullNode.getCoinsByPuzzleHashes(
    keychain.puzzlehashes,
  );

  final delayPh = keychain.puzzlehashes[4];
  final singletonWalletVector =
      keychain.getNextSingletonWalletVector(keychainSecret.masterPrivateKey);

  final changePuzzlehash = keychain.puzzlehashes[3];

  Bytes? launcherId;
  if (poolService != null) {
    launcherId = await poolService.createPlotNftForPool(
      p2SingletonDelayedPuzzlehash: delayPh,
      singletonWalletVector: singletonWalletVector,
      coins: coins,
      keychain: keychain,
      fee: 50,
      changePuzzlehash: changePuzzlehash,
    );
  } else {
    final initialTargetState = PoolState(
      poolSingletonState: PoolSingletonState.selfPooling,
      targetPuzzlehash: selfPoolingPuzzlehash!,
      ownerPublicKey: singletonWalletVector.singletonOwnerPublicKey,
      relativeLockHeight: 0,
    );

    final genesisCoin = coins[0];

    final plotNftSpendBundle = plotNftWalletService.createPoolNftSpendBundle(
      initialTargetState: initialTargetState,
      keychain: keychain,
      fee: 50,
      coins: coins,
      genesisCoinId: genesisCoin.id,
      p2SingletonDelayedPuzzlehash: delayPh,
      changePuzzlehash: changePuzzlehash,
    );

    await fullNode.pushTransaction(plotNftSpendBundle);

    launcherId = PlotNftWalletService.makeLauncherCoin(genesisCoin.id).id;
  }

  var launcherCoin = await fullNode.getCoinById(launcherId);

  while (launcherCoin == null) {
    print('waiting for plot nft to be created...');
    await Future<void>.delayed(const Duration(seconds: 15));
    launcherCoin = await fullNode.getCoinById(launcherId);
  }

  final newPlotNft = await fullNode.getPlotNftByLauncherId(launcherId);
  print(newPlotNft);

  final contractPuzzlehash = PlotNftWalletService.launcherIdToP2Puzzlehash(
    launcherId,
    PlotNftWalletService.defaultDelayTime,
    delayPh,
  );

  final payoutPuzzlehash = keychain.puzzlehashes[1];

  final payoutAddress = Address.fromPuzzlehash(
    payoutPuzzlehash,
    ChiaNetworkContextWrapper().blockchainNetwork.addressPrefix,
  );

  final contractAddress = Address.fromPuzzlehash(
    contractPuzzlehash,
    ChiaNetworkContextWrapper().blockchainNetwork.addressPrefix,
  );

  print('Contract Address: ${contractAddress.address}');
  print('Payout Address: ${payoutAddress.address}');

  if (poolService != null) {
    final addFarmerResponse = await poolService.registerAsFarmerWithPool(
      plotNft: newPlotNft!,
      singletonWalletVector: singletonWalletVector,
      payoutPuzzlehash: keychain.puzzlehashes[1],
    );
    print('Pool welcome message: ${addFarmerResponse.welcomeMessage}');

    GetFarmerResponse? farmerInfo;
    var attempts = 0;
    while (farmerInfo == null && attempts < 6) {
      print('waiting for farmer information to become available...');
      try {
        attempts = attempts + 1;
        await Future<void>.delayed(const Duration(seconds: 15));
        farmerInfo = await poolService.getFarmerInfo(
          authenticationPrivateKey: singletonWalletVector.poolingAuthenticationPrivateKey,
          launcherId: launcherId,
        );
      } on PoolResponseException catch (e) {
        if (e.poolErrorResponse.responseCode != PoolErrorState.farmerNotKnown) {
          rethrow;
        }
        if (attempts == 5) {
          print(e.poolErrorResponse.message);
        }
      }
    }

    if (farmerInfo != null) {
      print(farmerInfo);
    }
  }

  return PlotNFTDetails(
    contractAddress: contractAddress,
    payoutAddress: payoutAddress,
    launcherId: launcherId,
  );
}
