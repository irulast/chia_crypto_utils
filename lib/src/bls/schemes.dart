import 'dart:convert';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/bls/hd_keys.dart' as hd_keys;
import 'package:chia_crypto_utils/src/bls/op_swu_g2.dart';
import 'package:chia_crypto_utils/src/bls/pairing.dart';
import 'package:quiver/collection.dart';

final basicSchemeDst = utf8.encode('BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_NUL_');
final augSchemeDst = utf8.encode('BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_AUG_');
final popSchemeDst = utf8.encode('BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_');
final popSchemePopDst = utf8.encode('BLS_POP_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_');

JacobianPoint coreSignMpl(PrivateKey sk, List<int> message, List<int> dst) {
  return g2Map(message, dst) * sk.value;
}

bool coreVerifyMpl(JacobianPoint pk, List<int> message, JacobianPoint signature, List<int> dst) {
  if (!signature.isValid || !pk.isValid) {
    return false;
  }
  final q = g2Map(message, dst);
  final one = Fq12.one(defaultEc.q);
  final pairingResult = atePairingMulti([pk, -JacobianPoint.generateG1()], [q, signature]);
  return pairingResult == one;
}

JacobianPoint coreAggregateMpl(List<JacobianPoint> signatures) {
  if (signatures.isEmpty) {
    throw ArgumentError('Must aggregate at least 1 signature.');
  }
  var aggregate = signatures[0];
  assert(aggregate.isValid, 'base signature is invalid');
  for (final signature in signatures.sublist(1)) {
    assert(signature.isValid, 'subsequent signature in aggregate signature is invalid');
    aggregate += signature;
  }
  return aggregate;
}

bool coreAggregateVerify(
  List<JacobianPoint> pks,
  List<List<int>> ms,
  JacobianPoint signature,
  List<int> dst,
) {
  if (pks.length != ms.length || pks.isEmpty) {
    return false;
  }
  if (!signature.isValid) {
    return false;
  }
  final qs = [signature];
  final ps = [-JacobianPoint.generateG1()];
  for (var i = 0; i < pks.length; i++) {
    if (!pks[i].isValid) {
      return false;
    }
    qs.add(g2Map(ms[i], dst));
    ps.add(pks[i]);
  }
  return Fq12.one(defaultEc.q) == atePairingMulti(ps, qs);
}

class BasicSchemeMPL {
  static PrivateKey keyGen(List<int> seed) {
    return hd_keys.keyGen(seed);
  }

  static JacobianPoint sign(PrivateKey sk, List<int> message) {
    return coreSignMpl(sk, message, basicSchemeDst);
  }

  static bool verify(JacobianPoint pk, List<int> message, JacobianPoint signature) {
    return coreVerifyMpl(pk, message, signature, basicSchemeDst);
  }

  static JacobianPoint aggregate(List<JacobianPoint> signatures) {
    return coreAggregateMpl(signatures);
  }

  static bool aggregateVerify(
    List<JacobianPoint> pks,
    List<List<int>> ms,
    JacobianPoint signature,
  ) {
    if (pks.length != ms.length || pks.isEmpty) {
      return false;
    }
    for (final msg in ms) {
      for (final match in ms) {
        if (msg != match && listsEqual(msg, match)) {
          return false;
        }
      }
    }
    return coreAggregateVerify(pks, ms, signature, basicSchemeDst);
  }

  static PrivateKey deriveChildSk(PrivateKey sk, int index) {
    return hd_keys.deriveChildSk(sk, index);
  }

  static PrivateKey deriveChildSkUnhardened(PrivateKey sk, int index) {
    return hd_keys.deriveChildSkUnhardened(sk, index);
  }

  static JacobianPoint deriveChildPkUnhardened(JacobianPoint pk, int index) {
    return hd_keys.deriveChildG1Unhardened(pk, index);
  }
}

class AugSchemeMPL {
  static PrivateKey keyGen(List<int> seed) {
    return hd_keys.keyGen(seed);
  }

  static JacobianPoint sign(PrivateKey sk, List<int> message) {
    final pk = sk.getG1();
    return coreSignMpl(sk, pk.toBytes() + message, augSchemeDst);
  }

  static Map<String, dynamic> _signTask(SignArguments args) {
    final signature = sign(args.sk, args.message);
    return <String, dynamic>{
      'signature': signature.toHex(),
    };
  }

