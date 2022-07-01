import 'package:get_it/get_it.dart';

class LoggingContext {
  GetIt get getIt => GetIt.I;

  void setLogger(LoggingFunction logger) {
    getIt
      ..registerSingleton<LoggingFunction>(logger)
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

  LoggingFunction get defaultLogger => print;
  LogLevel defaultLogLevel = LogLevel.none;

  LoggingFunction get _logger {
    if (!getIt.isRegistered<LoggingFunction>()) {
      return defaultLogger;
    }
    return getIt.get<LoggingFunction>();
  }

  LogLevel get logLevel {
    if (!getIt.isRegistered<LogLevel>()) {
      return defaultLogLevel;
    }
    return getIt.get<LogLevel>();
  }
}

typedef LoggingFunction = void Function(String text);

enum LogLevel { none, low, high }

LogLevel stringToLogLevel(String logLevelString) {
  switch (logLevelString) {
    case 'none':
      return LogLevel.none;
    case 'low':
      return LogLevel.low;
    case 'high':
      return LogLevel.high;
    default:
      throw ArgumentError('Invalid LogLevel String');
  }
}
