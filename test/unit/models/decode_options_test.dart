import 'dart:convert';

import 'package:qs_dart/src/enums/duplicates.dart';
import 'package:qs_dart/src/models/decode_options.dart';
import 'package:test/test.dart';

void main() {
  group('DecodeOptions', () {
    test('copyWith no modifications', () {
      final DecodeOptions options = const DecodeOptions(
        allowDots: true,
        allowEmptyLists: true,
        listLimit: 20,
        charset: utf8,
        charsetSentinel: true,
        comma: true,
        delimiter: '&',
        depth: 20,
        duplicates: Duplicates.last,
        ignoreQueryPrefix: true,
        interpretNumericEntities: true,
        parameterLimit: 200,
        parseLists: true,
        strictNullHandling: true,
      );

      final DecodeOptions newOptions = options.copyWith();

      expect(newOptions.allowDots, isTrue);
      expect(newOptions.allowEmptyLists, isTrue);
      expect(newOptions.listLimit, 20);
      expect(newOptions.charset, utf8);
      expect(newOptions.charsetSentinel, isTrue);
      expect(newOptions.comma, isTrue);
      expect(newOptions.delimiter, '&');
      expect(newOptions.depth, 20);
      expect(newOptions.duplicates, Duplicates.last);
      expect(newOptions.ignoreQueryPrefix, isTrue);
      expect(newOptions.interpretNumericEntities, isTrue);
      expect(newOptions.parameterLimit, 200);
      expect(newOptions.parseLists, isTrue);
      expect(newOptions.strictNullHandling, isTrue);
      expect(newOptions, equals(options));
    });

    test('copyWith modifications', () {
      final DecodeOptions options = const DecodeOptions(
        allowDots: true,
        allowEmptyLists: true,
        listLimit: 10,
        charset: latin1,
        charsetSentinel: true,
        comma: true,
        delimiter: ',',
        depth: 10,
        duplicates: Duplicates.combine,
        ignoreQueryPrefix: true,
        interpretNumericEntities: true,
        parameterLimit: 100,
        parseLists: false,
        strictNullHandling: true,
      );

      final DecodeOptions newOptions = options.copyWith(
        allowDots: false,
        allowEmptyLists: false,
        listLimit: 20,
        charset: utf8,
        charsetSentinel: false,
        comma: false,
        delimiter: '&',
        depth: 20,
        duplicates: Duplicates.last,
        ignoreQueryPrefix: false,
        interpretNumericEntities: false,
        parameterLimit: 200,
        parseLists: true,
        strictNullHandling: false,
      );

      expect(newOptions.allowDots, isFalse);
      expect(newOptions.allowEmptyLists, isFalse);
      expect(newOptions.listLimit, 20);
      expect(newOptions.charset, utf8);
      expect(newOptions.charsetSentinel, isFalse);
      expect(newOptions.comma, isFalse);
      expect(newOptions.delimiter, '&');
      expect(newOptions.depth, 20);
      expect(newOptions.duplicates, Duplicates.last);
      expect(newOptions.ignoreQueryPrefix, isFalse);
      expect(newOptions.interpretNumericEntities, isFalse);
      expect(newOptions.parameterLimit, 200);
      expect(newOptions.parseLists, isTrue);
      expect(newOptions.strictNullHandling, isFalse);
    });

    test('toString', () {
      final DecodeOptions options = const DecodeOptions(
        allowDots: true,
        allowEmptyLists: true,
        listLimit: 10,
        charset: latin1,
        charsetSentinel: true,
        comma: true,
        delimiter: ',',
        depth: 10,
        duplicates: Duplicates.combine,
        ignoreQueryPrefix: true,
        interpretNumericEntities: true,
        parameterLimit: 100,
        parseLists: false,
        strictNullHandling: true,
      );

      expect(
        options.toString(),
        equals(
          'DecodeOptions(\n'
          '  allowDots: true,\n'
          '  allowEmptyLists: true,\n'
          '  listLimit: 10,\n'
          '  charset: Instance of \'Latin1Codec\',\n'
          '  charsetSentinel: true,\n'
          '  comma: true,\n'
          '  decodeDotInKeys: false,\n'
          '  delimiter: ,,\n'
          '  depth: 10,\n'
          '  duplicates: combine,\n'
          '  ignoreQueryPrefix: true,\n'
          '  interpretNumericEntities: true,\n'
          '  parameterLimit: 100,\n'
          '  parseLists: false,\n'
          '  strictNullHandling: true\n'
          ')',
        ),
      );
    });
  });
}
