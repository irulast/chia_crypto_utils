import 'dart:typed_data';

import 'package:bech32m/bech32m.dart';
import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:crypto/crypto.dart';

// compiled from chia/wallet/puzzles/p2_delegated_puzzle_or_hidden_puzzle.clvm
final standardTransactionPuzzle = Program.parse(
  '(a (q 2 (i 11 (q 2 (i (= 5 (point_add 11 (pubkey_for_exp (sha256 11 (a 6 (c 2 (c 23 ()))))))) (q 2 23 47) (q 8)) 1) (q 4 (c 4 (c 5 (c (a 6 (c 2 (c 23 ()))) ()))) (a 23 47))) 1) (c (q 50 2 (i (l 5) (q 11 (q . 2) (a 6 (c 2 (c 9 ()))) (a 6 (c 2 (c 13 ())))) (q 11 (q . 1) 5)) 1) 1))',
);

// from chia/wallet/puzzles/p2_delegated_puzzle_or_hidden_puzzle.py
final defaultHiddenPuzzle = Program.parse('(=)');

// compiled from chia/wallet/puzzles/calculate_synthetic_public_key.clvm
final calculateSyntheticKeyProgram = Program.parse('(point_add 2 (pubkey_for_exp (sha256 2 5)))');

// cribbed from chia/wallet/derive_keys.py
// EIP 2334 bls key derivation
// https://eips.ethereum.org/EIPS/eip-2334
// 12381 = bls spec number
// 8444 = Chia blockchain number and port number
// farmer: 0, pool: 1, wallet: 2, local: 3, backup key: 4, singleton: 5, pooling authentication key numbers: 6

const blsSpecNumber = 12381;
const chiaBlockchanNumber = 8444;
const farmerPathNumber = 0;
const poolPathNumber = 1;
const walletPathNumber = 2;
const localPathNumber = 3;
const backupKeyPathNumber = 4;
const singletonPathNumber = 5;
const poolingAuthenticationPathNumber = 6;

PrivateKey derivePath(PrivateKey sk, List<int> path) {
  return path.fold(sk, AugSchemeMPL.deriveChildSk);
}

PrivateKey derivePathUnhardened(PrivateKey sk, List<int> path) {
  return path.fold(sk, AugSchemeMPL.deriveChildSkUnhardened);
}

PrivateKey masterSkToFarmerSk(PrivateKey masterSk) {
  return derivePath(masterSk, [blsSpecNumber, chiaBlockchanNumber, farmerPathNumber, 0]);
}

PrivateKey masterSkToPoolSk(PrivateKey masterSk) {
  return derivePath(masterSk, [blsSpecNumber, chiaBlockchanNumber, poolPathNumber, 0]);
}

PrivateKey masterSkToWalletSk(PrivateKey masterSk, int index) {
  return derivePath(masterSk, [blsSpecNumber, chiaBlockchanNumber, walletPathNumber, index]);
}

PrivateKey masterSkToWalletSkUnhardened(PrivateKey masterSk, int index) {
  return derivePathUnhardened(masterSk, [blsSpecNumber, chiaBlockchanNumber, walletPathNumber, index]);
}

PrivateKey masterSkToLocalSk(PrivateKey masterSk) {
  return derivePath(masterSk, [blsSpecNumber, chiaBlockchanNumber, localPathNumber, 0]);
}

PrivateKey masterSkToBackupSk(PrivateKey masterSk) {
  return derivePath(masterSk, [blsSpecNumber, chiaBlockchanNumber, backupKeyPathNumber, 0]);
}

// This key controls a singleton on the blockchain, allowing for dynamic pooling (changing pools)
PrivateKey masterSkToSingletonOwnerSk(PrivateKey masterSk, int poolWalletIndex) {
  return derivePath(masterSk, [blsSpecNumber, chiaBlockchanNumber, singletonPathNumber, poolWalletIndex]);
}

// This key is used for the farmer to authenticate to the pool when sending partials
PrivateKey masterSkToPoolingAuthenticationSk(PrivateKey masterSk, int poolWalletIndex, int index) {
  assert(index < 10000);
  assert(poolWalletIndex < 10000);
  return derivePath(masterSk, [blsSpecNumber, chiaBlockchanNumber, poolingAuthenticationPathNumber, poolWalletIndex * 10000 + index]);
}

String getAddressFromPuzzle(Program puzzle, {bool testnet = false}) {
  final puzzlehash = puzzle.hash();

  final ticker = (testnet ? 'txch' : 'xch');

  final address = segwit.encode(Segwit(ticker, puzzlehash));
  return address;
}

// cribbed from chia/wallet/puzzles/p2_delegated_puzzle_or_hidden_puzzle.py
Program getPuzzleFromPk(JacobianPoint publicKey) {
  final syntheticPubKey = calculateSyntheticKeyProgram.run(
    Program.list([Program.fromBytes(publicKey.toBytes()), Program.fromBytes(defaultHiddenPuzzle.hash())
  ]));

  final curried = standardTransactionPuzzle.curry([syntheticPubKey.program]);

  return curried;
}

final groupOrder = BigInt.parse('0x73EDA753299D7D483339D80809A1D80553BDA402FFFE5BFEFFFFFFFF00000001');

BigInt calculateSyntheticOffset(JacobianPoint publicKey) {
  final blob = sha256.convert(publicKey.toBytes() + defaultHiddenPuzzle.hash()).bytes;
  // print(blob);
  final offset = bytesToBigInt(blob, Endian.big, signed: true);
  // print(offset.toString());
  final newOffset = offset % groupOrder;
  return newOffset;
}

PrivateKey calculateSyntheticPrivateKey(PrivateKey privateKey) {
  final secretExponent = bytesToBigInt(privateKey.toBytes(), Endian.big);
  // print(secretExponent.toString());

  final publicKey = privateKey.getG1();
  // print(publicKey.toBytes());
  final syntheticOffset = calculateSyntheticOffset(publicKey);
  // print(syntheticOffset.toString());

  final syntheticSecretExponent = (secretExponent + syntheticOffset) % groupOrder;

  final blob = bigIntToBytes(syntheticSecretExponent, 32, Endian.big);
  final syntheticPrivateKey = PrivateKey.fromBytes(blob);

  return syntheticPrivateKey;
}
