import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

Future<void> main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final walletService = StandardWalletService();

  final catOfferService = CatOfferWalletService();
  final cat1OfferService = Cat1OfferWalletService();

  test('should correctly check for spent coins in a CAT2 offer', () async {
    final adam = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    await adam.farmCoins();
    // sell cat
    final offer = catOfferService.makeOffer(
      coinsForOffer: MixedCoins(standardCoins: adam.standardCoins),
      offeredAmounts: const OfferedMixedAmounts(standard: 5000),
      changePuzzlehash: adam.firstPuzzlehash,
      requestedPayments: RequestedMixedPayments(
        standard: [Payment(1000, adam.firstPuzzlehash)],
      ),
      keychain: adam.keychain,
    );

    var offerContainsSpentCoins = await fullNodeSimulator
        .checkForSpentCoins(offer.offeredSpendBundle.coins);
    expect(offerContainsSpentCoins, false);

    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(500, adam.puzzlehashes[1])],
      coinsInput: adam.standardCoins,
      keychain: adam.keychain,
      changePuzzlehash: adam.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    offerContainsSpentCoins = await fullNodeSimulator
        .checkForSpentCoins(offer.offeredSpendBundle.coins);
    expect(offerContainsSpentCoins, true);
  });

  test('should correctly check for spent coins in a CAT1 offer', () async {
    final isaac = ChiaEnthusiast(fullNodeSimulator, walletSize: 2);
    await isaac.farmCoins();
    // sell cat
    final offer = cat1OfferService.makeOffer(
      coinsForOffer: MixedCoins(standardCoins: isaac.standardCoins),
      offeredAmounts: const OfferedMixedAmounts(standard: 5000),
      changePuzzlehash: isaac.firstPuzzlehash,
      requestedPayments: RequestedMixedPayments(
        standard: [Payment(1000, isaac.firstPuzzlehash)],
      ),
      keychain: isaac.keychain,
    );

    var offerContainsSpentCoins = await fullNodeSimulator
        .checkForSpentCoins(offer.offeredSpendBundle.coins);
    expect(offerContainsSpentCoins, false);

    final spendBundle = walletService.createSpendBundle(
      payments: [Payment(500, isaac.puzzlehashes[1])],
      coinsInput: isaac.standardCoins,
      keychain: isaac.keychain,
      changePuzzlehash: isaac.firstPuzzlehash,
    );

    await fullNodeSimulator.pushTransaction(spendBundle);
    await fullNodeSimulator.moveToNextBlock();

    offerContainsSpentCoins = await fullNodeSimulator
        .checkForSpentCoins(offer.offeredSpendBundle.coins);
    expect(offerContainsSpentCoins, true);
  });

  test('should parse a CAT1 offer', () async {
    const offerBinOfferFile =
        'offer1qqp83w76wzru6cmqvpsxvgqq4c96al7mw0a8es5t4rp80gn8femj6mkjl8luv7wrldg87dhkq6ejylvc8fvtprkkww3lthrg85m44nud6eesxhw0sx9m6p297u8zfd0mtjumc6k85sz38536z6h884rxujw2zfe704surksmm4m7usy4u48tmafcajc4dc0dmqa4h9z5f27e3qnuzf37yr78sl6kslts9aua5zfdg3r7knncj78pzg4nyzmdxdhxa8y7cr6v80zcal6vn70e6l7jvefay2w3taxa40llr08mgtgx9fchmmhm52adh3ej7alls3y84503wzpj4ny24522mf20qehlchu38t4ult0kgdvrppjjqza44dhjuaeulerr3er7a0ttl2038f0uk89x97f8fux7h8ulzfjldmle8kwhxlx8kvpptmq4tlx2xnxc2amwra7l9edrwpsnmymnu4quz4dta6msx6m2e5tawwzs4047rh8nqcdmccw96sym94sn3u27cucw2gkmejvluu79mdd48ax2yd8ul5fvmphyn085mzkdr9e2llucket2g7tt30e7ccmq45xeqd8a0lq6u3uwf8hl0ph4wlh2jvnpn7c5ev8hs0zte8v00aj9d86m2n6hxlnluhl4v26nf5tcvp4svg3eukmedd0t0m9s64d7l3jlkp647ux4net2dpaxx73e2xawjune2hlcml9vr9qkq9fxeumlg8m8hyvwmqtey6hkekasgt47ek203cfu4wul0dts3dva8d4ajexgcjuq4tk07tec43dl0vtwk0x7eqc2van8e9edvf7039l4m09h80ell32a8h4fx337wams3zh9s7vqhxcaztl4jhlwemzs79x4cvckrq7g76vadajxd4m8k7mh3806jfe5kcc9gn88jwln07g8wrlwz7vnutfc89khn4ctmmyccqhhq02m4qffg0pxleu5jxtry94j2m8646p3vpxqc0mugf9lweqya79vun2uh40cgx5unxd2vd2d7y9pdk5uxsnlhlwyslna7z83v6kz5s62rxmvp99p7skddw52g4z0p6ezvcaevxdvn8hev2cx3d4t7ylejc78r3kj2haxq8e4e7hzllwe54clh5n3s9cdkqkkvvehunzfhs245v2dtmnvq8m74wczw0skq4lk0l9ew5uk3qlwr2930e5my4mt48npp0cg3n6ac54wpd8n09tfuyhne4usala7ww7vckqmr93tsn0xdxldl9hkceatard28vtr4940qcq9dld6hvm6l706';
    final offer = Offer.fromBech32(offerBinOfferFile);
    final parsedOffer = await Cat1OfferWalletService.parseOffer(offer);

    expect(parsedOffer.requestedAmounts.cats.first.amount, equals(15.0));
    expect(parsedOffer.offeredAmounts.xch, equals(0.25));
  });

  test('should parse a CAT2 offer with human readable cat names', () async {
    const offerBinOfferFile =
        'offer1qqz83wcsltt6wcmqvpsxygqq6tmp20fkzcmnnwmf7mff2a7a0shrpjyfl0ytl6e7hwt0887qncnmeemqatsymvx33fkmgcsm4hvyv2ak6x9xmdrzlvl5q9gm53c97c97aaeu9w7kgm3k6uer5vnwg85fv4wp7cp7wakkphxwczhd6ddjtf24qewtxs8puwhkv7ak7uzfvtup8zu8rjhmv8kcd5rue94ny5znv0mf6c2gv4s46zax6a9wrzxyzvstl39mh0l8tn07zg0x0l44sll4zxmt9ee488fqm6e8dfhlm49s0fr6sq6s39qel54xn4el5x6kdpeecvjahpd6wanjhh9q48jrdsxymyuang88e587mlp0f66rqvgs5s2kjc0rcvwal2tsg47z52vkaswdxu6fwaku3gu8l6npr9dlpp0772gwy7wt4e756wfq8uslnc5jhgt6vfjpndta7tmqkr0km2h6gppdz00ndlhp5cpmuhzetfgz4zxetcdu6cxxeuyx3y8fy9gp8yakl8mdw3xt4dmg5uh77r5840n4dumaksh39w43la4hv6nyjmqcl747yan08gk0df0wlt32qf4kmq9yatlska3awfx840eh4jlhxnu4p8accevzh50jfehd0n7z8vl6mj3248lnlv4lldukak9ukctgqq4lu9zlheq49e670nxux9f0277rsvnaqln7cwddmx0hwuv5wuaaly22pmaa7k3yu6mqffxcumlc9x4dp0pzyhe08tptfa2dzkpljcadn9ep6v0kdy5ulan7tjsjqcunj589ge0l0lq7ljxs3yts7pllvf4866ka5v6ntue84lqwwnv4du6utr079h3fsalp9yuygw7725rjkw9vxcld45m3yn983gje74pulspd39c5u37mp3lf34f8ekyhawl9s006agjlrvlrkwfnmfxhfer7jr0e8cvaa060nmwlmwh4jklmja5t3tj7krjedfzzmhuc4x2nmtv49z60ne4f456h7rn4a3uvam560vsq8jh8erc6luda7';

    final offer = Offer.fromBech32(offerBinOfferFile);

    try {
      final parsedOffer = await OfferWalletService.parseOffer(
        offer,
        tailDatabaseApi: TailDatabaseApi(),
      );

      expect(
        parsedOffer.requestedAmounts.cats
            .firstWhere((cat) => cat.name == 'Spacebucks')
            .amount,
        equals(50000.0),
      );
      expect(parsedOffer.offeredAmounts.xch, equals(0.51));
    } on FormatException {
      //pass
    }
  });
}
