enum PoolErrorResponseCode {
  revertedSignagePoint(1),
  tooLate(2),
  notFound(3),
  invalidProof(4),
  proofNotGoodEnough(5),
  invalidDifficulty(6),
  invalidSignature(7),
  serverException(8),
  invalidP2SingletonPuzzleHash(9),
  farmerNotKnown(10),
  farmerAlreadyKnown(11),
  invalidAuthenticationToken(12),
  invalidPayoutInstructions(13),
  invalidSingleton(14),
  delayTimeTooShort(15),
  requestFailed(16);

  final int code;
  const PoolErrorResponseCode(this.code);
  factory PoolErrorResponseCode.fromCode(int code) {
    switch (code) {
      case 1:
        return revertedSignagePoint;
      case 2:
        return tooLate;
      case 3:
        return notFound;
      case 4:
        return invalidProof;
      case 5:
        return proofNotGoodEnough;
      case 6:
        return invalidDifficulty;
      case 7:
        return invalidSignature;
      case 8:
        return serverException;
      case 9:
        return invalidP2SingletonPuzzleHash;
      case 10:
        return farmerNotKnown;
      case 11:
        return farmerAlreadyKnown;
      case 12:
        return invalidAuthenticationToken;
      case 13:
        return invalidPayoutInstructions;
      case 14:
        return invalidSingleton;
      case 15:
        return delayTimeTooShort;
      case 16:
        return requestFailed;
      default:
        throw ArgumentError('invalid pool error response code');
    }
  }
}
