import 'package:qs_dart/qs.dart' as qs;
import 'package:test/test.dart';

import '../fixtures/data/e2e_test_cases.dart';

void main() {
  group('e2e', () {
    for (final ({Object? data, String encoded}) testCase in e2eTestCases) {
      test('${testCase.data} <-> ${testCase.encoded}', () {
        expect(
          qs.encode(testCase.data, const qs.EncodeOptions(encode: false)),
          equals(testCase.encoded),
        );
        expect(qs.decode(testCase.encoded), equals(testCase.data));
      });
    }
  });
}
