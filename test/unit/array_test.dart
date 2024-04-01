import 'dart:collection';

import 'package:qs_dart/src/models/undefined.dart';
import 'package:qs_dart/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('SplayTreeMap', () {
    test('indices are ordered in value', () {
      final SplayTreeMap<int, String> array =
          SplayTreeMap<int, String>.from({1: 'a', 0: 'b', 2: 'c'});

      expect(array.values, ['b', 'a', 'c']);
    });

    test('indices are ordered in value 2', () {
      final SplayTreeMap<int, String> array = SplayTreeMap<int, String>();
      array[1] = 'c';
      array[0] = 'b';
      array[2] = 'd';

      expect(array.values, ['b', 'c', 'd']);
    });
  });

  group('List.filled', () {
    test('fill with single item', () {
      final List<String?> array = List<String?>.filled(1, null, growable: true);
      array[0] = 'b';

      expect(array, ['b']);
    });

    test('fill with Undefined', () {
      final List<dynamic> array =
          List<dynamic>.filled(3, const Undefined(), growable: true);
      array[0] = 'a';
      array[2] = 'c';

      expect(array, ['a', const Undefined(), 'c']);
    });
  });

  group('removeUndefinedFromValue', () {
    test('remove Undefined from List', () {
      final Map<String, dynamic> mapWithUndefined = {
        'a': [
          'a',
          const Undefined(),
          'b',
          const Undefined(),
          'c',
        ],
      };

      Utils.removeUndefinedFromMap(mapWithUndefined);

      expect(mapWithUndefined, {
        'a': ['a', 'b', 'c'],
      });
    });

    test('remove Undefined from Map', () {
      final Map<String, dynamic> mapWithUndefined = {
        'a': {
          'a': 'a',
          'b': const Undefined(),
          'c': 'c',
        },
      };

      Utils.removeUndefinedFromMap(mapWithUndefined);

      expect(mapWithUndefined, {
        'a': {
          'a': 'a',
          'c': 'c',
        },
      });
    });
  });
}
