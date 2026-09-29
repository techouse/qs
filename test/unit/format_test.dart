import 'package:qs_dart/qs_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Format', () {
    test('toString returns each documented format name', () {
      expect(Format.rfc1738.toString(), 'rfc1738');
      expect(Format.rfc3986.toString(), 'rfc3986');
    });
  });
}
