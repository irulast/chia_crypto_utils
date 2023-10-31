import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/did/models/chia_did_info.dart';
import 'package:chia_crypto_utils/src/did/models/uncurried_did_puzzle.dart';
import 'package:synchronized/synchronized.dart';

enum DidSignMode {
  localKeychain,
  walletConnect,
}

abstract class DidSigningService {
  Future<JacobianPoint> signDidBundle(
    SpendBundle didBundle,
  );
  Future<DidInfo> getDidInfoForDid(Bytes did);

  static bool _isDidSpend(CoinSpend coinSpend) {
    return PuzzleDriver.match(coinSpend.puzzleReveal)?.type == SpendType.did;
  }
}

class PrivateKeyDidSigningService implements DidSigningService {
  PrivateKeyDidSigningService({
    required this.didPrivateKey,
    required this.fullNode,
  });

  final PrivateKey didPrivateKey;
  final ChiaFullNodeInterface fullNode;

  @override
  Future<JacobianPoint> signDidBundle(
    SpendBundle didBundle,
  ) async {
    return didBundle
        .signWithPrivateKey(didPrivateKey, filterCoinSpends: DidSigningService._isDidSpend)
        .signedBundle
        .aggregatedSignature!;
  }

  @override
  Future<DidInfo> getDidInfoForDid(Bytes did) async {
    final puzzlehash = getPuzzleFromPk(didPrivateKey.getG1()).hash();
    final didRecord = await fullNode.getDidRecordFromHint(puzzlehash, did);
    return didRecord!.toDidInfoForPkOrThrow(didPrivateKey.getG1());
  }
}

class KeychainDidSigningService implements DidSigningService {
  KeychainDidSigningService({
    required this.keychain,
    required this.fullNode,
  });

  final WalletKeychain keychain;
  final ChiaFullNodeInterface fullNode;

  @override
  Future<JacobianPoint> signDidBundle(
    SpendBundle didBundle,
  ) async {
    return didBundle
        .sign(keychain, filterCoinSpends: DidSigningService._isDidSpend)
        .signedBundle
        .aggregatedSignature!;
  }

  @override
  Future<DidInfo> getDidInfoForDid(Bytes did) async {
    final didRecord = await fullNode.getDidRecordForDid(did);
    return didRecord!.toDidInfoOrThrow(keychain);
  }
}

class WalletConnectDidSigningService implements DidSigningService {
  WalletConnectDidSigningService(this.client, this.fullNode);

  final WalletConnectAppClient client;

  final ChiaFullNodeInterface fullNode;

  final _lock = Lock();

  var _isInitialized = false;

  Future<T> _withInitializedClient<T>(
    Future<T> Function(WalletConnectAppClient client) action,
  ) async {
    return _lock.synchronized(() async {
      if (!_isInitialized) {
        await client.init();
        _isInitialized = true;
      }
      return action(client);
    });
  }

  /// throws [MissingDidException] if the did is not found in any of the connected fingerprints
  @override
  Future<DidInfo> getDidInfoForDid(Bytes did) async {
    final chiaDidInfo = (await _getChiaDidInfoForDid(did)).didInfo;
    final didRecord = await fullNode.getDidRecordForDid(did);
    return DidInfo(
      delegate: DidRecord(
        did: did,
        coin: didRecord!.coin,
        lineageProof: didRecord.lineageProof,
        metadata: didRecord.metadata,
        singletonStructure: didRecord.singletonStructure,
        backUpIdsHash: didRecord.backUpIdsHash,
        nVerificationsRequired: didRecord.nVerificationsRequired,
        backupIds: chiaDidInfo.backupIds?.map(Puzzlehash.new).toList() ?? didRecord.backupIds,
        hints: didRecord.hints,
        parentSpend: didRecord.parentSpend,
      ),
      innerPuzzle: chiaDidInfo.currentInnerPuzzle,
    );
  }

  /// throws [MissingDidException] if the did is not found in any of the connected fingerprints
  @override
  Future<JacobianPoint> signDidBundle(SpendBundle didBundle) async {
    final uncurriedDidPuzzle =
        UncurriedDidPuzzle.fromProgram(didBundle.coinSpends.single.puzzleReveal);
    final fingerprint = (await _getChiaDidInfoForDid(uncurriedDidPuzzle.did)).fingerprint;

    return _withInitializedClient((client) async {
      final response =
          await client.signSpendBundle(fingerprint: fingerprint, spendBundle: didBundle);

      return response.signature;
    });
  }

  /// throws [MissingDidException] if the did is not found in any of the connected fingerprints
  Future<ChiaDidInfoWithFingerprint> _getChiaDidInfoForDid(Bytes did) async {
    return _withInitializedClient((client) async {
      final fingerprints = client.fingerprints;
      for (final fingerprint in fingerprints) {
        final response = await client.getWallets(
          fingerprint: fingerprint,
          type: ChiaWalletType.did,
          includeData: true,
        );
        for (final walletInfo in response.wallets) {
          try {
            final didWalletInfo =
                ChiaDidInfo.fromJson(jsonDecode(walletInfo.data) as Map<String, dynamic>);
            if (didWalletInfo.did == did) {
              return ChiaDidInfoWithFingerprint(fingerprint, didWalletInfo);
            }
          } catch (e) {
            // pass
          }
        }
      }
      throw MissingDidException(did, fingerprints);
    });
  }
}

class MissingDidException implements Exception {
  MissingDidException(this.did, this.fingerprints);

  final Bytes did;

  final List<int> fingerprints;

  @override
  String toString() {
    return 'MissingDidException: could not find did $did in fingerprints $fingerprints';
  }
}

class ChiaDidInfoWithFingerprint {
  ChiaDidInfoWithFingerprint(this.fingerprint, this.didInfo);

  final int fingerprint;
  final ChiaDidInfo didInfo;
}
