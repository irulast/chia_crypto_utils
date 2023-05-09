import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

Future<void> main() async {
  final dexieApi = DexieApi();

  final currentUnixTimeStamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final offerValidityTime = currentUnixTimeStamp + 3600;
  const offeredAmount = ExchangeAmount(type: ExchangeAmountType.XCH, amount: 1000000000000);
  const requestedAmount = ExchangeAmount(type: ExchangeAmountType.BTC, amount: 200000);
  const messageAddress = Address('xch1m29jusdya59y5g3qhsqqd2tqwn0kgh2fg8ux7xt9x4vzs7927rmqmhsu02');
  const serializedLightningPaymentRequest =
      'lnbc2m1pjq55klpp5trkvjhdsplmnsg458yaesk7ejpe4e3a4zx4tqucaqcl8ekh6j9vqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdertnqk95dh65cqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldertnqk95dh65cqqqqryqqqqthqqpysp5t9es5tal7dzrzu9t076w54qyr9h9eeguk0yw5efywn8898lg53gq9qypqsqr3c469cu5t6wd6zmsequvp33ccvg83aymgs2hj6ljrzkngk8y73knlj7zdtnt82jzths0mp87e9uenr2ejj05nwqsjcwc0s54gnnteqqlg9uls';
  final lightningPaymentRequest = decodeLightningPaymentRequest(serializedLightningPaymentRequest);

  group(
    'should successfully send post request with offer file to dexie',
    () {
      test('without initialization coin id', () async {
        final privateKey = PrivateKey.generate();
        final publicKey = privateKey.getG1();

        final offerFile = XchToBtcMakerOfferFile(
          offeredAmount: offeredAmount,
          requestedAmount: requestedAmount,
          messageAddress: messageAddress,
          validityTime: offerValidityTime,
          publicKey: publicKey,
          lightningPaymentRequest: lightningPaymentRequest,
        );

        final serializedOfferFile = offerFile.serialize(privateKey);
        final response = await dexieApi.postOffer(serializedOfferFile);

        expect(response.success, equals(true));
      });

      test('with initialization coin id', () async {
        final privateKey = PrivateKey.generate();
        final publicKey = privateKey.getG1();

        final offerFile = XchToBtcMakerOfferFile(
          initializationCoinId:
              Bytes.fromHex('5db0138082bf1aa2144b736d67bdbcaa7d2cd9b07bab3bba15c8cd3d97df7eb4'),
          offeredAmount: offeredAmount,
          requestedAmount: requestedAmount,
          messageAddress: messageAddress,
          validityTime: offerValidityTime,
          publicKey: publicKey,
          lightningPaymentRequest: lightningPaymentRequest,
        );

        final serializedOfferFile = offerFile.serialize(privateKey);

        final response = await dexieApi.postOffer(serializedOfferFile);

        expect(response.success, equals(true));
      });
    },
    skip: 'sends post request to dexie',
  );

  test('should successfully inspect offer', () async {
    const dexieId = 'DBdWjDnnbZDzwLFKwB3XKUvvECtKhZ3rTbHCqVvwRsbS';
    final response = await dexieApi.inspectOffer(dexieId);

    expect(response.success, equals(true));
    expect(response.offerJson, isNotNull);
    expect(response.offerJson!['id'], equals(dexieId));
  });

  test('inspect offer query should fail if offer has not been posted', () async {
    final privateKey = PrivateKey.generate();
    final publicKey = privateKey.getG1();

    final offerFile = XchToBtcMakerOfferFile(
      offeredAmount: offeredAmount,
      requestedAmount: requestedAmount,
      messageAddress: messageAddress,
      validityTime: offerValidityTime,
      publicKey: publicKey,
      lightningPaymentRequest: lightningPaymentRequest,
    );

    final serializedOfferFile = offerFile.serialize(privateKey);

    final dexieId = generateDexieId(serializedOfferFile);
    final response = await dexieApi.inspectOffer(dexieId);

    expect(response.success, equals(false));
    expect(response.errorMessage, equals('Offer not found'));
  });

  test('should correctly generate dexie id from serialized offer file', () {
    const serializedOfferFile =
        'ccoffer1v4u55urzd4krqc2hgeekzkrsdpjywmrkvfkrj6nzxfk82kpjd345j6nsw4j9w7rnf3p55aj6d4dxccmd2e45j6nsxayku534vdr42620d999j5fsva55cs62dp39wwf3vfh9z620dfyhwn2yg9m563zpwax5svrnf9hy5mrrtptxccen2fk95s6fxejhjj3sv4vyymzfdfhkj5tv2fzyj6thd9v4wvtkv3tn2vzfdfhhsn2yggu5cs62w3d9snn6t9tkgmzcxfrxkkjgffkxxv6dd98kuumfv3yxca662dynvjtwdp4xzs6fwdyk63nttfyy5mrrxdxkjnmffg69jvn80p3x5kthv9rhq6nr2auxun65dv6954zjx4sk66pkvdtkxv6etp5rgnfnggc9536xw3jysur2vye4vmtz23qn2e25g9u5u6nywfjysnnjvft52vmr2ahh5cndwqcxz72289xyxj3jt9thsuz6gakrqe2k8ycxz4e3d3yk5mmcfe4xxdz023xnqnn62ye5cs62waj9wjnnv9t5uenpxftr2jt2da55736kd4d9g3tcfceyv6je0ffx5nn629m574zexp8855fst92927z0g3fxcnj5f56yu4r8wadx63ndtfzyumz6g38x6kj82ek4j6nrx48ywjtef4axkdz6232n2n6y2f54jm2f0fxk5jf3tf49ja6e233hsn6yf4uy74rrx48x6jfjt94xx7zwga2ngk25vam5u3rrxpvh55f4f95hw6tzgakxuc2g2f6kz4e4devrxsngv4tnzmrzdefxvcmd2euxg46k0fjyxjfkv4u55a6etpk8gkjhx5c9sv62d334s4nvvve4z620d998xcndff4y6kz40p35gnn0v3vxcdnpxdp8wnjctge5um26wf3kuce4vfyyj7nrfpdrykjh2ycy6jrswa35g5n3vseyvd2wga3nqkjh25exgkrs0fv4wmmef4zxs6m9fprrgk3jxpukxmjjwfjxu3ntvdvyv6nrtpcrvk3ndpux2kr0x9jxu3nev4khq7ryxg6nyezhf4mkg4zjxpj5wdr6fet5u6z6d4xnxer6dvc95vmgxf34g4nhf5eyuv202afxkn652ek5uvngwd3k6emhtfh957jwg3drxc6gtfh45jz2x3snx6rwvfy9zvtrtpkxkcmw2euxxkzx0p3kumrcvdvyv7ryga58sc6cgg6kxmnsw934sce5t9axgd26detrqc6cgc656vn5xe85gkfjf4k45drytpf8zerd2ek5uv6909j9wur6v4y9yvzwg3tx5cen24mkz7jex385w7rjv4h927nzgaf8je28ws695vncxp89s334tfyy5vtrtpr8sc6cfg6kxkzx0p34s5n0vdvyvam9tp88wnjhwqm95v6zw98yg6e4f4r5ummygahn2kn2d3hy6m2exf39w6pjtge4ydje2acrvkfjws6yu7nrxpj4s4n0f4rhgumzdeyh5c28xyexxmjxxpsku3f4vdvxcamrtp88scfnfgexy3zw0f34w5fsvd29y6mz23kxse2g2gc95m29xfdxujnwfcexgm26d4jrzc65feuk2mjkxfjx6vretfhyyvtrtp8xukn6ddmky3zjw4jk56pktgey67nyxdnnxk3jv3hxy4zpxpj5s53nvd292dtyd4drqcj5fyc454e3xd35gmr5v3y95aryd4cxunn625e95jrvxe3x5jntvf2xkdrrtppxscfnvvcxg4r8d9xyxj3sv9tnzmrzxdtrqjt2du6yu6j3wax5svfe9esnqdpexu6rvwfnxyex2ctp8yen2wtrxg6nzcf4xa3rsvmy8p3xxv3evccrydf4xsurgwrzx33nzvfnxajxxv3cxcensvf3x5mrwvfjv43nvdnxxajnqefsvv6xve34vs6rjvnyx9jr2ery8qcrqvryvyerzvenx43nyd3nv9nrjctxvf3nxd3kvfjrzcee8y6nqdr9vdjxxd3hxpnx2wtyxa3nscee8yunvc3hx5ersdfsvg6rjvpsv9snzvpkxvex2wp4xgmnjcmyvy6ngd3cxcersdmrxpsnvep4xc6n2vpcxpnxzf9ej00';
    const expectedDexieId = 'FtEDqUdCRimi58sRVHk6gSYBx2ehpX26DcZumvWUuWds';

    final dexieId = generateDexieId(serializedOfferFile);
    expect(dexieId, equals(expectedDexieId));
  });
}
