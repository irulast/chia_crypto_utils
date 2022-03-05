class ChiaWalletSet {
  ChiaWalletVector hardened;
  ChiaWalletVector unhardened;

  ChiaWalletSet({
    required this.hardened,
    required this.unhardened,
  });

  factory ChiaWalletSet.fromRow(List<dynamic> row) {
    final hardenedVector = ChiaWalletVector(childPublicKeyHex: row[0], puzzlehashHex: row[1]);
    final unhardenedVector = ChiaWalletVector(childPublicKeyHex: row[2], puzzlehashHex: row[3]);

    return ChiaWalletSet(hardened: hardenedVector, unhardened: unhardenedVector);
  }
}

class ChiaWalletVector {
  String childPublicKeyHex;
  String puzzlehashHex;

  ChiaWalletVector({
    required this.childPublicKeyHex,
    required this.puzzlehashHex
  });
}
