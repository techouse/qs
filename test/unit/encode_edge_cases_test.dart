import 'dart:collection';
import 'dart:convert' show Encoding;

import 'package:qs_dart/qs_dart.dart';
import 'package:test/test.dart';

// Map-like test double that throws when accessing the 'boom' key to exercise the
// try/catch undefined path in the encoder's value resolution logic.
class _Dyn extends MapBase<String, dynamic> {
  final Map<String, dynamic> _store = {'ok': 42};

  @override
  dynamic operator [](Object? key) {
    if (key == 'boom') throw ArgumentError('boom');
    return _store[key];
  }

  @override
  void operator []=(String key, dynamic value) => _store[key] = value;

  @override
  void clear() => _store.clear();

  @override
  Iterable<String> get keys => _store.keys;

  @override
  dynamic remove(Object? key) => _store.remove(key);

  @override
  bool containsKey(Object? key) => _store.containsKey(key);

  // Explicit length getter (not abstract in MapBase but included for clarity / coverage intent)
  @override
  int get length => _store.length;
}

void main() {
  group('encode edge cases', () {
    test('cycle detection: shared subobject visited twice without throwing',
        () {
      final shared = {'z': 1};
      final obj = {'a': shared, 'b': shared};
      // Encoded output will have two key paths referencing the same subobject; no RangeError.
      final encoded = QS.encode(obj);
      expect(encoded.contains('a%5Bz%5D=1'), isTrue);
      expect(encoded.contains('b%5Bz%5D=1'), isTrue);
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

    test('filter iterable branch on MapBase with throwing key access', () {
      final dyn = _Dyn();
      // Encode the MapBase directly with a filter that forces lookups for both 'ok'
      // (successful) and 'boom' (throws → caught → undefined + skipped by skipNulls).
      final encoded = QS.encode(
          dyn, const EncodeOptions(filter: ['ok', 'boom'], skipNulls: true));
      expect(encoded, 'ok=42');
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
      expect(
        RegExp(r'a%5Bx%5D%5Bk%5D=v', caseSensitive: false).hasMatch(encoded),
        isTrue,
      );
      expect(
        RegExp(r'b%5By%5D%5Bz%5D%5Bk%5D=v', caseSensitive: false)
            .hasMatch(encoded),
        isTrue,
      );
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
      // Allow either percent-encoded or raw bracket form (both are acceptable depending on encoding path),
      // and an optional trailing '=' if future changes emit an explicit empty value.
      final pattern = RegExp(r'^(outer%5Bp%5D%5B%5D=?|outer\[p\]\[\](=?))$');
      expect(encoded, matches(pattern));
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
    v == null ? '' : 'X_${v.toString()}';
