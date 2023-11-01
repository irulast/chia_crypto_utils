class InvalidNftException implements Exception {
  @override
  String toString() {
    return 'Invalid NFT. Puzzles did not match';
  }
}
