import 'dart:math';

import 'package:chia_crypto_utils/chia_crypto_utils.dart';
import 'package:chia_crypto_utils/src/utils/spawn_and_wait_for_isolate/spawn_and_wait_for_isolate.dart';
import 'package:test/test.dart';

Future<void> main() async {
  test('should work with primative argument', () async {
    final result = await spawnAndWaitForIsolate<bool, int>(
      taskArgument: 5,
      isolateTask: (taskArgument) {
        final isPrime = checkIsPrime(taskArgument);
        return <String, dynamic>{
          'is_prime': isPrime,
        };
      },
      handleTaskCompletion: (taskMessage) {
        return taskMessage['is_prime'] as bool;
      },
    );

    expect(result, true);
  });

  test('accurately should notify caller of progress', () async {
    final progressUpdates = <double>[];
    final result = await spawnAndWaitForIsolateWithProgressUpdates<bool, int>(
      taskArgument: 5,
      isolateTask: (taskArgument, onProgressUpdate) {
        var isPrime = checkIsPrime(taskArgument);
        onProgressUpdate(0.33);
        isPrime = checkIsPrime(taskArgument);
        onProgressUpdate(0.66);
        isPrime = checkIsPrime(taskArgument);
        onProgressUpdate(1);
        return <String, dynamic>{
          'is_prime': isPrime,
        };
      },
      handleTaskCompletion: (taskMessage) {
        return taskMessage['is_prime'] as bool;
      },
      onProgressUpdate: progressUpdates.add,
    );

    expect(result, true);
    expect(progressUpdates.length, equals(3));
    expect(progressUpdates[0], equals(0.33));
    expect(progressUpdates[1], equals(0.66));
    expect(progressUpdates[2], equals(1));
  });

  test('should catch isolate exception', () async {
    bool? caught;
    try {
      await spawnAndWaitForIsolate<bool, int>(
        taskArgument: 5,
        isolateTask: (taskArgument) {
          taskArgument as bool;
          final isPrime = checkIsPrime(taskArgument);
          return <String, dynamic>{
            'is_prime': isPrime,
          };
        },
        handleTaskCompletion: (taskMessage) {
          return taskMessage['is_prime'] as bool;
        },
      );
      caught = false;
    } on Exception {
      caught = true;
    }
    expect(caught == true, true);
  });
}

bool checkIsPrime(int n) {
  if (n < 2) return false;

  // It's sufficient to search for prime factors in the range [1,sqrt(N)]:
  final limit = (sqrt(n) + 1).toInt();

  for (var p = 2; p < limit; ++p) {
    if (n % p == 0) return false;
  }

  return true;
}
