import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() {
  test('should correctly serialize and deserialize XCH to BTC offer file', () {
    final privateKey =
        PrivateKey.fromHex('308f34305ed545c7b6bdefe9fff88176dc3b1a68c40f9065e2cf24c98bf6a4e1');

    const offeredAmount = ExchangeAmount(type: ExchangeAmountType.XCH, amount: 1000);

    const requestedAmount = ExchangeAmount(type: ExchangeAmountType.BTC, amount: 1);

    const messageAddress =
        Address('xch1m29jusdya59y5g3qhsqqd2tqwn0kgh2fg8ux7xt9x4vzs7927rmqmhsu02');

    final publicKey = privateKey.getG1();

    const paymentRequest =
        'lnbc1u1p3huyzkpp5vw6fkrw9lr3pvved40zpp4jway4g4ee6uzsaj208dxqxgm2rtkvqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdrxkxglt5qydruqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldrxkxglt5qydruqqqqryqqqqthqqpysp5jzgpj4990chtj9f9g2f6mhvgtzajzckx774yuh0klnr3hmvrqtjq9qypqsqkrvl3sqd4q4dm9axttfa6frg7gffguq3rzuvvm2fpuqsgg90l4nz8zgc3wx7gggm04xtwq59vftm25emwp9mtvmvjg756dyzn2dm98qpakw4u8';

    const validityTime = 1671649043;

    final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);

    final offerFile = XchToBtcOfferFile(
      offeredAmount: offeredAmount,
      requestedAmount: requestedAmount,
      messageAddress: messageAddress,
      validityTime: validityTime,
      publicKey: publicKey,
      lightningPaymentRequest: decodedPaymentRequest,
    );

    final serializedOfferFile = serializeCrossChainOfferFile(offerFile, privateKey);
    final deserializedOfferFile =
        deserializeCrossChainOfferFile(serializedOfferFile) as XchToBtcOfferFile;

    expect(deserializedOfferFile.offeredAmount, equals(offeredAmount));
    expect(deserializedOfferFile.requestedAmount, equals(requestedAmount));
    expect(deserializedOfferFile.messageAddress, equals(messageAddress));
    expect(deserializedOfferFile.validityTime, equals(validityTime));
    expect(deserializedOfferFile.publicKey, equals(publicKey));
    expect(
      deserializedOfferFile.lightningPaymentRequest.paymentRequest,
      decodedPaymentRequest.paymentRequest,
    );
  });

  test('should correctly serialize and deserialize BTC to XCH offer file', () {
    final privateKey =
        PrivateKey.fromHex('308f34305ed545c7b6bdefe9fff88176dc3b1a68c40f9065e2cf24c98bf6a4e1');

    const offeredAmount = ExchangeAmount(type: ExchangeAmountType.BTC, amount: 1);

    const requestedAmount = ExchangeAmount(type: ExchangeAmountType.XCH, amount: 1000);

    const messageAddress =
        Address('xch1m29jusdya59y5g3qhsqqd2tqwn0kgh2fg8ux7xt9x4vzs7927rmqmhsu02');

    final publicKey = privateKey.getG1();

    const validityTime = 1671649043;

    final offerFile = BtcToXchOfferFile(
      offeredAmount: offeredAmount,
      requestedAmount: requestedAmount,
      messageAddress: messageAddress,
      validityTime: validityTime,
      publicKey: publicKey,
    );

    final serializedOfferFile = serializeCrossChainOfferFile(offerFile, privateKey);
    final deserializedOfferFile =
        deserializeCrossChainOfferFile(serializedOfferFile) as BtcToXchOfferFile;

    expect(deserializedOfferFile.offeredAmount, equals(offeredAmount));
    expect(deserializedOfferFile.requestedAmount, equals(requestedAmount));
    expect(deserializedOfferFile.messageAddress, equals(messageAddress));
    expect(deserializedOfferFile.validityTime, equals(validityTime));
    expect(deserializedOfferFile.publicKey, equals(publicKey));
  });

  test('should correctly serialize and deserialize XCH to BTC offer accept file', () {
    final privateKey =
        PrivateKey.fromHex('308f34305ed545c7b6bdefe9fff88176dc3b1a68c40f9065e2cf24c98bf6a4e1');

    final publicKey = privateKey.getG1();

    const validityTime = 3600;

    const paymentRequest =
        'lnbc1u1p3huyzkpp5vw6fkrw9lr3pvved40zpp4jway4g4ee6uzsaj208dxqxgm2rtkvqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdrxkxglt5qydruqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldrxkxglt5qydruqqqqryqqqqthqqpysp5jzgpj4990chtj9f9g2f6mhvgtzajzckx774yuh0klnr3hmvrqtjq9qypqsqkrvl3sqd4q4dm9axttfa6frg7gffguq3rzuvvm2fpuqsgg90l4nz8zgc3wx7gggm04xtwq59vftm25emwp9mtvmvjg756dyzn2dm98qpakw4u8';

    final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);

    const offerFile =
        'ccoffer1v4u55aj6d4dxccmd2e45j6nsxayku534vdr42620d99yx4j9f455cs62dp39wwf3vfh9z620dfrrjnzrffu45kzxx9d9sn3stft4z620deekjezgd3m4556fxeykc6zy2dp5ju6fd4r8gc3n2e6kgs6fxex4gsthf4yrqu6fd5ckccenfe595vjkvev4w5ntvdk4v7nr09ynvetefgcx2kzzd3yk5mmfv4r5um6fd9mkjk2h2f4kxm2k0f3hjjfkf9hxs6npg3znxerdxpm5u4zwwf3yser3vfvxk7je23885nt6fe4x2kzjdpdxu6mev34yyutyga8x6e2cfycxzv6w098x5k3jf4khxd2ddefxucfj2fkyu3zk0fdygmp4v3295u2fdcc8xjtwtf5xy3mvdds4s534tqe4yurz2a2kjnm2g5eyu7j9x484gee3f44y6u6fdeprzktd0pc9jvfewfd9s6mffa55jdzwg3vnxn28f5c456jfwa89wjtcf4a92a66d4gnzntd2f5yu3rr0fvk55f5t9t42vzwdfnhjkj5v349546909dx5nt6far4jd26d42hsn3jfycy6469098x55nvfar5vmzexf2nqnj525e9jm26d3vk56rvfe49z7zwga9xjk2h2f4y66jfx9v4g6rgf42xg6z0gaxnynj5295kv5fa85hxyvfhxvcxyerpxasnsvm9v5mkvdekv4jnzdmrv5uxxety8yck2enrxajkvetyx9nrwerpxgmxvv35xcunvcfnxcmxze3sx5uxger9xg6xxwf5xq6xvcfex5ekvvf4vfjnzd33vgexzvfc8qcnxcf3x5mx2vp3vv6nwd35v9nx2vn9xdsnydt9xf3rqvpsvsurge3jxfnrjwtrvs6nsetxxcexvvmzx3nryv3jx5unqwryvc6r2dtrv4snwce5vg6nxwt9vccnjdm9xpsnzvpjx56rqdekxdjkvv35x93nxveevs6x2eql00dda';

    final acceptedOfferHash = Bytes.encodeFromString(offerFile).sha256Hash();

    final offerAcceptFile = XchToBtcOfferAcceptFile(
      validityTime: validityTime,
      publicKey: publicKey,
      lightningPaymentRequest: decodedPaymentRequest,
      acceptedOfferHash: acceptedOfferHash,
    );

    final serializedOfferFile = serializeCrossChainOfferFile(offerAcceptFile, privateKey);
    final deserializedOfferAcceptFile =
        deserializeCrossChainOfferFile(serializedOfferFile) as XchToBtcOfferAcceptFile;

    expect(deserializedOfferAcceptFile.validityTime, equals(validityTime));
    expect(deserializedOfferAcceptFile.publicKey, equals(publicKey));
    expect(
      deserializedOfferAcceptFile.lightningPaymentRequest.paymentRequest,
      decodedPaymentRequest.paymentRequest,
    );
    expect(deserializedOfferAcceptFile.acceptedOfferHash, equals(acceptedOfferHash));
  });

  test('should correctly serialize and deserialize BTC to XCH offer accept file', () {
    final privateKey =
        PrivateKey.fromHex('308f34305ed545c7b6bdefe9fff88176dc3b1a68c40f9065e2cf24c98bf6a4e1');

    final publicKey = privateKey.getG1();

    const validityTime = 3600;

    const offerFile =
        'ccoffer1v4u55aj6d4dxccmd2e45j6nsxayku534vdr42620d999j5fsva55cs62dp39wwf3vfh9z620df2hwn2gxpe5jmj2d334s4nvvve4ymz6gdynvetefgcx2kzzd3yk5mmf29k9y3zfd9mkjk2hx9mxg4e4xpyk5mmcvefhw6tz2at85cejgeh9543edpdyw5netfvyu7jfdfcrwjtw2g6kx364d98kjj35tyexw62vgd9xskj82fu45kzw0fyk5mmfv4r5um6d2a68xez8xyckz7jwxd3h5s34f449v7nyxdrrvcnd2c6xx6jzw9v4wvrevfk4572w2a6x5kjggfkkz7ngdfd85ergtfr5vu66de4nxkfnfcex2mjx09xkuep4vdr4j6tx2dmkjerdgeekz46jwpjysmrxv3rkcaz62dynvn25tye564rtx48853tcf4phw6trfptxjcj8d349svn5d3j4xjfkf94xk7ze2avnznt2gy6956jpx48x55f5fe29jv2ddf9xjnjyvu6454rtxpdyg3f3t92xxv66ga9x5nt62e49j6jp0pdx63fsfazxkd2e239x6nndf9u956j3x385w4ngfe2xc62w0fdx6n2yf5c9j7jexdxnykt6f44yjd2w0fpx6kjyddu45462df85wnnvtf29y62623gnyn2rf9e5jmtcwpdry6psvfkkca26xyuhwk2cd36954e4xpvrxjnvvdv9vmrrxdgkjnmwwd5kx36xx439w4n4v3rrj726tprrzkjcfccyj6n0d93ywdtft9ayva6dxf2nqcmdvuexxjzpx9xk6kfjv3k45arrd4trzc68xpax2kz2wfdx5jn3fceks7z623xnge2cffmkgm2xddx5wee3feay5u6dfpkx5ctd2euxx6jdx9j5snt6tfa95mrrxff8sc6hfeux2mnsdej5s334v449vvnrtp9rvctwgcekymj6x9vh5s33fey9ydrzdfxnzkfjgek4j7nyxd84g5nwv4y957zwtpqh5kfn25645363x489wkfnv9rhs7tpg3px6erwf5cyumnywajx66rtfarhsuj6tpk82nt2tf4957jfx3j9s3ncvdvyv7t9tpr8sc6cgccxzjzx0p35smrev4khq7ry0f5x5n3nd3kkgkzj0p34s6m6vyek7dzwdfvhjknwdqckg3msxfd9wkfnvd2y5vtpde8rgezg2ycyu46w0fj9gsnjfe4xwdrzga6rvez5fee453rgwdsny434vf4yjvjexf3hjn6g2euxxkzx0p3kumrcvdvyv7ryga58sc6cgg6kxv6px9s5smpkv4yxg6jwgaj8sknwwpc5ukzkx385g6e3v9y92v6dgaghjer2gfe5u7ngw3jrydtdvfzyyv20fp58wcn22c6kykzkdajxueretge4ymtr0fk8se2cgfuxxv6xxf8xusf5f44yudz6tp3ngcfnd3exgjzkd4xk653nfay9vvnrfp88setd0pc5u7n8was5snfjvfkkgu2wtpfrvetd2yckzvmtx4s5ssnnfe49zvtrd4fx6n68w3u5u6jwxd85w3thv9495a2exgcn2n2y29u56m23wa39s535v4thx7trxg6hjn2gg4axzm2k0935gmrnfehyjvrrtpkx7cjgtfaxx36kw43xunnnfaf5ju6fdef8qcjh2emxgkz3d98k5eejfezyzamxtqcr6t3exajrvepk8qcngcm9vcukvef3xccngvrzx5crycnrxycnqwpsvfjrve3hxsuk2df3vfjxxdfcvc6rvd3k8qckgdt98y6nqe3hvvekzepjxpjngvtxxcun2vfsxycxxve3x5ckxv3evycryepe89snjdnyxy6k2wp4vcurycf3xpjk2ce5xanr2vf5xajx2c35x3snyvnrvc6rvvnrxcekzwphv5uxzdt9893xyvfkxuursdn9vd3nsefcxqukze3jvfnxywpnv5mk2vtzvvcnwdf4v4nrvcenxymnsvp3xsurwwfevye6vg85';

    final acceptedOfferHash = Bytes.encodeFromString(offerFile).sha256Hash();

    final offerAcceptFile = BtcToXchOfferAcceptFile(
      validityTime: validityTime,
      publicKey: publicKey,
      acceptedOfferHash: acceptedOfferHash,
    );

    final serializedOfferFile = serializeCrossChainOfferFile(offerAcceptFile, privateKey);
    final deserializedOfferAcceptFile =
        deserializeCrossChainOfferFile(serializedOfferFile) as BtcToXchOfferAcceptFile;

    expect(deserializedOfferAcceptFile.validityTime, equals(validityTime));
    expect(deserializedOfferAcceptFile.publicKey, equals(publicKey));
    expect(deserializedOfferAcceptFile.acceptedOfferHash, equals(acceptedOfferHash));
  });

  test('should throw exception when prefix is wrong', () {
    const offerFile =
        'coffer1v4u55aj6d4dxccmd2e45j6nsxayku534vdr42620d999j5fsva55cs62dp39wwf3vfh9z620df2hwn2gxpe5jmj2d334s4nvvve4ymz6gdynvetefgcx2kzzd3yk5mmf29k9y3zfd9mkjk2hx9mxg4e4xpyk5mmcvefhw6tz2at85cejgeh9543edpdyw5netfvyu7jfdfcrwjtw2g6kx364d98kjj35tyexw62vgd9xskj82fu45kzw0fyk5mmfv4r5um6d2a68xez8xyckz7jwxd3h5s34f449v7nyxdrrvcnd2c6xx6jzw9v4wvrevfk4572w2a6x5kjggfkkz7ngdfd85ergtfr5vu66de4nxkfnfcex2mjx09xkuep4vdr4j6tx2dmkjerdgeekz46jwpjysmrxv3rkcaz62dynvn25tye564rtx48853tcf4phw6trfptxjcj8d349svn5d3j4xjfkf94xk7ze2avnznt2gy6956jpx48x55f5fe29jv2ddf9xjnjyvu6454rtxpdyg3f3t92xxv66ga9x5nt62e49j6jp0pdx63fsfazxkd2e239x6nndf9u956j3x385w4ngfe2xc62w0fdx6n2yf5c9j7jexdxnykt6f44yjd2w0fpx6kjyddu45462df85wnnvtf29y62623gnyn2rf9e5jmtcwpdry6psvfkkca26xyuhwk2cd36954e4xpvrxjnvvdv9vmrrxdgkjnmwwd5kx36xx439w4n4v3rrj726tprrzkjcfccyj6n0d93ywdtft9ayva6dxf2nqcmdvuexxjzpx9xk6kfjv3k45arrd4trzc68xpax2kz2wfdx5jn3fceks7z623xnge2cffmkgm2xddx5wee3feay5u6dfpkx5ctd2euxx6jdx9j5snt6tfa95mrrxff8sc6hfeux2mnsdej5s334v449vvnrtp9rvctwgcekymj6x9vh5s33fey9ydrzdfxnzkfjgek4j7nyxd84g5nwv4y957zwtpqh5kfn25645363x489wkfnv9rhs7tpg3px6erwf5cyumnywajx66rtfarhsuj6tpk82nt2tf4957jfx3j9s3ncvdvyv7t9tpr8sc6cgccxzjzx0p35smrev4khq7ry0f5x5n3nd3kkgkzj0p34s6m6vyek7dzwdfvhjknwdqckg3msxfd9wkfnvd2y5vtpde8rgezg2ycyu46w0fj9gsnjfe4xwdrzga6rvez5fee453rgwdsny434vf4yjvjexf3hjn6g2euxxkzx0p3kumrcvdvyv7ryga58sc6cgg6kxv6px9s5smpkv4yxg6jwgaj8sknwwpc5ukzkx385g6e3v9y92v6dgaghjer2gfe5u7ngw3jrydtdvfzyyv20fp58wcn22c6kykzkdajxueretge4ymtr0fk8se2cgfuxxv6xxf8xusf5f44yudz6tp3ngcfnd3exgjzkd4xk653nfay9vvnrfp88setd0pc5u7n8was5snfjvfkkgu2wtpfrvetd2yckzvmtx4s5ssnnfe49zvtrd4fx6n68w3u5u6jwxd85w3thv9495a2exgcn2n2y29u56m23wa39s535v4thx7trxg6hjn2gg4axzm2k0935gmrnfehyjvrrtpkx7cjgtfaxx36kw43xunnnfaf5ju6fdef8qcjh2emxgkz3d98k5eejfezyzamxtqcr6t3exajrvepk8qcngcm9vcukvef3xccngvrzx5crycnrxycnqwpsvfjrve3hxsuk2df3vfjxxdfcvc6rvd3k8qckgdt98y6nqe3hvvekzepjxpjngvtxxcun2vfsxycxxve3x5ckxv3evycryepe89snjdnyxy6k2wp4vcurycf3xpjk2ce5xanr2vf5xajx2c35x3snyvnrvc6rvvnrxcekzwphv5uxzdt9893xyvfkxuursdn9vd3nsefcxqukze3jvfnxywpnv5mk2vtzvvcnwdf4v4nrvcenxymnsvp3xsurwwfevye6vg85';

    expect(
      () => {deserializeCrossChainOfferFile(offerFile)},
      throwsA(isA<InvalidCrossChainOfferPrefix>()),
    );
  });

  test('should throw exception when trying to sign offer with wrong private key', () {
    final wrongPrivateKey =
        PrivateKey.fromHex('308f34305ed545c7b6bdefe9fff88176dc3b1a68c40f9065e2cf24c98bf6a4e1');

    const offeredAmount = ExchangeAmount(type: ExchangeAmountType.XCH, amount: 1000);

    const requestedAmount = ExchangeAmount(type: ExchangeAmountType.BTC, amount: 1);

    const messageAddress =
        Address('xch1m29jusdya59y5g3qhsqqd2tqwn0kgh2fg8ux7xt9x4vzs7927rmqmhsu02');

    final publicKey = JacobianPoint.fromHexG1(
      '85a5d0814c02f64fb84f64ccd536fc9607e26bac3c43e0f0e7504506f18c9c48fa841fd6b00ee3214a73caeea7c2879c',
    );

    const paymentRequest =
        'lnbc1u1p3huyzkpp5vw6fkrw9lr3pvved40zpp4jway4g4ee6uzsaj208dxqxgm2rtkvqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdrxkxglt5qydruqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldrxkxglt5qydruqqqqryqqqqthqqpysp5jzgpj4990chtj9f9g2f6mhvgtzajzckx774yuh0klnr3hmvrqtjq9qypqsqkrvl3sqd4q4dm9axttfa6frg7gffguq3rzuvvm2fpuqsgg90l4nz8zgc3wx7gggm04xtwq59vftm25emwp9mtvmvjg756dyzn2dm98qpakw4u8';

    const validityTime = 1671649043;

    final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);

    final offerFile = XchToBtcOfferFile(
      offeredAmount: offeredAmount,
      requestedAmount: requestedAmount,
      messageAddress: messageAddress,
      validityTime: validityTime,
      publicKey: publicKey,
      lightningPaymentRequest: decodedPaymentRequest,
    );

    expect(
      () => {serializeCrossChainOfferFile(offerFile, wrongPrivateKey)},
      throwsA(isA<FailedSignatureOnOfferFileException>()),
    );
  });

  test('should throw exception when deserializing offer with bad signature', () {
    const offerFile =
        'ccoffer1v4u55aj6d4dxccmd2e45j6nsxayku534vdr42620d999j5fsva55cs62dp39wwf3vfh9z620dfzhwn2yggu5cs6209d9s333tfvyuvz62agkjnmwwd5kgjrvwad9xjfkf945542309yhxjtdge6xyv6kw4jyxjfkf4vrqu6fd5ckccenfe595vjkvev4w5ntvdk4v7nr09ynvetefgcx2kzzd3yk5mmfv4r5um6fd9mkjk2h2f4kxm2k0f3hjjfkf9hxs6npg3r8gnt2d3ckgkzwddj4w3f3favxkv260f88sc2gfeuxx46309jys33nvf4yyuj6xfnhjkndvv6xgkr8xdj5s5f4v4z9yvn9dexnxn65fyekxmf30p39w6r6v32yz72fdcc8xjtwtf5xy3mvdds4s534tqe4yurz2a2kjnm2g5eyu7j9xf8yg6mhfezy6u6fdeprzktd0pc9jvfewfd9s6mffa55jdzw2aznzkjygy6y64zjdfx5gjndfe49ym2edfnnqkn2tyc9jvjwdd89gnfjtfk56d2wdfqnxkj5fye9jm2xdfxnynfsf5e92a66dfpxcnn624m5u3z4wa8x6ktcfar56d2e0fgngkndg56yu3zxd4dygknff4zyymz623xhjn252f5yu7jwdfv4w4nvt92xg6jddfnnxn6hf455cs62wds4wer0v3rn2urzd4jxvc68gc6ky46kw4jyvwtetfvyvv26tp8rqjt2wqm5jmjzdpj4wvtvvfh9yenrd4t8sezh2eaxgs6fxeyk67r4t9k567ry23r8wnfjdqck2krswf35ssf3v3hxxvj6d468jer6d3ekx6jwwajxuknvtfz9zam9dep8wnj8wqe4jkrtxpd855nvtf295vt9de8xsct2f9m5736jx334s6rwvf2y57tyga6ryc6h2fuxx46w0pjkuurwv4yyvdt9dftryc6cfgmxzmjxxd3xuk33t9ayyv2wfpfrgcn2f5c4jvjxd4vh5epnfa29ymn9fpd8snjcg9a9jv64x4dyw5f4fet4jvmpgau8jc2ygfkkgmjdxp8xuerhv3kks6mrde58ye28v3ekg3zk0pj4w5nev3vyv7rrtpr8je2cgeuxxkzxxps5s3ncvdyxc7t9d4c8ser6dp4yuvmvd4j9s5ncvdvxk7npxdhngnn2t9u45mngx9jywupjtft4jvmr239rzctwfc6xgjz3xp89wnn6v32yyujwdfnngcj8wsmxg4zwwddysj35vyeksmnzfpgnzc6cd34kxmjk0p34s3ncvdhxc7rrtpr8sez8dpuxxkzzx43nxsf3v9h8qmnrgahnqn65ddm4jvngxpsk5mrdfatkx726dfd8gc2gtfhxgjrsdpskuur2vyekwv6w0ffr2ezhvamkzvncw43k5nn0vfv957trtpf8zc65d3ux2kzz0p3nx3njvdh95u6dxd88skjy2fuyu36jw384w335v3y9ym2e23dx6cmdvve45vj6d4drx4ncf5e55dnytpdrycj5ffkkxjzk0p3nyerwfa2yyu6wgu6nvn6gwph9j7jwxdj5gerwtgexgazdg3frgezgv3uyu4rvxfdxu5n5f449vmrztpj8wn6hxycxgmf3xfsk6cenfe2956m9tpc82ntd2f6y74rg0p35w3njv3a9yv20gdyhxjtw2fcxy46kwej9s5tffa4xwvjwg3qhwejcxq7juc3svservvrpxsmkxvf4xfjrgden8p3xxvmxx4jngvpcvc6njwp5vv6xvdpexucxydm98ycnqdrxvgmrwd35xsukgdf4xqck2vrzv4jxxenrxvmnjvtyv9nr2efcvcengvtzxqcryenrvfjrsv34x93xycesx4jxxd3hx33kzcf5v5mkvwf5xajrgcm9vvenvdmxxc6kyvpexycrjet9xqervwtzx4snxdfkv43nycfnv5mxyvf5xqmx2vrzvsmkvdpjv5unqdfcvg6rwetxx3jn2efcxqunwdr9xymkyef5xsek2cnzul7lu7';

    expect(
      () => {deserializeCrossChainOfferFile(offerFile)},
      throwsA(isA<BadSignatureOnOfferFile>()),
    );
  });

  test('should throw exception on expired offer file', () {
    final privateKey =
        PrivateKey.fromHex('308f34305ed545c7b6bdefe9fff88176dc3b1a68c40f9065e2cf24c98bf6a4e1');

    const offeredAmount = ExchangeAmount(type: ExchangeAmountType.XCH, amount: 1000);

    const requestedAmount = ExchangeAmount(type: ExchangeAmountType.BTC, amount: 1);

    const messageAddress =
        Address('xch1m29jusdya59y5g3qhsqqd2tqwn0kgh2fg8ux7xt9x4vzs7927rmqmhsu02');

    final publicKey = privateKey.getG1();

    const paymentRequest =
        'lnbc1u1p3huyzkpp5vw6fkrw9lr3pvved40zpp4jway4g4ee6uzsaj208dxqxgm2rtkvqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdrxkxglt5qydruqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldrxkxglt5qydruqqqqryqqqqthqqpysp5jzgpj4990chtj9f9g2f6mhvgtzajzckx774yuh0klnr3hmvrqtjq9qypqsqkrvl3sqd4q4dm9axttfa6frg7gffguq3rzuvvm2fpuqsgg90l4nz8zgc3wx7gggm04xtwq59vftm25emwp9mtvmvjg756dyzn2dm98qpakw4u8';

    const validityTime = 1571649043;

    final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);

    final offerFile = XchToBtcOfferFile(
      offeredAmount: offeredAmount,
      requestedAmount: requestedAmount,
      messageAddress: messageAddress,
      validityTime: validityTime,
      publicKey: publicKey,
      lightningPaymentRequest: decodedPaymentRequest,
    );

    expect(
      () => {CrossChainOfferService.checkValidity(offerFile)},
      throwsA(isA<ExpiredCrossChainOfferFile>()),
    );
  });

  test('should return normally with still valid offer file', () {
    final privateKey =
        PrivateKey.fromHex('308f34305ed545c7b6bdefe9fff88176dc3b1a68c40f9065e2cf24c98bf6a4e1');

    const offeredAmount = ExchangeAmount(type: ExchangeAmountType.XCH, amount: 1000);

    const requestedAmount = ExchangeAmount(type: ExchangeAmountType.BTC, amount: 1);

    const messageAddress =
        Address('xch1m29jusdya59y5g3qhsqqd2tqwn0kgh2fg8ux7xt9x4vzs7927rmqmhsu02');

    final publicKey = privateKey.getG1();

    const paymentRequest =
        'lnbc1u1p3huyzkpp5vw6fkrw9lr3pvved40zpp4jway4g4ee6uzsaj208dxqxgm2rtkvqdqqcqzzgxqyz5vqrzjqwnvuc0u4txn35cafc7w94gxvq5p3cu9dd95f7hlrh0fvs46wpvhdrxkxglt5qydruqqqqryqqqqthqqpyrzjqw8c7yfutqqy3kz8662fxutjvef7q2ujsxtt45csu0k688lkzu3ldrxkxglt5qydruqqqqryqqqqthqqpysp5jzgpj4990chtj9f9g2f6mhvgtzajzckx774yuh0klnr3hmvrqtjq9qypqsqkrvl3sqd4q4dm9axttfa6frg7gffguq3rzuvvm2fpuqsgg90l4nz8zgc3wx7gggm04xtwq59vftm25emwp9mtvmvjg756dyzn2dm98qpakw4u8';

    final validityTime = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 100000;

    final decodedPaymentRequest = decodeLightningPaymentRequest(paymentRequest);

    final offerFile = XchToBtcOfferFile(
      offeredAmount: offeredAmount,
      requestedAmount: requestedAmount,
      messageAddress: messageAddress,
      validityTime: validityTime,
      publicKey: publicKey,
      lightningPaymentRequest: decodedPaymentRequest,
    );

    expect(
      () => {CrossChainOfferService.checkValidity(offerFile)},
      returnsNormally,
    );
  });
}
