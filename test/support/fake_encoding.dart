import 'dart:convert' show Converter, Encoding, utf8;

/// Shared fake encoding used by charset validation tests.
class FakeEncoding extends Encoding {
  const FakeEncoding();

  @override
  String get name => 'fake';

  @override
  Converter<List<int>, String> get decoder => utf8.decoder;

  @override
  Converter<String, List<int>> get encoder => utf8.encoder;
}
