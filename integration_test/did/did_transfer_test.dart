@Timeout(Duration(minutes: 10))
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:test/test.dart';

void main() async {
  if (!(await SimulatorUtils.checkIfSimulatorIsRunning())) {
    print(SimulatorUtils.simulatorNotRunningWarning);
    return;
  }

  final fullNodeSimulator = SimulatorFullNodeInterface.withDefaultUrl();

  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

  LoggingContext().setLogLevel(LogLevel.low);

  late ChiaEnthusiast nathan;
  late ChiaEnthusiast meera;
  late ChiaEnthusiast grant;

  final didWalletService = DIDWalletService();

  setUp(() async {
    nathan = ChiaEnthusiast(fullNodeSimulator, walletSize: 8);
    await nathan.farmCoins();
    await nathan.issueDid([Program.fromBool(true).hash()]);

    grant = ChiaEnthusiast(fullNodeSimulator, walletSize: 8);
    await grant.farmCoins();

    meera = ChiaEnthusiast(fullNodeSimulator, walletSize: 8);
    await meera.farmCoins();
  });

  Future<DidInfo> passAroundDid(DidInfo origionalDid) async {
    final nathanToGrantSpendBundle = didWalletService.createSpendBundle(
      newP2Puzzlehash: grant.firstPuzzlehash,
      didInfo: origionalDid,
      keychain: nathan.keychain,
    );

    await fullNodeSimulator.pushTransaction(nathanToGrantSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final grantDid = (await fullNodeSimulator.getDidRecordsFromHint(grant.firstPuzzlehash))
        .single
        .toDidInfoOrThrow(grant.keychain);

    final grantToMeeraSpendBundle = didWalletService.createSpendBundle(
      newP2Puzzlehash: meera.firstPuzzlehash,
      didInfo: grantDid,
      keychain: grant.keychain,
    );

    await fullNodeSimulator.pushTransaction(grantToMeeraSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final meeraDid = (await fullNodeSimulator.getDidRecordsFromHint(meera.firstPuzzlehash))
        .single
        .toDidInfoOrThrow(meera.keychain);

    final meeraToNathanSpendBundle = didWalletService.createSpendBundle(
      newP2Puzzlehash: nathan.firstPuzzlehash,
      didInfo: meeraDid,
      keychain: meera.keychain,
    );
    await fullNodeSimulator.pushTransaction(meeraToNathanSpendBundle);
    await fullNodeSimulator.moveToNextBlock();

    final nathanDid = (await fullNodeSimulator.getDidRecordsFromHint(nathan.firstPuzzlehash))
        .single
        .toDidInfoOrThrow(nathan.keychain);

    expectDidEquality(nathanDid, origionalDid);

    return nathanDid;
  }

  test('should pass around and use did to mint', () async {
    final origionalDid = nathan.didInfo!;
    final nathanDid = await passAroundDid(origionalDid);
    expectDidEquality(nathanDid, origionalDid);
  });
}

void expectDidEquality(DidInfo actual, DidInfo expected) {
  expect(actual.backUpIdsHash, expected.backUpIdsHash);
  expect(actual.did, expected.did);
  expect(actual.metadata.toProgram(), expected.metadata.toProgram());
  expect(actual.singletonStructure, expected.singletonStructure);
  expect(actual.nVerificationsRequired, expected.nVerificationsRequired);
}
