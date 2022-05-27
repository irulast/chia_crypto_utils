// ignore_for_file: lines_longer_than_80_chars

import 'package:chia_crypto_utils/src/bls/bls12381.dart';
import 'package:chia_crypto_utils/src/bls/field/extensions/fq2.dart';
import 'package:chia_crypto_utils/src/bls/field/extensions/fq6.dart';
import 'package:chia_crypto_utils/src/bls/field/field.dart';
import 'package:chia_crypto_utils/src/bls/field/field_base.dart';
import 'package:quiver/collection.dart';

final rv1 = BigInt.parse(
  '0x6AF0E0437FF400B6831E36D6BD17FFE48395DABC2D3435E77F76E17009241C5EE67992F72EC05F4C81084FBEDE3CC09',
);

final rootsOfUnity = <Fq2>[
  Fq2(q, [Fq(q, BigInt.one), Fq(q, BigInt.zero)]),
  Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.one)]),
  Fq2(q, [Fq(q, rv1), Fq(q, rv1)]),
  Fq2(q, [Fq(q, rv1), Fq(q, q - rv1)])
];

final frobCoeffs = <List<int>, Field>{
  [2, 1, 1]: Fq(q, -BigInt.one),
  [6, 1, 1]: Fq2(q, [
    Fq(q, BigInt.zero),
    Fq(
      q,
      BigInt.parse(
        '0x1A0111EA397FE699EC02408663D4DE85AA0D857D89759AD4897D29650FB85F9B409427EB4F49FFFD8BFD00000000AAAC',
      ),
    )
  ]),
  [6, 1, 2]: Fq2(q, [
    Fq(
      q,
      BigInt.parse(
        '0x1A0111EA397FE699EC02408663D4DE85AA0D857D89759AD4897D29650FB85F9B409427EB4F49FFFD8BFD00000000AAAD',
      ),
    ),
    Fq(q, BigInt.zero)
  ]),
  [6, 2, 1]: Fq2(q, [
    Fq(
      q,
      BigInt.parse(
        '0x5F19672FDF76CE51BA69C6076A0F77EADDB3A93BE6F89688DE17D813620A00022E01FFFFFFFEFFFE',
      ),
    ),
    Fq(q, BigInt.zero)
  ]),
  [6, 2, 2]: Fq2(q, [
    Fq(
      q,
      BigInt.parse(
        '0x1A0111EA397FE699EC02408663D4DE85AA0D857D89759AD4897D29650FB85F9B409427EB4F49FFFD8BFD00000000AAAC',
      ),
    ),
    Fq(q, BigInt.zero)
  ]),
  [6, 3, 1]: Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.one)]),
  [6, 3, 2]: Fq2(q, [
    Fq(
      q,
      BigInt.parse(
        '0x1A0111EA397FE69A4B1BA7B6434BACD764774B84F38512BF6730D2A0F6B0F6241EABFFFEB153FFFFB9FEFFFFFFFFAAAA',
      ),
    ),
    Fq(q, BigInt.zero)
  ]),
  [6, 4, 1]: Fq2(q, [
    Fq(
      q,
      BigInt.parse(
        '0x1A0111EA397FE699EC02408663D4DE85AA0D857D89759AD4897D29650FB85F9B409427EB4F49FFFD8BFD00000000AAAC',
      ),
    ),
    Fq(q, BigInt.zero)
  ]),
  [6, 4, 2]: Fq2(q, [
    Fq(
      q,
      BigInt.parse(
        '0x5F19672FDF76CE51BA69C6076A0F77EADDB3A93BE6F89688DE17D813620A00022E01FFFFFFFEFFFE',
      ),
    ),
    Fq(q, BigInt.zero)
  ]),
  [6, 5, 1]: Fq2(q, [
    Fq(q, BigInt.zero),
    Fq(
      q,
      BigInt.parse(
        '0x5F19672FDF76CE51BA69C6076A0F77EADDB3A93BE6F89688DE17D813620A00022E01FFFFFFFEFFFE',
      ),
    )
  ]),
  [6, 5, 2]: Fq2(q, [
    Fq(
      q,
      BigInt.parse(
        '0x5F19672FDF76CE51BA69C6076A0F77EADDB3A93BE6F89688DE17D813620A00022E01FFFFFFFEFFFF',
      ),
    ),
    Fq(q, BigInt.zero),
  ]),
  [12, 1, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
          '0x1904D3BF02BB0667C231BEB4202C0D1F0FD603FD3CBD5F4F7B2443D784BAB9C4F67EA53D63E7813D8D0775ED92235FB8',
        ),
      ),
      Fq(
        q,
        BigInt.parse(
          '0xFC3E2B36C4E03288E9E902231F9FB854A14787B6C7B36FEC0C8EC971F63C5F282D5AC14D6C7EC22CF78A126DDC4AF3',
        ),
      )
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 2, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
          '0x5F19672FDF76CE51BA69C6076A0F77EADDB3A93BE6F89688DE17D813620A00022E01FFFFFFFEFFFF',
        ),
      ),
      Fq(q, BigInt.zero),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 3, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
          '0x135203E60180A68EE2E9C448D77A2CD91C3DEDD930B1CF60EF396489F61EB45E304466CF3E67FA0AF1EE7B04121BDEA2',
        ),
      ),
      Fq(
        q,
        BigInt.parse(
          '0x6AF0E0437FF400B6831E36D6BD17FFE48395DABC2D3435E77F76E17009241C5EE67992F72EC05F4C81084FBEDE3CC09',
        ),
      ),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 4, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
          '0x5F19672FDF76CE51BA69C6076A0F77EADDB3A93BE6F89688DE17D813620A00022E01FFFFFFFEFFFE',
        ),
      ),
      Fq(q, BigInt.zero),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 5, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
          '0x144E4211384586C16BD3AD4AFA99CC9170DF3560E77982D0DB45F3536814F0BD5871C1908BD478CD1EE605167FF82995',
        ),
      ),
      Fq(
        q,
        BigInt.parse(
          '0x5B2CFD9013A5FD8DF47FA6B48B1E045F39816240C0B8FEE8BEADF4D8E9C0566C63A3E6E257F87329B18FAE980078116',
        ),
      ),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 6, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
          '0x1A0111EA397FE69A4B1BA7B6434BACD764774B84F38512BF6730D2A0F6B0F6241EABFFFEB153FFFFB9FEFFFFFFFFAAAA',
        ),
      ),
      Fq(q, BigInt.zero),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 7, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
          '0xFC3E2B36C4E03288E9E902231F9FB854A14787B6C7B36FEC0C8EC971F63C5F282D5AC14D6C7EC22CF78A126DDC4AF3',
        ),
      ),
      Fq(
        q,
        BigInt.parse(
          '0x1904D3BF02BB0667C231BEB4202C0D1F0FD603FD3CBD5F4F7B2443D784BAB9C4F67EA53D63E7813D8D0775ED92235FB8',
        ),
      ),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 8, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
          '0x1A0111EA397FE699EC02408663D4DE85AA0D857D89759AD4897D29650FB85F9B409427EB4F49FFFD8BFD00000000AAAC',
        ),
      ),
      Fq(q, BigInt.zero),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 9, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
          '0x6AF0E0437FF400B6831E36D6BD17FFE48395DABC2D3435E77F76E17009241C5EE67992F72EC05F4C81084FBEDE3CC09',
        ),
      ),
      Fq(
        q,
        BigInt.parse(
          '0x135203E60180A68EE2E9C448D77A2CD91C3DEDD930B1CF60EF396489F61EB45E304466CF3E67FA0AF1EE7B04121BDEA2',
        ),
      ),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 10, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
          '0x1A0111EA397FE699EC02408663D4DE85AA0D857D89759AD4897D29650FB85F9B409427EB4F49FFFD8BFD00000000AAAD',
        ),
      ),
      Fq(q, BigInt.zero),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
  [12, 11, 1]: Fq6(q, [
    Fq2(q, [
      Fq(
        q,
        BigInt.parse(
          '0x5B2CFD9013A5FD8DF47FA6B48B1E045F39816240C0B8FEE8BEADF4D8E9C0566C63A3E6E257F87329B18FAE980078116',
        ),
      ),
      Fq(
        q,
        BigInt.parse(
          '0x144E4211384586C16BD3AD4AFA99CC9170DF3560E77982D0DB45F3536814F0BD5871C1908BD478CD1EE605167FF82995',
        ),
      ),
    ]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
    Fq2(q, [Fq(q, BigInt.zero), Fq(q, BigInt.zero)]),
  ]),
};

Field getFrobCoeff(List<int> key) {
  for (final item in frobCoeffs.entries) {
    if (listsEqual(item.key, key)) {
      return item.value;
    }
  }
  throw StateError('Unknown frob coeff.');
}
