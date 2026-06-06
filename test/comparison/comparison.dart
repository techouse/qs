import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:qs_dart/qs_dart.dart' as qs;

Iterable<String> buildComparisonLines(String testCasesJson) sync* {
  final List<Map<String, dynamic>> e2eTestCases =
      List.from(jsonDecode(testCasesJson));

  for (final Map<String, dynamic> testCase in e2eTestCases) {
    final String encoded = qs.encode(testCase['data']);
    final Map decoded = qs.decode(testCase['encoded']);
    yield 'Encoded: $encoded';
    yield 'Decoded: ${jsonEncode(decoded)}';
  }
}
