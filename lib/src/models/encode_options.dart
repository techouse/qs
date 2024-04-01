import 'dart:convert' show Encoding, utf8, latin1;

import 'package:equatable/equatable.dart';
import 'package:qs_dart/src/enums/format.dart';
import 'package:qs_dart/src/enums/list_format.dart';
import 'package:qs_dart/src/utils.dart';

typedef Encoder = String Function(
  dynamic value, {
  Encoding? charset,
  Format? format,
});
typedef DateSerializer = String Function(DateTime date);
typedef Sorter = int Function(dynamic a, dynamic b);

final class EncodeOptions with EquatableMixin {
  const EncodeOptions({
    this.addQueryPrefix = false,
    this.allowEmptyLists = false,
    this.charset = utf8,
    this.charsetSentinel = false,
    this.delimiter = '&',
    this.encode = true,
    this.encodeDotInKeys = false,
    this.encodeValuesOnly = false,
    this.format = Format.rfc3986,
    this.filter,
    this.skipNulls = false,
    this.strictNullHandling = false,
    this.commaRoundTrip,
    this.sort,
    bool? allowDots,
    ListFormat? listFormat,
    @Deprecated('Use listFormat instead') bool? indices,
    DateSerializer? serializeDate,
    Encoder? encoder,
  })  : allowDots = allowDots ?? encodeDotInKeys || false,
        listFormat = listFormat ??
            (indices == false ? ListFormat.repeat : null) ??
            ListFormat.indices,
        _serializeDate = serializeDate,
        _encoder = encoder,
        assert(
          charset == utf8 || charset == latin1,
          'Invalid charset',
        ),
        assert(
          filter == null || filter is Function || filter is List,
          'Invalid filter',
        );

  final bool addQueryPrefix;
  final bool allowDots;
  final bool allowEmptyLists;
  final ListFormat listFormat;
  final Encoding charset;
  final bool charsetSentinel;
  final String delimiter;
  final bool encode;
  final bool encodeDotInKeys;
  final bool encodeValuesOnly;
  final Format format;
  final bool skipNulls;
  final bool strictNullHandling;
  final bool? commaRoundTrip;
  final Sorter? sort;
  final dynamic filter;
  final DateSerializer? _serializeDate;
  final Encoder? _encoder;

  Formatter get formatter => format.formatter;

  String encoder(dynamic value, {Encoding? charset, Format? format}) =>
      _encoder?.call(
        value,
        charset: charset ?? this.charset,
        format: format ?? this.format,
      ) ??
      Utils.encode(
        value,
        charset: charset ?? this.charset,
        format: format ?? this.format,
      );

  String serializeDate(DateTime date) =>
      _serializeDate?.call(date) ?? date.toIso8601String();

  EncodeOptions copyWith({
    bool? addQueryPrefix,
    bool? allowDots,
    bool? allowEmptyLists,
    ListFormat? listFormat,
    Encoding? charset,
    bool? charsetSentinel,
    String? delimiter,
    bool? encode,
    bool? encodeDotInKeys,
    bool? encodeValuesOnly,
    Format? format,
    bool? skipNulls,
    bool? strictNullHandling,
    bool? commaRoundTrip,
    Sorter? sort,
    dynamic filter,
    DateSerializer? serializeDate,
    Encoder? encoder,
  }) =>
      EncodeOptions(
        addQueryPrefix: addQueryPrefix ?? this.addQueryPrefix,
        allowDots: allowDots ?? this.allowDots,
        allowEmptyLists: allowEmptyLists ?? this.allowEmptyLists,
        listFormat: listFormat ?? this.listFormat,
        charset: charset ?? this.charset,
        charsetSentinel: charsetSentinel ?? this.charsetSentinel,
        delimiter: delimiter ?? this.delimiter,
        encode: encode ?? this.encode,
        encodeDotInKeys: encodeDotInKeys ?? this.encodeDotInKeys,
        encodeValuesOnly: encodeValuesOnly ?? this.encodeValuesOnly,
        format: format ?? this.format,
        skipNulls: skipNulls ?? this.skipNulls,
        strictNullHandling: strictNullHandling ?? this.strictNullHandling,
        commaRoundTrip: commaRoundTrip ?? this.commaRoundTrip,
        sort: sort ?? this.sort,
        filter: filter ?? this.filter,
        serializeDate: serializeDate ?? _serializeDate,
        encoder: encoder ?? _encoder,
      );

  @override
  String toString() => 'EncodeOptions(\n'
      '  addQueryPrefix: $addQueryPrefix,\n'
      '  allowDots: $allowDots,\n'
      '  allowEmptyLists: $allowEmptyLists,\n'
      '  listFormat: $listFormat,\n'
      '  charset: $charset,\n'
      '  charsetSentinel: $charsetSentinel,\n'
      '  delimiter: $delimiter,\n'
      '  encode: $encode,\n'
      '  encodeDotInKeys: $encodeDotInKeys,\n'
      '  encodeValuesOnly: $encodeValuesOnly,\n'
      '  format: $format,\n'
      '  skipNulls: $skipNulls,\n'
      '  strictNullHandling: $strictNullHandling,\n'
      '  commaRoundTrip: $commaRoundTrip,\n'
      '  sort: $sort,\n'
      '  filter: $filter,\n'
      '  serializeDate: $_serializeDate,\n'
      '  encoder: $_encoder,\n'
      ')';

  @override
  List<Object?> get props => [
        addQueryPrefix,
        allowDots,
        allowEmptyLists,
        listFormat,
        charset,
        charsetSentinel,
        delimiter,
        encode,
        encodeDotInKeys,
        encodeValuesOnly,
        format,
        skipNulls,
        strictNullHandling,
        commaRoundTrip,
        sort,
        filter,
        _serializeDate,
        _encoder,
      ];
}
