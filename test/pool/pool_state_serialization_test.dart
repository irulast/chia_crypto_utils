import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  const chiaPoolStateSerializedWithPoolUrl =
      '01034bf5122f344554c53bde2ebb8cd2b7e3d1600ad631c385a5d7cce23c7785459a97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb0100000008746573745f75726c00000926';
  const chiaPoolStateSerializedWithoutPoolUrl =
      '01034bf5122f344554c53bde2ebb8cd2b7e3d1600ad631c385a5d7cce23c7785459a97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb0000000926';
  test('should serialize pool state just like chia does', () {
    final targetPuzzlehash = Program.nil.hash();
    final ownerPublicKey = JacobianPoint.generateG1();

    final poolState = PoolState(
      poolSingletonState: PoolSingletonState.farmingToPool,
      targetPuzzlehash: targetPuzzlehash,
      ownerPublicKey: ownerPublicKey,
      poolUrl: 'test_url',
      relativeLockHeight: 2342,
    );
    final poolStateSerialized = poolState.toBytes();
    expect(
      poolStateSerialized.toHex(),
      equals(chiaPoolStateSerializedWithPoolUrl),
    );

    final poolStateDeserialize = PoolState.fromBytes(poolStateSerialized);
    final poolStateReSerialized = poolStateDeserialize.toBytes();
    expect(
      poolStateReSerialized.toHex(),
      equals(chiaPoolStateSerializedWithPoolUrl),
    );
  });

  test('should serialize pool state just like chia does without pool url', () {
    final targetPuzzlehash = Program.nil.hash();
    final ownerPublicKey = JacobianPoint.generateG1();

    final poolState = PoolState(
      poolSingletonState: PoolSingletonState.farmingToPool,
      targetPuzzlehash: targetPuzzlehash,
      ownerPublicKey: ownerPublicKey,
      relativeLockHeight: 2342,
    );
    final poolStateSerialized = poolState.toBytes();
    expect(
      poolStateSerialized.toHex(),
      equals(chiaPoolStateSerializedWithoutPoolUrl),
    );

    final poolStateDeserialize = PoolState.fromBytes(poolStateSerialized);
    final poolStateReSerialized = poolStateDeserialize.toBytes();
    expect(
      poolStateReSerialized.toHex(),
      equals(chiaPoolStateSerializedWithoutPoolUrl),
    );
  });
}
