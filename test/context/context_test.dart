// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:path/path.dart' as path;
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('should save network context correctly', () {
    ChiaNetworkContextWrapper().registerNetworkContext(Network.mainnet);

    var blockchainNetwork = ChiaNetworkContextWrapper().blockchainNetwork;

    expect(blockchainNetwork.name, 'mainnet');
    expect(blockchainNetwork.addressPrefix, 'xch');
    expect(
      blockchainNetwork.aggSigMeExtraData,
      'ccd5bb71183532bff220ba46c268991a3ff07eb358e8255a65c30a2dce0e5fbb',
    );

    ChiaNetworkContextWrapper().registerNetworkContext(Network.testnet10);

    blockchainNetwork = ChiaNetworkContextWrapper().blockchainNetwork;

    expect(blockchainNetwork.name, 'testnet10');
    expect(blockchainNetwork.addressPrefix, 'txch');
    expect(
      blockchainNetwork.aggSigMeExtraData,
      'ae83525ba8d1dd3f09b277de18ca3e43fc0af20d20c4b3e92ef2a48bd291ccb2',
    );
  });

  test('Should save logging context correctly', () {
    LoggingContext().setLogLevel(LogLevel.low);
    expect(LoggingContext().logLevel, equals(LogLevel.low));

    LoggingContext().setLogLevel(LogLevel.high);
    expect(LoggingContext().logLevel, equals(LogLevel.high));
  });

  test('logger should write to file correctly', () {
    final logFilePath = path.join(path.current, 'test/context/log.txt');

    File(logFilePath).createSync(recursive: true);
    final createdFile = File(logFilePath);

    void fileLogger(String text) {
      createdFile.writeAsStringSync('$text\n', mode: FileMode.append);
    }

    LoggingContext().setLogLevel(LogLevel.low);
    LoggingContext().setLogger(fileLogger);

    const lowLogLevelTextToLog = 'Howdy partner';
    const highLogLevelTextToLog =
        'Howdy partner, hows the weather in Guadalajara?';

    LoggingContext().log(lowLogLevelTextToLog, highLogLevelTextToLog);

    var loggedText = createdFile.readAsLinesSync();
    expect(loggedText.length, equals(1));
    expect(loggedText[0], equals(lowLogLevelTextToLog));

    LoggingContext().setLogLevel(LogLevel.high);
    LoggingContext().log(lowLogLevelTextToLog, highLogLevelTextToLog);

    loggedText = createdFile.readAsLinesSync();
    expect(loggedText.length, equals(2));
    expect(loggedText[1], equals(highLogLevelTextToLog));

    LoggingContext().log(lowLogLevelTextToLog);

    loggedText = createdFile.readAsLinesSync();
    expect(loggedText.length, equals(3));
    expect(loggedText[2], equals(lowLogLevelTextToLog));

    LoggingContext().log(null, highLogLevelTextToLog);

    loggedText = createdFile.readAsLinesSync();
    expect(loggedText.length, equals(4));
    expect(loggedText[3], equals(highLogLevelTextToLog));

    LoggingContext().setLogLevel(LogLevel.low);
    LoggingContext().log(null, highLogLevelTextToLog);

    expect(loggedText.length, equals(4));

    LoggingContext().setLogLevel(LogLevel.none);
    LoggingContext().log(lowLogLevelTextToLog, highLogLevelTextToLog);

    expect(loggedText.length, equals(4));

    createdFile.deleteSync();
  });
}
