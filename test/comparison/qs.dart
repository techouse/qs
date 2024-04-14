import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io' show File, Platform, exitCode, stdout;
import 'package:qs_dart/qs_dart.dart' as qs;
import 'package:cli_script/cli_script.dart' show wrapMain;
import 'package:path/path.dart' as p;

void main() {
  wrapMain(() {
    exitCode = 0;

    final String scriptDir = p.dirname(Platform.script.toFilePath());
    final File file = File(p.join(scriptDir, 'test_cases.json'));
    final String contents = file.readAsStringSync();
    final List<Map<String, dynamic>> e2eTestCases =
        List<Map<String, dynamic>>.from(
      jsonDecode(contents),
    );

    for (final testCase in e2eTestCases) {
      final String encoded = qs.encode(testCase['data']);
      final Map decoded = qs.decode(testCase['encoded']);
      stdout.writeln('Encoded: $encoded');
      stdout.writeln('Decoded: ${jsonEncode(decoded)}');
    }
  });
}
