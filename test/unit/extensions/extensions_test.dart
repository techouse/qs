import 'package:qs_dart/qs_dart.dart';
import 'package:qs_dart/src/extensions/extensions.dart';
import 'package:test/test.dart';

void main() {
  group('IterableExtension', () {
    test('whereNotUndefined', () {
      const Iterable<dynamic> iterable = [1, 2, Undefined(), 4, 5];
      final Iterable<dynamic> result = iterable.whereNotUndefined();
      expect(result, isA<Iterable<dynamic>>());
      expect(result, [1, 2, 4, 5]);
    });
  });

  group('ListExtension', () {
    test('whereNotUndefined', () {
      const List<dynamic> list = [1, 2, Undefined(), 4, 5];
      final List<dynamic> result = list.whereNotUndefined();
      expect(result, isA<List<dynamic>>());
      expect(result, [1, 2, 4, 5]);
    });
  });

  group('StringExtensions', () {
    test('slice', () {
      const String str = 'The quick brown fox jumps over the lazy dog.';
      expect(str.slice(31), 'the lazy dog.');
      expect(str.slice(31, 1999), 'the lazy dog.');
      expect(str.slice(4, 19), 'quick brown fox');
      expect(str.slice(-4), 'dog.');
      expect(str.slice(-9, -5), 'lazy');
    });
  });
}
