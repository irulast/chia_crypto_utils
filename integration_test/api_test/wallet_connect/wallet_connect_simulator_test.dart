@Timeout(Duration(minutes: 5))
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';
import 'package:walletconnect_flutter_v2/apis/core/core.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/session_models.dart';
import 'package:walletconnect_flutter_v2/apis/web3app/web3app.dart';
import 'package:walletconnect_flutter_v2/apis/web3wallet/web3wallet.dart';

// If one of these tests is taking a while or times out, try running it again.
Future<void> main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  const message = 'hello, world';
  const catAmount = 1000;
  const standardAmount = 10000000;
  const fee = 50;

  late ChiaEnthusiast meera;
  late ChiaEnthusiast nathan;
  late int fingerprint;
  late WalletConnectWalletClient walletClient;
  late WalletConnectAppClient appClient;
  late SessionData sessionData;
  late FullNodeWalletConnectRequestHandler requestHandler;
  late TestSessionProposalHandler sessionProposalHandler;
  late Map<int, ChiaWalletInfo> walletMap;
  setUp(() async {
    // set up wallet with standard coins, cat, and did
    meera = ChiaEnthusiast(fullNodeSimulator, walletSize: 5);

    await meera.farmCoins(5);

    await meera.issueMultiIssuanceCat();

    await meera.issueDid([Program.fromBool(true).hash()]);

    nathan = ChiaEnthusiast(fullNodeSimulator, walletSize: 5);
    await nathan.farmCoins();

    await meera.refreshCoins();
    await nathan.refreshCoins();

    // set up WalletConnect wallet client
    final walletCore = Core(projectId: testWalletProjectId);
    final web3Wallet = Web3Wallet(core: walletCore, metadata: defaultPairingMetadata);

    sessionProposalHandler = TestSessionProposalHandler();

    fingerprint = meera.keychainSecret.fingerprint;

    requestHandler = FullNodeWalletConnectRequestHandler(
      coreSecret: meera.keychainSecret,
      keychain: meera.keychain,
      fullNode: fullNodeSimulator,
    );

    walletClient = WalletConnectWalletClient(
      web3Wallet,
      fingerprint,
      sessionProposalHandler,
      requestHandler,
    );

    await walletClient.init();

    walletMap = walletClient.requestHandler.walletMap!;

    // set up WalletConnect app client
    final appCore = Core(projectId: walletConnectProjectId);
    final web3App = Web3App(core: appCore, metadata: defaultPairingMetadata);

    appClient = WalletConnectAppClient(web3App, (Uri uri) async {
      await walletClient.pair(uri);
    });

    await appClient.init();

    // pair with wallet client
    sessionData = await appClient.pair(
      requiredCommandTypes: testSupportedCommandTypes,
    );
  });

  tearDown(() async {
    await walletClient.disconnectPairing(sessionData.pairingTopic);
  });

  test('Should request and receive current address data', () async {
    final response = await appClient.getCurrentAddress(fingerprint: fingerprint);

    expect(response.address, equals(meera.firstPuzzlehash.toAddressWithContext()));
    print(response.toJson());
  });

  test('Should make request and throw exception when request is rejected', () async {
    requestHandler.approveRequest = false;

    expect(
      () async => {await appClient.getCurrentAddress(fingerprint: fingerprint)},
      throwsA(isA<ErrorResponseException>()),
    );
  });

  test('Should request and receive next address data', () async {
    final initialLastIndex = meera.puzzlehashes.length - 1;

    final response = await appClient.getNextAddress(fingerprint: fingerprint);

    final expectedNewAddress = meera.puzzlehashes[initialLastIndex + 1].toAddressWithContext();

    expect(response.address.address, equals(expectedNewAddress.address));
  });

  test('Should request and receive sync status', () async {
    final response = await appClient.getSyncStatus(fingerprint: fingerprint);

    expect(response.syncStatusData.synced, isTrue);
    expect(response.syncStatusData.syncing, isFalse);
    expect(response.syncStatusData.genesisInitialized, isTrue);
  });

  test('Should request and receive wallet balance data', () async {
    final response = await appClient.getWalletBalance(fingerprint: fingerprint);

    expect(response.balance.confirmedWalletBalance, equals(meera.standardCoins.totalValue));
    expect(response.balance.fingerprint, equals(fingerprint));
    expect(response.balance.pendingChange, equals(0));
    expect(response.balance.pendingCoinRemovalCount, equals(0));
    expect(response.balance.pendingChange, equals(0));
    expect(response.balance.spendableBalance, equals(meera.standardCoins.totalValue));
    expect(response.balance.unconfirmedWalletBalance, equals(meera.standardCoins.totalValue));
    expect(response.balance.unspentCoinCount, equals(meera.standardCoins.length));
    expect(response.balance.walletId, equals(1));
    expect(response.balance.walletType, equals(ChiaWalletType.standard));
  });

  test('Should request and receive wallets data', () async {
    final response = await appClient.getWallets(fingerprint: fingerprint);

    expect(response.wallets.length, equals(3));

    final walletTypes = response.wallets.map((wallet) => wallet.type);

    final standardWallets = walletTypes.where((type) => type == ChiaWalletType.standard);
    final didWallets = walletTypes.where((type) => type == ChiaWalletType.did);
    final catWallets = walletTypes.where((type) => type == ChiaWalletType.cat);
    final nftWallets = walletTypes.where((type) => type == ChiaWalletType.nft);

    expect(standardWallets.length, equals(1));
    expect(didWallets.length, equals(1));
    expect(catWallets.length, equals(1));
    expect(nftWallets.length, equals(0));
  });

  test('Should make transaction request, wait for confirmation, and receive sent transaction data',
      () async {
    final meeraStartingBalance = meera.standardCoins.totalValue;
    final nathanStartingBalance = nathan.standardCoins.totalValue;

    fullNodeSimulator.run();

    final response = await appClient.sendTransaction(
      fingerprint: fingerprint,
      address: nathan.firstPuzzlehash.toAddressWithContext(),
      amount: standardAmount,
      fee: fee,
      waitForConfirmation: true,
    );

    fullNodeSimulator.stop();

    expect(response.sentTransactionData.success, isTrue);
    expect(response.sentTransactionData.transaction.amount, equals(standardAmount));
    expect(response.sentTransactionData.transaction.feeAmount, equals(fee));
    expect(response.sentTransactionData.transaction.toPuzzlehash, equals(nathan.firstPuzzlehash));
    expect(response.sentTransactionData.transaction.confirmed, isTrue);

    await fullNodeSimulator.moveToNextBlock();
    await meera.refreshCoins();
    await nathan.refreshCoins();

    final meeraEndingBalance = meera.standardCoins.totalValue;
    final nathanEndingBalance = nathan.standardCoins.totalValue;

    expect(meeraEndingBalance, equals(meeraStartingBalance - fee - standardAmount));
    expect(nathanEndingBalance, equals(nathanStartingBalance + standardAmount));
  });

  test(
      'Should make a transaction request and receive sent transaction data without waiting for confirmation',
      () async {
    final meeraStartingBalance = meera.standardCoins.totalValue;
    final nathanStartingBalance = nathan.standardCoins.totalValue;

    final response = await appClient.sendTransaction(
      fingerprint: fingerprint,
      address: nathan.firstPuzzlehash.toAddressWithContext(),
      amount: standardAmount,
      fee: fee,
    );

    expect(response.sentTransactionData.success, isTrue);
    expect(response.sentTransactionData.transaction.amount, equals(standardAmount));
    expect(response.sentTransactionData.transaction.feeAmount, equals(fee));
    expect(response.sentTransactionData.transaction.toPuzzlehash, equals(nathan.firstPuzzlehash));
    expect(response.sentTransactionData.transaction.confirmed, isFalse);

    await fullNodeSimulator.moveToNextBlock();
    await meera.refreshCoins();
    await nathan.refreshCoins();

    final meeraEndingBalance = meera.standardCoins.totalValue;
    final nathanEndingBalance = nathan.standardCoins.totalValue;

    expect(meeraEndingBalance, equals(meeraStartingBalance - fee - standardAmount));
    expect(nathanEndingBalance, equals(nathanStartingBalance + standardAmount));
  });

  test('Should make a CAT transaction request and receive sent transaction data', () async {
    final meeraStartingCatBalance = meera.catCoins.totalValue;
    final nathanStartingCatBalance = nathan.catCoins.totalValue;

    final meeraCoinAssetId = meera.catCoinMap.keys.first;

    final response = await appClient.sendTransaction(
      walletId: walletMap.catWallets().keys.first,
      fingerprint: fingerprint,
      address: nathan.firstPuzzlehash.toAddressWithContext(),
      amount: catAmount,
      fee: fee,
    );

    expect(response.sentTransactionData.success, isTrue);
    expect(response.sentTransactionData.transaction.amount, equals(catAmount));
    expect(response.sentTransactionData.transaction.feeAmount, equals(fee));
    expect(response.sentTransactionData.transaction.toPuzzlehash, equals(nathan.firstPuzzlehash));
    expect(response.sentTransactionData.transaction.confirmed, isFalse);

    await fullNodeSimulator.moveToNextBlock();
    nathan.addAssetIdToKeychain(meeraCoinAssetId);
    await meera.refreshCoins();
    await nathan.refreshCoins();

    final meeraEndingCatBalance = meera.catCoins.totalValue;
    final nathanEndingCatBalance = nathan.catCoins.totalValue;

    expect(meeraEndingCatBalance, equals(meeraStartingCatBalance - catAmount));
    expect(nathanEndingCatBalance, equals(nathanStartingCatBalance + catAmount));
  });

  test('Should make request to spend CAT and receive sent transaction data', () async {
    final meeraStartingCatBalance = meera.catCoins.totalValue;
    final nathanStartingCatBalance = nathan.catCoins.totalValue;

    final meeraCoinAssetId = meera.catCoinMap.keys.first;

    final response = await appClient.spendCat(
      fingerprint: fingerprint,
      address: nathan.firstPuzzlehash.toAddressWithContext(),
      amount: catAmount,
      fee: fee,
      walletId: walletMap.catWallets().keys.first,
    );

    expect(response.sentTransactionData.success, isTrue);
    expect(response.sentTransactionData.transaction.amount, equals(catAmount));
    expect(response.sentTransactionData.transaction.feeAmount, equals(fee));
    expect(response.sentTransactionData.transaction.toPuzzlehash, equals(nathan.firstPuzzlehash));
    expect(response.sentTransactionData.transaction.confirmed, isFalse);

    await fullNodeSimulator.moveToNextBlock();
    nathan.addAssetIdToKeychain(meeraCoinAssetId);
    await meera.refreshCoins();
    await nathan.refreshCoins();

    final meeraEndingCatBalance = meera.catCoins.totalValue;
    final nathanEndingCatBalance = nathan.catCoins.totalValue;

    expect(meeraEndingCatBalance, equals(meeraStartingCatBalance - catAmount));
    expect(nathanEndingCatBalance, equals(nathanStartingCatBalance + catAmount));
  });

  test('Should request to sign by address and receive signature data', () async {
    final walletVector = meera.keychain.getWalletVector(meera.puzzlehashes[2]);

    final response = await appClient.signMessageByAddress(
      fingerprint: fingerprint,
      address: walletVector!.puzzlehash.toAddressWithContext(),
      message: message,
    );

    final expectedMessage = constructChip002Message(message);

    final verification = AugSchemeMPL.verify(
      response.signData.publicKey,
      expectedMessage,
      response.signData.signature,
    );

    expect(verification, isTrue);
  });

  test('Should request to sign by id and receive signature data', () async {
    final didInfo = meera.didInfo!;

    final response = await appClient.signMessageById(
      fingerprint: fingerprint,
      id: didInfo.did,
      message: message,
    );

    final expectedMessage = constructChip002Message(message);

    final verification = AugSchemeMPL.verify(
      response.signData.publicKey,
      expectedMessage,
      response.signData.signature,
    );

    expect(verification, isTrue);
  });

  test('Should request and receive verify signature data when signature is valid', () async {
    final walletVector = meera.keychain.getWalletVector(meera.puzzlehashes[2]);

    final signature =
        AugSchemeMPL.sign(walletVector!.childPrivateKey, Bytes.encodeFromString(message));

    final response = await appClient.verifySignature(
      fingerprint: fingerprint,
      publicKey: walletVector.childPublicKey,
      message: message,
      signature: signature,
      signingMode: SigningMode.blsMessageAugUtf8,
    );

    expect(response.verifySignatureData.isValid, isTrue);
  });

  test('Should request and receive verify signature data when signature is invalid', () async {
    final walletVector = meera.keychain.getWalletVector(meera.puzzlehashes[2]);

    final signature =
        AugSchemeMPL.sign(walletVector!.childPrivateKey, Bytes.encodeFromString(message));

    final response = await appClient.verifySignature(
      fingerprint: fingerprint,
      publicKey: nathan.keychain.unhardenedWalletVectors.first.childPublicKey,
      message: message,
      signature: signature,
      signingMode: SigningMode.blsMessageAugUtf8,
    );

    expect(response.verifySignatureData.isValid, isFalse);
  });

  test('Should request log in and receive response', () async {
    final response = await appClient.logIn(fingerprint: fingerprint);

    expect(response.logInData.fingerprint, equals(fingerprint));
    expect(response.logInData.success, isTrue);
  });
}
