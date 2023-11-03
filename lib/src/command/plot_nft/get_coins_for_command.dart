import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';

Future<List<Coin>> getCoinsForCommand({
  required String faucetRequestURL,
  required String faucetRequestPayload,
  required List<Puzzlehash> puzzlehashes,
  required ChiaFullNodeInterface fullNode,
  required String message,
}) async {
  final coinAddress = Address.fromPuzzlehash(
    puzzlehashes.first,
    ChiaNetworkContextWrapper().blockchainNetwork.addressPrefix,
  );

  if (faucetRequestURL.isNotEmpty && faucetRequestPayload.isNotEmpty) {
    final theFaucetRequestPayload = faucetRequestPayload.replaceAll(
      RegExp('SEND_TO_ADDRESS'),
      coinAddress.address,
    );

    final result = await Process.run('curl', [
      '-s',
      '-d',
      theFaucetRequestPayload,
      '-H',
      'Content-Type: application/json',
      '-X',
      'POST',
      faucetRequestURL,
    ]);

    stdout.write(result.stdout);
    stderr.write(result.stderr);
  } else {
    print(
      '$message: ${coinAddress.address}\n',
    );
    print('Press any key when coin has been sent');
    stdin.readLineSync();
  }

  var coins = <Coin>[];
  do {
    coins = await fullNode.getCoinsByPuzzleHashes(
      puzzlehashes,
    );
    if (coins.isEmpty) {
      print('waiting for coins');
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  } while (coins.isEmpty);

  if (coins.isNotEmpty) {
    print(coins);
  }

  return coins;
}
