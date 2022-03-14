import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/full_node.dart';
import 'package:chia_utils/src/context/context.dart';
import 'package:chia_utils/src/core/models/conditions/condition.dart';
import 'package:chia_utils/src/core/models/conditions/create_coin_condition.dart';
import 'package:chia_utils/src/core/service/base_wallet.dart';
import 'package:hex/hex.dart';

void main() async {
  final fullNode = FullNode('http://localhost:4000');
  final configurationProvider = ConfigurationProvider()
    ..setConfig(NetworkFactory.configId, {
      'yaml_file_path': 'lib/src/networks/chia/testnet10/config.yaml'
    }
  );

  final context = Context(configurationProvider);
  final blockcahinNetworkLoader = ChiaBlockchainNetworkLoader();
  context.registerFactory(NetworkFactory(blockcahinNetworkLoader.loadfromLocalFileSystem));
  final walletService = StandardWalletService(context);

  final destinationAddress = Address('txch1zjslf8dudv69vuyvfc2dddxteunjnra7w345ve32fv7rgfr93rdsyz494r');
  final destinationHash = destinationAddress.toPuzzlehash();
  final changeAddress = Address('txch1pdar6hnj8c9sgm74r72u40ed8cnpduzan5vr86qkvpftg0v52jksxp6hy3');
  final changeHash = changeAddress.toPuzzlehash();

  const testMnemonic = [
      'elder', 'quality', 'this', 'chalk', 'crane', 'endless',
      'machine', 'hotel', 'unfair', 'castle', 'expand', 'refuse',
      'lizard', 'vacuum', 'embody', 'track', 'crash', 'truth',
      'arrow', 'tree', 'poet', 'audit', 'grid', 'mesh',
  ];

  final masterKeyPair = MasterKeyPair.fromMnemonic(testMnemonic);

  final walletsSetList = <WalletSet>[];
  for (var i = 0; i < 1; i++) {
    final set1 = WalletSet.fromPrivateKey(masterKeyPair.masterPrivateKey, i);
    walletsSetList.add(set1);
  }

  final walletKeychain = WalletKeychain(walletsSetList);

  final unhardenedPuzzlehashes = walletKeychain.unhardenedMap.values.map((vec) => vec.puzzlehash).toList();

  const targetAssetId = "625c2184e97576f5df1be46c15b2b8771c79e4e6f0aa42d3bfecaebe733f4b8c";


  final tailPuzzleHashToStandardPuzzleHash = <Puzzlehash, Puzzlehash>{};
                                
  final catPuzzleHashGenerator = Program.parse("(a (q 2 30 (c 2 (c 5 (c 23 (c (sha256 28 11) (c (sha256 28 5) ())))))) (c (q (a 4 . 1) (q . 2) (a (i 5 (q 2 22 (c 2 (c 13 (c (sha256 26 (sha256 28 20) (sha256 26 (sha256 26 (sha256 28 18) 9) (sha256 26 11 (sha256 28 ())))) ())))) (q . 11)) 1) 11 26 (sha256 28 8) (sha256 26 (sha256 26 (sha256 28 18) 5) (sha256 26 (a 22 (c 2 (c 7 (c (sha256 28 28) ())))) (sha256 28 ())))) 1))");
  const TAIL_ADDRESS_GENERATOR_MOD_HASH = "72dec062874cd4d3aab892a0906688a1ae412b0109982e1797a170add88bdcdc";
  for (final puzzleHash in unhardenedPuzzlehashes) {
    final solution = Program.list([Program.fromHex(TAIL_ADDRESS_GENERATOR_MOD_HASH), Program.fromBytes(Puzzlehash.fromHex(targetAssetId).bytes), Program.fromBytes(puzzleHash.bytes)]);
    final result = catPuzzleHashGenerator.run(solution);
    tailPuzzleHashToStandardPuzzleHash[Puzzlehash(result.program.atom)] = puzzleHash;
  }
  // final solution = Program.fromString('')
  final coins = await fullNode.getCoinRecordsByPuzzleHashes(tailPuzzleHashToStandardPuzzleHash.keys.toList());
  assert(coins.length == 1);
  final catCoin = coins[0];

  final walletVector = walletKeychain.getWalletVector(tailPuzzleHashToStandardPuzzleHash[catCoin.puzzlehash]!);
  assert(walletVector != null);
  

  final conditions = <Condition>[];
  final createdCoins = <CoinPrototype>[];

  const spendAmount = 2000;
  final change = catCoin.amount - spendAmount;

  // generate conditions
  final sendCreateCoinCondition = CreateCoinCondition(destinationHash, spendAmount);
  conditions.add(sendCreateCoinCondition);
  createdCoins.add(
    CoinPrototype(
      parentCoinInfo: catCoin.id,
      puzzlehash: destinationHash,
      amount: spendAmount,
    ),
  );

  if (change > 0) {
    conditions.add(CreateCoinCondition(changeHash, change));
    createdCoins.add(
      CoinPrototype(
        parentCoinInfo: catCoin.id,
        puzzlehash: changeHash,
        amount: change,
      ),
    );
  }

  final parentCoin = await fullNode.getCoinByName(catCoin.parentCoinInfo);

  final parentCoinSpend = await fullNode.getPuzzleAndSolution(parentCoin.id, parentCoin.spentBlockIndex);

  // print(parentCoinSpend.puzzleReveal.toSource());





  // final solution = Program.list([Program.fromHex(TAIL_ADDRESS_GENERATOR_MOD_HASH), Program.fromBytes(Puzzlehash.fromHex(targetAssetId).bytes), Program.fromBytes(parentCoin.puzzlehash.bytes)]);
  // final result = catPuzzleHashGenerator.run(solution);

  // // final x = parentCoinSpend.puzzleReveal.
  // diverge from python
  // final parentInnerPuzzleHash = catPuzzleHashGenerator.run(Program.list([Program.fromHex(TAIL_ADDRESS_GENERATOR_MOD_HASH), Program.fromBytes(Puzzlehash.fromHex(targetAssetId).bytes), Program.fromBytes(parentCoin.puzzlehash.bytes)])).program;
  // final parentInnerPuzzle = Program.parse('(a (q 2 (q 2 (i 11 (q 2 (i (= 5 (point_add 11 (pubkey_for_exp (sha256 11 (a 6 (c 2 (c 23 ()))))))) (q 2 23 47) (q 8)) 1) (q 4 (c 4 (c 5 (c (a 6 (c 2 (c 23 ()))) ()))) (a 23 47))) 1) (c (q 50 2 (i (l 5) (q 11 (q . 2) (a 6 (c 2 (c 9 ()))) (a 6 (c 2 (c 13 ())))) (q 11 (q . 1) 5)) 1) 1)) (c (q . 0x94a96f7397ff4acb08b6532fd20bb975a2c350c19216fef4ae9f64499bc59fe919bcf7b531dd80a371ad7858bfb288d2) 1))');
  final parentInnerPuzzle = parentCoinSpend.puzzleReveal.uncurry().arguments[2];
  // final parentParentCoin = await fullNode.getCoinRecordsByPuzzleHashes([parentCoin.puzzlehash]);
  // print(parentParentCoin.length);
  // ignore: non_constant_identifier_names
  final CC_MOD = Program.parse('(a (q 2 94 (c 2 (c (c 5 (c (sha256 44 5) (c 11 ()))) (c (a 23 47) (c 95 (c (a 46 (c 2 (c 23 ()))) (c (sha256 639 1407 2943) (c -65 (c 383 (c 767 (c 1535 (c 3071 ())))))))))))) (c (q (((-54 . 61) 70 2 . 51) (60 . 4) 1 1 . -53) ((a 2 (i 5 (q 2 50 (c 2 (c 13 (c (sha256 34 (sha256 44 52) (sha256 34 (sha256 34 (sha256 44 92) 9) (sha256 34 11 (sha256 44 ())))) ())))) (q . 11)) 1) (a (i 11 (q 2 (i (= (a 46 (c 2 (c 19 ()))) 2975) (q 2 38 (c 2 (c (a 19 (c 95 (c 23 (c 47 (c -65 (c 383 (c 27 ()))))))) (c 383 ())))) (q 8)) 1) (q 2 (i 23 (q 2 (i (not -65) (q . 383) (q 8)) 1) (q 8)) 1)) 1) (c (c 5 39) (c (+ 11 87) 119)) 2 (i 5 (q 2 (i (= (a (i (= 17 120) (q . 89) ()) 1) (q . -113)) (q 2 122 (c 2 (c 13 (c 11 (c (c -71 377) ()))))) (q 2 90 (c 2 (c (a (i (= 17 120) (q 4 120 (c (a 54 (c 2 (c 19 (c 41 (c (sha256 44 91) (c 43 ())))))) 57)) (q 2 (i (= 17 36) (q 4 36 (c (sha256 32 41) 57)) (q . 9)) 1)) 1) (c (a (i (= 17 120) (q . 89) ()) 1) (c (a 122 (c 2 (c 13 (c 11 (c 23 ()))))) ())))))) 1) (q 4 () (c () 23))) 1) ((a (i 5 (q 4 9 (a 38 (c 2 (c 13 (c 11 ()))))) (q . 11)) 1) 11 34 (sha256 44 88) (sha256 34 (sha256 34 (sha256 44 92) 5) (sha256 34 (a 50 (c 2 (c 7 (c (sha256 44 44) ())))) (sha256 44 ())))) (a (i (l 5) (q 11 (q . 2) (a 46 (c 2 (c 9 ()))) (a 46 (c 2 (c 13 ())))) (q 11 44 5)) 1) (c (c 40 (c 95 ())) (a 126 (c 2 (c (c (c 47 5) (c 95 383)) (c (a 122 (c 2 (c 11 (c 5 (q ()))))) (c 23 (c -65 (c 383 (c (sha256 1279 (a 54 (c 2 (c 9 (c 2815 (c (sha256 44 45) (c 21 ())))))) 5887) (c 1535 (c 3071 ()))))))))))) 2 42 (c 2 (c 95 (c 59 (c (a (i 23 (q 9 45 (sha256 39 (a 54 (c 2 (c 41 (c 87 (c (sha256 44 -71) (c 89 ())))))) -73)) ()) 1) (c 23 (c 5 (c 767 (c (c (c 36 (c (sha256 124 47 383) ())) (c (c 48 (c (sha256 -65 (sha256 124 21 (+ 383 (- 735 43) 767))) ())) 19)) ()))))))))) 1))');

   final lineageProof = Program.list([
      Program.fromBytes(parentCoin.parentCoinInfo.bytes),
      Program.fromBytes(parentInnerPuzzle.hash()),
      Program.fromInt(parentCoin.amount)
   ]);

   final innerPuzzle = getPuzzleFromPk(walletVector!.childPrivateKey.getG1());

  final catPuzzle = CC_MOD.curry([
    Program.fromBytes(CC_MOD.hash()),
    Program.fromBytes(Puzzlehash.fromHex(targetAssetId).bytes),
    innerPuzzle
  ]);

  assert(const HexEncoder().convert(catPuzzle.hash()) == catCoin.puzzlehash.hex, 'hashes dont match');



  var catCoinProgram = Program.list([
    Program.fromBytes(catCoin.parentCoinInfo.bytes),
    Program.fromBytes(catCoin.puzzlehash.bytes),
    Program.fromInt(catCoin.amount),
  ]);

  final innerSolution = BaseWalletService.makeSolutionFromConditions(conditions);

  var catSolution = Program.list([
    innerSolution, 
    lineageProof, //potential failure
    Program.fromBytes(catCoin.id.bytes),
    catCoinProgram, //potential failure
    Program.list([Program.fromBytes(catCoin.parentCoinInfo.bytes), Program.fromBytes(innerPuzzle.hash()), Program.fromInt(catCoin.amount)]),
    Program.fromInt(0),
    Program.fromInt(0),
  ]);
  // print(innerSolution.toSource());
  // print('ACTUAL:');
  // print(catPuzzle.toSource());
  // print('------');
  // print(catSolution.toSource());

  final spendAndSig = walletService.createCoinsSpendAndSignature(catSolution, catPuzzle, walletVector.childPrivateKey, catCoin);

  final spendBundle = SpendBundle(coinSpends: [spendAndSig.coinSpend], aggregatedSignature: AugSchemeMPL.aggregate([spendAndSig.signature]));

  final res = catPuzzle.run(catSolution);
  print(res.program.toSource());

  await fullNode.pushTransaction(spendBundle);
  // print('EXPECTED');
  // final solution = Program.deserialize([255, 255, 128, 255, 255, 1, 255, 255, 51, 255, 160, 138, 102, 41, 47, 222, 158, 240, 129, 152, 217, 150, 234, 224, 234, 33, 103, 126, 180, 120, 175, 234, 190, 216, 3, 11, 27, 244, 44, 114, 143, 125, 204, 255, 15, 255, 255, 160, 138, 102, 41, 47, 222, 158, 240, 129, 152, 217, 150, 234, 224, 234, 33, 103, 126, 180, 120, 175, 234, 190, 216, 3, 11, 27, 244, 44, 114, 143, 125, 204, 128, 128, 255, 255, 51, 255, 160, 5, 50, 235, 78, 160, 113, 248, 249, 101, 169, 38, 158, 214, 219, 23, 157, 175, 95, 55, 153, 162, 123, 15, 157, 33, 139, 252, 237, 61, 88, 191, 251, 255, 45, 128, 255, 255, 60, 255, 160, 93, 7, 60, 11, 9, 128, 154, 115, 250, 12, 237, 133, 99, 130, 158, 131, 46, 227, 21, 16, 61, 90, 107, 184, 196, 171, 195, 81, 88, 170, 31, 39, 128, 128, 255, 128, 128, 255, 255, 160, 59, 134, 35, 223, 91, 227, 245, 119, 16, 26, 179, 175, 143, 253, 14, 27, 182, 71, 35, 203, 148, 32, 67, 53, 114, 158, 208, 226, 8, 192, 122, 240, 255, 160, 226, 91, 15, 247, 165, 14, 74, 250, 227, 134, 205, 171, 83, 140, 112, 152, 61, 183, 240, 79, 168, 53, 180, 88, 85, 17, 79, 157, 121, 12, 65, 74, 255, 100, 128, 255, 160, 182, 134, 102, 6, 17, 171, 104, 121, 121, 18, 204, 164, 145, 180, 4, 52, 18, 195, 34, 232, 51, 254, 242, 19, 23, 104, 27, 230, 181, 37, 212, 45, 255, 255, 160, 42, 173, 165, 235, 175, 133, 191, 40, 116, 37, 125, 152, 218, 101, 197, 148, 9, 153, 133, 86, 145, 119, 78, 133, 147, 37, 198, 0, 219, 140, 248, 84, 255, 160, 80, 214, 49, 151, 230, 197, 122, 158, 151, 47, 197, 77, 161, 52, 193, 136, 233, 175, 197, 99, 45, 219, 222, 172, 103, 210, 243, 98, 28, 177, 158, 163, 255, 60, 128, 255, 255, 160, 42, 173, 165, 235, 175, 133, 191, 40, 116, 37, 125, 152, 218, 101, 197, 148, 9, 153, 133, 86, 145, 119, 78, 133, 147, 37, 198, 0, 219, 140, 248, 84, 255, 160, 190, 10, 64, 85, 44, 86, 59, 65, 96, 28, 20, 86, 83, 20, 15, 151, 210, 61, 216, 204, 82, 25, 185, 200, 73, 93, 32, 48, 115, 45, 147, 11, 255, 60, 128, 255, 128, 255, 128, 128]);
  // final puzzle = Program.deserialize([255, 2, 255, 255, 1, 255, 2, 255, 255, 1, 255, 2, 255, 94, 255, 255, 4, 255, 2, 255, 255, 4, 255, 255, 4, 255, 5, 255, 255, 4, 255, 255, 11, 255, 44, 255, 5, 128, 255, 255, 4, 255, 11, 255, 128, 128, 128, 128, 255, 255, 4, 255, 255, 2, 255, 23, 255, 47, 128, 255, 255, 4, 255, 95, 255, 255, 4, 255, 255, 2, 255, 46, 255, 255, 4, 255, 2, 255, 255, 4, 255, 23, 255, 128, 128, 128, 128, 255, 255, 4, 255, 255, 11, 255, 130, 2, 127, 255, 130, 5, 127, 255, 130, 11, 127, 128, 255, 255, 4, 255, 129, 191, 255, 255, 4, 255, 130, 1, 127, 255, 255, 4, 255, 130, 2, 255, 255, 255, 4, 255, 130, 5, 255, 255, 255, 4, 255, 130, 11, 255, 255, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 255, 255, 4, 255, 255, 1, 255, 255, 255, 255, 129, 202, 61, 255, 70, 255, 2, 51, 255, 255, 60, 4, 255, 1, 255, 1, 129, 203, 255, 255, 255, 2, 255, 2, 255, 255, 3, 255, 5, 255, 255, 1, 255, 2, 255, 50, 255, 255, 4, 255, 2, 255, 255, 4, 255, 13, 255, 255, 4, 255, 255, 11, 255, 34, 255, 255, 11, 255, 44, 255, 52, 128, 255, 255, 11, 255, 34, 255, 255, 11, 255, 34, 255, 255, 11, 255, 44, 255, 92, 128, 255, 9, 128, 255, 255, 11, 255, 34, 255, 11, 255, 255, 11, 255, 44, 255, 128, 128, 128, 128, 128, 255, 128, 128, 128, 128, 128, 255, 255, 1, 11, 128, 255, 1, 128, 255, 255, 2, 255, 255, 3, 255, 11, 255, 255, 1, 255, 2, 255, 255, 3, 255, 255, 9, 255, 255, 2, 255, 46, 255, 255, 4, 255, 2, 255, 255, 4, 255, 19, 255, 128, 128, 128, 128, 255, 130, 11, 159, 128, 255, 255, 1, 255, 2, 255, 38, 255, 255, 4, 255, 2, 255, 255, 4, 255, 255, 2, 255, 19, 255, 255, 4, 255, 95, 255, 255, 4, 255, 23, 255, 255, 4, 255, 47, 255, 255, 4, 255, 129, 191, 255, 255, 4, 255, 130, 1, 127, 255, 255, 4, 255, 27, 255, 128, 128, 128, 128, 128, 128, 128, 128, 255, 255, 4, 255, 130, 1, 127, 255, 128, 128, 128, 128, 128, 255, 255, 1, 255, 8, 128, 128, 255, 1, 128, 255, 255, 1, 255, 2, 255, 255, 3, 255, 23, 255, 255, 1, 255, 2, 255, 255, 3, 255, 255, 32, 255, 129, 191, 128, 255, 255, 1, 130, 1, 127, 255, 255, 1, 255, 8, 128, 128, 255, 1, 128, 255, 255, 1, 255, 8, 128, 128, 255, 1, 128, 128, 255, 1, 128, 255, 255, 4, 255, 255, 4, 255, 5, 255, 39, 128, 255, 255, 4, 255, 255, 16, 255, 11, 255, 87, 128, 255, 119, 128, 128, 255, 2, 255, 255, 3, 255, 5, 255, 255, 1, 255, 2, 255, 255, 3, 255, 255, 9, 255, 255, 2, 255, 255, 3, 255, 255, 9, 255, 17, 255, 120, 128, 255, 255, 1, 89, 255, 128, 128, 255, 1, 128, 255, 255, 1, 129, 143, 128, 255, 255, 1, 255, 2, 255, 122, 255, 255, 4, 255, 2, 255, 255, 4, 255, 13, 255, 255, 4, 255, 11, 255, 255, 4, 255, 255, 4, 255, 129, 185, 255, 130, 1, 121, 128, 255, 128, 128, 128, 128, 128, 128, 255, 255, 1, 255, 2, 255, 90, 255, 255, 4, 255, 2, 255, 255, 4, 255, 255, 2, 255, 255, 3, 255, 255, 9, 255, 17, 255, 120, 128, 255, 255, 1, 255, 4, 255, 120, 255, 255, 4, 255, 255, 2, 255, 54, 255, 255, 4, 255, 2, 255, 255, 4, 255, 19, 255, 255, 4, 255, 41, 255, 255, 4, 255, 255, 11, 255, 44, 255, 91, 128, 255, 255, 4, 255, 43, 255, 128, 128, 128, 128, 128, 128, 128, 255, 57, 128, 128, 255, 255, 1, 255, 2, 255, 255, 3, 255, 255, 9, 255, 17, 255, 36, 128, 255, 255, 1, 255, 4, 255, 36, 255, 255, 4, 255, 255, 11, 255, 32, 255, 41, 128, 255, 57, 128, 128, 255, 255, 1, 9, 128, 255, 1, 128, 128, 255, 1, 128, 255, 255, 4, 255, 255, 2, 255, 255, 3, 255, 255, 9, 255, 17, 255, 120, 128, 255, 255, 1, 89, 255, 128, 128, 255, 1, 128, 255, 255, 4, 255, 255, 2, 255, 122, 255, 255, 4, 255, 2, 255, 255, 4, 255, 13, 255, 255, 4, 255, 11, 255, 255, 4, 255, 23, 255, 128, 128, 128, 128, 128, 128, 255, 128, 128, 128, 128, 128, 128, 128, 255, 1, 128, 255, 255, 1, 255, 4, 255, 128, 255, 255, 4, 255, 128, 255, 23, 128, 128, 128, 255, 1, 128, 255, 255, 255, 2, 255, 255, 3, 255, 5, 255, 255, 1, 255, 4, 255, 9, 255, 255, 2, 255, 38, 255, 255, 4, 255, 2, 255, 255, 4, 255, 13, 255, 255, 4, 255, 11, 255, 128, 128, 128, 128, 128, 128, 255, 255, 1, 11, 128, 255, 1, 128, 255, 11, 255, 34, 255, 255, 11, 255, 44, 255, 88, 128, 255, 255, 11, 255, 34, 255, 255, 11, 255, 34, 255, 255, 11, 255, 44, 255, 92, 128, 255, 5, 128, 255, 255, 11, 255, 34, 255, 255, 2, 255, 50, 255, 255, 4, 255, 2, 255, 255, 4, 255, 7, 255, 255, 4, 255, 255, 11, 255, 44, 255, 44, 128, 255, 128, 128, 128, 128, 128, 255, 255, 11, 255, 44, 255, 128, 128, 128, 128, 128, 255, 255, 2, 255, 255, 3, 255, 255, 7, 255, 5, 128, 255, 255, 1, 255, 11, 255, 255, 1, 2, 255, 255, 2, 255, 46, 255, 255, 4, 255, 2, 255, 255, 4, 255, 9, 255, 128, 128, 128, 128, 255, 255, 2, 255, 46, 255, 255, 4, 255, 2, 255, 255, 4, 255, 13, 255, 128, 128, 128, 128, 128, 255, 255, 1, 255, 11, 255, 44, 255, 5, 128, 128, 255, 1, 128, 255, 255, 4, 255, 255, 4, 255, 40, 255, 255, 4, 255, 95, 255, 128, 128, 128, 255, 255, 2, 255, 126, 255, 255, 4, 255, 2, 255, 255, 4, 255, 255, 4, 255, 255, 4, 255, 47, 255, 5, 128, 255, 255, 4, 255, 95, 255, 130, 1, 127, 128, 128, 255, 255, 4, 255, 255, 2, 255, 122, 255, 255, 4, 255, 2, 255, 255, 4, 255, 11, 255, 255, 4, 255, 5, 255, 255, 1, 255, 128, 128, 128, 128, 128, 128, 255, 255, 4, 255, 23, 255, 255, 4, 255, 129, 191, 255, 255, 4, 255, 130, 1, 127, 255, 255, 4, 255, 255, 11, 255, 130, 4, 255, 255, 255, 2, 255, 54, 255, 255, 4, 255, 2, 255, 255, 4, 255, 9, 255, 255, 4, 255, 130, 10, 255, 255, 255, 4, 255, 255, 11, 255, 44, 255, 45, 128, 255, 255, 4, 255, 21, 255, 128, 128, 128, 128, 128, 128, 128, 255, 130, 22, 255, 128, 255, 255, 4, 255, 130, 5, 255, 255, 255, 4, 255, 130, 11, 255, 255, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 255, 2, 255, 42, 255, 255, 4, 255, 2, 255, 255, 4, 255, 95, 255, 255, 4, 255, 59, 255, 255, 4, 255, 255, 2, 255, 255, 3, 255, 23, 255, 255, 1, 255, 9, 255, 45, 255, 255, 11, 255, 39, 255, 255, 2, 255, 54, 255, 255, 4, 255, 2, 255, 255, 4, 255, 41, 255, 255, 4, 255, 87, 255, 255, 4, 255, 255, 11, 255, 44, 255, 129, 185, 128, 255, 255, 4, 255, 89, 255, 128, 128, 128, 128, 128, 128, 128, 255, 129, 183, 128, 128, 255, 128, 128, 255, 1, 128, 255, 255, 4, 255, 23, 255, 255, 4, 255, 5, 255, 255, 4, 255, 130, 2, 255, 255, 255, 4, 255, 255, 4, 255, 255, 4, 255, 36, 255, 255, 4, 255, 255, 11, 255, 124, 255, 47, 255, 130, 1, 127, 128, 255, 128, 128, 128, 255, 255, 4, 255, 255, 4, 255, 48, 255, 255, 4, 255, 255, 11, 255, 129, 191, 255, 255, 11, 255, 124, 255, 21, 255, 255, 16, 255, 130, 1, 127, 255, 255, 17, 255, 130, 2, 223, 255, 43, 128, 255, 130, 2, 255, 128, 128, 128, 255, 128, 128, 128, 255, 19, 128, 128, 255, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 255, 1, 128, 128, 255, 255, 4, 255, 255, 1, 160, 114, 222, 192, 98, 135, 76, 212, 211, 170, 184, 146, 160, 144, 102, 136, 161, 174, 65, 43, 1, 9, 152, 46, 23, 151, 161, 112, 173, 216, 139, 220, 220, 255, 255, 4, 255, 255, 1, 160, 108, 203, 54, 101, 114, 103, 117, 67, 24, 93, 228, 119, 89, 247, 66, 201, 108, 57, 158, 245, 31, 235, 4, 67, 143, 206, 57, 61, 137, 5, 107, 132, 255, 255, 4, 255, 255, 1, 255, 2, 255, 255, 1, 255, 2, 255, 255, 1, 255, 2, 255, 255, 3, 255, 11, 255, 255, 1, 255, 2, 255, 255, 3, 255, 255, 9, 255, 5, 255, 255, 29, 255, 11, 255, 255, 30, 255, 255, 11, 255, 11, 255, 255, 2, 255, 6, 255, 255, 4, 255, 2, 255, 255, 4, 255, 23, 255, 128, 128, 128, 128, 128, 128, 128, 128, 255, 255, 1, 255, 2, 255, 23, 255, 47, 128, 255, 255, 1, 255, 8, 128, 128, 255, 1, 128, 255, 255, 1, 255, 4, 255, 255, 4, 255, 4, 255, 255, 4, 255, 5, 255, 255, 4, 255, 255, 2, 255, 6, 255, 255, 4, 255, 2, 255, 255, 4, 255, 23, 255, 128, 128, 128, 128, 255, 128, 128, 128, 128, 255, 255, 2, 255, 23, 255, 47, 128, 128, 128, 255, 1, 128, 255, 255, 4, 255, 255, 1, 255, 50, 255, 2, 255, 255, 3, 255, 255, 7, 255, 5, 128, 255, 255, 1, 255, 11, 255, 255, 1, 2, 255, 255, 2, 255, 6, 255, 255, 4, 255, 2, 255, 255, 4, 255, 9, 255, 128, 128, 128, 128, 255, 255, 2, 255, 6, 255, 255, 4, 255, 2, 255, 255, 4, 255, 13, 255, 128, 128, 128, 128, 128, 255, 255, 1, 255, 11, 255, 255, 1, 1, 255, 5, 128, 128, 255, 1, 128, 255, 1, 128, 128, 255, 255, 4, 255, 255, 1, 176, 153, 62, 128, 201, 89, 84, 35, 155, 149, 222, 252, 133, 112, 144, 190, 186, 167, 252, 180, 115, 195, 237, 65, 255, 126, 22, 246, 167, 179, 210, 193, 176, 114, 102, 112, 136, 119, 110, 97, 14, 53, 227, 25, 156, 116, 21, 246, 205, 255, 1, 128, 128, 255, 1, 128, 128, 128, 128]);
  // print(puzzle.toSource());
  // print('------');
  // print(solution.toSource());
  // print(puzzle.run(solution).program.toSource());

  
}

// (0x72dec062874cd4d3aab892a0906688a1ae412b0109982e1797a170add88bdcdc 0x625c2184e97576f5df1be46c15b2b8771c79e4e6f0aa42d3bfecaebe733f4b8c 0x0b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454ad)
// (0x72dec062874cd4d3aab892a0906688a1ae412b0109982e1797a170add88bdcdc 0x625c2184e97576f5df1be46c15b2b8771c79e4e6f0aa42d3bfecaebe733f4b8c 0x0b7a3d5e723e0b046fd51f95cabf2d3e2616f05d9d1833e8166052b43d9454ad)