  static Future<JacobianPoint> signAsync(PrivateKey sk, List<int> message) {
    return spawnAndWaitForIsolate(
      taskArgument: SignArguments(sk, message),
      isolateTask: _signTask,
      handleTaskCompletion: (taskResultJson) {
        return JacobianPoint.fromHexG2(taskResultJson['signature'] as String);
      },
    );
  }

  static bool verify(JacobianPoint pk, List<int> message, JacobianPoint signature) {
    return coreVerifyMpl(pk, pk.toBytes() + message, signature, augSchemeDst);
  }

  static JacobianPoint aggregate(List<JacobianPoint> signatures) {
    return coreAggregateMpl(signatures);
  }

  static bool aggregateVerify(
    List<JacobianPoint> pks,
    List<List<int>> ms,
    JacobianPoint signature,
  ) {
    if (pks.length != ms.length || pks.isEmpty) {
      return false;
    }
    final mPrimes = <List<int>>[];
    for (var i = 0; i < pks.length; i++) {
      mPrimes.add(pks[i].toBytes() + ms[i]);
    }
    return coreAggregateVerify(pks, mPrimes, signature, augSchemeDst);
  }

  static PrivateKey deriveChildSk(PrivateKey sk, int index) {
    return hd_keys.deriveChildSk(sk, index);
  }

  static PrivateKey deriveChildSkUnhardened(PrivateKey sk, int index) {
    return hd_keys.deriveChildSkUnhardened(sk, index);
  }

  static JacobianPoint deriveChildPkUnhardened(JacobianPoint pk, int index) {
    return hd_keys.deriveChildG1Unhardened(pk, index);
  }
}

class PopSchemeMPL {
  static PrivateKey keyGen(List<int> seed) {
    return hd_keys.keyGen(seed);
  }

  static JacobianPoint sign(PrivateKey sk, List<int> message) {
    return coreSignMpl(sk, message, popSchemeDst);
  }

  static bool verify(JacobianPoint pk, List<int> message, JacobianPoint signature) {
    return coreVerifyMpl(pk, message, signature, popSchemeDst);
  }

  static JacobianPoint aggregate(List<JacobianPoint> signatures) {
    return coreAggregateMpl(signatures);
  }

  static bool aggregateVerify(
    List<JacobianPoint> pks,
    List<List<int>> ms,
    JacobianPoint signature,
  ) {
    if (pks.length != ms.length || pks.isEmpty) {
      return false;
    }
    for (final msg in ms) {
      for (final match in ms) {
        if (msg != match && listsEqual(msg, match)) {
          return false;
        }
      }
    }
    return coreAggregateVerify(pks, ms, signature, popSchemeDst);
  }

  static JacobianPoint popProve(PrivateKey sk) {
    final pk = sk.getG1();
    return g2Map(pk.toBytes(), popSchemePopDst) * sk.value;
  }

  static bool popVerify(JacobianPoint pk, JacobianPoint proof) {
    try {
      assert(proof.isValid, 'invalid proof');
      assert(pk.isValid, 'invalid primary key');
      final q = g2Map(pk.toBytes(), popSchemePopDst);
      final one = Fq12.one(defaultEc.q);
      final pairingResult = atePairingMulti([pk, -JacobianPoint.generateG1()], [q, proof]);
      return pairingResult == one;
    } on Exception {
      return false;
    }
  }

  static bool fastAggregateVerify(
    List<JacobianPoint> pks,
    List<int> message,
    JacobianPoint signature,
  ) {
    if (pks.isEmpty) {
      return false;
    }
    var aggregate = pks[0];
    for (final pk in pks.sublist(1)) {
      aggregate += pk;
    }
    return coreVerifyMpl(aggregate, message, signature, popSchemeDst);
  }

  static PrivateKey deriveChildSk(PrivateKey sk, int index) {
    return hd_keys.deriveChildSk(sk, index);
  }

  static PrivateKey deriveChildSkUnhardened(PrivateKey sk, int index) {
    return hd_keys.deriveChildSkUnhardened(sk, index);
  }

  static JacobianPoint deriveChildPkUnhardened(JacobianPoint pk, int index) {
    return hd_keys.deriveChildG1Unhardened(pk, index);
  }
}

class SignArguments {
  SignArguments(this.sk, this.message);

  final PrivateKey sk;
  final List<int> message;
}
