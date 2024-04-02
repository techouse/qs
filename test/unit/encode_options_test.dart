import 'dart:convert';

import 'package:qs_dart/src/enums/format.dart';
import 'package:qs_dart/src/enums/list_format.dart';
import 'package:qs_dart/src/models/encode_options.dart';
import 'package:test/test.dart';

void main() {
  group('EncodeOptions', () {
    test('copyWith', () {
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
  });
}
