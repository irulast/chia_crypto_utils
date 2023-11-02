import 'package:test_process/test_process.dart';

extension ConvenienceMethods on TestProcess {
  Future<String> waitForStdout(String stdout) async {
    String next;
    do {
      next = await this.stdout.next;
    } while (!next.contains(stdout));

    return next;
  }

  Future<String> nextWhileHasNext() async {
    String next;
    bool hasNext;
    do {
      next = await stdout.next;

      hasNext = await stdout.hasNext;
    } while (hasNext);

    return next;
  }

  Future<void> nextUntilExit() async {
    await nextWhileHasNext();

    await shouldExit(0);
  }

  void enter() {
    stdin.write('\n');
  }
}
