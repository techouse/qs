import 'dart:convert' show base64Decode, utf8;

import 'comparison.dart';

void main() {
  const String encodedTestCases =
      String.fromEnvironment('QS_COMPARISON_TEST_CASES_BASE64');
  if (encodedTestCases.isEmpty) {
    throw StateError('Missing QS_COMPARISON_TEST_CASES_BASE64.');
  }

  final String testCasesJson = utf8.decode(base64Decode(encodedTestCases));
  for (final String line in buildComparisonLines(testCasesJson)) {
    // ignore: avoid_print
    print(line);
  }
}
