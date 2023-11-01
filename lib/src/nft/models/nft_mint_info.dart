import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class NftMintInfo with ToBytesMixin {
  NftMintInfo({
    required this.mintHeight,
    required this.mintTimestamp,
    required this.minterDid,
  });
  factory NftMintInfo.fromBytes(Bytes bytes) {
    final iterator = bytes.iterator;
    final mintHeight = intFrom64BitsStream(iterator);
    final mintTimestamp = intFrom64BitsStream(iterator);

    final minterDid = Puzzlehash.maybeFromStream(iterator);

    return NftMintInfo(mintHeight: mintHeight, mintTimestamp: mintTimestamp, minterDid: minterDid);
  }

  static Future<NftMintInfo?> maybeFromEveSpend(CoinSpend eveSpend, Coin eveCoin) async {
    try {
      final nftMintInfo = await fromEveSpend(eveSpend, eveCoin);
      return nftMintInfo;
    } catch (e) {
      return null;
    }
  }

  /// throws [InvalidMintInfoException]
  static Future<NftMintInfo?> fromEveSpend(CoinSpend eveSpend, Coin eveCoin) async {
    final uncurriedNft = await UncurriedNftPuzzle.fromProgram(eveSpend.puzzleReveal);
    if (uncurriedNft == null) {
      return null;
    }

    if (!uncurriedNft.doesSupportDid) {
      return NftMintInfo(
        mintHeight: eveCoin.confirmedBlockIndex,
        mintTimestamp: eveCoin.timestamp,
        minterDid: null,
      );
    }
    final innerResult = () {
      try {
        return uncurriedNft.getInnerResult(eveSpend.solution);
      } catch (e) {
        throw InvalidMintInfoException('Error getting inner result: $e');
      }
    }();

    final didMagicConditions = BaseWalletService.extractConditionsFromResult(
      innerResult,
      NftDidMagicConditionCondition.isThisCondition,
      NftDidMagicConditionCondition.fromProgram,
    );

    if (didMagicConditions.length > 1) {
      throw InvalidMintInfoException('More than one nft didMagicConditions condition');
    }
    if (didMagicConditions.isEmpty) {
      throw InvalidMintInfoException('Expected did magic condition but found none');
    }

    return NftMintInfo(
      mintHeight: eveCoin.confirmedBlockIndex,
      mintTimestamp: eveCoin.timestamp,
      minterDid: didMagicConditions.single.targetDidOwner,
    );
  }

  final int mintHeight;
  final int mintTimestamp;
  DateTime get dateMinted => DateTime.fromMillisecondsSinceEpoch(mintTimestamp * 1000);

  final Bytes? minterDid;

  Address? get minterDidBetch32 {
    if (minterDid == null) return null;
    return Address.fromPuzzlehash(Puzzlehash(minterDid!), didPrefix);
  }

  @override
  Bytes toBytes() {
    return Bytes([
      ...intTo64Bits(mintHeight),
      ...intTo64Bits(mintTimestamp),
      ...minterDid.optionallySerialize(),
    ]);
  }
}

const didPrefix = 'did:chia:';

class InvalidMintInfoException implements Exception {
  InvalidMintInfoException(this.message);

  final String message;

  @override
  String toString() => 'InvalidMintInfo: $message';
}
