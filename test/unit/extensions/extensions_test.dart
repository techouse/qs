import 'package:qs_dart/qs_dart.dart';
import 'package:qs_dart/src/extensions/extensions.dart';
import 'package:test/test.dart';

void main() {
  group('IterableExtension', () {
    test('whereNotUndefined', () {
      const Iterable<dynamic> iterable = [1, 2, Undefined(), 4, 5];
      final Iterable<dynamic> result = iterable.whereNotType<Undefined>();
      expect(result, isA<Iterable<dynamic>>());
      expect(result, [1, 2, 4, 5]);
    });
  });
}
