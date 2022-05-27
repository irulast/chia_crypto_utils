// ignore_for_file: lines_longer_than_80_chars

class ChiaWalletSet {
  ChiaWalletVector hardened;
  ChiaWalletVector unhardened;

  ChiaWalletSet({
    required this.hardened,
    required this.unhardened,
  });

  factory ChiaWalletSet.fromRow(List<dynamic> row) {
    final hardenedVector = ChiaWalletVector(
      childPublicKeyHex: row[0] as String,
      puzzlehashHex: row[1] as String,
    );
    final unhardenedVector = ChiaWalletVector(
      childPublicKeyHex: row[2] as String,
      puzzlehashHex: row[3] as String,
    );

    return ChiaWalletSet(
      hardened: hardenedVector,
      unhardened: unhardenedVector,
    );
  }
}

class ChiaWalletVector {
  String childPublicKeyHex;
  String puzzlehashHex;

  ChiaWalletVector({
    required this.childPublicKeyHex,
    required this.puzzlehashHex,
  });
}
