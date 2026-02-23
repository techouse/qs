import 'dart:convert' show Encoding, utf8;

import 'package:qs_dart/src/enums/format.dart';
import 'package:qs_dart/src/enums/list_format.dart';
import 'package:qs_dart/src/models/encode_config.dart';
import 'package:qs_dart/src/models/encode_options.dart';
import 'package:test/test.dart';

String _encoder(dynamic value, {Encoding? charset, Format? format}) =>
    value.toString();
String _serializeDate(DateTime date) => date.toIso8601String();
int _sort(dynamic a, dynamic b) => 0;

void main() {
  group('EncodeConfig', () {
    test('copyWith returns same instance when unchanged', () {
      final config = _baseConfig();

      expect(identical(config.copyWith(), config), isTrue);
    });

    test('withEncoder delegates to copyWith and can clear encoder', () {
      final config = _baseConfig(encoder: _encoder);

      final cleared = config.withEncoder(null);

      expect(cleared, equals(config.copyWith(encoder: null)));
      expect(cleared.encoder, isNull);
      expect(identical(cleared, config), isFalse);
    });

    test('copyWith can clear nullable fields', () {
      final config = _baseConfig(
        encoder: _encoder,
        serializeDate: _serializeDate,
        sort: _sort,
        filter: const ['a', 'b'],
      );

      final copy = config.copyWith(
        encoder: null,
        serializeDate: null,
        sort: null,
        filter: null,
      );

      expect(copy.encoder, isNull);
      expect(copy.serializeDate, isNull);
      expect(copy.sort, isNull);
      expect(copy.filter, isNull);
      expect(copy.generateArrayPrefix, same(config.generateArrayPrefix));
      expect(copy.formatter, same(config.formatter));
    });

    test('copyWith treats const Object filter as explicit override', () {
      const marker = Object();
      final config = _baseConfig(filter: null);

      final copy = config.copyWith(filter: marker);

      expect(identical(copy.filter, marker), isTrue);
    });

    test('equatable props compare all fields', () {
      final a = _baseConfig();
      final b = _baseConfig();

      expect(a, equals(b));
      expect(a.copyWith(skipNulls: true), isNot(equals(b)));
    });
  });
}

EncodeConfig _baseConfig({
  ListFormatGenerator? generateArrayPrefix,
  bool commaRoundTrip = false,
  bool commaCompactNulls = false,
  bool allowEmptyLists = false,
  bool strictNullHandling = false,
  bool skipNulls = false,
  bool encodeDotInKeys = false,
  Encoder? encoder,
  DateSerializer? serializeDate,
  Sorter? sort,
  dynamic filter,
  bool allowDots = false,
  Format format = Format.rfc3986,
  Formatter? formatter,
  bool encodeValuesOnly = false,
}) {
  return EncodeConfig(
    generateArrayPrefix: generateArrayPrefix ?? ListFormat.indices.generator,
    commaRoundTrip: commaRoundTrip,
    commaCompactNulls: commaCompactNulls,
    allowEmptyLists: allowEmptyLists,
    strictNullHandling: strictNullHandling,
    skipNulls: skipNulls,
    encodeDotInKeys: encodeDotInKeys,
    encoder: encoder,
    serializeDate: serializeDate,
    sort: sort,
    filter: filter,
    allowDots: allowDots,
    format: format,
    formatter: formatter ?? format.formatter,
    encodeValuesOnly: encodeValuesOnly,
    charset: utf8,
  );
}
