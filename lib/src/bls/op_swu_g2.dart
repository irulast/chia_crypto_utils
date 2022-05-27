// ignore_for_file: non_constant_identifier_names

import 'package:chia_crypto_utils/src/bls/bls12381.dart';
import 'package:chia_crypto_utils/src/bls/ec/ec.dart';
import 'package:chia_crypto_utils/src/bls/ec/jacobian_point.dart';
import 'package:chia_crypto_utils/src/bls/field/extensions/fq2.dart';
import 'package:chia_crypto_utils/src/bls/field/field_base.dart';
import 'package:chia_crypto_utils/src/bls/field/field_constants.dart';
import 'package:chia_crypto_utils/src/bls/hash_to_field.dart';

List<Fq2> xnum = [
  Fq2(
    q,
    [
      Fq(
        q,
        BigInt.parse(
          '0x5C759507E8E333EBB5B7A9A47D7ED8532C52D39FD3A042A88B58423C50AE15D5C2638E343D9C71C6238AAAAAAAA97D6',
        ),
      ),
      Fq(
        q,
        BigInt.parse(
          '0x5C759507E8E333EBB5B7A9A47D7ED8532C52D39FD3A042A88B58423C50AE15D5C2638E343D9C71C6238AAAAAAAA97D6',
        ),
      )
    ],
  ),
  Fq2(
    q,
    [
      Fq(q, BigInt.zero),
      Fq(
        q,
        BigInt.parse(
          '0x11560BF17BAA99BC32126FCED787C88F984F87ADF7AE0C7F9A208C6B4F20A4181472AAA9CB8D555526A9FFFFFFFFC71A',
        ),
      )
    ],
  ),
  Fq2(
    q,
    [
      Fq(
        q,
        BigInt.parse(
          '0x11560BF17BAA99BC32126FCED787C88F984F87ADF7AE0C7F9A208C6B4F20A4181472AAA9CB8D555526A9FFFFFFFFC71E',
        ),
      ),
      Fq(
        q,
        BigInt.parse(
          '0x8AB05F8BDD54CDE190937E76BC3E447CC27C3D6FBD7063FCD104635A790520C0A395554E5C6AAAA9354FFFFFFFFE38D',
        ),
      )
    ],
  ),
  Fq2(
    q,
    [
      Fq(
        q,
        BigInt.parse(
          '0x171D6541FA38CCFAED6DEA691F5FB614CB14B4E7F4E810AA22D6108F142B85757098E38D0F671C7188E2AAAAAAAA5ED1',
        ),
      ),
      Fq(q, BigInt.zero)
    ],
  ),
];

List<Fq2> xden = [
  Fq2(
    q,
    [
      Fq(q, BigInt.zero),
      Fq(
        q,
        BigInt.parse(
          '0x1A0111EA397FE69A4B1BA7B6434BACD764774B84F38512BF6730D2A0F6B0F6241EABFFFEB153FFFFB9FEFFFFFFFFAA63',
        ),
      )
    ],
  ),
  Fq2(
    q,
    [
      Fq(q, BigInt.from(0xC)),
      Fq(
        q,
        BigInt.parse(
          '0x1A0111EA397FE69A4B1BA7B6434BACD764774B84F38512BF6730D2A0F6B0F6241EABFFFEB153FFFFB9FEFFFFFFFFAA9F',
        ),
      )
    ],
  ),
  Fq2(q, [Fq(q, BigInt.one), Fq(q, BigInt.zero)]),
];

