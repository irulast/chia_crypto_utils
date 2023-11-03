// ignore_for_file: void_checks

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:chia_crypto_utils/src/utils/spawn_and_wait_for_isolate/models/isolate_message_type.dart';
import 'package:chia_crypto_utils/src/utils/spawn_and_wait_for_isolate/models/progress_update_message.dart';
import 'package:chia_crypto_utils/src/utils/spawn_and_wait_for_isolate/models/result_message.dart';

Future<T> spawnAndWaitForIsolate<T, R>({
  required R taskArgument,
  required FutureOr<Map<String, dynamic>> Function(R taskArgument) isolateTask,
  required FutureOr<T> Function(Map<String, dynamic> taskResultJson)
      handleTaskCompletion,
}) {
  FutureOr<Map<String, dynamic>> task(
    R taskArgument,
    void Function(double p) onProgressUpdate,
  ) {
    return isolateTask(taskArgument);
  }

  return spawnAndWaitForIsolateWithProgressUpdates<T, R>(
    taskArgument: taskArgument,
    isolateTask: task,
    handleTaskCompletion: handleTaskCompletion,
    onProgressUpdate: (progress) {},
  );
}

// wrapper around dart Isolate.spawn to simplify interface and
// allow the caller to wait for the completion of the isolate
Future<T> spawnAndWaitForIsolateWithProgressUpdates<T, R>({
  required R taskArgument,
  required void Function(double progress) onProgressUpdate,
  required FutureOr<Map<String, dynamic>> Function(
    R taskArgument,
    void Function(double progress) onProgressUpdate,
  ) isolateTask,
  required FutureOr<T> Function(Map<String, dynamic> taskResultJson)
      handleTaskCompletion,
}) async {
  final receivePort = ReceivePort();
  final errorPort = ReceivePort();
  final completer = Completer<void>();

  T? result;

  receivePort.listen(
    (dynamic message) async {
      final messageJson = jsonDecode(message as String) as Map<String, dynamic>;
      final messageType = getIsolateMessageTypeFromJson(messageJson);

      switch (messageType) {
        case IsolateMessageType.progressUpdate:
          final progressUpdateMessage =
              ProgressUpdateMessage.fromJson(messageJson);
          onProgressUpdate(progressUpdateMessage.progress);
          break;
        case IsolateMessageType.result:
          final resultMessage = ResultMessage.fromJson(messageJson);
          result = await handleTaskCompletion(resultMessage.body);
          receivePort.close();
      }
    },
    onDone: () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    },
  );

  errorPort.listen((dynamic message) {
    // first is Error Message
    // second is stacktrace which is not needed
    final errors = message as List<dynamic>;
    errorPort.close();
    if (!completer.isCompleted) {
      completer.completeError(
        errors.first as Object,
        StackTrace.fromString(errors[1].toString()),
      );
    }
    receivePort.close();
  });

  final taskArgumentAndSendPort =
      TaskArgumentAndSendPort(taskArgument, receivePort.sendPort);

  await Isolate.spawn(
    _makeActualTask(isolateTask),
    taskArgumentAndSendPort,
    onError: errorPort.sendPort,
  );
  await completer.future.onError((error, stackTrace) {
    throw IsolateException(error, stackTrace);
  });

  return result as T;
}

// creates the actual isolate task that takes the task argument
// and sendport as a single parameter and uses the sendport to
// send the resulting message to the recieve port

Future<void> Function(TaskArgumentAndSendPort<R> taskArgumentAndSendPort)
    _makeActualTask<R>(
  FutureOr<Map<String, dynamic>> Function(
    R taskArgument,
    void Function(double progress) onProgressUpdate,
  ) task,
) {
  return (TaskArgumentAndSendPort<R> taskArgumentAndSendPort) async {
    final taskResultJson = await task(
      taskArgumentAndSendPort.taskArgument,
      (progress) {
        taskArgumentAndSendPort.sendport
            .send(jsonEncode(ProgressUpdateMessage(progress).toJson()));
      },
    );
    taskArgumentAndSendPort.sendport.send(
      jsonEncode(ResultMessage(taskResultJson).toJson()),
    );
  };
}

class TaskArgumentAndSendPort<T> {
  TaskArgumentAndSendPort(this.taskArgument, this.sendport);
  final T taskArgument;
  final SendPort sendport;
}

class IsolateException implements Exception {
  IsolateException(this.error, this.stackTrace);

  final Object? error;
  final StackTrace stackTrace;

  @override
  String toString() {
    return 'An error occurred inside an isolate: $error';
  }
}
