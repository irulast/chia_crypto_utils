// ignore_for_file: non_constant_identifier_names, unrelated_type_equality_checks

import 'dart:convert';
import 'dart:typed_data';

import 'package:chia_crypto_utils/src/bls/ec/ec.dart';
import 'package:chia_crypto_utils/src/bls/ec/jacobian_point.dart';
import 'package:chia_crypto_utils/src/bls/field/extensions/fq12.dart';
import 'package:chia_crypto_utils/src/bls/field/extensions/fq2.dart';
import 'package:chia_crypto_utils/src/bls/field/extensions/fq6.dart';
import 'package:chia_crypto_utils/src/bls/field/field_base.dart';
import 'package:chia_crypto_utils/src/bls/hash_to_field.dart';
import 'package:chia_crypto_utils/src/bls/hkdf.dart';
import 'package:chia_crypto_utils/src/bls/op_swu_g2.dart';
import 'package:chia_crypto_utils/src/bls/pairing.dart';
import 'package:chia_crypto_utils/src/bls/private_key.dart';
import 'package:chia_crypto_utils/src/bls/schemes.dart';
import 'package:chia_crypto_utils/src/clvm/bytes_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';
import 'package:quiver/iterables.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

class HkdfIn {
  final String ikm;
  final String salt;
  final String info;
  final String prkExpected;
  final String okmExpected;
  int L;
  HkdfIn(this.ikm, this.salt, this.info, this.prkExpected, this.okmExpected, this.L);
}

class Eip2333In {
  final String seed;
  final String masterSk;
  final String childSk;
  final int childIndex;
  Eip2333In(this.seed, this.masterSk, this.childSk, this.childIndex);
}