List<Fq2> ynum = [
  Fq2(q, [
    Fq(
      q,
      BigInt.parse(
        '0x1530477C7AB4113B59A4C18B076D11930F7DA5D4A07F649BF54439D87D27E500FC8C25EBF8C92F6812CFC71C71C6D706',
      ),
    ),
    Fq(
      q,
      BigInt.parse(
        '0x1530477C7AB4113B59A4C18B076D11930F7DA5D4A07F649BF54439D87D27E500FC8C25EBF8C92F6812CFC71C71C6D706',
      ),
    ),
  ]),
  Fq2(q, [
    Fq(q, BigInt.zero),
    Fq(
      q,
      BigInt.parse(
        '0x5C759507E8E333EBB5B7A9A47D7ED8532C52D39FD3A042A88B58423C50AE15D5C2638E343D9C71C6238AAAAAAAA97BE',
      ),
    ),
  ]),
  Fq2(q, [
    Fq(
      q,
      BigInt.parse(
        '0x11560BF17BAA99BC32126FCED787C88F984F87ADF7AE0C7F9A208C6B4F20A4181472AAA9CB8D555526A9FFFFFFFFC71C',
      ),
    ),
    Fq(
      q,
      BigInt.parse(
        '0x8AB05F8BDD54CDE190937E76BC3E447CC27C3D6FBD7063FCD104635A790520C0A395554E5C6AAAA9354FFFFFFFFE38F',
      ),
    ),
  ]),
  Fq2(q, [
    Fq(
      q,
      BigInt.parse(
        '0x124C9AD43B6CF79BFBF7043DE3811AD0761B0F37A1E26286B0E977C69AA274524E79097A56DC4BD9E1B371C71C718B10',
      ),
    ),
    Fq(q, BigInt.zero),
  ]),
];

List<Fq2> yden = [
  Fq2(q, [
    Fq(
      q,
      BigInt.parse(
        '0x1A0111EA397FE69A4B1BA7B6434BACD764774B84F38512BF6730D2A0F6B0F6241EABFFFEB153FFFFB9FEFFFFFFFFA8FB',
      ),
    ),
    Fq(
      q,
      BigInt.parse(
        '0x1A0111EA397FE69A4B1BA7B6434BACD764774B84F38512BF6730D2A0F6B0F6241EABFFFEB153FFFFB9FEFFFFFFFFA8FB',
      ),
    ),
  ]),
  Fq2(q, [
    Fq(q, BigInt.zero),
    Fq(
      q,
      BigInt.parse(
        '0x1A0111EA397FE69A4B1BA7B6434BACD764774B84F38512BF6730D2A0F6B0F6241EABFFFEB153FFFFB9FEFFFFFFFFA9D3',
      ),
    ),
  ]),
  Fq2(
    q,
    [
      Fq(q, BigInt.from(0x12)),
      Fq(
        q,
        BigInt.parse(
          '0x1A0111EA397FE69A4B1BA7B6434BACD764774B84F38512BF6730D2A0F6B0F6241EABFFFEB153FFFFB9FEFFFFFFFFAA99',
        ),
      )
    ],
  ),
  Fq2(q, [Fq(q, BigInt.one), Fq(q, BigInt.zero)]),
];

BigInt sgn0(Fq2 x) {
  final sign0 = (x.elements[0] as Fq).value % BigInt.two == BigInt.one;
  final zero0 = (x.elements[0] as Fq).value == BigInt.zero;
  final sign1 = (x.elements[1] as Fq).value % BigInt.two == BigInt.one;
  return sign0 || (zero0 && sign1) ? BigInt.one : BigInt.zero;
}

final xi_2 = Fq2(q, [Fq(q, -BigInt.two), Fq(q, -BigInt.one)]);
final Ell2p_a = Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.from(240))]);
final Ell2p_b = Fq2(q, [Fq(q, BigInt.from(1012)), Fq(q, BigInt.from(1012))]);
final ev1 = BigInt.parse(
  '0x699BE3B8C6870965E5BF892AD5D2CC7B0E85A117402DFD83B7F4A947E02D978498255A2AAEC0AC627B5AFBDF1BF1C90',
);
final ev2 = BigInt.parse(
  '0x8157CD83046453F5DD0972B6E3949E4288020B5B8A9CC99CA07E27089A2CE2436D965026ADAD3EF7BABA37F2183E9B5',
);
final ev3 = BigInt.parse(
  '0xAB1C2FFDD6C253CA155231EB3E71BA044FD562F6F72BC5BAD5EC46A0B7A3B0247CF08CE6C6317F40EDBC653A72DEE17',
);
final ev4 = BigInt.parse(
  '0xAA404866706722864480885D68AD0CCAC1967C7544B447873CC37E0181271E006DF72162A3D3E0287BF597FBF7F8FC1',
);
final etas = [
  Fq2(q, [Fq(q, ev1), Fq(q, ev2)]),
  Fq2(q, [Fq(q, q - ev2), Fq(q, ev1)]),
  Fq2(q, [Fq(q, ev3), Fq(q, ev4)]),
  Fq2(q, [Fq(q, q - ev4), Fq(q, ev3)])
];

