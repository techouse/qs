import 'package:qs_dart/src/models/undefined.dart';
import 'package:test/test.dart';

void main() {
  group('Undefined', () {
    test('copyWith', () {
      final Undefined undefined = const Undefined();
      final Undefined newUndefined = undefined.copyWith();

      expect(newUndefined, equals(undefined));
    });
  });
}
