// ignore_for_file: non_constant_identifier_names

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/clvm/keywords.dart';
import 'package:crypto/crypto.dart';

// file cribbed from chia/wallet/util/curry_and_treehash.py

Puzzlehash shatreeAtom(Bytes atom) {
  final s = sha256.convert(ONE + atom);

  return Puzzlehash(s.bytes);
}

Puzzlehash shatreePair(Bytes leftHash, Bytes rightHash) {
  final s = sha256.convert(TWO + leftHash + rightHash);

  return Puzzlehash(s.bytes);
}

Puzzlehash curryAndTreeHash(Program mod, List<Puzzlehash> hashedArguments) {
  final quotedModHash = Program.cons(Program.fromBigInt(keywords['q']!), mod).hash();
  final curedValues = curriedValuesTreeHash(hashedArguments);
  return shatreePair(
    A_KW_TREEHASH,
    shatreePair(quotedModHash, shatreePair(curedValues, NULL_TREEHASH)),
  );
}

Puzzlehash curriedValuesTreeHash(List<Puzzlehash> arguments) {
  if (arguments.isEmpty) {
    return ONE_TREEHASH;
  }

  return shatreePair(
    C_KW_TREEHASH,
    shatreePair(
      shatreePair(Q_KW_TREEHASH, arguments.first),
      shatreePair(curriedValuesTreeHash(arguments.sublist(1)), NULL_TREEHASH),
    ),
  );
}

final NULL = Bytes.fromHex('');
final ONE = Bytes.fromHex('01');
final TWO = Bytes.fromHex('02');

final Q_KW = Bytes.fromHex('01');
final A_KW = Bytes.fromHex('02');
final C_KW = Bytes.fromHex('04');

final Q_KW_TREEHASH = shatreeAtom(Q_KW);
final A_KW_TREEHASH = shatreeAtom(A_KW);
final C_KW_TREEHASH = shatreeAtom(C_KW);
final ONE_TREEHASH = shatreeAtom(ONE);
final NULL_TREEHASH = shatreeAtom(NULL);
