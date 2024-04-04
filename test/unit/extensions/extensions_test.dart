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
}
