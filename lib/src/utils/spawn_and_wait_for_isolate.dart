import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

// wrapper around dart Isolate.spawn to simplify interface and
// allow the caller to wait for the completion of the isolate
Future<T> spawnAndWaitForIsolate<T, R>({
  required R taskArgument,
  required FutureOr<Map<String, dynamic>> Function(R taskArgument) isolateTask,
  required FutureOr<T> Function(Map<String, dynamic> taskResultJson) handleTaskCompletion,
}) async {
  final receivePort = ReceivePort();
  final errorPort = ReceivePort();

  final completer = Completer<void>();

  T? result;

  receivePort.listen(
    (dynamic message) async {
      result = await handleTaskCompletion(
        jsonDecode(message as String) as Map<String, dynamic>,
      );
      receivePort.close();
    },
    onDone: completer.complete,
  );

  errorPort.listen((dynamic message) {
    // first is Error Message
    // second is stacktrace which is not needed
    final errors = message as List<dynamic>;
    errorPort.close();
    completer.completeError(errors.first as Object);
  });

  final taskArgumentAndSendPort = TaskArgumentAndSendPort(taskArgument, receivePort.sendPort);

  await Isolate.spawn(
    _makeActualTask(isolateTask),
    taskArgumentAndSendPort,
    onError: errorPort.sendPort,
  );

  await Future.wait([completer.future]);
  return result as T;
}

// creates the actual isolate task that takes the task argument
// and sendport as a single parameter and uses the sendport to
// send the resulting message to the recieve port
Future<void> Function(TaskArgumentAndSendPort<R> taskArgumentAndSendPort) _makeActualTask<R>(
  FutureOr<Map<String, dynamic>> Function(R taskArgument) task,
) {
  return (TaskArgumentAndSendPort<R> taskArgumentAndSendPort) async {
    final taskResultJson = await task(taskArgumentAndSendPort.taskArgument);
    taskArgumentAndSendPort.sendport.send(
      jsonEncode(taskResultJson),
    );
  };
}

class TaskArgumentAndSendPort<T> {
  final T taskArgument;
  final SendPort sendport;

  TaskArgumentAndSendPort(this.taskArgument, this.sendport);
}
