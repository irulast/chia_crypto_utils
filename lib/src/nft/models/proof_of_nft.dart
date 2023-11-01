import 'dart:typed_data';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

class ProofOfNft {
  factory ProofOfNft.fromNft(NftRecord nft, WalletKeychain keychain) {
    final walletVector = keychain.getWalletVectorOrThrow(nft.p2Puzzlehash);
    final syntheticPrivateKey = calculateSyntheticPrivateKey(walletVector.childPrivateKey);
    final syntheticPublicKey = syntheticPrivateKey.getG1();
    final timestamp = DateTime.now();
    final timestampBytes = encodeInt(timestamp.millisecondsSinceEpoch);
    final signature = AugSchemeMPL.sign(syntheticPrivateKey, nft.launcherId + timestampBytes);

    return ProofOfNft._(
      launcherId: nft.launcherId,
      timestamp: timestamp,
      signature: signature,
      syntheticPublicKey: syntheticPublicKey,
      nftCoinId: nft.coin.id,
    );
  }
  ProofOfNft._({
    required this.launcherId,
    required this.timestamp,
    required this.signature,
    required this.syntheticPublicKey,
    required this.nftCoinId,
  });

  static Bytes get memoIdentifier => encodeInt(65912384);

  static ProofOfNft? maybeFromMemos(List<Bytes> memos) {
    if (memos.length < 6 || memos[0] != memoIdentifier) {
      return null;
    }
    final launcherId = memos[1];
    final signature = JacobianPoint.fromBytesG2(memos[2]);
    final nftP2SyntheticPublicKey = JacobianPoint.fromBytesG1(memos[3]);
    final coinId = Puzzlehash(memos[4]);
    final timestamp = bytesToInt(memos[5], Endian.big);
    return ProofOfNft._(
      launcherId: launcherId,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
      signature: signature,
      syntheticPublicKey: nftP2SyntheticPublicKey,
      nftCoinId: coinId,
    );
  }

  final Bytes launcherId;
  final Bytes nftCoinId;
  final DateTime timestamp;
  final JacobianPoint signature;
  final JacobianPoint syntheticPublicKey;

  List<Bytes> toMemos() {
    return [
      memoIdentifier,
      launcherId,
      signature.toBytes(),
      syntheticPublicKey.toBytes(),
      nftCoinId,
      encodeInt(timestamp.millisecondsSinceEpoch),
    ];
  }

  Future<NftVerificationResult> verify(ChiaFullNodeInterface fullNode) async {
    final nftCoin = await fullNode.getCoinById(nftCoinId);
    final nullResult = NftVerificationResult(nft: null, success: false);
    if (nftCoin == null) {
      return nullResult;
    }
    final parentSpend = await fullNode.getParentSpend(nftCoin);
    if (parentSpend == null) {
      return nullResult;
    }

    final nft = () {
      try {
        final nft = NftRecord.fromParentCoinSpend(parentSpend, nftCoin);
        return nft;
      } catch (_) {
        return null;
      }
    }();
    if (nft == null) {
      return nullResult;
    }

    final p2PuzzleReveal = getP2PuzzleFromSyntheticPublicKey(syntheticPublicKey);
    if (p2PuzzleReveal.hash() != nft.p2Puzzlehash) {
      return NftVerificationResult(
        nft: nft,
        success: false,
      );
    }

    return NftVerificationResult(
      nft: nft,
      success: AugSchemeMPL.verify(
        syntheticPublicKey,
        nft.launcherId + encodeInt(timestamp.millisecondsSinceEpoch),
        signature,
      ),
    );
  }
}

class NftVerificationResult {
  NftVerificationResult({
    required this.nft,
    required bool success,
  }) : _success = success;

  final NftRecord? nft;

  final bool _success;

  bool get success => _success && nft != null;
}

class InvalidNftProofMemos implements Exception {
  @override
  String toString() {
    return '';
  }
}