void main() {
  group('HKDF', () {
    List<HkdfIn> tests = [
      HkdfIn(
          "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b",
          "000102030405060708090a0b0c",
          "f0f1f2f3f4f5f6f7f8f9",
          "077709362c2e32df0ddc3f0dc47bba6390b6c73bb50f9c3122ec844ad7c2b3e5",
          "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865",
          42),
      HkdfIn(
        "000102030405060708090a0b0c0d0e0f"
            "101112131415161718191a1b1c1d1e1f"
            "202122232425262728292a2b2c2d2e2f"
            "303132333435363738393a3b3c3d3e3f"
            "404142434445464748494a4b4c4d4e4f",
        "606162636465666768696a6b6c6d6e6f"
            "707172737475767778797a7b7c7d7e7f"
            "808182838485868788898a8b8c8d8e8f"
            "909192939495969798999a9b9c9d9e9f"
            "a0a1a2a3a4a5a6a7a8a9aaabacadaeaf",
        "b0b1b2b3b4b5b6b7b8b9babbbcbdbebf"
            "c0c1c2c3c4c5c6c7c8c9cacbcccdcecf"
            "d0d1d2d3d4d5d6d7d8d9dadbdcdddedf"
            "e0e1e2e3e4e5e6e7e8e9eaebecedeeef"
            "f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff",
        "06a6b88c5853361a06104c9ceb35b45cef760014904671014a193f40c15fc244",
        "b11e398dc80327a1c8e7f78c596a4934"
            "4f012eda2d4efad8a050cc4c19afa97c"
            "59045a99cac7827271cb41c65e590e09"
            "da3275600c2f09b8367793a9aca3db71"
            "cc30c58179ec3e87c14c01d5c1f3434f"
            "1d87",
        82,
      ),
      HkdfIn(
        "0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b",
        "",
        "",
        "19ef24a32c717b167f33a91d6f648bdf96596776afdb6377ac434c1c293ccb04",
        "8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d9d201395faa4b61a96c8",
        42,
      ),
      HkdfIn(
        "8704f9ac024139fe62511375cf9bc534c0507dcf00c41603ac935cd5943ce0b4b88599390de14e743ca2f56a73a04eae13aa3f3b969b39d8701e0d69a6f8d42f",
        "53d8e19b",
        "",
        "eb01c9cd916653df76ffa61b6ab8a74e254ebfd9bfc43e624cc12a72b0373dee",
        "8faabea85fc0c64e7ca86217cdc6dcdc88551c3244d56719e630a3521063082c46455c2fd5483811f9520a748f0099c1dfcfa52c54e1c22b5cdf70efb0f3c676",
        64,
      )
    ];
    for (var item in tests) {
      test(
          'For ikm(${item.ikm}), salt(${item.salt}), info(${item.info}), prkExpected(${item.prkExpected}), okmExpected(${item.okmExpected})',
          () {
        var salt = const HexDecoder().convert(item.salt);
        var ikm = const HexDecoder().convert(item.ikm);
        var info = const HexDecoder().convert(item.info);
        var prkExpected = const HexDecoder().convert(item.prkExpected);
        var okmExpected = const HexDecoder().convert(item.okmExpected);
        var prk = extract(salt, ikm);
        var okm = expand(item.L, prk, info);
        expect(prkExpected.length == 32, isTrue);
        expect(item.L == okmExpected.length, isTrue);
        expect(bytesEqual(prk, prkExpected), isTrue);
        expect(bytesEqual(okm, okmExpected), isTrue);
      });
    }
  });

  group('eip2333', () {
    List<Eip2333In> tests = [
      Eip2333In(
          "3141592653589793238462643383279502884197169399375105820974944592",
          "4ff5e145590ed7b71e577bb04032396d1619ff41cb4e350053ed2dce8d1efd1c",
          "5c62dcf9654481292aafa3348f1d1b0017bbfb44d6881d26d2b17836b38f204d",
          3141592653),
      Eip2333In(
          "0099FF991111002299DD7744EE3355BBDD8844115566CC55663355668888CC00",
          "1ebd704b86732c3f05f30563dee6189838e73998ebc9c209ccff422adee10c4b",
          "1b98db8b24296038eae3f64c25d693a269ef1e4d7ae0f691c572a46cf3c0913c",
          4294967295),
      Eip2333In(
        "d4e56740f876aef8c010b86a40d5f56745a118d0906a34e69aec8c0db1cb8fa3",
        "614d21b10c0e4996ac0608e0e7452d5720d95d20fe03c59a3321000a42432e1a",
        "08de7136e4afc56ae3ec03b20517d9c1232705a747f588fd17832f36ae337526",
        42,
      ),
      Eip2333In(
          "c55257c360c07c72029aebc1b53c05ed0362ada38ead3e3e9efa3708e53495531f09a6987599d18264c1e1c92f2cf141630c7a3c4ab7c81b2f001698e7463b04",
          "0befcabff4a664461cc8f190cdd51c05621eb2837c71a1362df5b465a674ecfb",
          "1a1de3346883401f1e3b2281be5774080edb8e5ebe6f776b0f7af9fea942553a",
          0)
    ];
    for (var item in tests) {
      test(
          'For seed(${item.seed}), masterSk(${item.masterSk}), childSk(${item.childSk}), childIndex(${item.childIndex})',
          () {
        var seed = const HexDecoder().convert(item.seed);
        var master = BasicSchemeMPL.keyGen(seed);
        var child = BasicSchemeMPL.deriveChildSk(master, item.childIndex);
        expect(master.toBytes().length == 32, isTrue);
        expect(child.toBytes().length == 32, isTrue);
        expect(bytesEqual(master.toBytes(), const HexDecoder().convert(item.masterSk)), isTrue);
        expect(bytesEqual(child.toBytes(), const HexDecoder().convert(item.childSk)), isTrue);
      });
    }
  });

  group('Fields', () {
    var seventeen = BigInt.from(17);
    var a = Fq(seventeen, BigInt.from(30));
    var b = Fq(seventeen, BigInt.from(-18));
    var c = Fq2(seventeen, [a, b]);
    var d = Fq2(seventeen, [a + a, Fq(seventeen, BigInt.from(-5))]);
    var e = c * d;
    var f = e * d;
    test('Multiplication', () => expect(f == e, isFalse));
    var e_sq = e * e as Fq2;
    var e_sqrt = e_sq.modSqrt();
    test('Square and Root', () => expect(e_sqrt.pow(BigInt.two) == e_sq, isTrue));
    var a2 = Fq(
      BigInt.parse('172487123095712930573140951348'),
      BigInt.parse('3012492130751239573498573249085723940848571098237509182375'),
    );
    var b2 = Fq(BigInt.parse('172487123095712930573140951348'),
        BigInt.parse('3432984572394572309458723045723849'));
    var c2 = Fq2(BigInt.parse('172487123095712930573140951348'), [a2, b2]);
    test('Inequality', () => expect(b2 == c2, isFalse));
    var g = Fq6(seventeen, [c, d, d * d * c]);
    var h = Fq6(seventeen, [a + a * c, c * b * a, b * b * d * Fq(seventeen, BigInt.from(21))]);
    var i = Fq12(seventeen, [g, h]);
    test('Double Negation', () => expect(~(~i) == i, isTrue));
    test('Inverse Root Identity', () => expect(~i.root * i.root == Fq6.one(seventeen), isTrue));
    var x = Fq12(seventeen, [Fq6.zero(seventeen), i.root]);
    test('Inverse Identity', () => expect(~x * x == Fq12.one(seventeen), isTrue));
    var j = Fq6(seventeen, [a + a * c, Fq2.zero(seventeen), Fq2.zero(seventeen)]);
    var j2 = Fq6(seventeen, [a + a * c, Fq2.zero(seventeen), Fq2.one(seventeen)]);
    test('Extension Equaliy', () {
      expect(j == (a + a * c), isTrue);
      expect(j2 == (a + a * c), isFalse);
      expect(j == j2, isFalse);
    });
    test('Frob Coeffs', () {
      var one = Fq(defaultEc.q, BigInt.one);
      var two = one + one;
      var a3 = Fq2(defaultEc.q, [two, two]);
      var b3 = Fq6(defaultEc.q, [a3, a3, a3]);
      var c3 = Fq12(defaultEc.q, [b3, b3]);
      for (var base in [a3, b3, c3]) {
        for (var expo in range(1, base.extension)) {
          expect(base.qiPower(expo.toInt()) == base.pow(defaultEc.q.pow(expo.toInt())), isTrue);
        }
      }
    });
  });

  group('Elliptic Curve', () {
    var five = BigInt.from(5);
    var three = BigInt.from(3);
    var q = defaultEc.q;
    var g = JacobianPoint.generateG1();
    test('G1 Multiplication', () {
      expect(g.isOnCurve, isTrue);
      expect(g * BigInt.two == g + g, isTrue);
      expect((g * three).isOnCurve, isTrue);
      expect(g * three == g + g + g, isTrue);
    });
    var g2 = JacobianPoint.generateG2();
    test('Commutative', () {
      expect(g2.x * (Fq(q, BigInt.two) * g2.y) == Fq(q, BigInt.two) * (g2.x * g2.y), isTrue);
      expect(g2.isOnCurve, isTrue);
    });
    var s = g2 + g2;
    test('Twist', () {
      expect(s.toAffine().twist().untwist() == s.toAffine(), isTrue);
      expect((s.toAffine().twist() * five).untwist() == (s * five).toAffine(), isTrue);
      expect(s.toAffine().twist() * five == (s * five).toAffine().twist(), isTrue);
    });
    test('G2 Multiplication', () {
      expect(s.isOnCurve, isTrue);
      expect(g2.isOnCurve, isTrue);
      expect(g2 + g2 == g2 * BigInt.two, isTrue);
      expect(g2 * five == (g2 * BigInt.two) + (g2 * BigInt.two) + g2, isTrue);
    });
    var y = yForX(g2.x, ec: defaultEcTwist);
    test('Y For X', () {
      expect(y == g2.y || -y == g2.y, isTrue);
    });
    var g_j = JacobianPoint.generateG1();
    var g2_j = JacobianPoint.generateG2();
    var g2_j2 = JacobianPoint.generateG2() * BigInt.two;
    test('Conversions', () {
      expect(g.toAffine().toJacobian() == g, isTrue);
      expect((g_j * BigInt.two).toAffine() == g.toAffine() * BigInt.two, isTrue);
      expect((g2_j + g2_j2).toAffine() == g2.toAffine() * three, isTrue);
    });
  });

  test('Edge Case Sign Fq2', () {
    var q = defaultEc.q;
    var a = Fq(q, BigInt.from(62323));
    var testCase1 = Fq2(q, [a, Fq(q, BigInt.zero)]);
    var testCase2 = Fq2(q, [-a, Fq(q, BigInt.zero)]);
    expect(signFq2(testCase1) != signFq2(testCase2), isTrue);
    var testCase3 = Fq2(q, [Fq(q, BigInt.zero), a]);
    var testCase4 = Fq2(q, [Fq(q, BigInt.zero), -a]);
    expect(signFq2(testCase3) != signFq2(testCase4), isTrue);
  });

  test('XMD', () {
    var msg = randomBytes(48);
    var dst = randomBytes(16);
    Map<List<int>, int> ress = {};
    for (var lengthNum in range(16, 8192)) {
      var length = lengthNum.toInt();
      var result = expandMessageXmd(msg, dst, length, sha512);
      expect(length == result.length, isTrue);
      var key = result.sublist(0, 16);
      ress[key] = (ress[key] ?? 0) + 1;
    }
    for (var item in ress.values) {
      expect(item == 1, isTrue);
    }
  });

  test('SWU', () {
    var dst_1 = utf8.encode("QUUX-V01-CS02-with-BLS12381G2_XMD:SHA-256_SSWU_RO_");
    var msg_1 = utf8.encode('abcdef0123456789');
    var res = g2Map(msg_1, dst_1).toAffine();
    expect(
        ((res.x as Fq2).elements[0] as Fq).value ==
            BigInt.parse(
                '0x121982811D2491FDE9BA7ED31EF9CA474F0E1501297F68C298E9F4C0028ADD35AEA8BB83D53C08CFC007C1E005723CD0'),
        isTrue);
    expect(
        ((res.x as Fq2).elements[1] as Fq).value ==
            BigInt.parse(
                '0x190D119345B94FBD15497BCBA94ECF7DB2CBFD1E1FE7DA034D26CBBA169FB3968288B3FAFB265F9EBD380512A71C3F2C'),
        isTrue);
    expect(
        ((res.y as Fq2).elements[0] as Fq).value ==
            BigInt.parse(
                '0x05571A0F8D3C08D094576981F4A3B8EDA0A8E771FCDCC8ECCEAF1356A6ACF17574518ACB506E435B639353C2E14827C8'),
        isTrue);
    expect(
        ((res.y as Fq2).elements[1] as Fq).value ==
            BigInt.parse(
                '0x0BB5E7572275C567462D91807DE765611490205A941A5A6AF3B1691BFE596C31225D3AABDF15FAFF860CB4EF17C7C3BE'),
        isTrue);
  });

  group('Elements', () {
    var i1 = bytesToBigInt([1, 2], Endian.big);
    var i2 = bytesToBigInt([3, 1, 4, 1, 5, 9], Endian.big);
    var b1 = i1;
    var b2 = i2;
    var g1 = JacobianPoint.generateG1();
    var g2 = JacobianPoint.generateG2();
    var u1 = JacobianPoint.infinityG1();
    var u2 = JacobianPoint.infinityG2();
    var x1 = g1 * b1;
    var x2 = g1 * b2;
    var y1 = g2 * b1;
    var y2 = g2 * b2;
    test('G1 Multiplication Equality', () {
      expect(x1 == x2, isFalse);
      expect(x1 * b1 == x1 * b1, isTrue);
      expect(x1 * b1 == x1 * b2, isFalse);
    });
    var left = x1 + u1;
    var right = x1;
    test('G1 Addition Equality', () {
      expect(left == right, isTrue);
      expect(x1 + x2 == x2 + x1, isTrue);
      expect(x1 + -x1 == u1, isTrue);
      expect(x1 == JacobianPoint.fromBytesG1(x1.toBytes()), isTrue);
    });
    var copy = x1.clone();
    test('G1 Copy', () {
      expect(x1 == copy, isTrue);
      x1 += x2;
      expect(x1 == copy, isFalse);
    });
    test('G2 Multiplication Equality', () {
      expect(y1 == y2, isFalse);
      expect(y1 * b1 == y1 * b1, isTrue);
      expect(y1 * b1 == y1 * b2, isFalse);
    });
    test('G2 Addition Equality', () {
      expect(y1 + u2 == y1, isTrue);
      expect(y1 + y2 == y2 + y1, isTrue);
      expect(y1 + -y1 == u2, isTrue);
      expect(y1 == JacobianPoint.fromBytesG2(y1.toBytes()), isTrue);
    });
    var copy2 = y1.clone();
    test('G2 Copy', () {
      expect(y1 == copy2, isTrue);
      y1 += y2;
      expect(y1 == copy2, isFalse);
    });
    var pair = atePairing(x1, y1);
    test('Ate Pairing', () {
      expect(pair == atePairing(x1, y2), isFalse);
      expect(pair == atePairing(x2, y1), isFalse);
      var copy3 = pair.clone();
      expect(pair == copy3, isTrue);
      var sk = BigInt.parse('728934712938472938472398074');
      var pk = g1 * sk;
      var Hm = y2 * BigInt.from(12371928312) + y2 * BigInt.parse('12903812903891023');
      var sig = Hm * sk;
      expect(atePairing(g1, sig) == atePairing(pk, Hm), isTrue);
    });
  });

  group('Chia Vectors 1', () {
    var seed1 = List.filled(32, 0x00);
    var seed2 = List.filled(32, 0x01);
    var msg1 = [7, 8, 9];
    var msg2 = [10, 11, 12];
    var sk1 = BasicSchemeMPL.keyGen(seed1);
    var sk2 = BasicSchemeMPL.keyGen(seed2);
    test('Private and Public Key', () {
      expect(sk1.toHex() == '4a353be3dac091a0a7e640620372f5e1e2e4401717c1e79cac6ffba8f6905604',
          isTrue);
      expect(
          sk1.getG1().toHex() ==
              '85695fcbc06cc4c4c9451f4dce21cbf8de3e5a13bf48f44cdbb18e2038ba7b8bb1632d7911ef1e2e08749bddbf165352',
          isTrue);
    });
    var sig1 = BasicSchemeMPL.sign(sk1, msg1);
    var sig2 = BasicSchemeMPL.sign(sk2, msg2);
    test('Signatures', () {
      expect(
          sig1.toHex() ==
              'b8faa6d6a3881c9fdbad803b170d70ca5cbf1e6ba5a586262df368c75acd1d1ffa3ab6ee21c71f844494659878f5eb230c958dd576b08b8564aad2ee0992e85a1e565f299cd53a285de729937f70dc176a1f01432129bb2b94d3d5031f8065a1',
          isTrue);
      expect(
          sig2.toHex() ==
              'a9c4d3e689b82c7ec7e838dac2380cb014f9a08f6cd6ba044c263746e39a8f7a60ffee4afb78f146c2e421360784d58f0029491e3bd8ab84f0011d258471ba4e87059de295d9aba845c044ee83f6cf2411efd379ef38bf4cf41d5f3c0ae1205d',
          isTrue);
    });
    var aggSig1 = BasicSchemeMPL.aggregate([sig1, sig2]);
    test('Aggregated Signature 1', () {
      expect(
          aggSig1.toHex() ==
              'aee003c8cdaf3531b6b0ca354031b0819f7586b5846796615aee8108fec75ef838d181f9d244a94d195d7b0231d4afcf06f27f0cc4d3c72162545c240de7d5034a7ef3a2a03c0159de982fbc2e7790aeb455e27beae91d64e077c70b5506dea3',
          isTrue);
      expect(BasicSchemeMPL.aggregateVerify([sk1.getG1(), sk2.getG1()], [msg1, msg2], aggSig1),
          isTrue);
    });
    var msg3 = [1, 2, 3];
    var msg4 = [1, 2, 3, 4];
    var msg5 = [1, 2];
    var sig3 = BasicSchemeMPL.sign(sk1, msg3);
    var sig4 = BasicSchemeMPL.sign(sk1, msg4);
    var sig5 = BasicSchemeMPL.sign(sk2, msg5);
    var aggSig2 = BasicSchemeMPL.aggregate([sig3, sig4, sig5]);
    test('Aggregated Signature 2', () {
      expect(
          aggSig2.toHex() ==
              'a0b1378d518bea4d1100adbc7bdbc4ff64f2c219ed6395cd36fe5d2aa44a4b8e710b607afd965e505a5ac3283291b75413d09478ab4b5cfbafbeea366de2d0c0bcf61deddaa521f6020460fd547ab37659ae207968b545727beba0a3c5572b9c',
          isTrue);
      expect(
          BasicSchemeMPL.aggregateVerify(
              [sk1.getG1(), sk1.getG1(), sk2.getG1()], [msg3, msg4, msg5], aggSig2),
          isTrue);
    });
  });

  test('Chia Vectors 3', () {
    var seed1 = List.filled(32, 0x04);
    var sk1 = PopSchemeMPL.keyGen(seed1);
    var proof = PopSchemeMPL.popProve(sk1);
    expect(
        proof.toHex() ==
            "84f709159435f0dc73b3e8bf6c78d85282d19231555a8ee3b6e2573aaf66872d9203fefa1ef"
                "700e34e7c3f3fb28210100558c6871c53f1ef6055b9f06b0d1abe22ad584ad3b957f3018a8f5"
                "8227c6c716b1e15791459850f2289168fa0cf9115",
        isTrue);
  });

  test('Pyecc Vectors', () {
    var ref_sig1Basic =
        "\x96\xba4\xfa\xc3<\x7f\x12\x9d`*\x0b\xc8\xa3\xd4?\x9a\xbc\x01N\xce\xaa\xb75\x91F\xb4\xb1P\xe5{\x80\x86Es\x8f5g\x1e\x9e\x10\xe0\xd8b\xa3\x0c\xabp\x07N\xb5\x83\x1d\x13\xe6\xa5\xb1b\xd0\x1e\xeb\xe6\x87\xd0\x16J\xdb\xd0\xa8d7\n|\"*'h\xd7pM\xa2T\xf1\xbf\x18#f[\xc26\x1f\x9d\xd8\xc0\x0e\x99"
            .codeUnits;
    var ref_sig2Basic =
        '\xa4\x02y\t2\x13\x0fvj\xf1\x1b\xa7\x16Sf\x83\xd8\xc4\xcf\xa5\x19G\xe4\xf9\x08\x1f\xed\xd6\x92\xd6\xdc\x0c\xac[\x90K\xee^\xa6\xe2Ui\xe3m{\xe4\xcaY\x06\x9a\x96\xe3K\x7fp\x07X\xb7\x16\xf9IJ\xaaY\xa9nt\xd1J;U*\x9ak\xc1)\xe7\x17\x19[\x9d`\x06\xfdm\\\xefGh\xc0"\xe0\xf71j\xbf'
            .codeUnits;
    var ref_sigABasic =
        "\x98|\xfd;\xcdb(\x02\x87\x02t\x83\xf2\x9cU\$^\xd81\xf5\x1d\xd6\xbd\x99\x9ao\xf1\xa1\xf1\xf1\xf0\xb6Gw\x8b\x01g5\x9cqPUX\xa7n\x15\x8ef\x18\x1e\xe5\x12Y\x05\xa6B\$k\x01\xe7\xfa^\xe5=h\xa4\xfe\x9b\xfb)\xa8\xe2f\x01\xf0\xb9\xadW}\xdd\x18\x87js1|!n\xa6\x1fC\x04\x14\xecQ\xc5"
            .codeUnits;
    var ref_sig1Aug =
        '\x81\x80\xf0,\xcbr\xe9"\xb1R\xfc\xed\xbe\x0e\x1d\x19R\x105Opp6X\xe8\xe0\x8c\xbe\xbf\x11\xd4\x97\x0e\xabj\xc3\xcc\xf7\x15\xf3\xfb\x87m\xf9\xa9yz\xbd\x0c\x1a\xf6\x1a\xae\xad\xc9,,\xfe\\\nV\xc1F\xcc\x8c?qQ\xa0s\xcf_\x16\xdf8\$g\$\xc4\xae\xd7?\xf3\x0e\xf5\xda\xa6\xaa\xca\xed\x1a&\xec\xaa3k'
            .codeUnits;
    var ref_sig2Aug =
        '\x99\x11\x1e\xea\xfbA-\xa6\x1eL7\xd3\xe8\x06\xc6\xfdj\xc9\xf3\x87\x0eT\xda\x92"\xbaNIH"\xc5\xb7eg1\xfazdY4\xd0KU\x9e\x92a\xb8b\x01\xbb\xeeW\x05RP\xa4Y\xa2\xda\x10\xe5\x1f\x9c\x1aiA)\x7f\xfc]\x97\nUr6\xd0\xbd\xeb|\xf8\xff\x18\x80\x0b\x08c8q\xa0\xf0\xa7\xeaB\xf4t\x80'
            .codeUnits;
    var ref_sigAAug =
        "\x8c]\x03\xf9\xda\xe7~\x19\xa5\x94Z\x06\xa2\x14\x83n\xdb\x8e\x03\xb8QR]\x84\xb9\xded@\xe6\x8f\xc0\xcas\x03\xee\xed9\r\x86<\x9bU\xa8\xcfmY\x14\n\x01\xb5\x88G\x88\x1e\xb5\xafgsMD\xb2UVF\xc6al9\xab\x88\xd2S)\x9a\xcc\x1e\xb1\xb1\x9d\xdb\x9b\xfc\xbev\xe2\x8a\xdd\xf6q\xd1\x16\xc0R\xbb\x18G"
            .codeUnits;
    var ref_sig1Pop =
        "\x95P\xfbN\x7f~\x8c\xc4\xa9\x0b\xe8V\n\xb5\xa7\x98\xb0\xb20\x00\xb6\xa5J!\x17R\x02\x10\xf9\x86\xf3\xf2\x81\xb3v\xf2Y\xc0\xb7\x80b\xd1\xeb1\x92\xb3\xd9\xbb\x04\x9fY\xec\xc1\xb0:pI\xebf^\r\xf3d\x94\xaeL\xb5\xf1\x13l\xca\xee\xfc\x99X\xcb0\xc33==C\xf0qH\xc3\x86)\x9a{\x1b\xfc\r\xc5\xcf|"
            .codeUnits;
    var ref_sig2Pop =
        "\xa6\x906\xbc\x11\xae^\xfc\xbfa\x80\xaf\xe3\x9a\xdd\xde~'s\x1e\xc4\x02W\xbf\xdc<7\xf1{\x8d\xf6\x83\x06\xa3N\xbd\x10\xe9\xe3*5%7P\xdf\\\x87\xc2\x14/\x82\x07\xe8\xd5eG\x12\xb4\xe5T\xf5\x85\xfbhF\xff8\x04\xe4)\xa9\xf8\xa1\xb4\xc5ku\xd0\x86\x9e\xd6u\x80\xd7\x89\x87\x0b\xab\xe2\xc7\xc8\xa9\xd5\x1e{*"
            .codeUnits;
    var ref_sigAPop =
        "\xa4\xeat+\xcd\xc1U>\x9c\xa4\xe5`\xbe~^ln\xfajd\xdd\xdf\x9c\xa3\xbb(T#=\x85\xa6\xaa\xc1\xb7n\xc7\xd1\x03\xdbN3\x14\x8b\x82\xaf\x99#\xdb\x05\x93Jn\xce\x9aq\x01\xcd\x8a\x9dG\xce'\x97\x80V\xb0\xf5\x90\x00!\x81\x8cEi\x8a\xfd\xd6\xcf\x8ako\x7f\xee\x1f\x0bCqoU\xe4\x13\xd4\xb8z`9"
            .codeUnits;
    var secret1 = List.filled(32, 1);
    var secret2 = List.generate(32, (index) => index * 314159 % 256);
    var sk1 = PrivateKey.fromBytes(secret1);
    var sk2 = PrivateKey.fromBytes(secret2);
    var msg = [3, 1, 4, 1, 5, 9];
    var sig1Basic = BasicSchemeMPL.sign(sk1, msg);
    var sig2Basic = BasicSchemeMPL.sign(sk2, msg);
    var sigABasic = BasicSchemeMPL.aggregate([sig1Basic, sig2Basic]);
    var sig1Aug = AugSchemeMPL.sign(sk1, msg);
    var sig2Aug = AugSchemeMPL.sign(sk2, msg);
    var sigAAug = AugSchemeMPL.aggregate([sig1Aug, sig2Aug]);
    var sig1Pop = PopSchemeMPL.sign(sk1, msg);
    var sig2Pop = PopSchemeMPL.sign(sk2, msg);
    var sigAPop = PopSchemeMPL.aggregate([sig1Pop, sig2Pop]);
    expect(sig1Basic.toBytes(), equals(ref_sig1Basic));
    expect(sig2Basic.toBytes(), equals(ref_sig2Basic));
    expect(sigABasic.toBytes(), equals(ref_sigABasic));
    expect(sig1Aug.toBytes(), equals(ref_sig1Aug));
    expect(sig2Aug.toBytes(), equals(ref_sig2Aug));
    expect(sigAAug.toBytes(), equals(ref_sigAAug));
    expect(sig1Pop.toBytes(), equals(ref_sig1Pop));
    expect(sig2Pop.toBytes(), equals(ref_sig2Pop));
    expect(sigAPop.toBytes(), equals(ref_sigAPop));
  });

  group('Invalid Vectors', () {
    var invalidInputs1 = [
      "c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      "c00000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000",
      "3a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa",
      "7a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa",
      "fa0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa",
      "9a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaa",
      "9a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaaaa",
      "9a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa",
      "9a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab",
    ];
    var invalidInputs2 = [
      "c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      "c00000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      "c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000",
      "3a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      "7a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      "fa0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      "9a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      "9a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      "9a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaa7",
      "9a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      "9a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab",
    ];
    for (var s in invalidInputs1) {
      test('G1 $s', () {
        var bytes = const HexDecoder().convert(s);
        expect(() {
          assert(JacobianPoint.fromBytesG1(bytes).isValid);
        }, throwsA(isA<dynamic>()));
      });
    }
    for (var s in invalidInputs2) {
      test('G2 $s', () {
        var bytes = const HexDecoder().convert(s);
        expect(() {
          assert(JacobianPoint.fromBytesG2(bytes).isValid);
        }, throwsA(isA<dynamic>()));
      });
    }
  });

  group('Readme', () {
    var seed = [
      0,
      50,
      6,
      244,
      24,
      199,
      1,
      25,
      52,
      88,
      192,
      19,
      18,
      12,
      89,
      6,
      220,
      18,
      102,
      58,
      209,
      82,
      12,
      62,
      89,
      110,
      182,
      9,
      44,
      20,
      254,
      22,
    ];
    var sk = AugSchemeMPL.keyGen(seed);
    var pk = sk.getG1();
    var message = [1, 2, 3, 4, 5];
    var signature = AugSchemeMPL.sign(sk, message);
    test('AugSchemeMPL Verify', () => expect(AugSchemeMPL.verify(pk, message, signature), isTrue));
    var sk_bytes = sk.toBytes();
    var pk_bytes = pk.toBytes();
    var signature_bytes = signature.toBytes();
    var skFromBytes = PrivateKey.fromBytes(sk_bytes);
    var pkFromBytes = JacobianPoint.fromBytesG1(pk_bytes);
    var signatureFromBytes = JacobianPoint.fromBytesG2(signature_bytes);
    test('From Bytes', () {
      expect(sk == skFromBytes, isTrue);
      expect(pk == pkFromBytes, isTrue);
      expect(signature == signatureFromBytes, isTrue);
    });
    var seed1 = [1] + seed.sublist(1);
    var sk1 = AugSchemeMPL.keyGen(seed1);
    var seed2 = [2] + seed.sublist(1);
    var sk2 = AugSchemeMPL.keyGen(seed2);
    var message2 = [1, 2, 3, 4, 5, 6, 7];
    var pk1 = sk1.getG1();
    var sig1 = AugSchemeMPL.sign(sk1, message);
    var pk2 = sk2.getG1();
    var sig2 = AugSchemeMPL.sign(sk2, message2);
    var agg_sig = AugSchemeMPL.aggregate([sig1, sig2]);
    test(
        'AugSchemeMPL Aggregate Verify 1',
        () =>
            expect(AugSchemeMPL.aggregateVerify([pk1, pk2], [message, message2], agg_sig), isTrue));
    var seed3 = [3] + seed.sublist(1);
    var sk3 = AugSchemeMPL.keyGen(seed3);
    var pk3 = sk3.getG1();
    var message3 = [100, 2, 254, 88, 90, 45, 23];
    var sig3 = AugSchemeMPL.sign(sk3, message3);
    var agg_sig_final = AugSchemeMPL.aggregate([agg_sig, sig3]);
    test(
        'AugSchemeMPL Aggregate Verify 2',
        () => expect(
            AugSchemeMPL.aggregateVerify(
                [pk1, pk2, pk3], [message, message2, message3], agg_sig_final),
            isTrue));
    var pop_sig1 = PopSchemeMPL.sign(sk1, message);
    var pop_sig2 = PopSchemeMPL.sign(sk2, message);
    var pop_sig3 = PopSchemeMPL.sign(sk3, message);
    var pop1 = PopSchemeMPL.popProve(sk1);
    var pop2 = PopSchemeMPL.popProve(sk2);
    var pop3 = PopSchemeMPL.popProve(sk3);
    test('PopSchemeMPL Prove', () {
      expect(PopSchemeMPL.popVerify(pk1, pop1), isTrue);
      expect(PopSchemeMPL.popVerify(pk2, pop2), isTrue);
      expect(PopSchemeMPL.popVerify(pk3, pop3), isTrue);
    });
    var pop_sig_agg = PopSchemeMPL.aggregate([pop_sig1, pop_sig2, pop_sig3]);
    test(
        'PopSchemeMPL Fast Aggregate Verify',
        () => expect(
            PopSchemeMPL.fastAggregateVerify([pk1, pk2, pk3], message, pop_sig_agg), isTrue));
    var pop_agg_pk = pk1 + pk2 + pk3;
    test('PopSchemeMPL Verify',
        () => expect(PopSchemeMPL.verify(pop_agg_pk, message, pop_sig_agg), isTrue));
    var pop_agg_sk = PrivateKey.aggregate([sk1, sk2, sk3]);
    test('PopSchemeMPL Aggregate Sign',
        () => expect(PopSchemeMPL.sign(pop_agg_sk, message) == pop_sig_agg, isTrue));
    var master_sk = AugSchemeMPL.keyGen(seed);
    var child = AugSchemeMPL.deriveChildSk(master_sk, 152);
    AugSchemeMPL.deriveChildSk(child, 952);
    var master_pk = master_sk.getG1();
    var child_u = AugSchemeMPL.deriveChildSkUnhardened(master_sk, 22);
    var grandchild_u = AugSchemeMPL.deriveChildSkUnhardened(child_u, 0);
    var child_u_pk = AugSchemeMPL.deriveChildPkUnhardened(master_pk, 22);
    var grandchild_u_pk = AugSchemeMPL.deriveChildPkUnhardened(child_u_pk, 0);
    test('AugSchemeMPL Child Keys', () => expect(grandchild_u_pk == grandchild_u.getG1(), isTrue));
  });

  test('Current', () {
    var seed = [
      0,
      50,
      6,
      244,
      24,
      199,
      1,
      25,
      52,
      88,
      192,
      19,
      18,
      12,
      89,
      6,
      220,
      18,
      102,
      58,
      209,
      82,
      12,
      62,
      89,
      110,
      182,
      9,
      44,
      20,
      254,
      22,
    ];
    var sk = AugSchemeMPL.keyGen(seed);
    var pk = sk.getG1();
    var message = [1, 2, 3, 4, 5];
    var signature = AugSchemeMPL.sign(sk, message);
    expect(AugSchemeMPL.verify(pk, message, signature), isTrue);
  });
}
