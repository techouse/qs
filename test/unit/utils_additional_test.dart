import 'dart:collection';

import 'package:qs_dart/qs_dart.dart';
import 'package:qs_dart/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('Utils.merge edge branches', () {
    test('normalizes to map when Undefined persists and parseLists is false',
        () {
      final result = Utils.merge(
        [const Undefined()],
        const [Undefined()],
        const DecodeOptions(parseLists: false),
      );

      final splay = result as SplayTreeMap;
      expect(splay.isEmpty, isTrue);
    });

    test('combines non-iterable scalars into a list pair', () {
      expect(Utils.merge('left', 'right'), equals(['left', 'right']));
    });

    test('combines scalar and iterable respecting Undefined stripping', () {
      final result = Utils.merge(
        'seed',
        ['tail', const Undefined()],
      );
      expect(result, equals(['seed', 'tail']));
    });
  });

  group('Utils.encode surrogate handling', () {
    const int segmentLimit = 1024;

    String buildBoundaryString() {
      final high = String.fromCharCode(0xD83D);
      final low = String.fromCharCode(0xDE00);
      return '${'a' * (segmentLimit - 1)}$high${low}tail';
    }

    test('avoids splitting surrogate pairs across segments', () {
      final encoded = Utils.encode(buildBoundaryString());
      expect(encoded.startsWith('a' * (segmentLimit - 1)), isTrue);
      expect(encoded, contains('%F0%9F%98%80'));
      expect(encoded.endsWith('tail'), isTrue);
    });

    test('encodes high-and-low surrogate pair to four-byte UTF-8', () {
      final emoji = String.fromCharCodes([0xD83D, 0xDE01]);
      expect(Utils.encode(emoji), equals('%F0%9F%98%81'));
    });

    test('encodes lone low surrogate as three-byte sequence', () {
      final loneLow = String.fromCharCode(0xDC00);
      expect(Utils.encode(loneLow), equals('%ED%B0%80'));
    });
  });

  group('Utils helpers', () {
    test('isNonNullishPrimitive treats Uri based on skipNulls flag', () {
      final emptyUri = Uri.parse('');
      expect(Utils.isNonNullishPrimitive(emptyUri), isTrue);
      expect(Utils.isNonNullishPrimitive(emptyUri, true), isFalse);
      final populated = Uri.parse('https://example.com');
      expect(Utils.isNonNullishPrimitive(populated, true), isTrue);
    });

    test('interpretNumericEntities handles astral plane code points', () {
      expect(Utils.interpretNumericEntities('&#128512;'), equals('😀'));
    });

    test('createIndexMap materializes non-List iterables', () {
      final iterable = Iterable.generate(3, (i) => i * 2);
      expect(
        Utils.createIndexMap(iterable),
        equals({'0': 0, '1': 2, '2': 4}),
      );
    });
  });
}
