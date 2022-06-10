// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/cat/exceptions/mixed_asset_ids_exception.dart';
import 'package:chia_crypto_utils/src/core/exceptions/change_puzzlehash_needed_exception.dart';
import 'package:test/test.dart';

Future<void> main() async {
  final assetId = Puzzlehash.fromHex(
    '625c2184e97576f5df1be46c15b2b8771c79e4e6f0aa42d3bfecaebe733f4b8c',
  );
  const parentCoinSpendJson =
      '{"coin": {"parent_coin_info": "f4151ea2a45da9a31c748f71c866f27d17b91b605aeafa4089c35c685be72f77", "puzzle_hash": "778fd03bdb07f0f99046738bc6981dafacbbc0c09fecce04006576f301b74b12", "amount": 100}, "puzzle_reveal": "ff02ffff01ff02ffff01ff02ff5effff04ff02ffff04ffff04ff05ffff04ffff0bff2cff0580ffff04ff0bff80808080ffff04ffff02ff17ff2f80ffff04ff5fffff04ffff02ff2effff04ff02ffff04ff17ff80808080ffff04ffff0bff82027fff82057fff820b7f80ffff04ff81bfffff04ff82017fffff04ff8202ffffff04ff8205ffffff04ff820bffff80808080808080808080808080ffff04ffff01ffffffff81ca3dff46ff0233ffff3c04ff01ff0181cbffffff02ff02ffff03ff05ffff01ff02ff32ffff04ff02ffff04ff0dffff04ffff0bff22ffff0bff2cff3480ffff0bff22ffff0bff22ffff0bff2cff5c80ff0980ffff0bff22ff0bffff0bff2cff8080808080ff8080808080ffff010b80ff0180ffff02ffff03ff0bffff01ff02ffff03ffff09ffff02ff2effff04ff02ffff04ff13ff80808080ff820b9f80ffff01ff02ff26ffff04ff02ffff04ffff02ff13ffff04ff5fffff04ff17ffff04ff2fffff04ff81bfffff04ff82017fffff04ff1bff8080808080808080ffff04ff82017fff8080808080ffff01ff088080ff0180ffff01ff02ffff03ff17ffff01ff02ffff03ffff20ff81bf80ffff0182017fffff01ff088080ff0180ffff01ff088080ff018080ff0180ffff04ffff04ff05ff2780ffff04ffff10ff0bff5780ff778080ff02ffff03ff05ffff01ff02ffff03ffff09ffff02ffff03ffff09ff11ff7880ffff0159ff8080ff0180ffff01818f80ffff01ff02ff7affff04ff02ffff04ff0dffff04ff0bffff04ffff04ff81b9ff82017980ff808080808080ffff01ff02ff5affff04ff02ffff04ffff02ffff03ffff09ff11ff7880ffff01ff04ff78ffff04ffff02ff36ffff04ff02ffff04ff13ffff04ff29ffff04ffff0bff2cff5b80ffff04ff2bff80808080808080ff398080ffff01ff02ffff03ffff09ff11ff2480ffff01ff04ff24ffff04ffff0bff20ff2980ff398080ffff010980ff018080ff0180ffff04ffff02ffff03ffff09ff11ff7880ffff0159ff8080ff0180ffff04ffff02ff7affff04ff02ffff04ff0dffff04ff0bffff04ff17ff808080808080ff80808080808080ff0180ffff01ff04ff80ffff04ff80ff17808080ff0180ffffff02ffff03ff05ffff01ff04ff09ffff02ff26ffff04ff02ffff04ff0dffff04ff0bff808080808080ffff010b80ff0180ff0bff22ffff0bff2cff5880ffff0bff22ffff0bff22ffff0bff2cff5c80ff0580ffff0bff22ffff02ff32ffff04ff02ffff04ff07ffff04ffff0bff2cff2c80ff8080808080ffff0bff2cff8080808080ffff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff2effff04ff02ffff04ff09ff80808080ffff02ff2effff04ff02ffff04ff0dff8080808080ffff01ff0bff2cff058080ff0180ffff04ffff04ff28ffff04ff5fff808080ffff02ff7effff04ff02ffff04ffff04ffff04ff2fff0580ffff04ff5fff82017f8080ffff04ffff02ff7affff04ff02ffff04ff0bffff04ff05ffff01ff808080808080ffff04ff17ffff04ff81bfffff04ff82017fffff04ffff0bff8204ffffff02ff36ffff04ff02ffff04ff09ffff04ff820affffff04ffff0bff2cff2d80ffff04ff15ff80808080808080ff8216ff80ffff04ff8205ffffff04ff820bffff808080808080808080808080ff02ff2affff04ff02ffff04ff5fffff04ff3bffff04ffff02ffff03ff17ffff01ff09ff2dffff0bff27ffff02ff36ffff04ff02ffff04ff29ffff04ff57ffff04ffff0bff2cff81b980ffff04ff59ff80808080808080ff81b78080ff8080ff0180ffff04ff17ffff04ff05ffff04ff8202ffffff04ffff04ffff04ff24ffff04ffff0bff7cff2fff82017f80ff808080ffff04ffff04ff30ffff04ffff0bff81bfffff0bff7cff15ffff10ff82017fffff11ff8202dfff2b80ff8202ff808080ff808080ff138080ff80808080808080808080ff018080ffff04ffff01a072dec062874cd4d3aab892a0906688a1ae412b0109982e1797a170add88bdcdcffff04ffff01a0625c2184e97576f5df1be46c15b2b8771c79e4e6f0aa42d3bfecaebe733f4b8cffff04ffff01ff02ffff01ff02ffff01ff02ffff03ff0bffff01ff02ffff03ffff09ff05ffff1dff0bffff1effff0bff0bffff02ff06ffff04ff02ffff04ff17ff8080808080808080ffff01ff02ff17ff2f80ffff01ff088080ff0180ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff17ff80808080ff80808080ffff02ff17ff2f808080ff0180ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0b51851c33c513e1d4f0b16534b81e91fb6fd3353384887e94ed53c350295bbbbb909ee9ef26b6ff4e82a96bfc7e364b8ff018080ff0180808080", "solution": "ffff80ffff01ffff3cffa07cc11210514345fcccc45f12135335d51c1ca5ba926fe3f4e070916c1dbd9c2180ffff33ffa06b9af21702cb537ddeaa7c16f44e182099aa3c9354e60fed18a0bacbcccaea4fff8200c880ffff33ffa06b9af21702cb537ddeaa7c16f44e182099aa3c9354e60fed18a0bacbcccaea4fff6480ffff33ffa00b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454adff820d168080ff8080ffffa06f756fb68aeb4a89d6844e57c5778877be620b7bc495b43b3b3f3ff633d01814ffa00b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454adff820d1680ffa019cf756cd15ca67fa80e0da8bba572a03b64c74d6ba111e82826b02d7d43c648ffffa0f4151ea2a45da9a31c748f71c866f27d17b91b605aeafa4089c35c685be72f77ffa0778fd03bdb07f0f99046738bc6981dafacbbc0c09fecce04006576f301b74b12ff6480ffffa0f4151ea2a45da9a31c748f71c866f27d17b91b605aeafa4089c35c685be72f77ffa00b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454adff820d1680ff820ddeff8080"}';
  final parentCoinSpend = CoinSpend.fromJson(
    jsonDecode(parentCoinSpendJson) as Map<String, dynamic>,
  );
  final coin0 = Coin(
    confirmedBlockIndex: 17409283,
    spentBlockIndex: 0,
    coinbase: false,
    timestamp: 2748299274,
    parentCoinInfo: Bytes.fromHex(
      'c1fdd54dd268a26fde78bb203a32a14ca942f015a9343d4ea5e9961f997256a1',
    ),
    puzzlehash: Puzzlehash.fromHex(
      '778fd03bdb07f0f99046738bc6981dafacbbc0c09fecce04006576f301b74b12',
    ),
    amount: 200,
  );
  final catCoin0 = CatCoin(
    coin: coin0,
    parentCoinSpend: parentCoinSpend,
  );

  final coin1 = Coin(
    confirmedBlockIndex: 17409283,
    spentBlockIndex: 0,
    coinbase: false,
    timestamp: 274829924,
    parentCoinInfo: Bytes.fromHex(
      'c1fdd54dd268a26fde78bb203a32a14ca942f015a9343d4ea5e9961f997256a1',
    ),
    puzzlehash: Puzzlehash.fromHex(
      '5db372b6e7577013035b4ee3fced2a7466d6ff1d3716b182afe520d83ee3427a',
    ),
    amount: 100,
  );
  final catCoin1 = CatCoin(
    coin: coin1,
    parentCoinSpend: parentCoinSpend,
  );

  final catCoins = [catCoin0, catCoin1];

  final otherCoin = Coin(
    confirmedBlockIndex: 17409283,
    spentBlockIndex: 0,
    coinbase: false,
    timestamp: 274829924,
    parentCoinInfo: Bytes.fromHex(
      '9e79c349dda91dd066d10c71094b3a55fce22ca6eb95b263c8df7f931a307bc8',
    ),
    puzzlehash: Puzzlehash.fromHex(
      '6b7a64b0c59c1b5f1fc037b6765f2f5a727c162a72a6147184fe1c632921db8f',
    ),
    amount: 1000,
  );
  const otherCatParentJson =
      '{"coin": {"parent_coin_info": "6468acf73bd52b38ee43ab1462a03121672f5057bfd3f818abeb2eea66f34ecb", "puzzle_hash": "11791f73b6e6f6dc98467c1a160bd76c80345b33a77182151229d6d73e295ed7", "amount": 1000}, "puzzle_reveal": "ff02ffff01ff02ffff01ff02ff5effff04ff02ffff04ffff04ff05ffff04ffff0bff2cff0580ffff04ff0bff80808080ffff04ffff02ff17ff2f80ffff04ff5fffff04ffff02ff2effff04ff02ffff04ff17ff80808080ffff04ffff0bff82027fff82057fff820b7f80ffff04ff81bfffff04ff82017fffff04ff8202ffffff04ff8205ffffff04ff820bffff80808080808080808080808080ffff04ffff01ffffffff81ca3dff46ff0233ffff3c04ff01ff0181cbffffff02ff02ffff03ff05ffff01ff02ff32ffff04ff02ffff04ff0dffff04ffff0bff22ffff0bff2cff3480ffff0bff22ffff0bff22ffff0bff2cff5c80ff0980ffff0bff22ff0bffff0bff2cff8080808080ff8080808080ffff010b80ff0180ffff02ffff03ff0bffff01ff02ffff03ffff09ffff02ff2effff04ff02ffff04ff13ff80808080ff820b9f80ffff01ff02ff26ffff04ff02ffff04ffff02ff13ffff04ff5fffff04ff17ffff04ff2fffff04ff81bfffff04ff82017fffff04ff1bff8080808080808080ffff04ff82017fff8080808080ffff01ff088080ff0180ffff01ff02ffff03ff17ffff01ff02ffff03ffff20ff81bf80ffff0182017fffff01ff088080ff0180ffff01ff088080ff018080ff0180ffff04ffff04ff05ff2780ffff04ffff10ff0bff5780ff778080ff02ffff03ff05ffff01ff02ffff03ffff09ffff02ffff03ffff09ff11ff7880ffff0159ff8080ff0180ffff01818f80ffff01ff02ff7affff04ff02ffff04ff0dffff04ff0bffff04ffff04ff81b9ff82017980ff808080808080ffff01ff02ff5affff04ff02ffff04ffff02ffff03ffff09ff11ff7880ffff01ff04ff78ffff04ffff02ff36ffff04ff02ffff04ff13ffff04ff29ffff04ffff0bff2cff5b80ffff04ff2bff80808080808080ff398080ffff01ff02ffff03ffff09ff11ff2480ffff01ff04ff24ffff04ffff0bff20ff2980ff398080ffff010980ff018080ff0180ffff04ffff02ffff03ffff09ff11ff7880ffff0159ff8080ff0180ffff04ffff02ff7affff04ff02ffff04ff0dffff04ff0bffff04ff17ff808080808080ff80808080808080ff0180ffff01ff04ff80ffff04ff80ff17808080ff0180ffffff02ffff03ff05ffff01ff04ff09ffff02ff26ffff04ff02ffff04ff0dffff04ff0bff808080808080ffff010b80ff0180ff0bff22ffff0bff2cff5880ffff0bff22ffff0bff22ffff0bff2cff5c80ff0580ffff0bff22ffff02ff32ffff04ff02ffff04ff07ffff04ffff0bff2cff2c80ff8080808080ffff0bff2cff8080808080ffff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff2effff04ff02ffff04ff09ff80808080ffff02ff2effff04ff02ffff04ff0dff8080808080ffff01ff0bff2cff058080ff0180ffff04ffff04ff28ffff04ff5fff808080ffff02ff7effff04ff02ffff04ffff04ffff04ff2fff0580ffff04ff5fff82017f8080ffff04ffff02ff7affff04ff02ffff04ff0bffff04ff05ffff01ff808080808080ffff04ff17ffff04ff81bfffff04ff82017fffff04ffff0bff8204ffffff02ff36ffff04ff02ffff04ff09ffff04ff820affffff04ffff0bff2cff2d80ffff04ff15ff80808080808080ff8216ff80ffff04ff8205ffffff04ff820bffff808080808080808080808080ff02ff2affff04ff02ffff04ff5fffff04ff3bffff04ffff02ffff03ff17ffff01ff09ff2dffff0bff27ffff02ff36ffff04ff02ffff04ff29ffff04ff57ffff04ffff0bff2cff81b980ffff04ff59ff80808080808080ff81b78080ff8080ff0180ffff04ff17ffff04ff05ffff04ff8202ffffff04ffff04ffff04ff24ffff04ffff0bff7cff2fff82017f80ff808080ffff04ffff04ff30ffff04ffff0bff81bfffff0bff7cff15ffff10ff82017fffff11ff8202dfff2b80ff8202ff808080ff808080ff138080ff80808080808080808080ff018080ffff04ffff01a072dec062874cd4d3aab892a0906688a1ae412b0109982e1797a170add88bdcdcffff04ffff01a0e224fbe34909e0192800a3fe841013572975cac5d7c67ae5e79cef31efb6d808ffff04ffff01ff01ffff33ff80ff818fffff02ffff01ff02ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff82027fff80808080ff80808080ffff02ff82027fffff04ff0bffff04ff17ffff04ff2fffff04ff5fffff04ff81bfff82057f80808080808080ffff04ffff01ff31ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b0b6b322066033f70cddddf13c0b9762d0b91866d27f40f21b88e569813d0f95d8d274cd97ccf7d707127fa1af1f7d240cff018080ffffff02ffff01ff02ffff03ff2fffff01ff0880ffff01ff02ffff03ffff09ff2dff0280ff80ffff01ff088080ff018080ff0180ffff04ffff01a06468acf73bd52b38ee43ab1462a03121672f5057bfd3f818abeb2eea66f34ecbff018080ff808080ffff33ffa09b9eb32223755ac209e0ab0e0e0338d8129cd041bd0da606bc7cb080c54490abff8203e8ffffa09b9eb32223755ac209e0ab0e0e0338d8129cd041bd0da606bc7cb080c54490ab808080ff0180808080", "solution": "ff80ff80ffa09e79c349dda91dd066d10c71094b3a55fce22ca6eb95b263c8df7f931a307bc8ffffa06468acf73bd52b38ee43ab1462a03121672f5057bfd3f818abeb2eea66f34ecbffa011791f73b6e6f6dc98467c1a160bd76c80345b33a77182151229d6d73e295ed7ff8203e880ffffa06468acf73bd52b38ee43ab1462a03121672f5057bfd3f818abeb2eea66f34ecbffa0f566efacf63eab0b59120d85de1f29f5018baabd74e526ee9b573f4f4829ba34ff8203e880ff80ff8080"}';
  final otherParentCoinSpend = CoinSpend.fromJson(
    jsonDecode(otherCatParentJson) as Map<String, dynamic>,
  );
  final otherCat = CatCoin(
    coin: otherCoin,
    parentCoinSpend: otherParentCoinSpend,
  );

  final standardCoin = Coin(
    confirmedBlockIndex: 16409283,
    spentBlockIndex: 0,
    coinbase: false,
    timestamp: 274829924,
    parentCoinInfo: Bytes.fromHex(
      'e3b0c44298fc1c149afbf4c8996fb92400000000000000000000000000000003',
    ),
    puzzlehash: Puzzlehash.fromHex(
      '0b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454ad',
    ),
    amount: 100000,
  );

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final catWalletService = CatWalletService();

  const testMnemonic = [
    'elder',
    'quality',
    'this',
    'chalk',
    'crane',
    'endless',
    'machine',
    'hotel',
    'unfair',
    'castle',
    'expand',
    'refuse',
    'lizard',
    'vacuum',
    'embody',
    'track',
    'crash',
    'truth',
    'arrow',
    'tree',
    'poet',
    'audit',
    'grid',
    'mesh',
  ];

  final keychainSecret = KeychainCoreSecret.fromMnemonic(testMnemonic);

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 20; i++) {
    final set1 = WalletSet.fromPrivateKey(keychainSecret.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final walletKeychain = WalletKeychain.fromWalletSets(walletsSetList)
    ..addOuterPuzzleHashesForAssetId(assetId);

  final changePuzzlehash = walletKeychain.unhardenedMap.values.toList()[0].puzzlehash;
  final targetPuzzlehash = walletKeychain.unhardenedMap.values.toList()[1].puzzlehash;

  test('Produces valid spendbundle', () async {
    final payment = Payment(250, targetPuzzlehash);
    final spendBundle = catWalletService.createSpendBundle(
      payments: [payment],
      catCoinsInput: catCoins,
      changePuzzlehash: changePuzzlehash,
      keychain: walletKeychain,
    );
    catWalletService.validateSpendBundle(spendBundle);
  });

  test('Produces valid spendbundle with fee', () async {
    final payment = Payment(250, targetPuzzlehash);
    final spendBundle = catWalletService.createSpendBundle(
      payments: [payment],
      catCoinsInput: catCoins,
      changePuzzlehash: changePuzzlehash,
      keychain: walletKeychain,
      fee: 1000,
      standardCoinsForFee: [standardCoin],
    );
    catWalletService.validateSpendBundle(spendBundle);
  });

  test('Produces valid spendbundle with fee and multiple payments', () async {
    final payment = Payment(200, targetPuzzlehash, memos: const <String>['Chia is really cool']);
    final payment1 = Payment(100, targetPuzzlehash, memos: const <int>[1000]);
    final spendBundle = catWalletService.createSpendBundle(
      payments: [payment, payment1],
      catCoinsInput: catCoins,
      changePuzzlehash: changePuzzlehash,
      keychain: walletKeychain,
      fee: 1000,
      standardCoinsForFee: [standardCoin],
    );
    catWalletService.validateSpendBundle(spendBundle);
  });

  test('Should throw error when mixing cat types', () {
    final payment = Payment(250, targetPuzzlehash);
    expect(
      () {
        catWalletService.createSpendBundle(
          payments: [payment],
          catCoinsInput: catCoins + [otherCat],
          changePuzzlehash: changePuzzlehash,
          keychain: walletKeychain,
        );
      },
      throwsA(isA<MixedAssetIdsException>()),
    );
  });

  test('Should create valid spendbundle without change puzzlehash when there is no change', () {
    final totalCoinsValue = catCoins.fold(
      0,
      (int previousValue, coin) => previousValue + coin.amount,
    );
    final spendBundle = catWalletService.createSpendBundle(
      payments: [Payment(totalCoinsValue, targetPuzzlehash)],
      catCoinsInput: catCoins,
      keychain: walletKeychain,
    );

    catWalletService.validateSpendBundle(spendBundle);
  });

  test('Should throw exception when change puzzlehash is not given and there is change', () {
    expect(
      () {
        catWalletService.createSpendBundle(
          payments: [Payment(100, targetPuzzlehash)],
          catCoinsInput: catCoins,
          keychain: walletKeychain,
        );
      },
      throwsA(isA<ChangePuzzlehashNeededException>()),
    );
  });
}
