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
  // current 
  // final address = Address('xch1ye5dzd44kkatnxx2je4s2agpwtqds5lsm5mlyef7plum5danxalq2dnqap');
  final address = Address('xch1pdar6hnj8c9sgm74r72u40ed8cnpduzan5vr86qkvpftg0v52jkstxap9z');
  
  await simulatorFullNode.farmTransactionBlock(address);
  await simulatorFullNode.moveToNextBlock();

  final coins = await fullNodeInterface.getCoinsByPuzzleHashes([address.toPuzzlehash()]);
  coins.forEach((element) {
    print('-------');
    // print(element.toJson());
    // print('id hex: ${element.id.toHex()}');
    print('parent_info: ${element.parentCoinInfo.toUint8List()}');
    // print('parent coin info hex: ' + element.parentCoinInfo.toHex());
    print('puzzle_hash: ${element.puzzlehash.toUint8List()}');
    print('amount: ${element.amount}');
  });
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

  const coinSpendsJson = '[{"coin": {"parent_coin_info": "0xe3b0c44298fc1c149afbf4c8996fb92400000000000000000000000000000001", "puzzle_hash": "0x0b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454ad", "amount": 1750000000000}, "puzzle_reveal": "0xff02ffff01ff02ffff01ff02ffff03ff0bffff01ff02ffff03ffff09ff05ffff1dff0bffff1effff0bff0bffff02ff06ffff04ff02ffff04ff17ff8080808080808080ffff01ff02ff17ff2f80ffff01ff088080ff0180ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff17ff80808080ff80808080ffff02ff17ff2f808080ff0180ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0a4eb51326d2b1583201e22173c8d0e05a595c73039776ef179b7c40123794ebd43efb93364f5cf3ac3549d7b6851c10dff018080", "solution": "0xff80ffff01ffff33ffa01c2121e077ca2d57e3a447718fa42c3064bdf13bc7bf07bb3f39d084beb8c23eff82271080ffff33ffa0f794b351f24652734d4081887ef5addee7e84997b4216de591e1c9ff9ac98fb7ff8601977420b4f080ffff3cffa0612f6c1bdf609aa05265c9dc29eabdb7973f8496f26965defbe3240e29ab65668080ff8080"}, {"coin": {"parent_coin_info": "0x26081b15441311d9a207a078b650a05766975814fd5aa6935a759ddaf2a05af0", "puzzle_hash": "0x1c2121e077ca2d57e3a447718fa42c3064bdf13bc7bf07bb3f39d084beb8c23e", "amount": 10000}, "puzzle_reveal": "0xff02ffff01ff02ffff01ff02ff5effff04ff02ffff04ffff04ff05ffff04ffff0bff2cff0580ffff04ff0bff80808080ffff04ffff02ff17ff2f80ffff04ff5fffff04ffff02ff2effff04ff02ffff04ff17ff80808080ffff04ffff0bff82027fff82057fff820b7f80ffff04ff81bfffff04ff82017fffff04ff8202ffffff04ff8205ffffff04ff820bffff80808080808080808080808080ffff04ffff01ffffffff81ca3dff46ff0233ffff3c04ff01ff0181cbffffff02ff02ffff03ff05ffff01ff02ff32ffff04ff02ffff04ff0dffff04ffff0bff22ffff0bff2cff3480ffff0bff22ffff0bff22ffff0bff2cff5c80ff0980ffff0bff22ff0bffff0bff2cff8080808080ff8080808080ffff010b80ff0180ffff02ffff03ff0bffff01ff02ffff03ffff09ffff02ff2effff04ff02ffff04ff13ff80808080ff820b9f80ffff01ff02ff26ffff04ff02ffff04ffff02ff13ffff04ff5fffff04ff17ffff04ff2fffff04ff81bfffff04ff82017fffff04ff1bff8080808080808080ffff04ff82017fff8080808080ffff01ff088080ff0180ffff01ff02ffff03ff17ffff01ff02ffff03ffff20ff81bf80ffff0182017fffff01ff088080ff0180ffff01ff088080ff018080ff0180ffff04ffff04ff05ff2780ffff04ffff10ff0bff5780ff778080ff02ffff03ff05ffff01ff02ffff03ffff09ffff02ffff03ffff09ff11ff7880ffff0159ff8080ff0180ffff01818f80ffff01ff02ff7affff04ff02ffff04ff0dffff04ff0bffff04ffff04ff81b9ff82017980ff808080808080ffff01ff02ff5affff04ff02ffff04ffff02ffff03ffff09ff11ff7880ffff01ff04ff78ffff04ffff02ff36ffff04ff02ffff04ff13ffff04ff29ffff04ffff0bff2cff5b80ffff04ff2bff80808080808080ff398080ffff01ff02ffff03ffff09ff11ff2480ffff01ff04ff24ffff04ffff0bff20ff2980ff398080ffff010980ff018080ff0180ffff04ffff02ffff03ffff09ff11ff7880ffff0159ff8080ff0180ffff04ffff02ff7affff04ff02ffff04ff0dffff04ff0bffff04ff17ff808080808080ff80808080808080ff0180ffff01ff04ff80ffff04ff80ff17808080ff0180ffffff02ffff03ff05ffff01ff04ff09ffff02ff26ffff04ff02ffff04ff0dffff04ff0bff808080808080ffff010b80ff0180ff0bff22ffff0bff2cff5880ffff0bff22ffff0bff22ffff0bff2cff5c80ff0580ffff0bff22ffff02ff32ffff04ff02ffff04ff07ffff04ffff0bff2cff2c80ff8080808080ffff0bff2cff8080808080ffff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff2effff04ff02ffff04ff09ff80808080ffff02ff2effff04ff02ffff04ff0dff8080808080ffff01ff0bff2cff058080ff0180ffff04ffff04ff28ffff04ff5fff808080ffff02ff7effff04ff02ffff04ffff04ffff04ff2fff0580ffff04ff5fff82017f8080ffff04ffff02ff7affff04ff02ffff04ff0bffff04ff05ffff01ff808080808080ffff04ff17ffff04ff81bfffff04ff82017fffff04ffff0bff8204ffffff02ff36ffff04ff02ffff04ff09ffff04ff820affffff04ffff0bff2cff2d80ffff04ff15ff80808080808080ff8216ff80ffff04ff8205ffffff04ff820bffff808080808080808080808080ff02ff2affff04ff02ffff04ff5fffff04ff3bffff04ffff02ffff03ff17ffff01ff09ff2dffff0bff27ffff02ff36ffff04ff02ffff04ff29ffff04ff57ffff04ffff0bff2cff81b980ffff04ff59ff80808080808080ff81b78080ff8080ff0180ffff04ff17ffff04ff05ffff04ff8202ffffff04ffff04ffff04ff24ffff04ffff0bff7cff2fff82017f80ff808080ffff04ffff04ff30ffff04ffff0bff81bfffff0bff7cff15ffff10ff82017fffff11ff8202dfff2b80ff8202ff808080ff808080ff138080ff80808080808080808080ff018080ffff04ffff01a072dec062874cd4d3aab892a0906688a1ae412b0109982e1797a170add88bdcdcffff04ffff01a0625c2184e97576f5df1be46c15b2b8771c79e4e6f0aa42d3bfecaebe733f4b8cffff04ffff01ff01ffff33ff80ff818fffff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff82027fff80808080ff80808080ffff02ff82027fffff04ff0bffff04ff17ffff04ff2fffff04ff5fffff04ff81bfff82057f80808080808080ffff04ffff01ff31ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0add4758d972b7c2bd84798749ee2094c0c9e52b5b6618c985d4a8e841bf464a4079efa01e372d2307b6c26e6d1cceae6ff018080ffffff02ffff01ff02ffff03ff2fffff01ff0880ffff01ff02ffff03ffff09ff2dff0280ff80ffff01ff088080ff018080ff0180ffff04ffff01a026081b15441311d9a207a078b650a05766975814fd5aa6935a759ddaf2a05af0ff018080ff808080ffff33ffa00b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454adff822710ffffa00b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454ad808080ff0180808080", "solution": "0xff80ff80ffa00fe40b1ec35f3472c8cf0f244c207c26e7a8678413dceb87cff38dc2c1c95093ffffa026081b15441311d9a207a078b650a05766975814fd5aa6935a759ddaf2a05af0ffa01c2121e077ca2d57e3a447718fa42c3064bdf13bc7bf07bb3f39d084beb8c23eff82271080ffffa026081b15441311d9a207a078b650a05766975814fd5aa6935a759ddaf2a05af0ffa0b0d05bdb7ed1b96763a8cec0a67ad6c76f129da3417f2ea220a62a9858f45e83ff82271080ff80ff8080"}]';
  var l = jsonDecode(coinSpendsJson) as Iterable;
  final spends = List<CoinSpend>.from(l.map<CoinSpend>((dynamic model)=> CoinSpend.fromJson(model as Map<String, dynamic>)));
  final aggSig = JacobianPoint.fromBytesG2([128, 115, 176, 31, 102, 152, 209, 254, 244, 249, 12, 51, 40, 145, 135, 253, 133, 60, 146, 181, 55, 110, 207, 137, 54, 6, 182, 38, 140, 113, 163, 98, 203, 20, 200, 80, 208, 99, 183, 82, 32, 123, 151, 155, 206, 65, 73, 74, 9, 25, 201, 75, 249, 211, 243, 225, 222, 89, 88, 5, 214, 137, 183, 181, 10, 33, 31, 14, 30, 189, 53, 116, 255, 135, 202, 139, 216, 120, 57, 159, 76, 68, 123, 160, 78, 205, 189, 48, 2, 7, 241, 77, 192, 129, 61, 196]);
  print(aggSig.toHex());
  final spendBundle = SpendBundle(coinSpends: spends, aggregatedSignature: aggSig);

  // spendBundle.debug();

  await fullNodeInterface.pushTransaction(spendBundle);
  SimulatorHttpRpc.deleteDatabase();
}
