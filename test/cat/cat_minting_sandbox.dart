import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/simulator_full_node_interface.dart';
import 'package:chia_utils/src/api/simulator_http_rpc.dart';
import 'package:chia_utils/src/cat/models/cat_coin.dart';
import 'package:chia_utils/src/cat/models/spendable_cat.dart';
import 'package:chia_utils/src/cat/puzzles/cat/cat.clvm.hex.dart';
import 'package:chia_utils/src/cat/puzzles/tails/delegated_tail/delegated_tail.clvm.hex.dart';
import 'package:chia_utils/src/cat/puzzles/tails/genesis_by_coin_id/genesis_by_coin_id.clvm.hex.dart';
import 'package:chia_utils/src/cat/service/wallet.dart';
import 'package:chia_utils/src/clvm.dart';
import 'package:chia_utils/src/clvm/program.dart';

import '../simulator/simulator_utils.dart';

void main() async {
  // 1) curry coin_id to spend into tail puzzle
  // 1) create cat puzzle from curried tail, solution, cat_recipent puzzle hash
  // 2) generate regular xch with desired cat amount, fee, puzzle hash of constructed cat puzzle
  // 3) get eve coin (addition where ph = cat_ph)

  final configurationProvider = ConfigurationProvider()
    ..setConfig(NetworkFactory.configId, {
      'yaml_file_path': 'lib/src/networks/chia/mainnet/config.yaml'
    }
  );
  final context = Context(configurationProvider);
  final blockcahinNetworkLoader = ChiaBlockchainNetworkLoader();
  context.registerFactory(NetworkFactory(blockcahinNetworkLoader.loadfromLocalFileSystem));
  final walletService = StandardWalletService(context);

  final catWalletService = CatWalletService(context);

  const testMnemonic = [
      'elder', 'quality', 'this', 'chalk', 'crane', 'endless',
      'machine', 'hotel', 'unfair', 'castle', 'expand', 'refuse',
      'lizard', 'vacuum', 'embody', 'track', 'crash', 'truth',
      'arrow', 'tree', 'poet', 'audit', 'grid', 'mesh',
  ];
  // final testMnemonic = 'guilt rail green junior loud track cupboard citizen begin play west adapt myself panda eye finger nuclear someone update light dance exotic expect layer'.split(' ');

  final masterKeyPair = MasterKeyPair.fromMnemonic(testMnemonic);

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 11; i++) {
    final set1 = WalletSet.fromPrivateKey(masterKeyPair.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final keychain = WalletKeychain(walletsSetList);

  final address = Address.fromPuzzlehash(keychain.unhardenedMap.values.first.puzzlehash, walletService.blockchainNetwork.addressPrefix);
  const amount = 10000;

  final simulatorHttpRpc = SimulatorHttpRpc(SimulatorUtils.simulatorUrl,
    certBytes: SimulatorUtils.certBytes,
    keyBytes: SimulatorUtils.keyBytes,
  );
  final fullNodeSimulator = SimulatorFullNodeInterface(simulatorHttpRpc);

  await fullNodeSimulator.farmCoins(address);
  await fullNodeSimulator.moveToNextBlock();
  final coins = await fullNodeSimulator.getCoinsByPuzzleHashes([address.toPuzzlehash()]);
  final originCoin = coins[0];

  
  final walletSet = keychain.unhardenedMap.values.first;
  print(masterKeyPair.masterPublicKey.toHex());

  final publicKey = walletSet.childPublicKey;
  final curriedTail = delegatedTailProgram.curry([Program.fromBytes(publicKey.toBytes())]);
  
  final curriedGenesisByCoinId = genesisByCoinIdProgram.curry([Program.fromBytes(originCoin.id.toUint8List())]);
  final tailSolution = Program.list([curriedGenesisByCoinId, Program.nil]);

  final signature = AugSchemeMPL.sign(walletSet.childPrivateKey, curriedGenesisByCoinId.hash());


  // final spendBundle = catWalletService.makeMintingSpendbundle(
  //   tail: curriedTail, 
  //   solution: tailSolution, 
  //   standardCoins: coins, 
  //   destinationPuzzlehash: address.toPuzzlehash(), 
  //   changePuzzlehash: address.toPuzzlehash(), 
  //   amount: amount, 
  //   signature: signature, 
  //   keychain: keychain,
  //   originId: originCoin.id,
  // );
  
  final spendBundle = catWalletService.makeMultiIssuanceCatSpendBundle(
    genesisCoinId: originCoin.id, 
    standardCoins: coins, 
    privateKey: walletSet.childPrivateKey, 
    destinationPuzzlehash: address.toPuzzlehash(), 
    changePuzzlehash: address.toPuzzlehash(), 
    amount: amount, 
    keychain: keychain,
  );
  await fullNodeSimulator.pushTransaction(spendBundle);
  await fullNodeSimulator.moveToNextBlock();
  final outer = WalletKeychain.makeOuterPuzzleHash(address.toPuzzlehash(), Puzzlehash(curriedTail.hash()));
  final cats = await fullNodeSimulator.getCatCoinsByOuterPuzzleHashes([outer]);
  print(cats);
  return;


  // p2_puzzle = Program.to(
        // (1, [[51, 0, -113, curried_tail, solution], [51, address, amount, [address]]])
  //   )

  // final payToPuzzle = Program.cons(
  //   Program.fromInt(1),
  //   Program.list([
  //     Program.list([
  //       Program.fromInt(51),
  //       Program.fromInt(0),
  //       Program.fromInt(-113),
  //       curriedTail,
  //       tailSolution
  //     ]),
  //     Program.list([
  //       Program.fromInt(51),
  //       Program.fromBytes(address.toPuzzlehash().toUint8List()),
  //       Program.fromInt(amount),
  //       Program.list([Program.fromBytes(address.toPuzzlehash().toUint8List()),])
  //     ]),
  //   ]),
  // );

  // // print('my pay to puzzle');
  // // print(payToPuzzle.serializeHex() == 'ff01ffff33ff80ff818fffff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff82027fff80808080ff80808080ffff02ff82027fffff04ff0bffff04ff17ffff04ff2fffff04ff5fffff04ff81bfff82057f80808080808080ffff04ffff01ff31ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0add4758d972b7c2bd84798749ee2094c0c9e52b5b6618c985d4a8e841bf464a4079efa01e372d2307b6c26e6d1cceae6ff018080ffffff02ffff01ff02ffff03ff2fffff01ff0880ffff01ff02ffff03ffff09ff2dff0280ff80ffff01ff088080ff018080ff0180ffff04ffff01a026081b15441311d9a207a078b650a05766975814fd5aa6935a759ddaf2a05af0ff018080ff808080ffff33ffa00b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454adff822710ffffa00b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454ad808080');

  // final catPuzzle = catProgram.curry([
  //   Program.fromBytes(catProgram.hash()),
  //   Program.fromBytes(curriedTail.hash()),
  //   payToPuzzle,
  // ]);

  // final catPuzzleHash = Puzzlehash(catPuzzle.hash());

  // // print('my pay to puzzle');
  // // print(catPuzzle.serializeHex() == 'ff02ffff01ff02ffff01ff02ff5effff04ff02ffff04ffff04ff05ffff04ffff0bff2cff0580ffff04ff0bff80808080ffff04ffff02ff17ff2f80ffff04ff5fffff04ffff02ff2effff04ff02ffff04ff17ff80808080ffff04ffff0bff82027fff82057fff820b7f80ffff04ff81bfffff04ff82017fffff04ff8202ffffff04ff8205ffffff04ff820bffff80808080808080808080808080ffff04ffff01ffffffff81ca3dff46ff0233ffff3c04ff01ff0181cbffffff02ff02ffff03ff05ffff01ff02ff32ffff04ff02ffff04ff0dffff04ffff0bff22ffff0bff2cff3480ffff0bff22ffff0bff22ffff0bff2cff5c80ff0980ffff0bff22ff0bffff0bff2cff8080808080ff8080808080ffff010b80ff0180ffff02ffff03ff0bffff01ff02ffff03ffff09ffff02ff2effff04ff02ffff04ff13ff80808080ff820b9f80ffff01ff02ff26ffff04ff02ffff04ffff02ff13ffff04ff5fffff04ff17ffff04ff2fffff04ff81bfffff04ff82017fffff04ff1bff8080808080808080ffff04ff82017fff8080808080ffff01ff088080ff0180ffff01ff02ffff03ff17ffff01ff02ffff03ffff20ff81bf80ffff0182017fffff01ff088080ff0180ffff01ff088080ff018080ff0180ffff04ffff04ff05ff2780ffff04ffff10ff0bff5780ff778080ff02ffff03ff05ffff01ff02ffff03ffff09ffff02ffff03ffff09ff11ff7880ffff0159ff8080ff0180ffff01818f80ffff01ff02ff7affff04ff02ffff04ff0dffff04ff0bffff04ffff04ff81b9ff82017980ff808080808080ffff01ff02ff5affff04ff02ffff04ffff02ffff03ffff09ff11ff7880ffff01ff04ff78ffff04ffff02ff36ffff04ff02ffff04ff13ffff04ff29ffff04ffff0bff2cff5b80ffff04ff2bff80808080808080ff398080ffff01ff02ffff03ffff09ff11ff2480ffff01ff04ff24ffff04ffff0bff20ff2980ff398080ffff010980ff018080ff0180ffff04ffff02ffff03ffff09ff11ff7880ffff0159ff8080ff0180ffff04ffff02ff7affff04ff02ffff04ff0dffff04ff0bffff04ff17ff808080808080ff80808080808080ff0180ffff01ff04ff80ffff04ff80ff17808080ff0180ffffff02ffff03ff05ffff01ff04ff09ffff02ff26ffff04ff02ffff04ff0dffff04ff0bff808080808080ffff010b80ff0180ff0bff22ffff0bff2cff5880ffff0bff22ffff0bff22ffff0bff2cff5c80ff0580ffff0bff22ffff02ff32ffff04ff02ffff04ff07ffff04ffff0bff2cff2c80ff8080808080ffff0bff2cff8080808080ffff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff2effff04ff02ffff04ff09ff80808080ffff02ff2effff04ff02ffff04ff0dff8080808080ffff01ff0bff2cff058080ff0180ffff04ffff04ff28ffff04ff5fff808080ffff02ff7effff04ff02ffff04ffff04ffff04ff2fff0580ffff04ff5fff82017f8080ffff04ffff02ff7affff04ff02ffff04ff0bffff04ff05ffff01ff808080808080ffff04ff17ffff04ff81bfffff04ff82017fffff04ffff0bff8204ffffff02ff36ffff04ff02ffff04ff09ffff04ff820affffff04ffff0bff2cff2d80ffff04ff15ff80808080808080ff8216ff80ffff04ff8205ffffff04ff820bffff808080808080808080808080ff02ff2affff04ff02ffff04ff5fffff04ff3bffff04ffff02ffff03ff17ffff01ff09ff2dffff0bff27ffff02ff36ffff04ff02ffff04ff29ffff04ff57ffff04ffff0bff2cff81b980ffff04ff59ff80808080808080ff81b78080ff8080ff0180ffff04ff17ffff04ff05ffff04ff8202ffffff04ffff04ffff04ff24ffff04ffff0bff7cff2fff82017f80ff808080ffff04ffff04ff30ffff04ffff0bff81bfffff0bff7cff15ffff10ff82017fffff11ff8202dfff2b80ff8202ff808080ff808080ff138080ff80808080808080808080ff018080ffff04ffff01a072dec062874cd4d3aab892a0906688a1ae412b0109982e1797a170add88bdcdcffff04ffff01a0625c2184e97576f5df1be46c15b2b8771c79e4e6f0aa42d3bfecaebe733f4b8cffff04ffff01ff01ffff33ff80ff818fffff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff82027fff80808080ff80808080ffff02ff82027fffff04ff0bffff04ff17ffff04ff2fffff04ff5fffff04ff81bfff82057f80808080808080ffff04ffff01ff31ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0add4758d972b7c2bd84798749ee2094c0c9e52b5b6618c985d4a8e841bf464a4079efa01e372d2307b6c26e6d1cceae6ff018080ffffff02ffff01ff02ffff03ff2fffff01ff0880ffff01ff02ffff03ffff09ff2dff0280ff80ffff01ff088080ff018080ff0180ffff04ffff01a026081b15441311d9a207a078b650a05766975814fd5aa6935a759ddaf2a05af0ff018080ff808080ffff33ffa00b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454adff822710ffffa00b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454ad808080ff0180808080');

  // final signedSpendBundle = walletService.createSpendBundle([originCoin], amount, Puzzlehash(catPuzzle.hash()), address.toPuzzlehash(), keychain, originId: originCoin.id);
  // assert(signedSpendBundle.coinSpends.length == 1);
  // final eveParentCoinSpend = signedSpendBundle.coinSpends[0];
  // // print(eveParentCoinSpend.solution);
  // final eveCoin = CoinPrototype(
  //   parentCoinInfo: originCoin.id,
  //   puzzlehash: catPuzzleHash,
  //   amount: amount,
  // );


  // final eveCat = CatCoin.eve(coin: eveCoin, parentCoinSpend: eveParentCoinSpend, assetId: Puzzlehash(curriedTail.hash()));
  // // // print(eveCoin.toJson());
  // // // print(eveCoin.id.toHex() == '0fe40b1ec35f3472c8cf0f244c207c26e7a8678413dceb87cff38dc2c1c95093');
  // // print(Program.deserializeHex('80').toSource());

  // // payToPuzzle.run(Program.nil).program.toList().forEach((element) {
  // //   print(element);
  // // });

  // final spendableEve = SpendableCat(coin: eveCat, innerPuzzle: payToPuzzle, innerSolution: Program.nil);

  // final eveUnsignedSpendbundle = catWalletService.makeCatSpendBundleFromSpendableCats([spendableEve], keychain, signed: false);

  // final finalBundle = SpendBundle.aggregate([
  //   signedSpendBundle,
  //   eveUnsignedSpendbundle,
  //   SpendBundle(coinSpends: [], aggregatedSignature: signature),
  // ]);

  // await fullNodeSimulator.pushTransaction(finalBundle);
  // await fullNodeSimulator.moveToNextBlock();

  
}
