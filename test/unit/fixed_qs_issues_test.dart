import 'package:qs_dart/qs_dart.dart';
import 'package:test/test.dart';

void main() {
  group('fixed ljharb/qs issues', () {
    test('ljharb/qs#493', () {
      final Map<String, dynamic> original = {
        'search': {'withbracket[]': 'foobar'}
      };
      final String encoded = 'search[withbracket[]]=foobar';

      expect(
        QS.encode(original, EncodeOptions(encode: false)),
        equals(encoded),
      );
      expect(QS.decode(encoded), equals(original));
    });
  });
}
