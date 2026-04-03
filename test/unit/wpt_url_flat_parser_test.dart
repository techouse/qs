import 'package:qs_dart/src/qs.dart';
import 'package:test/test.dart';

/// WPT-derived flat query parser coverage based on:
/// /Users/klemen/Work/wpt/url/urlencoded-parser.any.js
///
/// Only the overlapping flat-input cases are imported here. Expectations are
/// written for `qs_dart` semantics rather than WHATWG `URLSearchParams`
/// behavior, and broader WHATWG-only divergences are intentionally omitted.

final class _FlatDecodeCase {
  const _FlatDecodeCase({
    required this.name,
    required this.input,
    required this.expected,
  });

  final String name;
  final String input;
  final Map<String, Object?> expected;
}

void main() {
  group('decode WPT flat parser coverage', () {
    const List<_FlatDecodeCase> emptyAndDegenerateInputs = [
      _FlatDecodeCase(
        name: 'empty string yields an empty map',
        input: '',
        expected: <String, Object?>{},
      ),
      _FlatDecodeCase(
        name: 'bare key decodes to an empty string',
        input: 'a',
        expected: <String, Object?>{'a': ''},
      ),
      _FlatDecodeCase(
        name: 'key value pair decodes normally',
        input: 'a=b',
        expected: <String, Object?>{'a': 'b'},
      ),
      _FlatDecodeCase(
        name: 'explicit empty value is preserved',
        input: 'a=',
        expected: <String, Object?>{'a': ''},
      ),
      _FlatDecodeCase(
        name: 'empty keys are ignored',
        input: '=b',
        expected: <String, Object?>{},
      ),
    ];

    const List<_FlatDecodeCase> delimiterNoiseAndEmptyNamesValues = [
      _FlatDecodeCase(
        name: 'bare delimiter yields an empty map',
        input: '&',
        expected: <String, Object?>{},
      ),
      _FlatDecodeCase(
        name: 'leading delimiters are ignored',
        input: '&a',
        expected: <String, Object?>{'a': ''},
      ),
      _FlatDecodeCase(
        name: 'trailing delimiters are ignored',
        input: 'a&',
        expected: <String, Object?>{'a': ''},
      ),
      _FlatDecodeCase(
        name: 'multiple bare keys retain order across keys',
        input: 'a&b&c',
        expected: <String, Object?>{'a': '', 'b': '', 'c': ''},
      ),
      _FlatDecodeCase(
        name: 'multiple key value pairs decode normally',
        input: 'a=b&c=d',
        expected: <String, Object?>{'a': 'b', 'c': 'd'},
      ),
      _FlatDecodeCase(
        name: 'trailing delimiter after pairs is ignored',
        input: 'a=b&c=d&',
        expected: <String, Object?>{'a': 'b', 'c': 'd'},
      ),
      _FlatDecodeCase(
        name: 'runs of empty segments are ignored',
        input: '&&&a=b&&&&c=d&',
        expected: <String, Object?>{'a': 'b', 'c': 'd'},
      ),
    ];

    const List<_FlatDecodeCase> duplicateFlatKeysAndOrdering = [
      _FlatDecodeCase(
        name: 'duplicate bare keys combine into an ordered list',
        input: 'a&a',
        expected: <String, Object?>{
          'a': <String>['', ''],
        },
      ),
      _FlatDecodeCase(
        name: 'duplicate flat values preserve insertion order',
        input: 'a=a&a=b&a=c',
        expected: <String, Object?>{
          'a': <String>['a', 'b', 'c'],
        },
      ),
    ];

    const List<_FlatDecodeCase> percentDecodingAndMalformedPercent = [
      _FlatDecodeCase(
        name: 'only the first equals sign splits the pair',
        input: 'a==a',
        expected: <String, Object?>{'a': '=a'},
      ),
      _FlatDecodeCase(
        name: 'plus signs decode as spaces',
        input: 'a=a+b+c+d',
        expected: <String, Object?>{'a': 'a b c d'},
      ),
      _FlatDecodeCase(
        name: 'lone percent key is preserved',
        input: '%=a',
        expected: <String, Object?>{'%': 'a'},
      ),
      _FlatDecodeCase(
        name: 'malformed percent prefix in key stays literal',
        input: '%a=a',
        expected: <String, Object?>{'%a': 'a'},
      ),
      _FlatDecodeCase(
        name: 'partially encoded key suffix stays literal',
        input: '%a_=a',
        expected: <String, Object?>{'%a_': 'a'},
      ),
      _FlatDecodeCase(
        name: 'valid percent encoded key decodes',
        input: '%61=a',
        expected: <String, Object?>{'a': 'a'},
      ),
      _FlatDecodeCase(
        name: 'percent encoded key and plus decode together',
        input: '%61+%4d%4D=',
        expected: <String, Object?>{'a MM': ''},
      ),
      _FlatDecodeCase(
        name: 'lone percent value is preserved',
        input: 'id=0&value=%',
        expected: <String, Object?>{'id': '0', 'value': '%'},
      ),
      _FlatDecodeCase(
        name: 'invalid hex nibble keeps the whole token literal',
        input: 'b=%2sf%2a',
        expected: <String, Object?>{'b': '%2sf%2a'},
      ),
      _FlatDecodeCase(
        name: 'short malformed escape keeps the whole token literal',
        input: 'b=%2%2af%2a',
        expected: <String, Object?>{'b': '%2%2af%2a'},
      ),
      _FlatDecodeCase(
        name: 'literal percent followed by a valid escape stays literal',
        input: 'b=%%2a',
        expected: <String, Object?>{'b': '%%2a'},
      ),
    ];

    for (final testCase in emptyAndDegenerateInputs) {
      test('empty and degenerate inputs: ${testCase.name}', () {
        expect(QS.decode(testCase.input), equals(testCase.expected));
      });
    }

    for (final testCase in delimiterNoiseAndEmptyNamesValues) {
      test('delimiter noise and empty names or values: ${testCase.name}', () {
        expect(QS.decode(testCase.input), equals(testCase.expected));
      });
    }

    for (final testCase in duplicateFlatKeysAndOrdering) {
      test('duplicate flat keys and ordering: ${testCase.name}', () {
        expect(QS.decode(testCase.input), equals(testCase.expected));
      });
    }

    for (final testCase in percentDecodingAndMalformedPercent) {
      test('percent decoding and malformed percent: ${testCase.name}', () {
        expect(QS.decode(testCase.input), equals(testCase.expected));
      });
    }
  });
}
