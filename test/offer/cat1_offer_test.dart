import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

import '../util/mock_chia_enthusiast.dart';

void main() {
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final walletService = StandardWalletService();

  final nathan = MockChiaEnthusiast()
    ..addStandardCoins()
    ..addCat1Coins();
  final nathanCat1CoinAssetId = nathan.cat1Coins[0].assetId;

  final grant = MockChiaEnthusiast()
    ..addStandardCoins()
    ..addCat1Coins();

  final cat1OfferService = Cat1OfferWalletService();
  final cat1Offer = cat1OfferService.makeOffer(
    coinsForOffer: MixedCoins(standardCoins: nathan.standardCoins),
    offeredAmounts: const OfferedMixedAmounts(standard: 1000),
    requestedPayments: RequestedMixedPayments(
      standard: [Payment(900, nathan.firstPuzzlehash)],
    ),
    keychain: nathan.keychain,
    changePuzzlehash: nathan.firstPuzzlehash,
  );

  test('should validate signature of CAT1 offer spend bundle', () {
    expect(
      () => walletService
          .validateSpendBundleSignature(cat1Offer.offeredSpendBundle),
      returnsNormally,
    );
  });

  test('should bech32 encode and decode CAT1 offer', () {
    final encodedOffer = cat1Offer.toBech32();
    final decodedOffer = Offer.fromBech32(encodedOffer);
    final reEncodedOffer = decodedOffer.toBech32();
    expect(reEncodedOffer, equals(encodedOffer));
    expect(cat1Offer, equals(decodedOffer));
  });

  test('should parse CAT1 offer files', () {
    final usdsAssetId = Puzzlehash.fromHex(
      '6d95dae356e32a71db5ddcb42224754a02524c615c5fc35f568c2af04774e589',
    );
    final sporkAssetId = Puzzlehash.fromHex(
      'e9afb5ce4f89074cf84a5f3b872055e479c397e5f0acc16e917903b9991479a2',
    );

    const offerBinOfferFile =
        'offer1qqp83w76wzru6cmqvpsxvgqq4c96al7mw0a8es5t4rp80gn8femj6mkjl8luv7wrldg87dhkq6ejylvc8fvtprkkww3lthrg85m44nud6eesxhw0sx9m6p297u8zfd0mtjumc6k85sz38536z6h884rxujw2zfe704surksmm4m7usy4u48tmafcajc4dc0dmqa4h9z5f27e3qnuzf37yr78sl6kslts9aua5zfdg3r7knncj78pzg4nyzmdxdhxa8y7cr6v80zcal6vn70e6l7jvefay2w3taxa40llr08mgtgx9fchmmhm52adh3ej7alls3y84503wzpj4ny24522mf20qehlchu38t4ult0kgdvrppjjqza44dhjuaeulerr3er7a0ttl2038f0uk89x97f8fux7h8ulzfjldmle8kwhxlx8kvpptmq4tlx2xnxc2amwra7l9edrwpsnmymnu4quz4dta6msx6m2e5tawwzs4047rh8nqcdmccw96sym94sn3u27cucw2gkmejvluu79mdd48ax2yd8ul5fvmphyn085mzkdr9e2llucket2g7tt30e7ccmq45xeqd8a0lq6u3uwf8hl0ph4wlh2jvnpn7c5ev8hs0zte8v00aj9d86m2n6hxlnluhl4v26nf5tcvp4svg3eukmedd0t0m9s64d7l3jlkp647ux4net2dpaxx73e2xawjune2hlcml9vr9qkq9fxeumlg8m8hyvwmqtey6hkekasgt47ek203cfu4wul0dts3dva8d4ajexgcjuq4tk07tec43dl0vtwk0x7eqc2van8e9edvf7039l4m09h80ell32a8h4fx337wams3zh9s7vqhxcaztl4jhlwemzs79x4cvckrq7g76vadajxd4m8k7mh3806jfe5kcc9gn88jwln07g8wrlwz7vnutfc89khn4ctmmyccqhhq02m4qffg0pxleu5jxtry94j2m8646p3vpxqc0mugf9lweqya79vun2uh40cgx5unxd2vd2d7y9pdk5uxsnlhlwyslna7z83v6kz5s62rxmvp99p7skddw52g4z0p6ezvcaevxdvn8hev2cx3d4t7ylejc78r3kj2haxq8e4e7hzllwe54clh5n3s9cdkqkkvvehunzfhs245v2dtmnvq8m74wczw0skq4lk0l9ew5uk3qlwr2930e5my4mt48npp0cg3n6ac54wpd8n09tfuyhne4usala7ww7vckqmr93tsn0xdxldl9hkceatard28vtr4940qcq9dld6hvm6l706';
    final offerBinOffer = Offer.fromBech32(offerBinOfferFile);
    expect(offerBinOffer.requestedAmounts.standard, equals(0));
    expect(
      offerBinOffer.requestedAmounts.cat[usdsAssetId],
      equals(15 * mojosPerCat),
    );

    expect(
      offerBinOffer.offeredAmounts.standard,
      equals((0.25 * mojosPerXch).round()),
    );
    expect(offerBinOffer.offeredAmounts.cat.isEmpty, true);

    const offerPoolOfferFile =
        'offer1qqp83w76wzru6cmqvpsxygqqwc7hynr6hum6e0mnf72sn7uvvkpt68eyumkhelprk0adeg42nlelk2mpafrgx923m0l4lg84hc5wfcax4h0cxh9832t8ecfwt43p7gn6dp8534xegvt2ltd6tstq89fv80dtme9l7c8erqk2qkv42rtu4v333t7u7wlhnm0ah3wmyt02tc0c8l4hx277fw7tqzmwda73akfqvjgdxepdcvavnl6sv8at882x8ud7y4tahk692t3gzjq5uwe68h9he3mhf0dca0dv55z7k0jhu6h7t7j30w6046gnwcwj8uegkhcuzfznckmpjy6d5xzpf5q68rv368rvs6rrvj6rzq30p85avxqpzaashzhwr4yx4aaewfuatrjfpvn2gafvtnn63nwg89p57l86c2pt2da6alwgz2nmh9lwkw0lfemf786778tw6z4pfu4q7nmllfsumsdu3x2ucwm83f2zaqsk5tygtlrsae2gxrw7xrklmx7mtvppll2m2w3nzfe27j7haxrlhl9l820nj70heuwjf68l0a9yeseh8ald6mwt6ck6cl2nvhsm0j72rfg8mrgqvjxnunlsys4dnnl5msx2jwcr9yyexml3w795xd0rrr6m5dej36rx0rwkfyvm2cdpjz60ramha7tsv47mjrd0e9a2q2hmlu955dqvtgnw0w3h0mw4cahf9ht4r7ttw4dkltwc06zkwn7ecthn8u75x5sznullqghc29ef3wlvah8sv0astdvvhcwt8xyfdcrjahwalzyrwm793w6zhty8luhcsz3u8xqehudhem0g8rqt2atlv2tvf8xt955t83a7dm9zqdmg74yk9uzmn0hplupfknkm9wl342sw8slt6v9cl0med6692ummqkl9v45gvdeadwefgk4jzd5p0gvxcmlstpy6rggthzp3e8z0nxlk7km4w9atdp74umv3e76zq6203rryrjld0s24asfm8q0n985rnqzq4ppdhgdlgxmhu7erxfzl3nwllr0he68hf4jt80h7haug43sk0x8sv2rvahvrg2yh4kullad9r0xf20khs7qwud8eajwn5l9nmt5e8a37h88njw4kge6v03cdkjnmt7079fjex0hl4l9jv20m6dn5l7hv89vk3t4dkflunc8squav2m3sjn8m5r';
    final offerPoolOffer = Offer.fromBech32(offerPoolOfferFile);
    expect(
      offerPoolOffer.requestedAmounts.standard,
      equals((0.0125 * mojosPerXch).round()),
    );
    expect(offerPoolOffer.requestedAmounts.cat.isEmpty, true);

    expect(offerPoolOffer.offeredAmounts.standard, equals(0));
    expect(
      offerPoolOffer.offeredAmounts.cat[sporkAssetId],
      (3.253 * mojosPerCat).round(),
    );
  });

  test('should parse a CAT1 offer', () async {
    final offer = cat1OfferService.makeOffer(
      coinsForOffer: MixedCoins(cats: nathan.cat1Coins),
      offeredAmounts: OfferedMixedAmounts(cat: {nathanCat1CoinAssetId: 1000}),
      requestedPayments: RequestedMixedPayments(
        standard: [Payment(900, nathan.firstPuzzlehash)],
      ),
      keychain: nathan.keychain,
      changePuzzlehash: nathan.firstPuzzlehash,
    );
    final parsedOffer = await Cat1OfferWalletService.parseOffer(offer);
    expect(parsedOffer.requestedAmounts.standard, 900);
  });

  test('should fail with null keychain but non-empty offering coins for CAT1',
      () async {
    expect(
      () => cat1OfferService.makeOffer(
        coinsForOffer: MixedCoins(cats: nathan.cat1Coins),
        changePuzzlehash: nathan.firstPuzzlehash,
        requestedPayments: RequestedMixedPayments(
          standard: [Payment(1000, nathan.firstPuzzlehash)],
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('should fail with null keychain but non-zero offered amount for CAT1',
      () async {
    expect(
      () => cat1OfferService.makeOffer(
        offeredAmounts: OfferedMixedAmounts(cat: {nathanCat1CoinAssetId: 1000}),
        changePuzzlehash: nathan.firstPuzzlehash,
        requestedPayments: RequestedMixedPayments(
          standard: [Payment(1000, nathan.firstPuzzlehash)],
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test(
      'should fail with null keychain and both non-empty offering coins AND non-zero offered amount for CAT1',
      () async {
    expect(
      () => cat1OfferService.makeOffer(
        coinsForOffer: MixedCoins(cats: nathan.cat1Coins),
        offeredAmounts: OfferedMixedAmounts(cat: {nathanCat1CoinAssetId: 1000}),
        changePuzzlehash: nathan.firstPuzzlehash,
        requestedPayments: RequestedMixedPayments(
          standard: [Payment(1000, nathan.firstPuzzlehash)],
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('should fail with null puzzlehash and non-zero offer amount for CAT1',
      () async {
    final askOffer = cat1OfferService.makeOffer(
      coinsForOffer: MixedCoins(cats: nathan.cat1Coins),
      offeredAmounts: OfferedMixedAmounts(cat: {nathanCat1CoinAssetId: 1000}),
      changePuzzlehash: nathan.firstPuzzlehash,
      requestedPayments: RequestedMixedPayments(
        standard: [Payment(1000, nathan.firstPuzzlehash)],
      ),
      keychain: nathan.keychain,
    );

    expect(askOffer.isComplete, false);

    expect(
      () => cat1OfferService.takeOffer(
        askOffer: askOffer,
        coinsForOffer: MixedCoins(
          standardCoins: grant.standardCoins,
        ),
        keychain: grant.keychain,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('should fail with insufficient coins for CAT1', () async {
    expect(
      () => cat1OfferService.makeOffer(
        offeredAmounts: OfferedMixedAmounts(cat: {nathanCat1CoinAssetId: 1000}),
        changePuzzlehash: nathan.firstPuzzlehash,
        requestedPayments: RequestedMixedPayments(
          standard: [Payment(1000, nathan.firstPuzzlehash)],
        ),
        keychain: nathan.keychain,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test(
      'should fail when offered amounts exceeds offered coins amounts for CAT1',
      () async {
    expect(
      () => cat1OfferService.makeOffer(
        coinsForOffer: MixedCoins(standardCoins: nathan.standardCoins),
        offeredAmounts: const OfferedMixedAmounts(standard: 10000),
        requestedPayments: RequestedMixedPayments(
          standard: [Payment(900, nathan.firstPuzzlehash)],
        ),
        keychain: nathan.keychain,
        changePuzzlehash: nathan.firstPuzzlehash,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('should fail with invalid cat amount for CAT1', () async {
    expect(
      () => cat1OfferService.makeOffer(
        offeredAmounts: OfferedMixedAmounts(cat: {nathanCat1CoinAssetId: -1}),
        changePuzzlehash: nathan.firstPuzzlehash,
        requestedPayments: RequestedMixedPayments(
          standard: [Payment(1000, nathan.firstPuzzlehash)],
        ),
        keychain: nathan.keychain,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('should fail with invalid standard amount for CAT1', () async {
    expect(
      () => cat1OfferService.makeOffer(
        offeredAmounts: const OfferedMixedAmounts(standard: -1),
        changePuzzlehash: nathan.firstPuzzlehash,
        requestedPayments: RequestedMixedPayments(
          standard: [Payment(1000, nathan.firstPuzzlehash)],
        ),
        keychain: nathan.keychain,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('should create an offer from a CAT1 offer file', () async {
    const offerFile =
        'offer1qqp83w76wzrummwm0v6fg6guqlcdzegsw6xtys6cp4k3w33nkk36snsvzxfjapyr4n93g50dyjmzyw5ddzgqvd2y94aqjjvv962gdjpd9tm3n4e9jf5326k6wgvkemcwnx7lcd00axw0dreael70m880w00dluu7ulumeummtu2q5fv8jtew8ajndrh3uwkxg62ecfxtyejkzk2zkh2qwte80jp3h5j032hvvpjfc6qm9lnamtp3qk63w30ek4zk72ffecrffg8shs9u77k4xgjck73ravn9nlye2ykygwygx82ewfp5dkj96wk2jry20e262c5gj888ysfxnhmykskw424q978vrtslv0k5as6t0chk74tkkc09ml5rumekk8j4j8j789wkmctkulyav2uxjj6vpavlj2z783er609a7uyv3hhjkxq9hx84th2gdg8v2krx4vzz70g9m85vetks0sj48jfzqxx0e7cwqqvqzxqprqq337ttyl7v7vpjh0k5rlk0rlgjym8chjw29z6sn3mkgx585ghj88a5q6te3e5h6ugamhfaxax2h92zr002lz6hw428tnmsuz8jedwtywu3mv4nrm99f0zsd0rf4xkmgnlmnj0lnu065eurdu2hzkuuryhf0unfzjpda6dq0k67c9dd2nwkm0fmaps4h3chg40vmkjjezm9798hym0geq92wwfanqylmv7kvscena5sys7jjspc02gagnqa937dsj9w8ys7uztpkujxmlynymf89568u8t0hsa3etxhwf2c3nlw4y655lp3pzrcjrmr79gpxx820d8x207zkdcz6wca6km7hwn7trc9k0n8hnwgr20v57d7xnsw30uhcl7z2rnwpgrnw990wumnrlyw9s950m39pmexgwfytfz8gr4lqepj8g4q8psghe9acd78k5mmt49xhddflzwa2cz562jd80srsmwd98vh9n3790nzdpw6m57mgrvmygxx4zhtwd9egs3zmty3s4tpz40erckpps6zle363vne8esdrzfzvrkfz4pwm5dyt55escdey5w4zvwfu7mfwd5lzuzr6ldl2tth4g78e0lqfte7rp4dkcjh5dn4jydtjfa0jmxlk493xkn9v0sle34a52g3395avw6y5gquk6qdm3lchspqep4583zpgys8qg9qzzsppgqs5qg2qy9qzzna5mgpcdgc6a0pwdyvneckavqjk8xdw6kmy3r3xde87fmxga83z57r77qxh0pfp298w30xf48f48sjehlkcf4kd88g58vd905zer4nylvprje2u6w6mjgs6fvu6sd24tk88m9898aww82fhd9q9rzxdmg6uset82gnqf8u8zz2gslfqn5dm8ykq2p7vykh4drnq7wcfntedtnht6q0hj5yl3jcxwey3llx0k2selj4zhzdfx9fsw6rpcqvuqxwqr8qpnsqecqvuzxz7u5xduzc4p4f2a0k6wfk3qx47e60dsc6zk7c4tg2xhza76s0t7pw35cwgcfscs555h3xc3l4p445ty0dfr7m5n2446vwjea7zsh69y2pxa6vugx0587he3uljfjwnghhursdfal3ksu42ludq0g9sh8570qcjgk8e7frygwzqajxlxx4yv459nlvjcdhlf8k24n4yynnqq7zsxj68lqpq0rqj7h0492538p3l0husn9qhq2d9ujqwur4qq6sqdgqx5qr2qp4pcut4qsm676jnn0eg7l6dk4zk6kdj8k2vnk0rra78p7l9ychnnjmfg6trpqd9jx2g7uz87yyvnwx3n2f7xu5m02lzsl87ptdhqf2kec6akl7s2hr3jcm2umzpusputhqn7kchgr2mrcrplfrxqkcef36j56kdjtnx2n5ytehetjtuw7esmumjpf5xlh9ydcjnf89q94qq6sqdgqx5qr2qp4qq6nu4hhqnau472zd72ml9uzaa9rvqkhrcmpps46kptakckaff0y9gdrkk9jt4zcuya8p6yd8kp7xdkrhc8vd539j0n8wvhlfu6mp5459laafkhw474sdjy83q5crr7arrhdy467870s7jf2aptnp8t64fkvupg57h0ff2dgqc7lfny3h752r69cwv3gdd9u6pqgz4qq6sqdgqx5qr2qp4rc5t4rs8escq75u6d7ahllcfmkdk50dhjf93nwaauul8wry3kchr2u8wmgnp3xt6zex55supclk6tcg8n3f9ch5jscrl7mv03ey8qlu8kwa6y7537fqdjkfnv9x84v75jm25z04948lcqc7lvfcjl44vw56lhdusk4c8hvhtapwgq7yp52t2avamwl2k90pgt95uxdfm6hnvt04a99ffwd4kp3vz6a9avtjupyeyxnsd3kv23wq56tesqdgqx5qr2qp4qq6sqdgqxjl3ydqlxgz4qh2p5fth3pkg6ftzr4z6km4klcx3tjxklydkjfd47pc39jsu0x4ahs7h52mmum5uyu0m4xv5trdze7m7t2r0up7348aec2whdwag38yq0zdfy87y59aypk2u2mxtcjjkzvrdafk6h4cjuxdmy6tsvk3l29fwhcna5edkw7600ckx8xrng290k5k7zvvvvhvz2l07jxamx36x8zprmv48emqvp8wrg4dqswns0p4yp2kxsw6fe42anedgy7f48mhgxnmdyrsaaatjrhkecma7wuelsys2csr9gyqpsc5';
    final offer = Offer.fromBech32(offerFile);
    expect(offer, isNotNull);
  });
}
