import 'package:get_it/get_it.dart';

class LoggingContext {
  GetIt get getIt => GetIt.I;

  void setLogger(Logger logger) {
    getIt
      ..registerSingleton<Logger>(logger)
      ..allowReassignment = true;
  }

  void setLogLevel(LogLevel logLevel) {
    getIt
      ..registerSingleton<LogLevel>(logLevel)
      ..allowReassignment = true;
  }

  void log(String? lowLogLevelText, [String? highLogLevelText]) {
    final logger = _logger;

    switch (logLevel) {
      case LogLevel.none:
        break;

      case LogLevel.low:
        if (lowLogLevelText != null) {
          logger(lowLogLevelText);
        }
        break;

      case LogLevel.high:
        if (highLogLevelText != null) {
          logger(highLogLevelText);
        } else if (lowLogLevelText != null) {
          logger(lowLogLevelText);
        }
        break;
    }
  }

  Logger get defaultLogger => print;
  LogLevel defaultLogLevel = LogLevel.none;

  Logger get _logger {
    if (!getIt.isRegistered<Logger>()) {
      return defaultLogger;
    }
    return getIt.get<Logger>();
  }

  LogLevel get logLevel {
    if (!getIt.isRegistered<LogLevel>()) {
      return defaultLogLevel;
    }
    return getIt.get<LogLevel>();
  }
}

typedef Logger = void Function(String text);

enum LogLevel { none, low, high }
