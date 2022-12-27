import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';

Future<void> main() async {
  test('should correctly compile clsp file', () async {
    var result = await Process.run(
      'osascript',
      [
        '-e',
        'do shell script "./test/clsp/compile_clsp.sh test/clsp/genesis_by_coin_id.clsp" with administrator privileges',
      ],
    );
    stdout.write(result.stdout);
  });
}
