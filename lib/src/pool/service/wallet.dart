import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/core/service/base_wallet.dart';
import 'package:chia_utils/src/singleton/puzzles/singleton_top_layer/singleton_top_layer.clvm.hex.dart';
import 'package:chia_utils/src/singleton/service/singleton_service.dart';

class PoolWalletService extends BaseWalletService {
//   def create_waiting_room_inner_puzzle(
//     target_puzzle_hash: bytes32,
//     relative_lock_height: uint32,
//     owner_pubkey: G1Element,
//     launcher_id: bytes32,
//     genesis_challenge: bytes32,
//     delay_time: uint64,
//     delay_ph: bytes32,
// ) -> Program:
//     pool_reward_prefix = bytes32(genesis_challenge[:16] + b"\x00" * 16)
//     p2_singleton_puzzle_hash: bytes32 = launcher_id_to_p2_puzzle_hash(launcher_id, delay_time, delay_ph)
//     return POOL_WAITING_ROOM_MOD.curry(
//         target_puzzle_hash, p2_singleton_puzzle_hash, bytes(owner_pubkey), pool_reward_prefix, relative_lock_height
//     )
  Program createWaitingRoomInnerPuzzle({
    Puzzlehash targetPuzzlehash,
    int relativeLockHeight,
    JacobianPoint ownerPublicKey,
    Bytes launcherId,
    int delayTime,
    Puzzlehash delayPuzzlehash,
  }) {
    final poolRewardPrefix = Bytes.fromHex(blockchainNetwork.aggSigMeExtraData).sublist(0, 16) +
        Bytes(List.filled(16, 0));
    final p2SingletonPuzzlehash = launcherIdToP2Puzzlehash(launcherId, delayTime, delayPuzzlehash);
  }

// def launcher_id_to_p2_puzzle_hash(launcher_id: bytes32, seconds_delay: uint64, delayed_puzzle_hash: bytes32) -> bytes32:
//     return create_p2_singleton_puzzle(
//         SINGLETON_MOD_HASH, launcher_id, int_to_bytes(seconds_delay), delayed_puzzle_hash
//     ).get_tree_hash()
  Puzzlehash launcherIdToP2Puzzlehash(
      Bytes launcherId, int secondsDelay, Puzzlehash delayedPuzzlehash) {
    return SingletonService.createP2SingletonPuzzle(
      singletonModHash: singletonTopLayerProgram.hash(),
      launcherId: launcherId,
      secondsDelay: secondsDelay,
      delayedPuzzlehash: delayedPuzzlehash,
    ).hash();
  }
}
