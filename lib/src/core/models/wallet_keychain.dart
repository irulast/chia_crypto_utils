import 'package:chia_utils/chia_crypto_utils.dart';

class WalletKeychain {
  Map<Puzzlehash, WalletVector> hardenedMap = <Puzzlehash, WalletVector>{};
  Map<Puzzlehash, WalletVector> unhardenedMap = <Puzzlehash, WalletVector>{};
  Map<Puzzlehash, WalletVector> outerHashMap = <Puzzlehash, WalletVector>{};

  WalletVector? getWalletVector(Puzzlehash puzzlehash) {
    final walletVector = unhardenedMap[puzzlehash.hex];

    if (walletVector != null) {
      return walletVector;
    }

    return hardenedMap[puzzlehash.hex];
  }

  WalletVector? getWalletVectorByOuterHash(Puzzlehash outerPuzzleHash) {
    return outerHashMap[outerPuzzleHash];
  }

  WalletKeychain(List<WalletSet> walletSets) {
    final newHardenedMap = <Puzzlehash, WalletVector>{};
    final newUnhardenedMap = <Puzzlehash, WalletVector>{};

    for (final walletSet in walletSets) {
      newHardenedMap[walletSet.hardened.puzzlehash] = walletSet.hardened;
      newUnhardenedMap[walletSet.unhardened.puzzlehash] =
          walletSet.unhardened;
    }
    hardenedMap = newHardenedMap;
    unhardenedMap = newUnhardenedMap;
  }

  void addOuterPuzzleHashesForAssetId(Puzzlehash assetId) {
    for (final walletVector in unhardenedMap.values) {
      final outerPuzzleHash = makeOuterPuzzleHash(walletVector.puzzlehash, assetId);
      walletVector.assetIdtoOuterPuzzlehash[assetId] = outerPuzzleHash;
      outerHashMap[outerPuzzleHash] = walletVector;
    }
  }

  static final Program catOuterPuzzleHashGenerator = Program.parse("(a (q 2 30 (c 2 (c 5 (c 23 (c (sha256 28 11) (c (sha256 28 5) ())))))) (c (q (a 4 . 1) (q . 2) (a (i 5 (q 2 22 (c 2 (c 13 (c (sha256 26 (sha256 28 20) (sha256 26 (sha256 26 (sha256 28 18) 9) (sha256 26 11 (sha256 28 ())))) ())))) (q . 11)) 1) 11 26 (sha256 28 8) (sha256 26 (sha256 26 (sha256 28 18) 5) (sha256 26 (a 22 (c 2 (c 7 (c (sha256 28 28) ())))) (sha256 28 ())))) 1))");
  static const String TAIL_ADDRESS_GENERATOR_MOD_HASH = "72dec062874cd4d3aab892a0906688a1ae412b0109982e1797a170add88bdcdc";

  Puzzlehash makeOuterPuzzleHash(Puzzlehash innerPuzzleHash, Puzzlehash assetId) {
    final solution = Program.list([Program.fromHex(TAIL_ADDRESS_GENERATOR_MOD_HASH), Program.fromBytes(assetId.bytes), Program.fromBytes(innerPuzzleHash.bytes)]);
    final result = catOuterPuzzleHashGenerator.run(solution);
    return Puzzlehash(result.program.atom);
  }
}
