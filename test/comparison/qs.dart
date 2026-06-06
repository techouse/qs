import 'dart:io' show File, Platform, exitCode, stdout;

import 'package:cli_script/cli_script.dart' show wrapMain;
import 'package:path/path.dart' as p;

import 'comparison.dart';

void main() {
  wrapMain(() {
    exitCode = 0;

    final String scriptDir = p.dirname(Platform.script.toFilePath());
    final File file = File(p.join(scriptDir, 'test_cases.json'));
    final String contents = file.readAsStringSync();

    for (final String line in buildComparisonLines(contents)) {
      stdout.writeln(line);
    }
  });
}
