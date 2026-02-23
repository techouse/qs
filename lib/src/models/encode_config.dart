import 'dart:convert' show Encoding;

import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart' show internal;
import 'package:qs_dart/src/enums/format.dart';
import 'package:qs_dart/src/enums/list_format.dart';
import 'package:qs_dart/src/models/encode_options.dart';

/// Immutable configuration shared across encoder traversal frames.
@internal
final class EncodeConfig with EquatableMixin {
  const EncodeConfig({
    required this.generateArrayPrefix,
    required this.commaRoundTrip,
    required this.commaCompactNulls,
    required this.allowEmptyLists,
    required this.strictNullHandling,
    required this.skipNulls,
    required this.encodeDotInKeys,
    required this.encoder,
    required this.serializeDate,
    required this.sort,
    required this.filter,
    required this.allowDots,
    required this.format,
    required this.formatter,
    required this.encodeValuesOnly,
    required this.charset,
  });

  static const _NotSet _notSet = _NotSet();

  final ListFormatGenerator generateArrayPrefix;
  final bool commaRoundTrip;
  final bool commaCompactNulls;
  final bool allowEmptyLists;
  final bool strictNullHandling;
  final bool skipNulls;
  final bool encodeDotInKeys;
  final Encoder? encoder;
  final DateSerializer? serializeDate;
  final Sorter? sort;
  final dynamic filter;
  final bool allowDots;
  final Format format;
  final Formatter formatter;
  final bool encodeValuesOnly;
  final Encoding charset;

  EncodeConfig copyWith({
    ListFormatGenerator? generateArrayPrefix,
    bool? commaRoundTrip,
    bool? commaCompactNulls,
    bool? allowEmptyLists,
    bool? strictNullHandling,
    bool? skipNulls,
    bool? encodeDotInKeys,
    Object? encoder = _notSet,
    Object? serializeDate = _notSet,
    Object? sort = _notSet,
    Object? filter = _notSet,
    bool? allowDots,
    Format? format,
    Formatter? formatter,
    bool? encodeValuesOnly,
    Encoding? charset,
  }) {
    final nextGenerateArrayPrefix =
        generateArrayPrefix ?? this.generateArrayPrefix;
    final nextCommaRoundTrip = commaRoundTrip ?? this.commaRoundTrip;
    final nextCommaCompactNulls = commaCompactNulls ?? this.commaCompactNulls;
    final nextAllowEmptyLists = allowEmptyLists ?? this.allowEmptyLists;
    final nextStrictNullHandling =
        strictNullHandling ?? this.strictNullHandling;
    final nextSkipNulls = skipNulls ?? this.skipNulls;
    final nextEncodeDotInKeys = encodeDotInKeys ?? this.encodeDotInKeys;
    final Encoder? nextEncoder =
        identical(encoder, _notSet) ? this.encoder : encoder as Encoder?;
    final DateSerializer? nextSerializeDate = identical(serializeDate, _notSet)
        ? this.serializeDate
        : serializeDate as DateSerializer?;
    final Sorter? nextSort =
        identical(sort, _notSet) ? this.sort : sort as Sorter?;
    final nextFilter = identical(filter, _notSet) ? this.filter : filter;
    final nextAllowDots = allowDots ?? this.allowDots;
    final nextFormat = format ?? this.format;
    final nextFormatter = formatter ?? this.formatter;
    final nextEncodeValuesOnly = encodeValuesOnly ?? this.encodeValuesOnly;
    final nextCharset = charset ?? this.charset;

    if (identical(nextGenerateArrayPrefix, this.generateArrayPrefix) &&
        nextCommaRoundTrip == this.commaRoundTrip &&
        nextCommaCompactNulls == this.commaCompactNulls &&
        nextAllowEmptyLists == this.allowEmptyLists &&
        nextStrictNullHandling == this.strictNullHandling &&
        nextSkipNulls == this.skipNulls &&
        nextEncodeDotInKeys == this.encodeDotInKeys &&
        identical(nextEncoder, this.encoder) &&
        identical(nextSerializeDate, this.serializeDate) &&
        identical(nextSort, this.sort) &&
        identical(nextFilter, this.filter) &&
        nextAllowDots == this.allowDots &&
        identical(nextFormat, this.format) &&
        identical(nextFormatter, this.formatter) &&
        nextEncodeValuesOnly == this.encodeValuesOnly &&
        identical(nextCharset, this.charset)) {
      return this;
    }

    return EncodeConfig(
      generateArrayPrefix: nextGenerateArrayPrefix,
      commaRoundTrip: nextCommaRoundTrip,
      commaCompactNulls: nextCommaCompactNulls,
      allowEmptyLists: nextAllowEmptyLists,
      strictNullHandling: nextStrictNullHandling,
      skipNulls: nextSkipNulls,
      encodeDotInKeys: nextEncodeDotInKeys,
      encoder: nextEncoder,
      serializeDate: nextSerializeDate,
      sort: nextSort,
      filter: nextFilter,
      allowDots: nextAllowDots,
      format: nextFormat,
      formatter: nextFormatter,
      encodeValuesOnly: nextEncodeValuesOnly,
      charset: nextCharset,
    );
  }

  EncodeConfig withEncoder(Encoder? value) => copyWith(encoder: value);

  @override
  List<Object?> get props => [
        generateArrayPrefix,
        commaRoundTrip,
        commaCompactNulls,
        allowEmptyLists,
        strictNullHandling,
        skipNulls,
        encodeDotInKeys,
        encoder,
        serializeDate,
        sort,
        filter,
        allowDots,
        format,
        formatter,
        encodeValuesOnly,
        charset,
      ];
}

/// Private compile-time sentinel for copyWith optional arguments.
final class _NotSet {
  const _NotSet();
}
