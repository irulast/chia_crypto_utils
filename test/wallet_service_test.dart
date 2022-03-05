import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/full_node.dart';
import 'package:chia_utils/src/wallet/service/wallet_service.dart';
import 'package:chia_utils/src/models/address.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() async {
  final fullNode = FullNode('http://localhost:4000');
  final testnet = true;
  final walletService = WalletService(fullNode, testnet: testnet);

  final destinationAddress = Address('txch1pdar6hnj8c9sgm74r72u40ed8cnpduzan5vr86qkvpftg0v52jksxp6hy3');

  const testMnemonic = [
      'elder', 'quality', 'this', 'chalk', 'crane', 'endless',
      'machine', 'hotel', 'unfair', 'castle', 'expand', 'refuse',
      'lizard', 'vacuum', 'embody', 'track', 'crash', 'truth',
      'arrow', 'tree', 'poet', 'audit', 'grid', 'mesh',
  ];

  final masterKeyPair = MasterKeyPair.fromMnemonic(testMnemonic);

  List<WalletSet> walletsSetList = [];
  for(var i = 0; i < 20; i++) {
      final set1 = WalletSet.fromPrivateKey(masterKeyPair.masterPrivateKey, i, testnet: testnet);
      walletsSetList.add(set1);
  }

  final walletKeychain = WalletKeychain(walletsSetList);

  test('Should push transaction with fee', () async {
    final amountToSend = 10000;
    final fee = 100;

    final totalAmount = amountToSend + fee;

    
    final unhardenedPuzzlehashes = walletKeychain.unhardenedMap.values.map((vec) => vec.puzzlehash).toList();

    final coinRecordsResult = await walletService.getCoinRecordsByPuzzleHashes(unhardenedPuzzlehashes);
    final coinRecords = coinRecordsResult.payload!;

    final coinsToSpend = WalletService.selectCoinsToSpend(coinRecords, totalAmount);

    final result = await walletService.sendCoins(coinsToSpend, amountToSend, destinationAddress, walletKeychain.unhardenedMap.values.toList()[0].puzzlehash, walletKeychain, fee: fee);
    
    expect(result.success, true);
  });

  test('Should push transaction without fee', () async {
    final amountToSend = 10000;


    
    final unhardenedPuzzlehashes = walletKeychain.unhardenedMap.values.map((vec) => vec.puzzlehash).toList();

    final coinRecordsResult = await walletService.getCoinRecordsByPuzzleHashes(unhardenedPuzzlehashes);
    final coinRecords = coinRecordsResult.payload!;

    final coinsToSpend = WalletService.selectCoinsToSpend(coinRecords, amountToSend);

    final result = await walletService.sendCoins(coinsToSpend, amountToSend, destinationAddress, walletKeychain.unhardenedMap.values.toList()[0].puzzlehash, walletKeychain);
    
    expect(result.success, true);
  });
}