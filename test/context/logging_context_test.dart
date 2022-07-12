import 'dart:io';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  late File createdFile;

  setUp(() {
    final logFilePath = path.join(path.current, 'test/context/log.txt');
    File(logFilePath).createSync(recursive: true);
    createdFile = File(logFilePath);
  });
  tearDown(() {
    createdFile.deleteSync();
  });

  test('Should save logging context correctly', () {
    LoggingContext().setLogLevel(LogLevel.low);
    expect(LoggingContext().logLevel, equals(LogLevel.low));

    LoggingContext().setLogLevel(LogLevel.high);
    expect(LoggingContext().logLevel, equals(LogLevel.high));
  });

  group('logger should write to file correctly with varying log levels', () {
    LoggingContext().setLogTypes(api: true);

    for (final logFunction in [
      LoggingContext().info,
      LoggingContext().error,
      LoggingContext().api,
    ]) {
      final functionString = logFunction.toString();
      test('with logging function ${functionString.substring(functionString.indexOf("'"), functionString.lastIndexOf("'") + 1)}', () {
        void fileLogger(String text) {
          createdFile.writeAsStringSync('$text\n', mode: FileMode.append);
        }

        LoggingContext().setLogLevel(LogLevel.low);
        LoggingContext().setLogger(fileLogger);

        const lowLogLevelTextToLog = 'Howdy partner';
        const mediumLogLevelTextToLog = 'Howdy partner, hows weather?';

        const highLogLevelTextToLog = 'Howdy partner, hows the weather in Guadalajara?';
        logFunction(
          lowLogLevelTextToLog,
          mediumLog: mediumLogLevelTextToLog,
          highLog: highLogLevelTextToLog,
        );

        var loggedText = createdFile.readAsLinesSync();
        expect(loggedText.length, equals(1));
        expect(loggedText[0], equals(lowLogLevelTextToLog));

        LoggingContext().setLogLevel(LogLevel.medium);
        logFunction(
          lowLogLevelTextToLog,
          mediumLog: mediumLogLevelTextToLog,
          highLog: highLogLevelTextToLog,
        );

        loggedText = createdFile.readAsLinesSync();
        expect(loggedText.length, equals(2));
        expect(loggedText[1], equals(mediumLogLevelTextToLog));

        logFunction(lowLogLevelTextToLog);

        loggedText = createdFile.readAsLinesSync();
        expect(loggedText.length, equals(3));
        expect(loggedText[2], equals(lowLogLevelTextToLog));

        logFunction(null, highLog: highLogLevelTextToLog);

        loggedText = createdFile.readAsLinesSync();
        expect(loggedText.length, equals(3));

        LoggingContext().setLogLevel(LogLevel.high);
        logFunction(
          lowLogLevelTextToLog,
          mediumLog: mediumLogLevelTextToLog,
          highLog: highLogLevelTextToLog,
        );

        loggedText = createdFile.readAsLinesSync();
        expect(loggedText.length, equals(4));
        expect(loggedText[3], equals(highLogLevelTextToLog));

        logFunction(lowLogLevelTextToLog);

        loggedText = createdFile.readAsLinesSync();
        expect(loggedText.length, equals(5));
        expect(loggedText[4], equals(lowLogLevelTextToLog));

        logFunction(null, mediumLog: mediumLogLevelTextToLog);

        loggedText = createdFile.readAsLinesSync();
        expect(loggedText.length, equals(6));
        expect(loggedText[5], equals(mediumLogLevelTextToLog));

        logFunction(null, highLog: highLogLevelTextToLog);

        loggedText = createdFile.readAsLinesSync();
        expect(loggedText.length, equals(7));
        expect(loggedText[6], equals(highLogLevelTextToLog));

        LoggingContext().setLogLevel(LogLevel.low);
        logFunction(null, highLog: highLogLevelTextToLog);
        logFunction(null, mediumLog: mediumLogLevelTextToLog);

        expect(loggedText.length, equals(7));

        LoggingContext().setLogLevel(LogLevel.none);
        logFunction(
          lowLogLevelTextToLog,
          mediumLog: mediumLogLevelTextToLog,
          highLog: highLogLevelTextToLog,
        );

        expect(loggedText.length, equals(7));
      });
    }
  });

  test('logger should write to file correctly with varying log types', () {
    void fileLogger(String text) {
      createdFile.writeAsStringSync('$text\n', mode: FileMode.append);
    }

    LoggingContext().setLogTypes(info: true, error: true, api: false);

    LoggingContext().setLogLevel(LogLevel.low);

    LoggingContext().setLogger(fileLogger);

    const infoText = 'Howdy partner';
    const errorText = 'oh no theres an error';
    const apiText = '{status: "success"}';

    LoggingContext().info(infoText);
    LoggingContext().error(errorText);
    LoggingContext().api(apiText);

    var loggedText = createdFile.readAsLinesSync();
    expect(loggedText.length, equals(2));
    expect(loggedText[0], equals(infoText));
    expect(loggedText[1], equals(errorText));

    LoggingContext().setLogTypes(
      api: true,
    );
    LoggingContext().api(apiText);
    LoggingContext().info(infoText);
    LoggingContext().error(errorText);

    loggedText = createdFile.readAsLinesSync();
    expect(loggedText.length, equals(5));
    expect(loggedText[2], equals(apiText));
    expect(loggedText[3], equals(infoText));
    expect(loggedText[4], equals(errorText));

    LoggingContext().setLogTypes(
      api: false,
      info: false,
    );

    LoggingContext().api(apiText);
    LoggingContext().info(infoText);
    LoggingContext().error(errorText);

    loggedText = createdFile.readAsLinesSync();
    expect(loggedText.length, equals(6));
    expect(loggedText[5], equals(errorText));

    LoggingContext().setLogTypes(api: false, error: true);
    LoggingContext().api(apiText);
    LoggingContext().info(infoText);
    LoggingContext().error(errorText);

    loggedText = createdFile.readAsLinesSync();
    expect(loggedText.length, equals(7));
    expect(loggedText[6], equals(errorText));
  });
}
