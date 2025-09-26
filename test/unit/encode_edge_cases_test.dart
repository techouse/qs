import 'dart:convert' show Encoding;

import 'package:qs_dart/qs_dart.dart';
import 'package:test/test.dart';

// Dynamic indexer object used to exercise the fallback indexer try/catch path.
class _Dyn {
  final Map<String, dynamic> _values = {'ok': 42};

  dynamic operator [](Object? key) {
    if (key == 'boom') throw ArgumentError('boom');
    return _values[key];
  }
}

void main() {
  group('encode edge cases', () {
    test('cycle detection: shared subobject visited twice without throwing',
        () {
      final shared = {'z': 1};
      final obj = {'a': shared, 'b': shared};
      // Encoded output will have two key paths referencing the same subobject; no RangeError.
      final encoded = QS.encode(obj);
      // Accept either ordering; just verify two occurrences of '=1'.
      final occurrences = '=1'.allMatches(encoded).length;
      expect(occurrences, 2);
    });

    test('strictNullHandling with custom encoder emits only encoded key', () {
      final encoded = QS.encode(
          {
            'nil': null,
          },
          const EncodeOptions(
              strictNullHandling: true, encoder: _identityEncoder));
      // Expect just the key without '=' (qs semantics) – no trailing '=' segment.
      expect(encoded, 'nil');
    });

    test(
        'filter iterable branch + dynamic indexer fallback (throws for one key)',
        () {
      final dyn = _Dyn();
      // Provide filter at root limiting to key 'dyn'.
      // Inside recursion we pass function filter that returns the object (so _encode sees Function path),
      // then manually trigger iterable filter via an inner call by encoding a child map with iterable filter.
      final outer =
          QS.encode({'dyn': dyn}, const EncodeOptions(filter: ['dyn']));
      // Outer should serialize the object reference.
      expect(outer.startsWith('dyn='), isTrue);
      // Now directly exercise iterable filter branch by calling private logic through normal API:
      final inner = QS.encode({'ok': 42, 'boom': null},
          const EncodeOptions(filter: ['ok', 'boom'], skipNulls: true));
      // 'ok' present, 'boom' skipped by skipNulls.
      expect(inner, 'ok=42');
    });

    test('comma list empty emits nothing but executes Undefined sentinel path',
        () {
      final encoded = QS.encode(
          {'list': <String>[]},
          const EncodeOptions(
              listFormat: ListFormat.comma, allowEmptyLists: false));
      // Empty under comma + allowEmptyLists=false → nothing emitted.
      expect(encoded, isEmpty);
    });

    test(
        'cycle detection non-direct: shared object at different depths (pos != step path)',
        () {
      final shared = {'k': 'v'};
      final obj = {
        'a': {'x': shared},
        'b': {
          'y': {'z': shared}
        },
      };
      final encoded = QS.encode(obj);
      // Two serialized occurrences with percent-encoded brackets.
      expect(encoded.contains('a%5Bx%5D%5Bk%5D=v'), isTrue);
      expect(encoded.contains('b%5By%5D%5Bz%5D%5Bk%5D=v'), isTrue);
    });

    test(
        'strictNullHandling nested null returns prefix string (non-iterable recursion branch)',
        () {
      final encoded = QS.encode({
        'p': {'c': null}
      }, const EncodeOptions(strictNullHandling: true));
      // Brackets are percent-encoded in final output.
      expect(encoded.contains('p%5Bc%5D'), isTrue);
      expect(encoded.contains('p%5Bc%5D='), isFalse);
    });

    test(
        'strictNullHandling + custom mutating encoder transforms key (encoder ternary branch)',
        () {
      // Encoder mutates keys by wrapping them; value is null so only key is emitted.
      final encoded = QS.encode(
          {'nil': null},
          const EncodeOptions(
            strictNullHandling: true,
            encoder: _mutatingEncoder,
          ));
      expect(encoded, 'X_nil');
    });

    test(
        'allowEmptyLists nested empty list returns scalar fragment to parent (flatten branch)',
        () {
      final encoded = QS.encode({
        'outer': {'p': []}
      }, const EncodeOptions(allowEmptyLists: true));
      // Expect encoded key path with empty list marker in plain bracket form (no percent-encoding at this stage).
      expect(encoded, 'outer[p][]');
    });

    test('cycle detection step reset path (multi-level shared object)', () {
      // Construct a deeper object graph where the same shared leaf appears in
      // branches of differing depth to exercise the while-loop step reset logic.
      final shared = {'leaf': 1};
      final obj = {
        'a': {
          'l1': {'l2': shared}
        },
        'b': {
          'l1': {
            'l2': {
              'l3': {'l4': shared}
            }
          }
        },
        'c': 2,
      };
      final encoded = QS.encode(obj);
      // Two occurrences of the shared leaf serialization plus the scalar 'c'.
      final occurrences = 'leaf%5D=1'
          .allMatches(encoded)
          .length; // pattern like a%5Bl1%5D%5Bl2%5D%5Bleaf%5D=1
      expect(occurrences, 2);
      expect(encoded.contains('c=2'), isTrue);
    });
  });
}

String _identityEncoder(dynamic v, {Encoding? charset, Format? format}) =>
    v?.toString() ?? '';

String _mutatingEncoder(dynamic v, {Encoding? charset, Format? format}) =>
    'X_${v.toString()}';
