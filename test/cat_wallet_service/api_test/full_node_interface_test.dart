import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/chia_full_node_interface.dart';
import 'package:chia_utils/src/api/exceptions/bad_coin_id_exception.dart';
import 'package:chia_utils/src/api/full_node_http_rpc.dart';
import 'package:test/test.dart';

Future<void> main() async {
  const fullNodeRpc = FullNodeHttpRpc('http://localhost:4000');
  const fullNode = ChiaFullNodeInterface(fullNodeRpc);
  
  final testStandardCoins = [
    CoinPrototype(
      parentCoinInfo: Puzzlehash.fromHex('082612c36960d7b92ca8f91efe673c692ca0dc570f939357da7823b5c351e774'), 
      puzzlehash: Puzzlehash.fromHex('0b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454ad'), 
      amount: 9999994200,
    ),
    CoinPrototype(
      parentCoinInfo: Puzzlehash.fromHex('f51926bca32489339b0d6a9a64417dd3b20e3e96515bbf5602039bed8ef6f811'), 
      puzzlehash: Puzzlehash.fromHex('0b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454ad'), 
      amount: 8900,
    ),
  ];

  final testCatCoins = [
    CoinPrototype(
      parentCoinInfo: Puzzlehash.fromHex('bd131985a09e31dc4f59353eabe1c977f508a649f3c09bb28823c060a497b3dc'), 
      puzzlehash: Puzzlehash.fromHex('4422786164a154075e539d06ccd09fdbe1c9c495c0cd07bffc1e8de554834ea2'), 
      amount: 1000,
    ),
    CoinPrototype(
      parentCoinInfo: Puzzlehash.fromHex('c5f3cefaf64cab966aceba05c773a0d70fde446f35585529c4bf1d09c81ae33a'), 
      puzzlehash: Puzzlehash.fromHex('a60e072939586da0d058a0deb6148ae3b5e93726a2df27b42fdfed40c63a25fb'), 
      amount: 2000,
    ),
  ];
  

  test('should get standard coins by puzzlehashes', () async {
    final coins = await fullNode.getCoinsByPuzzleHashes(testStandardCoins.map((c) => c.puzzlehash,).toList());
    for(final testCoin in testStandardCoins) {
      expect(coins.contains(testCoin), true);
    }
  });
  
  test('should get standard coin by id', () async {
    final coin = await fullNode.getCoinById(testStandardCoins[0].id);
    expect(coin, testStandardCoins[0]);
  });

  test('should return null when coin is not found', () async {
    final coin = await fullNode.getCoinById(Puzzlehash.fromHex('cd131985a09e31dc4f59353eabe1c977f508a649f3c09bb28823c060a497b3dc'));
    expect(coin, null);
  });

  test('should throw error when full node rejects invalid id', () async {
    var errorThrown = false;
    try {
      await fullNode.getCoinById(Puzzlehash.fromHex('1cd131985a09e31dc4f59353eabe1c977f508a649f3c09bb28823c060a497b3dc'));
    } on BadCoinIdException catch (e) {
      errorThrown = true;
    }
    expect(errorThrown, true);
  });

}
