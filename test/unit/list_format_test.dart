import 'package:qs_dart/qs_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ListFormat generators', () {
    test('brackets format appends empty brackets', () {
      expect(ListFormat.brackets.generator('foo'), equals('foo[]'));
    });

    test('comma format keeps prefix untouched', () {
      expect(ListFormat.comma.generator('foo'), equals('foo'));
    });

    test('repeat format reuses the prefix', () {
      expect(ListFormat.repeat.generator('foo'), equals('foo'));
    });

    test('indices format injects the element index', () {
      expect(ListFormat.indices.generator('foo', '2'), equals('foo[2]'));
    });

    test('toString mirrors enum name', () {
      expect(ListFormat.indices.toString(), equals('indices'));
    });
  });
}
