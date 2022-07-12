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

  void setLogTypes({
    bool? info,
    bool? error,
    bool? api,
  }) {
    final currentLogTypes = logTypes;
    final newLogTypes = <LogType>{};
    if ((info != null && info) || (info == null && currentLogTypes.contains(LogType.info))) {
      newLogTypes.add(LogType.info);
    }
    if ((error != null && error) || (error == null && currentLogTypes.contains(LogType.error))) {
      newLogTypes.add(LogType.error);
    }
    if ((api != null && api) || (api == null && currentLogTypes.contains(LogType.api))) {
      newLogTypes.add(LogType.api);
    }

    getIt
      ..registerSingleton<LogTypes>(newLogTypes)
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

  void api(
    String? lowLog, {
    String? mediumLog,
    String? highLog,
  }) {
    if (logTypes.contains(LogType.api)) {
      _log(lowLog, mediumLog: mediumLog, highLog: highLog);
    }
  }

  void info(
    String? lowLog, {
    String? mediumLog,
    String? highLog,
  }) {
    if (logTypes.contains(LogType.info)) {
      _log(lowLog, mediumLog: mediumLog, highLog: highLog);
    }
  }

  void error(
    String? lowLog, {
    String? mediumLog,
    String? highLog,
  }) {
    if (logTypes.contains(LogType.error)) {
      _log(lowLog, mediumLog: mediumLog, highLog: highLog);
    }
  }

  void _log(
    String? lowLog, {
    String? mediumLog,
    String? highLog,
  }) {
    final logger = _logger;

    switch (logLevel) {
      case LogLevel.none:
        break;

      case LogLevel.low:
        if (lowLog != null) {
          logger(formatLog(lowLog));
        }
        break;

      case LogLevel.medium:
        if (mediumLog != null) {
          logger(formatLog(mediumLog));
        } else if (lowLog != null) {
          logger(formatLog(lowLog));
        }
        break;

      case LogLevel.high:
        if (highLog != null) {
          logger(formatLog(highLog));
        } else if (mediumLog != null) {
          logger(formatLog(mediumLog));
        } else if (lowLog != null) {
          logger(formatLog(lowLog));
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

enum LogLevel { none, low, medium, high }

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
