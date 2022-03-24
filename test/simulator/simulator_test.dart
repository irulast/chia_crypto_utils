import 'dart:convert';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/chia_full_node_interface.dart';
import 'package:chia_utils/src/core/service/base_wallet.dart';

import 'blockchain_await_util.dart';
import 'simulator_http_rpc.dart';

Future<void> main() async {
  const simulatorFullNode = SimulatorHttpRpc('http://localhost:4000');
  const fullNodeInterface = ChiaFullNodeInterface(simulatorFullNode);
  final blockchainAwaitUtil = BlockchainAwaitUtil(simulatorFullNode);
  // simulatorFullNode.getBlockchainState();
  var currentBlock = await blockchainAwaitUtil.getHeight();
  print('current block: $currentBlock');

  // //hard
  // final address = Address('xch1v8vergyvwugwv0tmxwnmeecuxh3tat5jaskkunnn79zjz0muds0qj0dxrl');
  final address = Address('xch1ye5dzd44kkatnxx2je4s2agpwtqds5lsm5mlyef7plum5danxalq2dnqap');
  
  await simulatorFullNode.farmTransactionBlock(address);
  await simulatorFullNode.moveToNextBlock();

  // final coins = await fullNodeInterface.getCoinsByPuzzleHashes([address.toPuzzlehash()]);
  // coins.forEach((element) {
  //   print('-------');
  //   // print(element.toJson());
  //   // print('id hex: ${element.id.toHex()}');
  //   print('parent_info: ${element.parentCoinInfo.toHex()}');
  //   // print('parent coin info hex: ' + element.parentCoinInfo.toHex());
  //   // print('puzzle_hash: ${element.puzzlehash.toUint8List()}');
  //   print('amount: ${element.amount}');
  // });
  // // e3b0c44298fc1c149afbf4c8996fb92400000000000000000000000000000001
  // // 27ae41e4649b934ca495991b7852b85500000000000000000000000000000001
  // SimulatorHttpRpc.deleteDatabase();
  // currentBlock = await blockchainAwaitUtil.getHeight();
  // print('current block: $currentBlock');

  // final configurationProvider = ConfigurationProvider()
  //   ..setConfig(NetworkFactory.configId, {
  //     'yaml_file_path': 'lib/src/networks/chia/testnet0/config.yaml'
  //   }
  // );

  // final context = Context(configurationProvider);
  // final blockcahinNetworkLoader = ChiaBlockchainNetworkLoader();
  // context.registerFactory(NetworkFactory(blockcahinNetworkLoader.loadfromLocalFileSystem));
  // final walletService = BaseWalletService(context);

  // final privateKey = PrivateKey.fromHex('704b30d89b99982910190440f65976c59143b949193e6c302049629d7b4c43aa');

  const coinSpendsJson = '[{"coin": {"parent_coin_info": "0xe3b0c44298fc1c149afbf4c8996fb92400000000000000000000000000000001", "puzzle_hash": "0x2668d136b5b5bab998ca966b05750172c0d853f0dd37f2653e0ff9ba37b3377e", "amount": 1750000000000}, "puzzle_reveal": "0xff02ffff01ff02ffff01ff02ffff03ff0bffff01ff02ffff03ffff09ff05ffff1dff0bffff1effff0bff0bffff02ff06ffff04ff02ffff04ff17ff8080808080808080ffff01ff02ff17ff2f80ffff01ff088080ff0180ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff17ff80808080ff80808080ffff02ff17ff2f808080ff0180ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0a1a7af6fae2dd8f6b6b80cac601f25ea116ece416b3af96303a1858c18d4c3d8738e6135385d3125ddaf1c18cc6e702dff018080", "solution": "0xff80ffff01ffff33ffa02b6b71bf543002a524a01376dd95286da292621644d5a917f12f52702ba5d298ff8203e880ffff33ffa0a3e24e4bbeb997bc8c339f50c4a011e30112e3c5bf5fa7b78056de69a58da9b5ff8601977420d81880ffff3cffa0fc36087e7bd5251a97a3baf62f2e42a93c38fcd1f1cf7331f04bdb9e2ae56d788080ff8080"}, {"coin": {"parent_coin_info": "0x2e02922bde5133162501a030bbe20872b638d629aec9255c8b37cfaf46d227a8", "puzzle_hash": "0x2b6b71bf543002a524a01376dd95286da292621644d5a917f12f52702ba5d298", "amount": 1000}, "puzzle_reveal": "0xff02ffff01ff02ffff01ff02ff5effff04ff02ffff04ffff04ff05ffff04ffff0bff2cff0580ffff04ff0bff80808080ffff04ffff02ff17ff2f80ffff04ff5fffff04ffff02ff2effff04ff02ffff04ff17ff80808080ffff04ffff0bff82027fff82057fff820b7f80ffff04ff81bfffff04ff82017fffff04ff8202ffffff04ff8205ffffff04ff820bffff80808080808080808080808080ffff04ffff01ffffffff81ca3dff46ff0233ffff3c04ff01ff0181cbffffff02ff02ffff03ff05ffff01ff02ff32ffff04ff02ffff04ff0dffff04ffff0bff22ffff0bff2cff3480ffff0bff22ffff0bff22ffff0bff2cff5c80ff0980ffff0bff22ff0bffff0bff2cff8080808080ff8080808080ffff010b80ff0180ffff02ffff03ff0bffff01ff02ffff03ffff09ffff02ff2effff04ff02ffff04ff13ff80808080ff820b9f80ffff01ff02ff26ffff04ff02ffff04ffff02ff13ffff04ff5fffff04ff17ffff04ff2fffff04ff81bfffff04ff82017fffff04ff1bff8080808080808080ffff04ff82017fff8080808080ffff01ff088080ff0180ffff01ff02ffff03ff17ffff01ff02ffff03ffff20ff81bf80ffff0182017fffff01ff088080ff0180ffff01ff088080ff018080ff0180ffff04ffff04ff05ff2780ffff04ffff10ff0bff5780ff778080ff02ffff03ff05ffff01ff02ffff03ffff09ffff02ffff03ffff09ff11ff7880ffff0159ff8080ff0180ffff01818f80ffff01ff02ff7affff04ff02ffff04ff0dffff04ff0bffff04ffff04ff81b9ff82017980ff808080808080ffff01ff02ff5affff04ff02ffff04ffff02ffff03ffff09ff11ff7880ffff01ff04ff78ffff04ffff02ff36ffff04ff02ffff04ff13ffff04ff29ffff04ffff0bff2cff5b80ffff04ff2bff80808080808080ff398080ffff01ff02ffff03ffff09ff11ff2480ffff01ff04ff24ffff04ffff0bff20ff2980ff398080ffff010980ff018080ff0180ffff04ffff02ffff03ffff09ff11ff7880ffff0159ff8080ff0180ffff04ffff02ff7affff04ff02ffff04ff0dffff04ff0bffff04ff17ff808080808080ff80808080808080ff0180ffff01ff04ff80ffff04ff80ff17808080ff0180ffffff02ffff03ff05ffff01ff04ff09ffff02ff26ffff04ff02ffff04ff0dffff04ff0bff808080808080ffff010b80ff0180ff0bff22ffff0bff2cff5880ffff0bff22ffff0bff22ffff0bff2cff5c80ff0580ffff0bff22ffff02ff32ffff04ff02ffff04ff07ffff04ffff0bff2cff2c80ff8080808080ffff0bff2cff8080808080ffff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff2effff04ff02ffff04ff09ff80808080ffff02ff2effff04ff02ffff04ff0dff8080808080ffff01ff0bff2cff058080ff0180ffff04ffff04ff28ffff04ff5fff808080ffff02ff7effff04ff02ffff04ffff04ffff04ff2fff0580ffff04ff5fff82017f8080ffff04ffff02ff7affff04ff02ffff04ff0bffff04ff05ffff01ff808080808080ffff04ff17ffff04ff81bfffff04ff82017fffff04ffff0bff8204ffffff02ff36ffff04ff02ffff04ff09ffff04ff820affffff04ffff0bff2cff2d80ffff04ff15ff80808080808080ff8216ff80ffff04ff8205ffffff04ff820bffff808080808080808080808080ff02ff2affff04ff02ffff04ff5fffff04ff3bffff04ffff02ffff03ff17ffff01ff09ff2dffff0bff27ffff02ff36ffff04ff02ffff04ff29ffff04ff57ffff04ffff0bff2cff81b980ffff04ff59ff80808080808080ff81b78080ff8080ff0180ffff04ff17ffff04ff05ffff04ff8202ffffff04ffff04ffff04ff24ffff04ffff0bff7cff2fff82017f80ff808080ffff04ffff04ff30ffff04ffff0bff81bfffff0bff7cff15ffff10ff82017fffff11ff8202dfff2b80ff8202ff808080ff808080ff138080ff80808080808080808080ff018080ffff04ffff01a072dec062874cd4d3aab892a0906688a1ae412b0109982e1797a170add88bdcdcffff04ffff01a0625c2184e97576f5df1be46c15b2b8771c79e4e6f0aa42d3bfecaebe733f4b8cffff04ffff01ff01ffff33ff80ff818fffff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff82027fff80808080ff80808080ffff02ff82027fffff04ff0bffff04ff17ffff04ff2fffff04ff5fffff04ff81bfff82057f80808080808080ffff04ffff01ff31ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0add4758d972b7c2bd84798749ee2094c0c9e52b5b6618c985d4a8e841bf464a4079efa01e372d2307b6c26e6d1cceae6ff018080ffffff02ffff01ff02ffff03ff2fffff01ff0880ffff01ff02ffff03ffff09ff2dff0280ff80ffff01ff088080ff018080ff0180ffff04ffff01a02e02922bde5133162501a030bbe20872b638d629aec9255c8b37cfaf46d227a8ff018080ff808080ffff33ffa02668d136b5b5bab998ca966b05750172c0d853f0dd37f2653e0ff9ba37b3377eff8203e8ffffa02668d136b5b5bab998ca966b05750172c0d853f0dd37f2653e0ff9ba37b3377e808080ff0180808080", "solution": "0xff80ff80ffa05d3d7bb283779287c52773fb313d57a4dedb398c54487fae7b499600c5afd640ffffa02e02922bde5133162501a030bbe20872b638d629aec9255c8b37cfaf46d227a8ffa02b6b71bf543002a524a01376dd95286da292621644d5a917f12f52702ba5d298ff8203e880ffffa02e02922bde5133162501a030bbe20872b638d629aec9255c8b37cfaf46d227a8ffa000090a5525f9e2aceff5ebbd64981f849a5c9a2b042ebc8c97b1052eddebdc84ff8203e880ff80ff8080"}]';
  var l = jsonDecode(coinSpendsJson) as Iterable;
  final spends = List<CoinSpend>.from(l.map<CoinSpend>((dynamic model)=> CoinSpend.fromJson(model as Map<String, dynamic>)));
  final aggSig = JacobianPoint.fromBytesG2([137, 189, 186, 211, 197, 236, 194, 175, 135, 28, 122, 120, 204, 139, 180, 44, 73, 46, 92, 252, 162, 11, 169, 13, 96, 28, 49, 126, 160, 9, 216, 50, 5, 106, 111, 94, 201, 76, 180, 88, 109, 171, 69, 116, 185, 204, 200, 130, 22, 246, 95, 211, 4, 246, 218, 100, 133, 249, 27, 75, 137, 129, 219, 150, 74, 91, 99, 76, 47, 27, 224, 219, 58, 29, 88, 187, 151, 143, 150, 195, 94, 40, 192, 223, 157, 48, 4, 211, 243, 119, 162, 45, 75, 47, 124, 3]);
  print(aggSig.toHex());
  final spendBundle = SpendBundle(coinSpends: spends, aggregatedSignature: aggSig);

  spendBundle.debug();

  await fullNodeInterface.pushTransaction(spendBundle);
  SimulatorHttpRpc.deleteDatabase();
}
