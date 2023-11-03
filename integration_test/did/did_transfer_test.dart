@Timeout(Duration(minutes: 5))
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  LoggingContext().setLogLevel(LogLevel.low);

  late ChiaEnthusiast nathan;
  late ChiaEnthusiast meera;
  late ChiaEnthusiast grant;

  final didWalletService = DIDWalletService();

  setUp(() async {
    nathan = ChiaEnthusiast(fullNodeSimulator, walletSize: 8);
    await nathan.farmCoins();
    await nathan.issueDid([Program.fromBool(true).hash()]);

    grant = ChiaEnthusiast(fullNodeSimulator, walletSize: 8);
    await grant.farmCoins();

    meera = ChiaEnthusiast(fullNodeSimulator, walletSize: 8);
    await meera.farmCoins();
  });

  Future<DidInfo> passAroundDid(DidInfo origionalDid) async {
    final nathanToGrantSpendBundle = didWalletService.createSpendBundle(
      newP2Puzzlehash: grant.firstPuzzlehash,
      didInfo: origionalDid,
      keychain: nathan.keychain,
    );

    await fullNodeSimulator.pushTransaction(nathanToGrantSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final grantDid =
        (await fullNodeSimulator.getDidRecordsFromHint(grant.firstPuzzlehash))
            .single
            .toDidInfoOrThrow(grant.keychain);

    final grantToMeeraSpendBundle = didWalletService.createSpendBundle(
      newP2Puzzlehash: meera.firstPuzzlehash,
      didInfo: grantDid,
      keychain: grant.keychain,
    );

    await fullNodeSimulator.pushTransaction(grantToMeeraSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final meeraDid =
        (await fullNodeSimulator.getDidRecordsFromHint(meera.firstPuzzlehash))
            .single
            .toDidInfoOrThrow(meera.keychain);

    final meeraToNathanSpendBundle = didWalletService.createSpendBundle(
      newP2Puzzlehash: nathan.firstPuzzlehash,
      didInfo: meeraDid,
      keychain: meera.keychain,
    );
    await fullNodeSimulator.pushTransaction(meeraToNathanSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final nathanDid =
        (await fullNodeSimulator.getDidRecordsFromHint(nathan.firstPuzzlehash))
            .single
            .toDidInfoOrThrow(nathan.keychain);

    expectDidEquality(nathanDid, origionalDid);

    return nathanDid;
  }

  Future<DidInfo> useDidInfoToBulkMint(DidInfo didInfo) async {
    final nathanDid = didInfo;
    final nftWalletService = NftWalletService();

    final targetPuzzleHash = nathan.puzzlehashes.first;
    await nathan.refreshCoins();

    final bulkMintSpendBundle =
        nftWalletService.createDidNftBulkMintSpendBundle(
      minterPuzzlehash: targetPuzzleHash,
      nftMintData: await NftMintingDataWithHashes.makeUniformBulkMintData(
        uriHashProvider: MockUriHashProvider(),
        dataUri: nftMetadata.dataUris.first,
        metadataUri: nftMetadata.metaUris!.first,
        editionTotal: 10,
        totalNftsToMint: 10,
      ),
      fee: 50,
      coins: nathan.standardCoins.sublist(0, 1),
      keychain: nathan.keychain,
      targetDidInfo: nathanDid,
      editionTotal: 10,
      changePuzzlehash: targetPuzzleHash,
      targetPuzzlehash: targetPuzzleHash,
    );

    await fullNodeSimulator.pushTransaction(bulkMintSpendBundle);

    await fullNodeSimulator.moveToNextBlock();
    final nftRecords =
        await fullNodeSimulator.getNftRecordsByHint(targetPuzzleHash);
    final mintedNftRecords = nftRecords.where(
      (element) => bulkMintSpendBundle.additions.contains(element.coin),
    );
    expect(mintedNftRecords.length, 10);
    final mirror = ChiaEnthusiast(fullNodeSimulator);

    for (final nftRecord in mintedNftRecords) {
      final sendBundle = nftWalletService.createSpendBundle(
        targetPuzzlehash: mirror.firstPuzzlehash,
        nftCoin: nftRecord.toNft(nathan.keychain),
        keychain: nathan.keychain,
      );
      await fullNodeSimulator.pushTransaction(sendBundle);
    }

    await fullNodeSimulator.moveToNextBlock();
    final sentNfts =
        await fullNodeSimulator.getNftRecordsByHint(mirror.firstPuzzlehash);
    expect(sentNfts.length, 10);

    final finalDid = await fullNodeSimulator.getDidRecordForDid(nathanDid.did);

    return finalDid!.toDidInfoOrThrow(nathan.keychain);
  }

  Future<DidInfo> useDidInfoToMint(DidInfo didInfo) async {
    var nathanDid = didInfo;
    final nftWalletService = NftWalletService();

    await nathan.refreshCoins();
    final createNftSpendBundle = nftWalletService.createGenerateNftSpendBundle(
      minterPuzzlehash: nathan.firstPuzzlehash,
      metadata: nftMetadata,
      fee: 0,
      coins: nathan.standardCoins.sublist(0, 1),
      keychain: nathan.keychain,
      changePuzzlehash: nathan.firstPuzzlehash,
      targetDidInfo: nathanDid,
      royaltyPercentagePoints: 200,
    );

    // return;
    await fullNodeSimulator.pushTransaction(createNftSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final nfts =
        await fullNodeSimulator.getNftRecordsByHint(nathan.firstPuzzlehash);

    await meera.issueDid();

    nathanDid = (await fullNodeSimulator.getDidRecordForDid(nathanDid.did))!
        .toDidInfoOrThrow(nathan.keychain);

    ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

    final spendNftBundle = nftWalletService.createSpendBundle(
      targetPuzzlehash: meera.firstPuzzlehash,
      nftCoin: nfts.single.toNft(nathan.keychain),
      keychain: nathan.keychain,
    );

    BaseWalletService().validateSpendBundleSignature(spendNftBundle);

    await fullNodeSimulator.pushTransaction(spendNftBundle);
    await fullNodeSimulator.moveToNextBlock();

    var meeraNft =
        (await fullNodeSimulator.getNftRecordsByHint(meera.firstPuzzlehash))
            .single;

    await fullNodeSimulator.pushTransaction(
      nftWalletService.createSpendBundle(
            targetPuzzlehash: meera.firstPuzzlehash,
            nftCoin: meeraNft.toNft(meera.keychain),
            keychain: meera.keychain,
            targetDidInfo: meera.didInfo,
          ) +
          nftWalletService.didWalletService.createSpendBundleFromPrivateKey(
            didInfo: meera.didInfo!,
            privateKey: meera.keychain
                .getWalletVectorOrThrow(meera.didInfo!.p2Puzzle.hash())
                .childPrivateKey,
            puzzlesToAnnounce: [meeraNft.launcherId],
          ),
    );

    await fullNodeSimulator.moveToNextBlock();
    meeraNft =
        (await fullNodeSimulator.getNftRecordsByHint(meera.firstPuzzlehash))
            .single;

    final mintInfo = await fullNodeSimulator
        .getNftMintInfoForLauncherId(meeraNft.launcherId);

    expect(mintInfo!.minterDid, nathanDid.did);
    expect(meeraNft.ownershipLayerInfo!.currentDid, meera.didInfo!.did);
    return nathanDid;
  }

  test('should pass around and use did to mint', () async {
    final origionalDid = nathan.didInfo!;
    var nathanDid = await passAroundDid(origionalDid);
    nathanDid = await useDidInfoToMint(nathanDid);
    nathanDid = await useDidInfoToBulkMint(nathanDid);
    expectDidEquality(nathanDid, origionalDid);
  });
}

final nftMetadata = NftMetadata(
  dataUris: const [
    'https://www.chia.net/img/branding/chia-logo.svg',
    'https://www.chia.net/img/a/chia-logo.svg',
    'https://www.chia.net/img/c/chia-logo.svg',
  ],
  dataHash: Program.fromInt(0).hash(),
  metaUris: const [
    'https://www.chia.net/music/branding/chia-logo.svg',
    'https://www.netflix.com',
    'https://www.sss.com',
  ],
);

void expectDidEquality(DidInfo actual, DidInfo expected) {
  expect(actual.backUpIdsHash, expected.backUpIdsHash);
  expect(actual.did, expected.did);
  expect(actual.metadata.toProgram(), expected.metadata.toProgram());
  expect(actual.singletonStructure, expected.singletonStructure);
  expect(actual.nVerificationsRequired, expected.nVerificationsRequired);
}
