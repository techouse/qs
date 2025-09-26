// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:convert';

import 'package:qs_dart/src/enums/decode_kind.dart';
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
        strictDepth: false,
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
          '  strictDepth: false,\n'
          '  strictNullHandling: true\n'
          ')',
        ),
      );
    });
  });

  group('DecodeOptions – allowDots / decodeDotInKeys interplay', () {
    test('constructor: allowDots=false + decodeDotInKeys=true throws', () {
      expect(
        () => DecodeOptions(allowDots: false, decodeDotInKeys: true),
        throwsA(anyOf(
          isA<ArgumentError>(),
          isA<StateError>(),
          isA<AssertionError>(),
        )),
      );
    });

    test('copyWith: making options inconsistent throws', () {
      final base = const DecodeOptions(decodeDotInKeys: true);
      expect(
        () => base.copyWith(allowDots: false),
        throwsA(anyOf(
          isA<ArgumentError>(),
          isA<StateError>(),
          isA<AssertionError>(),
        )),
      );
    });
  });

  group(
      'DecodeOptions.defaultDecode: KEY protects encoded dots prior to percent-decoding',
      () {
    final charsets = <Encoding>[utf8, latin1];

    test(
        "KEY maps %2E/%2e inside brackets to '.' when allowDots=true (UTF-8/ISO-8859-1)",
        () {
      for (final cs in charsets) {
        final opts = DecodeOptions(allowDots: true, charset: cs);
        expect(opts.decodeKey('a[%2E]'), equals('a[.]'));
        expect(opts.decodeKey('a[%2e]'), equals('a[.]'));
      }
    });

    test(
        "KEY maps %2E outside brackets to '.' when allowDots=true; independent of decodeDotInKeys (UTF-8/ISO)",
        () {
      for (final cs in charsets) {
        final opts1 =
            DecodeOptions(allowDots: true, decodeDotInKeys: false, charset: cs);
        final opts2 =
            DecodeOptions(allowDots: true, decodeDotInKeys: true, charset: cs);
        expect(opts1.decodeKey('a%2Eb'), equals('a.b'));
        expect(opts2.decodeKey('a%2Eb'), equals('a.b'));
      }
    });

    test('non-KEY decodes %2E to \'.\' (control)', () {
      for (final cs in charsets) {
        final opts = DecodeOptions(allowDots: true, charset: cs);
        expect(opts.decodeValue('a%2Eb'), equals('a.b'));
      }
    });

    test('KEY maps %2E/%2e inside brackets even when allowDots=false', () {
      for (final cs in charsets) {
        final opts = DecodeOptions(allowDots: false, charset: cs);
        expect(opts.decodeKey('a[%2E]'), equals('a[.]'));
        expect(opts.decodeKey('a[%2e]'), equals('a[.]'));
      }
    });

    test(
        "KEY outside %2E decodes to '.' when allowDots=false (no protection outside brackets)",
        () {
      for (final cs in charsets) {
        final opts = DecodeOptions(allowDots: false, charset: cs);
        expect(opts.decodeKey('a%2Eb'), equals('a.b'));
        expect(opts.decodeKey('a%2eb'), equals('a.b'));
      }
    });
  });

  group('DecodeOptions: allowDots / decodeDotInKeys interplay (computed)', () {
    test(
        'decodeDotInKeys=true implies allowDots==true when allowDots not explicitly false',
        () {
      final opts = const DecodeOptions(decodeDotInKeys: true);
      expect(opts.allowDots, isTrue);
    });
  });

  group(
      'DecodeOptions: key/value decoding + custom decoder behavior (C# parity)',
      () {
    test(
        'DecodeKey decodes percent sequences like values (allowDots=true, decodeDotInKeys=false)',
        () {
      final opts = const DecodeOptions(allowDots: true, decodeDotInKeys: false);
      expect(opts.decodeKey('a%2Eb'), equals('a.b'));
      expect(opts.decodeKey('a%2eb'), equals('a.b'));
    });

    test('DecodeValue decodes percent sequences normally', () {
      final opts = const DecodeOptions();
      expect(opts.decodeValue('%2E'), equals('.'));
    });

    test('Decoder is used for KEY and for VALUE', () {
      final List<Map<String, Object?>> calls = [];
      final opts = DecodeOptions(
        decoder: (String? s, {Encoding? charset, DecodeKind? kind}) {
          calls.add({'s': s, 'kind': kind});
          return s; // echo back
        },
      );

      expect(opts.decodeKey('x'), equals('x'));
      expect(opts.decodeValue('y'), equals('y'));

      expect(calls.length, 2);
      expect(calls[0]['kind'], DecodeKind.key);
      expect(calls[0]['s'], 'x');
      expect(calls[1]['kind'], DecodeKind.value);
      expect(calls[1]['s'], 'y');
    });

    test('Decoder null return is honored (no fallback to default)', () {
      final opts = DecodeOptions(
        decoder: (String? s, {Encoding? charset, DecodeKind? kind}) => null,
      );
      expect(opts.decodeValue('foo'), isNull);
      expect(opts.decodeKey('bar'), isNull);
    });

    test(
        "Single decoder acts like 'legacy' when ignoring kind (no default applied first)",
        () {
      // Emulate a legacy decoder that uppercases the raw token without percent-decoding.
      final opts = DecodeOptions(
        decoder: (String? s, {Encoding? charset, DecodeKind? kind}) =>
            s?.toUpperCase(),
      );
      expect(opts.decodeValue('abc'), equals('ABC'));
      // For keys, custom decoder gets the raw token; no default percent-decoding happens first.
      expect(opts.decodeKey('a%2Eb'), equals('A%2EB'));
    });

    test('copyWith preserves and allows overriding the decoder', () {
      final original = DecodeOptions(
        decoder: (String? s, {Encoding? charset, DecodeKind? kind}) =>
            s == null ? null : 'K:${kind ?? DecodeKind.value}:$s',
      );

      final copy = original.copyWith();
      expect(copy.decodeValue('v'), equals('K:${DecodeKind.value}:v'));
      expect(copy.decodeKey('k'), equals('K:${DecodeKind.key}:k'));

      final copy2 = original.copyWith(
        decoder: (String? s, {Encoding? charset, DecodeKind? kind}) =>
            s == null ? null : 'K2:${kind ?? DecodeKind.value}:$s',
      );
      expect(copy2.decodeValue('v'), equals('K2:${DecodeKind.value}:v'));
      expect(copy2.decodeKey('k'), equals('K2:${DecodeKind.key}:k'));
    });

    test('decoder wins over legacyDecoder when both are provided', () {
      String legacy(String? v, {Encoding? charset}) => 'L:${v ?? 'null'}';
      String dec(String? v, {Encoding? charset, DecodeKind? kind}) =>
          'K:${kind ?? DecodeKind.value}:${v ?? 'null'}';
      final opts = DecodeOptions(decoder: dec, legacyDecoder: legacy);

      expect(opts.decodeKey('x'), equals('K:${DecodeKind.key}:x'));
      expect(opts.decodeValue('y'), equals('K:${DecodeKind.value}:y'));
    });

    test('decodeKey coerces non-string decoder result via toString', () {
      final opts = DecodeOptions(
          decoder: (String? s, {Encoding? charset, DecodeKind? kind}) => 42);
      expect(opts.decodeKey('anything'), equals('42'));
    });

    test(
        'copyWith to an inconsistent combination (allowDots=false with decodeDotInKeys=true) throws',
        () {
      final original = const DecodeOptions(decodeDotInKeys: true);
      expect(
          () => original.copyWith(allowDots: false),
          throwsA(anyOf(
            isA<ArgumentError>(),
            isA<StateError>(),
            isA<AssertionError>(),
          )));
    });
  });

  group('DecodeOptions legacy decoder fallback', () {
    test('prefers legacy decoder when primary decoder absent', () {
      final calls = <Map<String, Object?>>[];
      final opts = DecodeOptions(
        legacyDecoder: (String? value, {Encoding? charset}) {
          calls.add({'value': value, 'charset': charset});
          return value?.toUpperCase();
        },
      );

      expect(opts.decode('abc', charset: latin1), equals('ABC'));
      expect(calls, hasLength(1));
      expect(calls.single['charset'], equals(latin1));
    });
  });
}
