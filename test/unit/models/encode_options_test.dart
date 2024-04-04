import 'dart:convert';

import 'package:qs_dart/src/enums/format.dart';
import 'package:qs_dart/src/enums/list_format.dart';
import 'package:qs_dart/src/models/encode_options.dart';
import 'package:test/test.dart';

void main() {
  group('EncodeOptions', () {
    test('copyWith no modifications', () {
      final EncodeOptions options = const EncodeOptions(
        addQueryPrefix: true,
        allowDots: true,
        allowEmptyLists: true,
        listFormat: ListFormat.indices,
        charset: latin1,
        charsetSentinel: true,
        delimiter: ',',
        encode: true,
        encodeDotInKeys: true,
        encodeValuesOnly: true,
        format: Format.rfc1738,
        skipNulls: true,
        strictNullHandling: true,
        commaRoundTrip: true,
      );

      final EncodeOptions newOptions = options.copyWith();

      expect(newOptions.addQueryPrefix, isTrue);
      expect(newOptions.allowDots, isTrue);
      expect(newOptions.allowEmptyLists, isTrue);
      expect(newOptions.listFormat, ListFormat.indices);
      expect(newOptions.charset, latin1);
      expect(newOptions.charsetSentinel, isTrue);
      expect(newOptions.delimiter, ',');
      expect(newOptions.encode, isTrue);
      expect(newOptions.encodeDotInKeys, isTrue);
      expect(newOptions.encodeValuesOnly, isTrue);
      expect(newOptions.format, Format.rfc1738);
      expect(newOptions.skipNulls, isTrue);
      expect(newOptions.strictNullHandling, isTrue);
      expect(newOptions.commaRoundTrip, isTrue);
      expect(newOptions, equals(options));
    });

    test('copyWith modifications', () {
      final EncodeOptions options = const EncodeOptions(
        addQueryPrefix: true,
        allowDots: true,
        allowEmptyLists: true,
        listFormat: ListFormat.indices,
        charset: latin1,
        charsetSentinel: true,
        delimiter: ',',
        encode: true,
        encodeDotInKeys: true,
        encodeValuesOnly: true,
        format: Format.rfc1738,
        skipNulls: true,
        strictNullHandling: true,
        commaRoundTrip: true,
      );

      final EncodeOptions newOptions = options.copyWith(
        addQueryPrefix: false,
        allowDots: false,
        allowEmptyLists: false,
        listFormat: ListFormat.brackets,
        charset: utf8,
        charsetSentinel: false,
        delimiter: '&',
        encode: false,
        encodeDotInKeys: false,
        encodeValuesOnly: false,
        format: Format.rfc3986,
        skipNulls: false,
        strictNullHandling: false,
        commaRoundTrip: false,
        filter: (String key, dynamic value) => false,
      );

      expect(newOptions.addQueryPrefix, isFalse);
      expect(newOptions.allowDots, isFalse);
      expect(newOptions.allowEmptyLists, isFalse);
      expect(newOptions.listFormat, ListFormat.brackets);
      expect(newOptions.charset, utf8);
      expect(newOptions.charsetSentinel, isFalse);
      expect(newOptions.delimiter, '&');
      expect(newOptions.encode, isFalse);
      expect(newOptions.encodeDotInKeys, isFalse);
      expect(newOptions.encodeValuesOnly, isFalse);
    });

    test('toString', () {
      final EncodeOptions options = const EncodeOptions(
        addQueryPrefix: true,
        allowDots: true,
        allowEmptyLists: true,
        listFormat: ListFormat.indices,
        charset: latin1,
        charsetSentinel: true,
        delimiter: ',',
        encode: true,
        encodeDotInKeys: true,
        encodeValuesOnly: true,
        format: Format.rfc1738,
        skipNulls: true,
        strictNullHandling: true,
        commaRoundTrip: true,
      );

      expect(
        options.toString(),
        equals('EncodeOptions(\n'
            '  addQueryPrefix: true,\n'
            '  allowDots: true,\n'
            '  allowEmptyLists: true,\n'
            '  listFormat: indices,\n'
            '  charset: Instance of \'Latin1Codec\',\n'
            '  charsetSentinel: true,\n'
            '  delimiter: ,,\n'
            '  encode: true,\n'
            '  encodeDotInKeys: true,\n'
            '  encodeValuesOnly: true,\n'
            '  format: rfc1738,\n'
            '  skipNulls: true,\n'
            '  strictNullHandling: true,\n'
            '  commaRoundTrip: true,\n'
            '  sort: null,\n'
            '  filter: null,\n'
            '  serializeDate: null,\n'
            '  encoder: null,\n'
            ')'),
      );
    });
  });
}