JacobianPoint osswu2Help(Fq2 t) {
  final numDenCommon = xi_2.pow(BigInt.two) * t.pow(BigInt.from(4)) + xi_2 * t.pow(BigInt.from(2));
  final x0_num = Ell2p_b * (numDenCommon + Fq(q, BigInt.one));
  var x0_den = -Ell2p_a * numDenCommon;
  // ignore: unrelated_type_equality_checks
  x0_den = x0_den == BigInt.zero ? Ell2p_a * xi_2 : x0_den;
  final gx0_den = x0_den.pow(BigInt.from(3));
  final gx0_num =
      Ell2p_b * gx0_den + Ell2p_a * x0_num * x0_den.pow(BigInt.two) + x0_num.pow(BigInt.from(3));
  var tmp1 = gx0_den.pow(BigInt.from(7));
  final tmp2 = gx0_num * tmp1;
  tmp1 *= tmp2 * gx0_den;
  var sqrtCandidate = tmp2 * tmp1.pow((q.pow(2) - BigInt.from(9)) ~/ BigInt.from(16));
  for (final root in rootsOfUnity) {
    var y0 = sqrtCandidate * root as Fq2;
    if (y0.pow(BigInt.two) * gx0_den == gx0_num) {
      if (sgn0(y0) != sgn0(t)) {
        y0 = -y0;
      }
      assert(sgn0(y0) == sgn0(t));
      return JacobianPoint(
        x0_num * x0_den,
        y0 * x0_den.pow(BigInt.from(3)),
        x0_den,
        false,
        ec: defaultEcTwist,
      );
    }
  }
  final x1_num = xi_2 * t.pow(BigInt.two) * x0_num;
  final x1_den = x0_den;
  final gx1_num = xi_2.pow(BigInt.from(3)) * t.pow(BigInt.from(6)) * gx0_num;
  final gx1_den = gx0_den;
  sqrtCandidate *= t.pow(BigInt.from(3));
  for (final eta in etas) {
    var y1 = eta * sqrtCandidate as Fq2;
    if (y1.pow(BigInt.two) * gx1_den == gx1_num) {
      if (sgn0(y1) != sgn0(t)) {
        y1 = -y1;
      }
      assert(sgn0(y1) == sgn0(t));
      return JacobianPoint(
        x1_num * x1_den,
        y1 * x1_den.pow(BigInt.from(3)),
        x1_den,
        false,
        ec: defaultEcTwist,
      );
    }
  }
  throw StateError('Bad osswu2Help.');
}

JacobianPoint iso3(JacobianPoint P) {
  return evalIso(P, [xnum, xden, ynum, yden], defaultEcTwist);
}

JacobianPoint optSwu2Map(Fq2 t, Fq2? t2) {
  var Pp = iso3(osswu2Help(t));
  if (t2 != null) {
    final Pp2 = iso3(osswu2Help(t2));
    Pp += Pp2;
  }
  return Pp * hEff;
}

JacobianPoint g2Map(List<int> alpha, List<int> DST) {
  final elements =
      Hp2(alpha, 2, DST).map((hh) => Fq2(q, hh.map((value) => Fq(q, value)).toList())).toList();
  return optSwu2Map(elements[0], elements[1]);
}
