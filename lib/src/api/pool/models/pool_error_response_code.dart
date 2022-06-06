enum PoolErrorState {
  revertedSignagePoint,
  tooLate,
  notFound,
  invalidProof,
  proofNotGoodEnough,
  invalidDifficulty,
  invalidSignature,
  serverException,
  invalidP2SingletonPuzzleHash,
  farmerNotKnown,
  farmerAlreadyKnown,
  invalidAuthenticationToken,
  invalidPayoutInstructions,
  invalidSingleton,
  delayTimeTooShort,
  requestFailed
}

extension PoolErrorResponseCode on PoolErrorState {
  int get code {
    switch (this) {
      case PoolErrorState.revertedSignagePoint:
        return 1;
      case PoolErrorState.tooLate:
        return 2;
      case PoolErrorState.notFound:
        return 3;
      case PoolErrorState.invalidProof:
        return 4;
      case PoolErrorState.proofNotGoodEnough:
        return 5;
      case PoolErrorState.invalidDifficulty:
        return 6;
      case PoolErrorState.invalidSignature:
        return 7;
      case PoolErrorState.serverException:
        return 8;
      case PoolErrorState.invalidP2SingletonPuzzleHash:
        return 9;
      case PoolErrorState.farmerNotKnown:
        return 10;
      case PoolErrorState.farmerAlreadyKnown:
        return 11;
      case PoolErrorState.invalidAuthenticationToken:
        return 12;
      case PoolErrorState.invalidPayoutInstructions:
        return 13;
      case PoolErrorState.invalidSingleton:
        return 14;
      case PoolErrorState.delayTimeTooShort:
        return 15;
      case PoolErrorState.requestFailed:
        return 16;
    }
  }
}

PoolErrorState codeToPoolErrorResponse(int code) {
  switch (code) {
    case 1:
      return PoolErrorState.revertedSignagePoint;
    case 2:
      return PoolErrorState.tooLate;
    case 3:
      return PoolErrorState.notFound;
    case 4:
      return PoolErrorState.invalidProof;
    case 5:
      return PoolErrorState.proofNotGoodEnough;
    case 6:
      return PoolErrorState.invalidDifficulty;
    case 7:
      return PoolErrorState.invalidSignature;
    case 8:
      return PoolErrorState.serverException;
    case 9:
      return PoolErrorState.invalidP2SingletonPuzzleHash;
    case 10:
      return PoolErrorState.farmerNotKnown;
    case 11:
      return PoolErrorState.farmerAlreadyKnown;
    case 12:
      return PoolErrorState.invalidAuthenticationToken;
    case 13:
      return PoolErrorState.invalidPayoutInstructions;
    case 14:
      return PoolErrorState.invalidSingleton;
    case 15:
      return PoolErrorState.delayTimeTooShort;
    case 16:
      return PoolErrorState.requestFailed;
    default:
      throw ArgumentError('Invalid Pool Error Response Code');
  }
}
