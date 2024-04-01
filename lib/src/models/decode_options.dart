import 'dart:convert' show Encoding, latin1, utf8;

import 'package:equatable/equatable.dart';
import 'package:qs_dart/src/enums/duplicates.dart';
import 'package:qs_dart/src/utils.dart';

typedef Decoder = dynamic Function(String? value, {Encoding? charset});

final class DecodeOptions with EquatableMixin {
  const DecodeOptions({
    bool? allowDots,
    this.allowEmptyLists = false,
    this.listLimit = 20,
    this.charset = utf8,
    this.charsetSentinel = false,
    this.comma = false,
    bool? decodeDotInKeys,
    this.delimiter = '&',
    this.depth = 5,
    this.duplicates = Duplicates.combine,
    this.ignoreQueryPrefix = false,
    this.interpretNumericEntities = false,
    this.parameterLimit = 1000,
    this.parseLists = true,
    this.strictNullHandling = false,
    Decoder? decoder,
  })  : allowDots = allowDots ?? decodeDotInKeys == true || false,
        decodeDotInKeys = decodeDotInKeys ?? true,
        _decoder = decoder,
        assert(
          charset == utf8 || charset == latin1,
          'Invalid charset',
        );

  final bool allowDots;
  final bool allowEmptyLists;
  final int listLimit;
  final Encoding charset;
  final bool charsetSentinel;
  final bool comma;
  final bool decodeDotInKeys;
  final Pattern delimiter;
  final int depth;
  final Duplicates duplicates;
  final bool ignoreQueryPrefix;
  final bool interpretNumericEntities;
  final num parameterLimit;
  final bool parseLists;
  final bool strictNullHandling;
  final Decoder? _decoder;

  dynamic decoder(String? value, {Encoding? charset}) => _decoder is Function
      ? _decoder?.call(value, charset: charset)
      : Utils.decode(value, charset: charset);

  DecodeOptions copyWith({
    bool? allowDots,
    bool? allowEmptyLists,
    int? listLimit,
    Encoding? charset,
    bool? charsetSentinel,
    bool? comma,
    bool? decodeDotInKeys,
    Pattern? delimiter,
    int? depth,
    Duplicates? duplicates,
    bool? ignoreQueryPrefix,
    bool? interpretNumericEntities,
    num? parameterLimit,
    bool? parseLists,
    bool? strictNullHandling,
    Decoder? decoder,
  }) =>
      DecodeOptions(
        allowDots: allowDots ?? this.allowDots,
        allowEmptyLists: allowEmptyLists ?? this.allowEmptyLists,
        listLimit: listLimit ?? this.listLimit,
        charset: charset ?? this.charset,
        charsetSentinel: charsetSentinel ?? this.charsetSentinel,
        comma: comma ?? this.comma,
        decodeDotInKeys: decodeDotInKeys ?? this.decodeDotInKeys,
        delimiter: delimiter ?? this.delimiter,
        depth: depth ?? this.depth,
        duplicates: duplicates ?? this.duplicates,
        ignoreQueryPrefix: ignoreQueryPrefix ?? this.ignoreQueryPrefix,
        interpretNumericEntities:
            interpretNumericEntities ?? this.interpretNumericEntities,
        parameterLimit: parameterLimit ?? this.parameterLimit,
        parseLists: parseLists ?? this.parseLists,
        strictNullHandling: strictNullHandling ?? this.strictNullHandling,
        decoder: decoder ?? _decoder,
      );

  @override
  String toString() => 'DecodeOptions(\n'
      '  allowDots: $allowDots,\n'
      '  allowEmptyLists: $allowEmptyLists,\n'
      '  listLimit: $listLimit,\n'
      '  charset: $charset,\n'
      '  charsetSentinel: $charsetSentinel,\n'
      '  comma: $comma,\n'
      '  decodeDotInKeys: $decodeDotInKeys,\n'
      '  delimiter: $delimiter,\n'
      '  depth: $depth,\n'
      '  duplicates: $duplicates,\n'
      '  ignoreQueryPrefix: $ignoreQueryPrefix,\n'
      '  interpretNumericEntities: $interpretNumericEntities,\n'
      '  parameterLimit: $parameterLimit,\n'
      '  parseLists: $parseLists,\n'
      '  strictNullHandling: $strictNullHandling\n'
      ')';

  @override
  List<Object?> get props => [
        allowDots,
        allowEmptyLists,
        listLimit,
        charset,
        charsetSentinel,
        comma,
        decodeDotInKeys,
        delimiter,
        depth,
        duplicates,
        ignoreQueryPrefix,
        interpretNumericEntities,
        parameterLimit,
        parseLists,
        strictNullHandling,
        _decoder,
      ];
}
