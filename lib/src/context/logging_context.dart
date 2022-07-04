import 'package:get_it/get_it.dart';

class LoggingContext {
  GetIt get getIt => GetIt.I;

  static const includencludeTimestampInstanceName = 'logging_context_include_timestamp';

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

  void setLogTypes(LogTypes logTypes) {
    getIt
      ..registerSingleton<LogTypes>(logTypes)
      ..allowReassignment = true;
  }

  // ignore: avoid_positional_boolean_parameters
  void setShouldIncludeTimestamp(bool shouldIncludeTimestamp) {
    getIt
      ..registerSingleton<bool>(
        shouldIncludeTimestamp,
        instanceName: includencludeTimestampInstanceName,
      )
      ..allowReassignment = true;
  }

  void api(String? lowLogLevelText, [String? highLogLevelText]) {
    if (logTypes.contains(LogType.api)) {
      _log(lowLogLevelText, highLogLevelText);
    }
  }

  void info(String? lowLogLevelText, [String? highLogLevelText]) {
    if (logTypes.contains(LogType.info)) {
      _log(lowLogLevelText, highLogLevelText);
    }
  }

  void error(String? lowLogLevelText, [String? highLogLevelText]) {
    if (logTypes.contains(LogType.error)) {
      _log(lowLogLevelText, highLogLevelText);
    }
  }

  void _log(String? lowLogLevelText, [String? highLogLevelText]) {
    final logger = _logger;

    switch (logLevel) {
      case LogLevel.none:
        break;

      case LogLevel.low:
        if (lowLogLevelText != null) {
          logger(formatLog(lowLogLevelText));
        }
        break;

      case LogLevel.high:
        if (highLogLevelText != null) {
          logger(formatLog(highLogLevelText));
        } else if (lowLogLevelText != null) {
          logger(formatLog(lowLogLevelText));
        }
        break;
    }
  }

  String formatLog(String log) {
    if (includeTimestamp) {
      final now = DateTime.now();
      final timestamp = '${now.hour}:${now.minute}:${now.second}';
      return '($timestamp)  $log';
    }

    return log;
  }

  LoggingFunction get defaultLogger => print;
  bool defaultIncludeTimestamp = false;
  LogLevel defaultLogLevel = LogLevel.none;
  LogTypes defaultLogTypes = {LogType.info, LogType.error};

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

  LogTypes get logTypes {
    if (!getIt.isRegistered<LogTypes>()) {
      return defaultLogTypes;
    }
    return getIt.get<LogTypes>();
  }

  bool get includeTimestamp {
    if (!getIt.isRegistered<bool>(instanceName: includencludeTimestampInstanceName)) {
      return defaultIncludeTimestamp;
    }
    return getIt.get<bool>(instanceName: includencludeTimestampInstanceName);
  }
}

typedef LoggingFunction = void Function(String text);
typedef LogTypes = Set<LogType>;

enum LogType { info, api, error }

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
