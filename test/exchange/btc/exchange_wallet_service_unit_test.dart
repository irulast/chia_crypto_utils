import 'dart:typed_data';
import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/exchange/btc/wallet.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

Future<void> main() async {
  ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);
  final walletService = BtcExchangeWalletService();

  final clawbackPrivateKey =
      PrivateKey.fromHex('2f03e845533570bef01eb68d7427072dc41855f63f4ee6f1bd8bb8986d5e8aef');
  final clawbackPublicKey = JacobianPoint.fromHexG1(
    'aef40548b6cb3e142b8cbc84243003e35049f347d294630cf34bec36465c19b3f7de31251c4ae15fc3f7fbf95bf20c31',
  );
  final clawbackPuzzlehash =
      Puzzlehash.fromHex('0c684c1c9fc4b2f72dce6a302f22d061977dce6823ad58e16b6274ee2ff67f4a');

  final sweepPrivateKey =
      PrivateKey.fromHex('48e6238ce89fa0b022b6c403baff8df213e6640fff3ff2069c6ee53d9dd3d146');
  final sweepPublicKey = JacobianPoint.fromHexG1(
    'a79d216b4a25ed1798205e6206821c487eaea4a19ece4e485ddce54134d75dc504516c1f0cd572c1aacab7b4463ce178',
  );

  final sweepPreimage =
      '5c1f10653dc3ff0531b77351dc6676de2e1f5f53c9f0a8867bcb054648f46a32'.hexToBytes();
  final sweepReceiptHash = Program.fromBytes(sweepPreimage).hash();

  final coin = CoinPrototype(
    parentCoinInfo:
        Puzzlehash.fromHex('a281e4134cac34d02dc5820d5d805eb3f1b93b1bbbc1294f2023b71174c509d0'),
    puzzlehash:
        Puzzlehash.fromHex('33ca448538a21ff42810294187645341159d0d2e01276031f8f497ecf464d8f9'),
    amount: 1600000000000,
  );

  final totalPublicKey = clawbackPublicKey + sweepPublicKey;

  final payment = Payment(coin.amount, clawbackPuzzlehash);

  final conditions = [payment.toCreateCoinCondition()];

  final hiddenPuzzle = walletService.generateHiddenPuzzle(
    clawbackDelaySeconds: 0,
    clawbackPublicKey: clawbackPublicKey,
    sweepReceiptHash: sweepReceiptHash,
    sweepPublicKey: sweepPublicKey,
  );

  final puzzleReveal = walletService.generateHoldingAddressPuzzle(
    clawbackDelaySeconds: 0,
    clawbackPublicKey: clawbackPublicKey,
    sweepReceiptHash: sweepReceiptHash,
    sweepPublicKey: sweepPublicKey,
  );

  final solution = walletService.clawbackOrSweepSolution(
    clawbackDelaySeconds: 0,
    totalPublicKey: totalPublicKey,
    clawbackPublicKey: clawbackPublicKey,
    sweepReceiptHash: sweepReceiptHash,
    sweepPublicKey: sweepPublicKey,
    conditions: conditions,
  );

  // expected values from chiaswap python code https://github.com/richardkiss/chiaswap/tree/main/chiaswap

  test('should correctly add together two public keys', () {
    expect(
      totalPublicKey,
      equals(
        JacobianPoint.fromHexG1(
          '8eaf9d23db2f736ff7ad6814cbcbdf3c3c4a115c61283b4e7cb4354505c7a2b138de6012d4f162576018d106ce16b370',
        ),
      ),
    );
  });

  test('should correctly generate holding address puzzlehash', () {
    final holdingAddressPuzzlehash = puzzleReveal.hash();

    expect(
      holdingAddressPuzzlehash,
      equals(
        Puzzlehash.fromHex(
          '33ca448538a21ff42810294187645341159d0d2e01276031f8f497ecf464d8f9',
        ),
      ),
    );
  });

  test('should correctly generate clawback solution', () {
    expect(
      solution.toBytes(),
      equals(
        Bytes.fromHex(
          'ffb08eaf9d23db2f736ff7ad6814cbcbdf3c3c4a115c61283b4e7cb4354505c7a2b138de6012d4f162576018d106ce16b370ffff02ffff01ff02ffff01ff02ffff03ff17ffff01ff02ffff03ffff09ffff0bff1780ff1380ffff01ff02ff06ffff04ff1bff2f8080ffff01ffff08808080ff0180ffff01ff04ffff04ff04ffff04ff09ff808080ffff02ff06ffff04ff0dff2f80808080ff0180ffff04ffff01ff50ff02ffff01ff02ffff03ff0bffff01ff02ffff03ffff09ff05ffff1dff0bffff1effff0bff0bffff02ff06ffff04ff02ffff04ff17ff8080808080808080ffff01ff02ff17ff2f80ffff01ff088080ff0180ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff17ff80808080ff80808080ffff02ff17ff2f808080ff0180ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ff018080ffff04ffff01ff80b0aef40548b6cb3e142b8cbc84243003e35049f347d294630cf34bec36465c19b3f7de31251c4ae15fc3f7fbf95bf20c31ffff04ffff01ffa06779d8cca6cb2423d0c55b3511e002e91c95b1f6ea8d93a61a563833e538d797b0a79d216b4a25ed1798205e6206821c487eaea4a19ece4e485ddce54134d75dc504516c1f0cd572c1aacab7b4463ce178ff01808080ffff80ffff80ffff01ffff33ffa00c684c1c9fc4b2f72dce6a302f22d061977dce6823ad58e16b6274ee2ff67f4aff860174876e80008080ff80808080',
        ),
      ),
    );
  });

  test('should correctly generate signature', () {
    final coinSpend = CoinSpend(coin: coin, puzzleReveal: puzzleReveal, solution: solution);
    final signature = walletService.makeSignatureForExchange(clawbackPrivateKey, coinSpend);

    expect(
      signature,
      equals(
        JacobianPoint.fromHexG2(
            'a12cf3f7ef5a07c6010229f5e97718623bb4b8f34857bc050c2ba996dbdb4e49afde584c5f6888cdd44b275e60df0f71016eee243b212627782781326bbd86e94fae255d6341368d2a0bbdeba548098cf2aa2af81c2028edb2e4b89bc6cb7568'),
      ),
    );
  });

  test('should correctly generate clawback spendbundle', () {
    final spendBundle = walletService.createExchangeSpendBundle(
      payments: [payment],
      coinsInput: [coin],
      clawbackDelaySeconds: 0,
      clawbackPrivateKey: clawbackPrivateKey,
      clawbackPublicKey: clawbackPublicKey,
      sweepReceiptHash: sweepReceiptHash,
      sweepPrivateKey: sweepPrivateKey,
      sweepPublicKey: sweepPublicKey,
    );

    expect(
      spendBundle.toHex(),
      equals(
        '00000001a281e4134cac34d02dc5820d5d805eb3f1b93b1bbbc1294f2023b71174c509d033ca448538a21ff42810294187645341159d0d2e01276031f8f497ecf464d8f900000174876e8000ff02ffff01ff02ffff01ff02ffff03ff0bffff01ff02ffff03ffff09ff05ffff1dff0bffff1effff0bff0bffff02ff06ffff04ff02ffff04ff17ff8080808080808080ffff01ff02ff17ff2f80ffff01ff088080ff0180ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff17ff80808080ff80808080ffff02ff17ff2f808080ff0180ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ffff04ffff01b08585c3f77ccee3269182ca2dbab562865620b4b9523f317dd0f977d2f94b73489241da9bad0222f8cde58429d97103f3ff018080ffb08eaf9d23db2f736ff7ad6814cbcbdf3c3c4a115c61283b4e7cb4354505c7a2b138de6012d4f162576018d106ce16b370ffff02ffff01ff02ffff01ff02ffff03ff17ffff01ff02ffff03ffff09ffff0bff1780ff1380ffff01ff02ff06ffff04ff1bff2f8080ffff01ffff08808080ff0180ffff01ff04ffff04ff04ffff04ff09ff808080ffff02ff06ffff04ff0dff2f80808080ff0180ffff04ffff01ff50ff02ffff01ff02ffff03ff0bffff01ff02ffff03ffff09ff05ffff1dff0bffff1effff0bff0bffff02ff06ffff04ff02ffff04ff17ff8080808080808080ffff01ff02ff17ff2f80ffff01ff088080ff0180ffff01ff04ffff04ff04ffff04ff05ffff04ffff02ff06ffff04ff02ffff04ff17ff80808080ff80808080ffff02ff17ff2f808080ff0180ffff04ffff01ff32ff02ffff03ffff07ff0580ffff01ff0bffff0102ffff02ff06ffff04ff02ffff04ff09ff80808080ffff02ff06ffff04ff02ffff04ff0dff8080808080ffff01ff0bffff0101ff058080ff0180ff018080ff018080ffff04ffff01ff80b0aef40548b6cb3e142b8cbc84243003e35049f347d294630cf34bec36465c19b3f7de31251c4ae15fc3f7fbf95bf20c31ffff04ffff01ffa06779d8cca6cb2423d0c55b3511e002e91c95b1f6ea8d93a61a563833e538d797b0a79d216b4a25ed1798205e6206821c487eaea4a19ece4e485ddce54134d75dc504516c1f0cd572c1aacab7b4463ce178ff01808080ffff80ffff80ffff01ffff33ffa00c684c1c9fc4b2f72dce6a302f22d061977dce6823ad58e16b6274ee2ff67f4aff860174876e80008080ff80808080a12cf3f7ef5a07c6010229f5e97718623bb4b8f34857bc050c2ba996dbdb4e49afde584c5f6888cdd44b275e60df0f71016eee243b212627782781326bbd86e94fae255d6341368d2a0bbdeba548098cf2aa2af81c2028edb2e4b89bc6cb7568',
      ),
    );
  });

  test('should correctly calculate total private key', () {
    final totalPrivateKey =
        calculateTotalPrivateKey(totalPublicKey, hiddenPuzzle, clawbackPrivateKey, sweepPrivateKey);

    expect(
      totalPrivateKey.toHex(),
      equals(
        '03ef5db9920a537b1b2b945b6531262d0564c5db2d4e8b1170fd066c672745f3',
      ),
    );
  });
}
