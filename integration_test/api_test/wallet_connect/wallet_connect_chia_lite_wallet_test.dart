@Timeout(Duration(minutes: 5))
@Skip('These are interactive tests using Chia Lite Wallet')
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';
import 'package:walletconnect_flutter_v2/apis/core/core.dart';
import 'package:walletconnect_flutter_v2/apis/sign_api/models/session_models.dart';
import 'package:walletconnect_flutter_v2/apis/web3app/web3app.dart';

// To run these tests, you must have a Chia Lite Wallet running.
// Run tests one at a time.
// When the test pauses, click on the WalletConnect icon in your wallet, click "Enable WalletConnect",
// then 'Add Connection' and paste in the URI string the test has printed out.
// Select 'Confirm' when prompted to execute a command in the Chia Lite Wallet.

// If the Chia Lite Wallet says that it has connected to an Unkown Application instead of Chia Crypto Utils,
// make sure you are on the latest version of the Chia Lite Wallet and try restarting it.

// If you receive a JsonRpcError, try running the test again.

// After the test is completed, the Chia Lite Wallet WalletConnect dialog will show that it is connected
// to an Unknown Application because the app client has disconnected. You may simply close the dialog.

Future<void> main() async {
  final core = Core(projectId: walletConnectProjectId);
  final web3App = Web3App(core: core, metadata: defaultPairingMetadata);
  const message = 'hello, world';

  late final WalletConnectAppClient appClient;
  late final SessionData sessionData;
  late final int fingerprint;
  setUpAll(() async {
    appClient = WalletConnectAppClient(web3App, (Uri uri) {
      print('wallet connect link:');
      print(uri);
    });

    await appClient.init();

    sessionData = await appClient.pair();
    fingerprint = sessionData.fingerprints.first;
  });

  tearDownAll(() async {
    await appClient.disconnectPairing(sessionData.pairingTopic);
  });

  test('Should request wallets from Chia Lite Wallet', () async {
    final getWalletsResponse = await appClient.getWallets(
      fingerprint: fingerprint,
      includeData: true,
    );

    final wallets = getWalletsResponse.wallets;

    for (final wallet in wallets) {
      print(wallet.type.name);
      print(wallet.data);
    }
  });

  test('Should request wallet balance from Chia Lite Wallet', () async {
    final response = await appClient.getWalletBalance(
      fingerprint: fingerprint,
    );

    print(response.balance.toJson());
  });

  test('Should request current address from Chia Lite Wallet', () async {
    final response = await appClient.getCurrentAddress(
      fingerprint: fingerprint,
    );

    print(response.address.address);
  });

  test('Should request new address from Chia Lite Wallet', () async {
    final response = await appClient.getNextAddress(
      fingerprint: fingerprint,
    );

    print(response.address.address);
  });

  test('Should request NFT count from Chia Lite Wallet', () async {
    final getWalletsResponse = await appClient.getWallets(
      fingerprint: fingerprint,
    );

    final nftWalletIds = getWalletsResponse.wallets
        .where((wallet) => wallet.type == ChiaWalletType.nft)
        .map((wallet) => wallet.id)
        .toList();

    final response = await appClient.getNFTsCount(
      fingerprint: fingerprint,
      walletIds: nftWalletIds,
    );

    print(response.countData);
  });

  test('Should request NFT info from Chia Lite Wallet', () async {
    // Navigate to NFTs, click on NFT you want to test, copy the NFT Coin ID and set it manually below

    const coinId = '5011cdcdcfe38738f855f2ff9a08ef49c6e298761f97dd261173fb9b2a76bac3';

    final response = await appClient.getNFTInfo(
      fingerprint: fingerprint,
      coinId: Bytes.fromHex(coinId),
    );

    print(response.toJson());
  });

  test('Should request NFTs from Chia Lite Wallet', () async {
    final getWalletsResponse = await appClient.getWallets(
      fingerprint: fingerprint,
    );

    final nftWalletIds = getWalletsResponse.wallets
        .where((wallet) => wallet.type == ChiaWalletType.nft)
        .map((wallet) => wallet.id)
        .toList();

    final response = await appClient.getNFTs(
      fingerprint: fingerprint,
      walletIds: nftWalletIds,
    );

    print(response.toJson());
  });

  test('Should request Chia Lite Wallet to send a transaction and then get transaction data',
      () async {
    final response = await appClient.sendTransaction(
      fingerprint: fingerprint,
      address: const Address('xch17c3q8nrd88a06rs2kjdacj5w5p3mtnf0cqmpgxseh2xfzp5tgeesn7pwr9'),
      amount: 50,
      fee: 50,
    );

    print(response.sentTransactionData.toJson());

    final transactionResponse = await appClient.getTransaction(
      fingerprint: fingerprint,
      transactionId: response.sentTransactionData.transactionId,
    );

    print(transactionResponse.toJson());
  });

  test('Should request Chia Lite Wallet to spend CAT and then get transaction data', () async {
    final getWalletsResponse = await appClient.getWallets(
      fingerprint: fingerprint,
    );

    final catWallets =
        getWalletsResponse.wallets.where((wallet) => wallet.type == ChiaWalletType.cat);

    final response = await appClient.spendCat(
      fingerprint: fingerprint,
      address: const Address('xch17c3q8nrd88a06rs2kjdacj5w5p3mtnf0cqmpgxseh2xfzp5tgeesn7pwr9'),
      amount: 1,
      fee: 50,
      walletId: catWallets.first.id,
      memos: ['CAT test'],
    );

    print(response.sentTransactionData.toJson());

    final transactionResponse = await appClient.getTransaction(
      fingerprint: fingerprint,
      transactionId: response.sentTransactionData.transactionId,
    );

    print(transactionResponse.toJson());
  });

  test('Should log in to fingerprint in Chia Lite Wallet', () async {
    final response = await appClient.logIn(fingerprint: fingerprint);

    print(response.toJson());
  });

  test('Should request sync status from Chia Lite Wallet', () async {
    final response = await appClient.getSyncStatus(fingerprint: fingerprint);

    print(response.toJson());
  });

  test('Should request Chia Lite Wallet to take offer', () async {
    // Paste offer to accept below
    const offer = '';

    final response = await appClient.takeOffer(
      fingerprint: fingerprint,
      offer: offer,
      fee: 50,
    );

    print(response.toJson());
  });

  test('Should request Chia Lite Wallet to sign message by address and then verify signature',
      () async {
    final addressResponse = await appClient.getCurrentAddress(
      fingerprint: fingerprint,
    );

    final signMessageResponse = await appClient.signMessageByAddress(
      fingerprint: fingerprint,
      address: addressResponse.address,
      message: message,
    );

    print(signMessageResponse.toJson());

    final verifySignatureResponse = await appClient.verifySignature(
      fingerprint: fingerprint,
      publicKey: signMessageResponse.signData.publicKey,
      message: message,
      signature: signMessageResponse.signData.signature,
      address: addressResponse.address,
      signingMode: signMessageResponse.signData.signingMode,
    );

    print(verifySignatureResponse.toJson());
  });

  test('Should request Chia Lite Wallet to sign message by id and then verify signature', () async {
    // in order to run this test, you must have a did on your current wallet in the Chia Lite Wallet
    // navigate to Settings > Profiles, hover over DID and copy the DID ID (Hex)
    // manually set it to variable below

    const didHex = '2c3b970e57261a7c77ca395072890c698b0d6e5fdd3447aaa43eea948df95b8c';

    final signMessageResponse = await appClient.signMessageById(
      fingerprint: fingerprint,
      id: didHex.hexToBytes(),
      message: message,
    );

    print(signMessageResponse.toJson());

    final verifySignatureResponse = await appClient.verifySignature(
      fingerprint: fingerprint,
      publicKey: signMessageResponse.signData.publicKey,
      message: message,
      signature: signMessageResponse.signData.signature,
      signingMode: signMessageResponse.signData.signingMode,
    );

    print(verifySignatureResponse.toJson());
  });

  test('Should request offer validity data from Chia Lite Wallet', () async {
    const offerBech32 =
        'offer1qqr83wcuu2rykcmqvpsxygqqemhmlaekcenaz02ma6hs5w600dhjlvfjn477nkwz369h88kll73h37fefnwk3qqnz8s0lle0lzwfpjm87m4vx3e3y6chtrhmzv0r720xmq7mxsae767d3ynrrfflfyupftepvf2adffnhckpccftjak9e8zvs8vfh7nlz48nga0w0wdm2m60gmd3lakccr9j6gl33s8kxj08lllfaru7428mhlt4hkm9akajg50nhdhvu4rhjeu5406en5hz3mzadn8thl8ps7y3r7lmuee2t24kk0hwmkh0lk0yn49jl3gu8kkf5u6ecg93xles7t87gedklgadklgadkmgadkmfavxn60yvkm0734mmqgt7uz7d7e7y77xkmf5mcmrwvn2gthfzkxx75q7vu7hqmrw6r8vmfwj8264q42evwl46m3mp366skmk8mmv29fznatzpteynryf8uwpl44r7hqmmerfy7625s9wuzr0xg3ukrq3hdsf7ekalamevt42y2m9el8aknna0ecfndjx37t8m22sva4053llv7mhulmfkva9uwemw2jum0c4w7tlekcpr0qq2xwsqp5mrl2lgz50raalr828yg9vpej23n0lqkwnhcnhyhevc5nvtkg2uahurk04yjlvthje2q233ath7uvu7vajemsx2z2lmlc9z597lwkf7ewkjh4hye3vdg2ln8lxhr30j7v86amj7d3sntj4zdhd03jrjtel7p2w90ztul5c73ltxsyc3e5yl6j9ceamushtve7fwyl5m9gtrnwsnt6jmywwdlut7syf990gfa6amld7n6gzac7wnhj0txhm6wen494lrqurd4e5ae26xe0svkjx4zvl2lcp5xrpd4pjv2xq57h50n3nh3thev7pndetda77hhw679z2222mdnpsfpaq927kn4h28fg2xs8p6rfu75m24ks05sjc54gnr30la2ztdan0dw7veevz3g4xvjlsfqn456zahl4d9gr8auw9vgl6ltm7jwn7cxhnlnkk8maagunk5tfc8z80py7sz06vf7t0xlz7kac2wg009g9lkn069w4c7mdtfan0s2sjkwux275r9cqdadsd4yl2ydqs';
    final response = await appClient.checkOfferValidity(
      fingerprint: fingerprint,
      offer: offerBech32,
    );

    print(response.toJson());
  });

  test('Should request NFT transfer from Chia Lite Wallet', () async {
    // manually set nftCoinId of the NFT you want to transfer and the targetAddress you want to transfer to

    const nftCoinId = '';
    const targetAddress = '';

    final getWalletsResponse = await appClient.getWallets(
      fingerprint: fingerprint,
      includeData: true,
    );

    final nftWallets =
        getWalletsResponse.wallets.where((wallet) => wallet.type == ChiaWalletType.nft).toList();

    // the wallet ID needs to be an NFT wallet, but it doesn't need to be the NFT wallet associated
    // with the NFT being transferred
    final response = await appClient.transferNFT(
      fingerprint: fingerprint,
      walletId: nftWallets.first.id,
      targetAddress: const Address(targetAddress),
      nftCoinIds: [Bytes.fromHex(nftCoinId)],
      fee: 50,
    );

    print(response.toJson());
  });

  test('Should request Chia Lite Wallet to create offer for wallet ids', () async {
    final getWalletsResponse = await appClient.getWallets(
      fingerprint: fingerprint,
      includeData: true,
    );

    final catWalletId =
        getWalletsResponse.wallets.firstWhere((wallet) => wallet.type == ChiaWalletType.cat).id;

    final response = await appClient.createOfferForIds(
      fingerprint: fingerprint,
      offer: {'1': 100000000, catWalletId.toString(): -1},
    );

    print(response.toJson());
  });

  test('Should request new session using same pairing', () async {
    final getWalletsResponse = await appClient.getWallets(
      fingerprint: fingerprint,
    );

    print(getWalletsResponse.wallets.map((wallet) => wallet.toJson()));

    await appClient.requestNewSession(pairingTopic: sessionData.pairingTopic);

    final balanceResponse = await appClient.getWalletBalance(
      fingerprint: fingerprint,
    );

    print(balanceResponse.balance.toJson());
  });

  test(
      'Should throw exception when Chia Lite Wallet response with JsonRpcError after user rejection',
      () async {
    // for this test, reject the getWallets request
    expect(
      () async => {
        await appClient.getWallets(
          fingerprint: fingerprint,
          includeData: true,
        )
      },
      throwsA(isA<JsonRpcErrorWalletResponseException>()),
    );
  });
}
