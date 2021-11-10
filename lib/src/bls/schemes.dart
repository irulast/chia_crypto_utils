import 'dart:convert';
import 'dart:typed_data';

import 'package:chia_utils/src/bls/ec.dart';
import 'package:chia_utils/src/bls/field_ext.dart';
import 'package:chia_utils/src/bls/hd_keys.dart' as hd_keys;
import 'package:chia_utils/src/bls/op_swu_g2.dart';
import 'package:chia_utils/src/bls/pairing.dart';
import 'package:chia_utils/src/bls/private_key.dart';
import 'package:quiver/collection.dart';

final basicSchemeDst = Uint8List.fromList(
    utf8.encode('BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_NUL_'));
final augSchemeDst = Uint8List.fromList(
    utf8.encode('BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_AUG_'));
final popSchemeDst = Uint8List.fromList(
    utf8.encode('BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_'));
final popSchemePopDst = Uint8List.fromList(
    utf8.encode('BLS_POP_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_'));

JacobianPoint coreSignMpl(PrivateKey sk, Uint8List message, Uint8List dst) {
  return g2Map(message, dst) * sk.value;
}

bool coreVerifyMpl(JacobianPoint pk, Uint8List message, JacobianPoint signature,
    Uint8List dst) {
  if (!signature.isValid || !pk.isValid) {
    return false;
  }
  var q = g2Map(message, dst);
  var one = Fq12.one(defaultEc.q);
  var pairingResult = atePairingMulti([pk, -G1Generator()], [q, signature]);
  return pairingResult == one;
}

JacobianPoint coreAggregateMpl(List<JacobianPoint> signatures) {
  if (signatures.isEmpty) {
    throw ArgumentError('Must aggregate at least 1 signature.');
  }
  var aggregate = signatures[0];
  assert(aggregate.isValid);
  for (var signature in signatures.sublist(1)) {
    assert(signature.isValid);
    aggregate += signature;
  }
  return aggregate;
}

bool coreAggregateVerify(List<JacobianPoint> pks, List<Uint8List> ms,
    JacobianPoint signature, Uint8List dst) {
  if (pks.length != ms.length || pks.isEmpty) {
    return false;
  }
  try {
    assert(signature.isValid);
    var qs = [signature];
    var ps = [-G1Generator()];
    for (var i = 0; i < pks.length; i++) {
      assert(pks[i].isValid);
      qs.add(g2Map(ms[i], dst));
      ps.add(pks[i]);
    }
    return Fq12.one(defaultEc.q) == atePairingMulti(ps, qs);
  } on AssertionError {
    return false;
  }
}

class BasicSchemeMPL {
  static PrivateKey keyGen(Uint8List seed) {
    return hd_keys.keyGen(seed);
  }

  static JacobianPoint sign(PrivateKey sk, Uint8List message) {
    return coreSignMpl(sk, message, basicSchemeDst);
  }

  static bool verify(
      JacobianPoint pk, Uint8List message, JacobianPoint signature) {
    return coreVerifyMpl(pk, message, signature, basicSchemeDst);
  }

  static JacobianPoint aggregate(List<JacobianPoint> signatures) {
    return coreAggregateMpl(signatures);
  }

  static bool aggregateVerify(
      List<JacobianPoint> pks, List<Uint8List> ms, JacobianPoint signature) {
    if (pks.length != ms.length || pks.isEmpty) {
      return false;
    }
    for (var msg in ms) {
      for (var match in ms) {
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
  static PrivateKey keyGen(Uint8List seed) {
    return hd_keys.keyGen(seed);
  }

  static JacobianPoint sign(PrivateKey sk, Uint8List message) {
    var pk = sk.getG1();
    return coreSignMpl(
        sk, Uint8List.fromList(pk.toBytes() + message), augSchemeDst);
  }

  static bool verify(
      JacobianPoint pk, Uint8List message, JacobianPoint signature) {
    return coreVerifyMpl(pk, Uint8List.fromList(pk.toBytes() + message),
        signature, augSchemeDst);
  }

  static JacobianPoint aggregate(List<JacobianPoint> signatures) {
    return coreAggregateMpl(signatures);
  }

  static bool aggregateVerify(
      List<JacobianPoint> pks, List<Uint8List> ms, JacobianPoint signature) {
    if (pks.length != ms.length || pks.isEmpty) {
      return false;
    }
    for (var msg in ms) {
      for (var match in ms) {
        if (msg != match && listsEqual(msg, match)) {
          return false;
        }
      }
    }
    List<Uint8List> mPrimes = [];
    for (var i = 0; i < pks.length; i++) {
      mPrimes.add(Uint8List.fromList(pks[i].toBytes() + ms[i]));
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
  static PrivateKey keyGen(Uint8List seed) {
    return hd_keys.keyGen(seed);
  }

  static JacobianPoint sign(PrivateKey sk, Uint8List message) {
    return coreSignMpl(sk, message, popSchemeDst);
  }

  static bool verify(
      JacobianPoint pk, Uint8List message, JacobianPoint signature) {
    return coreVerifyMpl(pk, message, signature, popSchemeDst);
  }

  static JacobianPoint aggregate(List<JacobianPoint> signatures) {
    return coreAggregateMpl(signatures);
  }

  static bool aggregateVerify(
      List<JacobianPoint> pks, List<Uint8List> ms, JacobianPoint signature) {
    if (pks.length != ms.length || pks.isEmpty) {
      return false;
    }
    for (var msg in ms) {
      for (var match in ms) {
        if (msg != match && listsEqual(msg, match)) {
          return false;
        }
      }
    }
    return coreAggregateVerify(pks, ms, signature, popSchemeDst);
  }

  static JacobianPoint popProve(PrivateKey sk) {
    var pk = sk.getG1();
    return g2Map(pk.toBytes(), popSchemePopDst) * sk.value;
  }

  static bool popVerify(JacobianPoint pk, JacobianPoint proof) {
    try {
      assert(proof.isValid);
      assert(pk.isValid);
      var q = g2Map(pk.toBytes(), popSchemePopDst);
      var one = Fq12.one(defaultEc.q);
      var pairingResult = atePairingMulti([pk, -G1Generator()], [q, proof]);
      return pairingResult == one;
    } on AssertionError {
      return false;
    }
  }

  static bool fastAggregateVerify(
      List<JacobianPoint> pks, Uint8List message, JacobianPoint signature) {
    if (pks.isEmpty) {
      return false;
    }
    var aggregate = pks[0];
    for (var pk in pks.sublist(1)) {
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
