import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

import '../util/mock_chia_enthusiast.dart';

void main() {
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final walletService = StandardWalletService();

  final nathan = MockChiaEnthusiast()
    ..addStandardCoins()
    ..addCatCoins()
    ..addCat1Coins();
  final nathanCatCoinAssetId = nathan.catCoins[0].assetId;
  final nathanCat1CoinAssetId = nathan.cat1Coins[0].assetId;

  final grant = MockChiaEnthusiast()..addStandardCoins();

  final catOfferService = CatOfferWalletService();
  final catOffer = catOfferService.makeOffer(
    coinsForOffer: MixedCoins(standardCoins: nathan.standardCoins),
    offeredAmounts: const OfferedMixedAmounts(standard: 1000),
    requestedPayments: RequestedMixedPayments(standard: [Payment(900, nathan.firstPuzzlehash)]),
    keychain: nathan.keychain,
    changePuzzlehash: nathan.firstPuzzlehash,
  );

  test('should validate signature of CAT2 offer spend bundle', () {
    expect(
      () => walletService.validateSpendBundleSignature(catOffer.offeredSpendBundle),
      returnsNormally,
    );
  });

  test('should bech32 encode and decode CAT2 offer', () {
    final encodedOffer = catOffer.toBech32();
    final decodedOffer = Offer.fromBech32(encodedOffer);
    final reEncodedOffer = decodedOffer.toBech32();
    expect(reEncodedOffer, equals(encodedOffer));
    expect(catOffer, equals(decodedOffer));
  });

  test('should parse CAT2 offer files', () {
    final usdsAssetId =
        Puzzlehash.fromHex('6d95dae356e32a71db5ddcb42224754a02524c615c5fc35f568c2af04774e589');
    final spaceBucksAssetId =
        Puzzlehash.fromHex('a628c1c2c6fcb74d53746157e438e108eab5c0bb3e5c80ff9b1910b3e4832913');

    const offerPoolUsdsRequested =
        'offer1qqz83wcsltt6wcmqvpsxygqqt6eygz974zk0y99dt8zz4v8tnzldmryclq5mla6lhmclhmwv3m6gqf5c8fupxm95vgd6mkzx9wmdrzndk33phtwclc84p3gx98wp0x80lww0pt4469udhhxg4qymj3mzr8ts0xx0t5d33denkp4h0rdv2c24gk0w63dclsc7dv2aar4akdz5nfw53v5usfe3yml8qlzc3ltq0auj57wap2szt2mcmns4svc5sespa0dts7he2wgac8rxykfdy27rnsmnl20etpl8chmn4tfw0hx83s6elq22mmytargvndkmqar6lxe97nwhnm70m29s4t9wt2vrm7s32338h6ws4zszgmh3yg55syk8e72h38nlp0496uhjtf4c562qkw4xhl5krz9u46jm0xf8m4nvj6llyvrkmzuj93mng4hafml60xhd7a4yw4z7hz75u3upvh0w05emdlyelxqrdthgf226a4pkn2svu72kvcyrxaxwwm3nkauh0909lffm04td57uxaa6u475ahc7082f567v47h8fk0nx862cntfaw0866kaq79xk0y6jlgymp4sxfzd0a0mq6u3u0f8h00pl5wlh2jvmpn6cymv0kstzmm8vw0ej408jm2h68xlmlunl9dfs3acnscrtpckyngws5u6unl0sk795d9s74rear0ll49tl0u7dhmu2eh2wj9208mc9nln0vxfqekc8234lxl6pfmm8rasa88m6dke04cykf0ruwu5hl5ktczwhklkl3ew8lnfrern7c54q9tal7zl547753w4sa0puawmwx8gel9kydfjm28aa0tumtevwr54ey44j3rdt8qqrksjl4shpmr2fvycn7vty22z03vunfhamgf0cd20j3hqc78m6q7hlyl3slzhfha00qx8k85l70x45xya7hvcrht35e8vamlhgyrmuaaktf3r0xn38w482knyurk404au5a04ut4j067jw23ylaldvaulae433lr4k3s5spk3wsprst2myfh';
    final offerPoolUsdsOffer = Offer.fromBech32(offerPoolUsdsRequested);
    expect(offerPoolUsdsOffer.requestedAmounts.standard, equals(0));
    expect(offerPoolUsdsOffer.requestedAmounts.cat[usdsAssetId], equals(0.42 * mojosPerCat));

    expect(offerPoolUsdsOffer.offeredAmounts.standard, equals((0.01 * mojosPerXch).round()));
    expect(offerPoolUsdsOffer.offeredAmounts.cat.isEmpty, true);

    const offerPoolSpacebucksOffered =
        'offer1qqz83wcsltt6wcmqvpsxygqqwc7hynr6hum6e0mnf72sn7uvvkpt68eyumkhelprk0adeg42nlelk2mpafs8tkhg2qa9qmxp3mp9hd0p40egtjc2t8lh9kldt70h3gatft30gztnle5ddrtp8wtnjqv43qkdaujr743dltdr67vx6ha0l3huslr8awq67r6wyntkln06xaw7uslmlum2vhd4aux33s8klqaq3nukvc7hamu5ln0wk239xhgnk0ykmh4e822jut6tl42stnl992lsqrhuxf4kll47yznx4q93kms3ljm8wqkh3f9tru5n0fw5680m9gwyzvfylpcrz0ykg6d3lg7d3lg7d3mg7d3mf7vpn60ydxclw34husq27uz7d7e7y77xkmf5mcmrwvn2gthfzkxx75q7vu7hqmrw6r8vmfwj8264q42mvn8ruzskxlaklvrfwfyx87ch3j83dt4crhtkcpkrjk6jvreexejdv959tq2ucyx7w4tyvzpnwmzstjnaz8z3kg6r93dzvttjn669sut6jmgsnhm5c7x3u784dzelwvuzdm5ulf5j7se8maqe6xlleg0jtm5z34qgyrrgsz6vhl30yr2vf77lqfhr5yzkpqedtehls2z93ud9em0uh8xaz58hvlyjdzvl5n67a0w6jwazhefxwtjfarrxmlsd23jl7l7phua7ce3jtumxet0nzesaz772t0n4q6q3e87r848cwead0cmhwedugg0fl8lc95mj4un3dwr942lam05va4l83w3dxa86m4e3ev3djxul4cjwtwrfkl74lu83cqvkznlnlla6u2v7ekwhtmynp9l6xx0rdnld2a52e2ektdgks4rlum7fkzc3z68chls9adkrwv8hth4a7xheueyaunekn7dd00626mn0w0lfff0eexfr040lq9kj84xsl2lcq5znpvf95r2yny6lmhhrwrhq0n7hrd9wulqh78td6gpv62eur0f4ytsnye6ksgtgwze8esk9q5pv0ek3g6796alwnkljxwym0haww8jntk9uwjmlalj5sw6g5jewfskk74ad64w0r4pv8lxl5mjpejn6austdsul8ed8katmxt038vu0lx0rnl6kkts5a5aduc23nxcgndthdkt03hlcx52m844h46gr2924hzlk5jkcxsq8kk0twyf29uts';
    final offerPoolSpacebucksOffer = Offer.fromBech32(offerPoolSpacebucksOffered);
    expect(offerPoolSpacebucksOffer.requestedAmounts.standard, equals((3.0 * mojosPerXch).round()));
    expect(offerPoolSpacebucksOffer.requestedAmounts.cat.isEmpty, true);

    expect(offerPoolSpacebucksOffer.offeredAmounts.standard, equals(0));
    expect(
      offerPoolSpacebucksOffer.offeredAmounts.cat[spaceBucksAssetId],
      (300000.0 * mojosPerCat).round(),
    );
  });

  test('should parse a CAT2 offer', () async {
    final offer = catOfferService.makeOffer(
      coinsForOffer: MixedCoins(cats: nathan.cat2Coins),
      offeredAmounts: OfferedMixedAmounts(cat: {nathanCatCoinAssetId: 1000}),
      requestedPayments: RequestedMixedPayments(standard: [Payment(900, nathan.firstPuzzlehash)]),
      keychain: nathan.keychain,
      changePuzzlehash: nathan.firstPuzzlehash,
    );

    try {
      final parsedOffer =
          await OfferWalletService.parseOffer(offer, tailDatabaseApi: TailDatabaseApi());
      expect(parsedOffer.requestedAmounts.standard, 900);
    } on FormatException {
      //pass
    }
  });

  test('should fail with null keychain but non-empty offering coins for CAT2', () async {
    expect(
      () => catOfferService.makeOffer(
        coinsForOffer: MixedCoins(cats: nathan.cat2Coins),
        changePuzzlehash: nathan.firstPuzzlehash,
        requestedPayments:
            RequestedMixedPayments(standard: [Payment(1000, nathan.firstPuzzlehash)]),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('should fail with null keychain but non-zero offered amount for CAT2', () async {
    expect(
      () => catOfferService.makeOffer(
        offeredAmounts: OfferedMixedAmounts(cat: {nathanCatCoinAssetId: 1000}),
        changePuzzlehash: nathan.firstPuzzlehash,
        requestedPayments:
            RequestedMixedPayments(standard: [Payment(1000, nathan.firstPuzzlehash)]),
        keychain: nathan.keychain,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test(
      'should fail with null keychain and both non-empty offering coins AND non-zero offered amount for CAT2',
      () async {
    expect(
      () => catOfferService.makeOffer(
        coinsForOffer: MixedCoins(cats: nathan.cat2Coins),
        offeredAmounts: OfferedMixedAmounts(cat: {nathanCatCoinAssetId: 1000}),
        changePuzzlehash: nathan.firstPuzzlehash,
        requestedPayments:
            RequestedMixedPayments(standard: [Payment(1000, nathan.firstPuzzlehash)]),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('should fail with null puzzlehash and non-zero offer amount for CAT2', () async {
    final askOffer = catOfferService.makeOffer(
      coinsForOffer: MixedCoins(cats: nathan.cat2Coins),
      offeredAmounts: OfferedMixedAmounts(cat: {nathanCatCoinAssetId: 1000}),
      changePuzzlehash: nathan.firstPuzzlehash,
      requestedPayments: RequestedMixedPayments(standard: [Payment(1000, nathan.firstPuzzlehash)]),
      keychain: nathan.keychain,
    );

    expect(askOffer.isComplete, false);

    expect(
      () => catOfferService.takeOffer(
        askOffer: askOffer,
        coinsForOffer: MixedCoins(
          standardCoins: grant.standardCoins,
        ),
        keychain: grant.keychain,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test(
      'should fail creating CAT2 offer with null puzzlehash and non-zero offer amount with CAT1 coins',
      () async {
    expect(
      () => catOfferService.makeOffer(
        coinsForOffer: MixedCoins(cats: nathan.cat1Coins),
        offeredAmounts: OfferedMixedAmounts(cat: {nathanCat1CoinAssetId: 1000}),
        changePuzzlehash: nathan.firstPuzzlehash,
        requestedPayments:
            RequestedMixedPayments(standard: [Payment(1000, nathan.firstPuzzlehash)]),
        keychain: nathan.keychain,
      ),
      throwsA(isA<InvalidCatException>()),
    );
  });

  test('should fail with insufficient coins for CAT2', () async {
    expect(
      () => catOfferService.makeOffer(
        offeredAmounts: OfferedMixedAmounts(cat: {nathanCatCoinAssetId: 1000}),
        changePuzzlehash: nathan.firstPuzzlehash,
        requestedPayments:
            RequestedMixedPayments(standard: [Payment(1000, nathan.firstPuzzlehash)]),
        keychain: nathan.keychain,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('should fail when offered amounts exceeds offered coins amounts for CAT2', () async {
    expect(
      () => catOfferService.makeOffer(
        coinsForOffer: MixedCoins(standardCoins: nathan.standardCoins),
        offeredAmounts: const OfferedMixedAmounts(standard: 10000),
        requestedPayments: RequestedMixedPayments(standard: [Payment(900, nathan.firstPuzzlehash)]),
        keychain: nathan.keychain,
        changePuzzlehash: nathan.firstPuzzlehash,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('should fail with invalid cat amount for CAT2', () async {
    expect(
      () => catOfferService.makeOffer(
        offeredAmounts: OfferedMixedAmounts(cat: {nathanCatCoinAssetId: -1}),
        changePuzzlehash: nathan.firstPuzzlehash,
        requestedPayments:
            RequestedMixedPayments(standard: [Payment(1000, nathan.firstPuzzlehash)]),
        keychain: nathan.keychain,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('should fail with invalid standard amount for CAT2', () async {
    expect(
      () => catOfferService.makeOffer(
        offeredAmounts: const OfferedMixedAmounts(standard: -1),
        changePuzzlehash: nathan.firstPuzzlehash,
        requestedPayments:
            RequestedMixedPayments(standard: [Payment(1000, nathan.firstPuzzlehash)]),
        keychain: nathan.keychain,
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('should create an offer from a CAT2 offer file', () async {
    const offerFile =
        'offer1qqz83wcsltt6wcmqvpsxvgqqwc7hynr6hum6e0mnf72sn7uvvkpt68eyumkhelprk0adeg42nlelk2mpafs8tkhg2qa9qmypkrdk8r7e8dn8cys4t0gh9gzpclu09nlu8af67nv0lruwayn4f9gd2aaqj22ekaflxalfjyatnxmwgj24w7zd37hxks4rufnk3htgw0uhv7hejx0jh7x7r3v455pqccrmpnkyge4gyu6dul05d04dm5lhmetucdlew74dvcc63ukywltrm99ltmrmxcmkdxptllw2ztxnw8u7sql9hrxt5eu3pgx643f0al09m4rp2fcpq8z9f3xthcqduhg7d3mg7d3mf7f3mt7psmt73smrlls02resx54c9ucdlaeeu9wkhgl3k6uez5gnw28ugv4wpucflwekxphxwcxhacd9ntf24zede2dhr6rnm432hswhkeutjf92j96njp8kyn8uu8utq84dplhz2nem592s2us9x7w90yvpph0tpl8h3l8xpe7sflkecxjnnvpkvlah4w5mw58x3xaaha2awtxhlnvh0ufw6twc6nmz3hyd8lrmcef7el5jpkqgynygqpjgh0k07qjzfk70lngvpda0uy6kquepg6yus920ewuef86jnsvn0crhl7lc28ed9rmyz663jxdn6fh2dmn5hpk9mudlnyc5jrag6nn07qhlv4xtmhv3xwdvcme7mqjekl6z7ddful2cmk7ffhqkhwp6ws4zvezsy4wela06pe3fje2eu7zm3k24nah37xu2wj7vnwtk489gljfmz4neg0henkl4fusjnlllstnyxt7kf30ky7lcejnd5ty4fr9cqflethna7nj6e2gntx64xjmanhhqlup0r7zw395hh03sf6a0w00m7m7gst6hdvnfc7dnu8hrep5wrtzuka5nwtlmwvquhxu2lc0lstwmzftlkstasxu43qj8ydfw0tq6p6mx0928nkk9lv9l2dmc9m3hpvsqmfr2sj0k0uq6z3kelanxpzavsy52xc3ajucx299hva0rg2re0cn6nh0g58ye462f6c4xc5vvhdedkfkuhg8r2zs5zzdz0z52lahwhwwx00kug49lw0k06s3xjwl80zjc7dzf5t6nw40wxh8s6kllpzm6wnflfqa04j6t34af8mdurwrdy69macyyn8fh74sghl9w7q3kz39m9q36rpr9snk68t9m5dlvdhepnzlj6gyv8fw94mv7nt47afezjjsmh0t3vtndax006tesamsrv66tcvwec97knz5g5f5qkhptx5zc728v97yas99fvcjw3ntq2euhcc9uaa2fhqq9g56czvtkul7vleljkvzvmdq75nwq0cq6vl2h97pu42zh3jeev08mka762u2tf00nmlejnwcqx86j7vph4h6apeaqs4r9ldl5ru0fj2pa96lmmr435pwk6e7huua5wuzkx9lnc38xmmsa6gl9t2mn3tq5r4fej7h537ayjf9420dlvk64f6xkn5te2ls8cshhrxdw6uk606ds5fk8ysld0hrpfd4r0mrjtrgyq0089v9hykz07t976f4anumcvh05t3093akc7thv0633tmmd9f79m2r86uk0t070852klhfuvvnedudp8h5yudcqgu4p8acxh9m7g';
    final offer = Offer.fromBech32(offerFile);
    expect(offer, isNotNull);
  });

  test('should parse this offer created after zDict had empty byte added', () {
    final offer = Offer.fromBech32(
      'offer1qqr83wcuu2rykcmqvpsxygqqgjnmp02ee85zk09aar7whk8673ajzmnmtdx5ajlnhq7mu7mzztflw8fswhc8d6nga5l447u06ml28d0ldrkn7khmlu063ksltjuz7vxl7uu7zhtt50cmdwv32yfh9r7yx2hq7vylhvmrqmn8vrt7uxje4542svsh77vsjfcnykl0lvz449g95urjvt3gel69v8p9cddwxtd59e4wn7ssptf2ged3g3r5luvjzvst53zpdk2a8nkv2mhm6jm9hs0x7m3kprdnev7dnm84rx8vl2udlu0wyp65wfy5kl7ws8y7hemapfg9x0eyl0pvesjgvtf24r0a2v49hq5yyde7wllmmlxd3d5qpp6jqxemmekpqjajl8hlhhw72hf9d40quj8sky2lkuvdazpm0m4dfnzaf7mje09tzvsrute7un4266cpv6x9knlh96gsnat7mnv0s49k0la2wpvt4ldyrk3sesh5vke35wke352ke35zke45z5p3vxmdchqq8allvphut0z3m408m48hnwu62msk07ywavmc2unpd4stnaeau9jelltjswzukyg454fq2acws300wpdg5r3k0rph9wmakdupvnyk9kwupwrhlwrrm9uudl7u3w3xntzzew70umne2cltxal9nnx8w65lw7xajvlhvkcdqsa0eyxmxqxeqekaluz70a7l0vd78vlgncklw4u9nknmmduhtzvua0h5d3su03feelhl75duln787yasu9q9sxwgfjdl7zu6je5vevwewm4v6s4henta9a4m4ahmjgrfrnmw45lxsamwluc09yhqd9hkllkl7t6cyrq2haaa3e5eunlkhcx3l07gyaryhadke67tt6km379ew4kv67wluxvjntljlvqswj7jmay2hd5tzmheg8h0fjfmxkxf3ehw7m0x4sxv5y4magt4lua7yhxl7plurstlqahvnpfam6ll6v0ns9lehnj2n3d24g0ruj50et8rxaeutdpvewj5pwcgxke0uteq6nxg9kz933y77nhm45u4zv7eltq5f9a849csepuwte7dylng0cjtwu3yj794anjjdkyyngzqarsdc96cz2v0627kv8hmykgm3j8rz7t6az7npxpevhfkyl4lcpakn3u5eeklk0rtw66kpaxjjuekhunuhvz7ka3efhl6exfnvkh0ht4eche79hahlr79cct3d8rx7xudjuxrdwmdmt6nl6avxk94n4dtl5n7fel72leqqu4yfd7qxjzf6r',
    );
    expect(offer.requestedAmounts.cat.length, 1);
    expect(offer.offeredCoins.cats.length, 1);
  });

  test('should create an offer from an offer file offering both CAT and NFT', () async {
    const offerFile =
        'offer1qqzh3wcuu2ryhmwu0v6ffhg7qlc8z2d00deqkhwlpp5usmg5hxzzfa6m5s5xdrp3p3nge339d9x8g425z3znmm4aeqj522y2gs22zgjzvk29f6zx5j0rxg66wht8h43uv7kaxw0089nlhqa4vmkmt8mdau7hk04luuanx2q5fg2vtcd8utvh4mxgxhnm3q6hcw6l3y4jck8gct3ct000lzdc4vun6l8zt3wdsm9mhltgflm87vrps65nzetn04aczrdlj6w3us5l0pv3dg96cjjkagmqn78r6n3ytdlxt33r2xg3er3whew8rg7e90x09hctgcls7znyew2ua8eakrte93j3ya4m87pxxa94j4x4r5uhtyfaexkkqgznrzgl3ezs3ww8dv7sj3arzdr4t9x9jt85kt53y608nttlgfmma3wz973y0d9egn9kytdky5035w5ete2te7rxw4zedgdyltxp5uwd9mfq7dlkgqwq9cssrrzzrlu9w8yt00gdahya2u9vae5hm5kmcsll0cnranrv4xedrec4hdxu546mkuvrju3vav267jaqs7r5p9y0p2flkj7hnjcyd2c77y00j8jzxj3lx6uf2apl8s935xwal8ajvwu0a00x8qg6ly6nnyd6qm20p3krqkv6mkfkn9mkl68lx9e6j8c0pugv9ly6p5qy9x8lm5gxv7krgwg02wghn2k48f5p68424n7kwnhgpltnv3etxu26qk04dka67ww23xtatmkgftc8lvzq0yafhf4x44ps94p2q4sspxplr38pk45czk9u5unez9yzcuf8esasvyssgmczj5tyau8kyjzdrlyzwj7gyzpp5y29tnaqzz7zwrd0r2qq743rl8aqfcygx3xc9zv9gcgvzmaakxyuup5n4kmwhddg4ejtyuucdws2j2u9vgt356hreylycldqz4gerjdasmrh3lphfq7mhmfs537kj7f6k76v5k57jv879p8f6cn4jffpc0luwq0ze828q54qxeyaxv6qywgggg2sl5pusxxdwp0klaslr5x5lrqkpk35854xvxcwfs8qgp9psn5nuruaxqph59wecamzdzhpkvfctg5dnknnslrp4v49l28wq8dtf56jm5tgt2ctwvg7svxhgddrsmgdj9lhsy0wr9z0hytcgyn9gsn8x8p56sjz75x0ejyk5ke4hq7eqmrcf35vze2k405eh0svjg8c4avmrtqtum6gpk0y2q057kg2trtzl2ea845x7hx6jrhpmkxhw2j29ajvftmt68aj8p7c6eclsncw85gflld5kaqhcphzxv8w8q2p0jr8f8078hcandan4uhx729vxqtjteaymqrntdqcxur2a7gc95tn552judqrtwxc4wuwykanm9e7emu2gcgy8qgcagh37s7pllnwyzxzr6taasm52ehecca9mgj0wk38ffqygae7tc0hk0zvee8nzw5r48e26xvravphk7850lcdf75ll4svsax8g5zs052ntmthc4mda099s7rka8wd2hpwkr4n9ktwnhwg4yhkflzhkfjnuduqtccesdvvrgg78snx23wlaj553llepuxy8pnum5k7ts6jk38g8eq8zgw36pessu5k8n0cclv5wnl8ta6vj7xtsjsk6qt3e7lx37zmj96e9hkqg7z909p4cgfrkfvj73zjpav9j375zyknyd3a7xv6rcc2kk5z8rw7jephu0vgs0f6gvvp9hhpktacsq92vhjw6e49fj7n0p9ec5umvu0jlhzd7wj67s7eg9g7kpdytrd39u7hh9c0f8ral8a3plap0egsvh6mlh9cn26r064yc8hvzsm5plru32x3kmpm3rn4xy7ddrjelj95e9sd3lphvh37d8n7yeza4hm2un8uvwtc4k8s7cz76qu3r5emwqme0md8ug93qkyj6jrvg93qkyjmjrv0uur7l35vghummp8plm5sfm2hhrlpnq5vm5j567klrl3hmkus4mt52ghasme0kul4gxd3dpjlsn9n6u9xtwl24nrhf44z04zem5x0wakwpe5aw0hnm62djq02c39wp5keu7dfqzly9e4t07ryzy5g3xesap3gd4wgx9ep8k96n4hul6p38vwtpfh33a225x0cst4c0n2vh2wk8hndk05959t78wpp5ksme2wjs78ytas848hg0r9j5my9mmlm3prktnptdfla0qdpd63u9xkljvjn8mjvmk3n06tfnhm8ema9540tf7v0em0z8gvwze5c5vqr24rgwgv83l8rcum2j3wz9n3m6yprtrrn3u87ucsxgc6kmkmz0dr02m5ydgn7kk5ulqzy88qqqhemp3lulmslecaeycjkwxkd6akajjrnlm9thcjrvhu4pk7nku3rmv80thdkvpqe9a4ln3zcz0q2jfuy5rahn0cr6qqaqqwsq8gqr5qp6r7hqlsq6r7nlq2wr7r25w4dv87z9h2dd2dh6kcyzu78q7h9hlp0taf970aat32ze87afpywtxpqn3mldz074v7u7qsed50ea64dqk6xh43puf0lfcrr26379l09g6qzr9n6qtuxev4gu5efnk8qv6ck77nujfdwasgg72rte8y977nh84lcdcpr09z8pcsgxrmdcsetnt5rstj7vk3de4gnnrpqr08wag3d42wdrwc8y4fjjcn8rwehzs33svfh04azwul2pysupwqpcqqvqqxqqrqqps9xrupsp7e7hycqpk8hfyzsp76nsp6mcvl3jm7neaatj8er2cn9feqn393ca7ug5hwkdymjacwscx9nuefsxss8m0m55tnwq4mlt4dn0y5r5z9892c5882and6hmhug5pzprrhgzl2cqzfjt4nru44s70j5a294qtjhz0s4rz53f2m20k3cpcawp640pr3twgvzzdrcqudngaw0va08zav5nrvyqx9k4hhcqehkjuw0h29s8ytnz2t63h42we98m7cfq8q836xnyu9208jq5sysqpsqqcqqvqqxqqrq8qqpsr7s4qqe9j69gu976g4dw2q7xdlvnf5x52vw5730wgqulv8lrw57plzwpd23syk3h023t9x76n6ursqqqhnnyzvj26g4jn04lte9ctdagd84fp66vyrx58utvzjzr7gyl4664d4946p2ay5hcvkrymktg3ttwax8mtyw9nhyd765us6yyajzzezuqyeewtue48uvfamn4u4h8wt7cw7fczw0kf7j8vnfevk9xjhw94r8d4uwl4v46n3asygpyyqvzqxpqrqspsgqcpsyqvz0k9gyt0rtfrtzl6m8zcn7j5jxjtwxusjewf87gvaujxzmr4q80jkm66eslpj2udh972mmnxavpt0mj4r5rz3mj70kech8r5h4d8na9dznhg6rtpkq2vmck6eqse4et8ycadzp4s3xnhvaf96ka77x9f28fzdk7rvmeklchfa7mf2uuxyw3ppvs679kvkh4z9a7swexkmw5q376mckcvr9f9zmjz53rntm07zfx7377q4jrpezu6cz8r6sgcjggqcyqvzqxpqrqspsrqgqcy8v2ugzcy2h62tt0hc0d0my28r45lss95ut8jepdr02h5m22eapwwpde6grgvr24mhdldt5drvth97a5v3q8fkd0xtl0fszelgyhm4kp8g577ga6d6eld3p0zmqeu8ar0mkv0e6k27d2lf6x2f5t3pjjl8u9f775h0n6sqjzcm57vp5gazzzezz5fv7ks5czcvdat9q6vkdp7a5mv24aur88plk8n0e777nc77vrcfgq2p0r5jeadr2wul2pysuz7qpcyqvzqxpqrqspsdxrupsf7e7hyczpk8hfyzsf76nsgys5ttljmues4a0jf53tew2nueedm8v77g4d38s9uumcu4f5kpyydsv556zlkhfupn6ftexta9r5zf05t92ys3jtjle4t4euvnhvd6endss5v6se5kgyh2djd9ynhptr5a3er47kum8fsx6hn9rrvkw8wmg57xh6avlv6dup53r5ufyrqhhhnrufl45krau9ytrua4lvf5739rq69tz2wrqyxujk5xgjtqv326m6wzzezry9u8208jqzqysspsgqcyqvzqxpqrq8qspst7s4qhfzhyrg7j9clks550gmpvhmdzs598q3wlmm352asep0sryzm62n5rcvnr968a05njpggp039rpnp70mvv8cmvxwftduthd08e76t9k6xactza6fr69xrlkph9u02kuxdgzn0g4fa96ku3fs3e0jlfkcmrjlpr9xrn8unxg73jyyajyze9j50fjm56fj3ev95a883ykd2k9p5v99z5rtdm727cvx5uvqkmmpnvahuwep0q6jflswe7yqvzqxpqrqspsgqcpsyqvzrk9wypv67n7n9nh5ysm8k86udswamw54ru5z4nz97pwmzky8wj9dfvuuk9gwgft5defx4zmw3fgp4y238tjjq08fzcuwh4y6ctwtx9hvmtnxh5er8pse8jpzmqcu2qtqlgjufmeml7z42dqx5ldwf3udw940f0qz2zmv40n4mwgcd20gazzwer0clnlehtzfqyzds56sryd5azan6caxuayhgfzmgkl8x98f09jj5nefyxrh9cpfd7rmz8punhafspcc0m9znk9pn3m7ndad4yz5wujw37e845jyk9xdr0zek2c82eq600a24uy59yaqvmsc8j2hwlmc4emtlf93qqekwh8hd2ct62glmxqrky692dpa8vl98tl6c5ddnph56mdck22n6nxg9lfjzmmdfazcc8g52hft26rzsspex4088gvtqy9v80f42eadm6jwra22rx5v2tl4ekpt0zkz8wfesym8kh8t7vfaf9a6h937p3j06dlarc7fstygnlywv0c29yxgjzmf8t5emmea7hyrwued95uah385hupzgdw4eenm36avnmeytsnflmgrpeetlny2wn70wuzmv4903p4lym4ukpj2vgsmq5jpz2yfgpyqgj3z2yf5c0sxfw37lyctll2ykg7s0k6xh8jh743p48wh34h8f23yu2rzyyls4lges4ehwzzp6677d5u0x5spa8c6al7nun5yxplc6uhxauuwk56kk5t76zmlj3wrs8dh29w8uh7l30w0z0jf3rdmwlj5c3wlkgjav9ful5zawt8arndv84maeewtd7l5faaq0h9nddev9my2d8wtdlduzvxfjwak97x3efjec8rgnvwa2lwtp808k8dv9fagyh3cg7sm7vc3m0fjynt9ylhufy6flzfvv48t532azll08v7t2lmryvulh2f7eqaedsefc9we55gqwsxpzqn59nxvq2pfuw020kazda3yckv95pxgn3knrw72h29wwg3ph2ndlafak45gmkgnzl2r5zmt26rw7fh46ulz80uzjlf2uyxn0qpdg0hhn656u9ykltexxhd8k2xsw7kuqxkq8tqr4sp6cqavqwklktm9tnytlcfdmxz0yssn5qe377lmgar8w4f5pd6l22naayaae6uc9j29wvhn2gq4naclvuw8n79yza00576qfapmfwj9gk66zw0559xvfqmtkw9g0cc8t5dwtym8trtu4x4erlktrjzytfr7kuvtwxks4vw89sj5kpldg5ujjahxdr82uqx94nemx9c7eyx4ldtvg3nwly90mffgeqk2lm00arxn4pr8msmpv0ggehaddfcqy9gvwq3d2t8t8rmgt8t556m37lxe9m0ef7tflgey9cupa3zh5lcyh5umuuxlhp7qltju9c49ekwf4aegny7mnttn9gwh42znx46gymsfv6aum9qwnh9f0ddrk5vhvuhda52gh83h3nyfjs6ka8pl9xetw66f56vkh4ujxtu89fym962dplsx4wkhnmsxu0k77';
    final offer = Offer.fromBech32(offerFile);
    expect(offer, isNotNull);
    expect(offer.offeredCoins.cats.length, 3);
    expect(offer.offeredCoins.nfts.length, 1);
  });

  test('should create an offer from an offer file offering an NFT', () async {
    const offerFile =
        'offer1qqph3wlykhv8jcmqvpsxygqqwc7hynr6hum6e0mnf72sn7uvvkpt68eyumkhelprk0adeg42nlelk2mpafsyjlm5pqpj3d3qecenf63cc0sjkmanlc9q4jhkwmtdexfc90la9757usts0da7v0jsrpk8stu0h36d6w8z3mtmzacdktmlt4p5rzldscy48n3vxzf4qre474w4zc87h7x52lx0kvfsc3pgq5ukf9h2jgdr8566q7u4wwulnf8l07wxkf3m05f9u5f46plkaylyemwm9dmemjt2l9vu6egm8wh5c95ltf77cx7n6mfzxed3uexm6zuwvn8t50zrzqdgmr8syfk8gyqxh8yp58vyrywcgxt6svcfpd9a5plf250sl6a3w87u80xundhff6f0hm3ruufl5g6vvtz66m38hlv9yvlll7prk43atl05mmc3vp9ml3ff725h9vdslwnnhsder8httu0za5rw0kgaz7707592usvequpqa4dma5v6g097ht8v3245uad0tde8rxwlj2eswm2hg2k5yt3ug6rhu6ynqprgwl5xalgq7wxp9avwqwelhnxr7eyfnkpur0klhcx5c70d4jf2h939nwk0kc0qrl9ne7gs930efl3ljzv9z5jj2pk2ttuljjv9dxv5n2v4a9vutp2ezkn2nedfpxmt2ftfyhv6npf9g4jet3nxay5n232et9rrj3d9dyz3j2vx49nddf0fny27n9tkpg5htxg9dtyhjat9yhyjt72f3842j7fen9addakxzcdv27gfwrn52nrq9n3fj7lnh8u58w423d23aze8e5d2twhqdt8zth4ewhtz7luvyhplvvdtp9vlpd6y6yndtkf4t8ylqa6qavrllrl5qzkd4n9vjnzwe545a4ftfpysxk2knsr74sc5j7qv3hyvqhflte0las8kmhhc0a2jruaxs0lnaj74k5dke003635trhx7t6dau3eng88vkk9qjnhf5l0fmj8a0pe7dyu5m2txavlte52zcv469lhd52mllkqhslts0srzlf0e0dull23y0vmuak8elxcm236lh4yethdavt57vpeau7h97txyh4amky22hg7rsg5tjem5tpc8gkysspalarcwpvfpknl5rytgf9ragatml2juh79yzwjylhlgyyl8n48w2kmudkg6a79el9g9pvwa5ea756ssvkc8yr9dtvar40pk827rdky867s8z3dlamtc9cqne7ktw0cnz27k6gesfwk2hflxl8z6v8h8acg26lvnxd89sh07qpvucpxvkqazpee4ury94smkcy4a3cqdmh7c0ahh9ua907p2dd9um8v239s7zhp0tk28whynnw0hrw8fvwfh96efjdf4c0w2n0jptar7s6k264whs22c5rdg6nll7zmv8lcrh0l8jmv4su3qnrjk880tqf07txz0pv90vv882c04eu850wp7nlc9avzeuwma2p0024j7ca6u4n2st8smp3yx4sn6h0y5uwhakn2mlcj6qy0vxtgdsy7cc8qwvxvgqy0lsk6qdrkptyshsrwn3q32gxnpxc7u0lal7za7h5x0ay0r0ma0l3pwx7g5llghss843hua2affl0e530flaep6m0ng0vpvh0y8tnu9n5hlducen42dwuhenucwl2una905t8slkwph26hj0lktzuaw87cl2w08yjp7nxhkf023vpwtevynamj50rcw27kcj63fk8u06a8tp5y03f67zdeflujhzmrzmk6hw0c2x5k03g7lrs6uhkn5wd00ausf8hmqq6pjl7ds5dtzmz';
    final offer = Offer.fromBech32(offerFile);
    expect(offer, isNotNull);
    expect(offer.offeredAmounts.cat, isEmpty);
    expect(offer.offeredAmounts.standard, 0);
    expect(offer.requestedAmounts.standard, 4500000000000);
  });
}
