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

/// Options that configure the output of [QS.encode].
final class EncodeOptions with EquatableMixin {
  const EncodeOptions({
    Encoder? encoder,
    DateSerializer? serializeDate,
    ListFormat? listFormat,
    @Deprecated('Use listFormat instead') bool? indices,
    bool? allowDots,
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
          filter == null || filter is Function || filter is Iterable,
          'Invalid filter',
        );

  /// Set to `true` to add a question mark `?` prefix to the encoded output.
  final bool addQueryPrefix;

  /// Set to `true` to use dot [Map] notation in the encoded output.
  final bool allowDots;

  /// Set to `true` to allow empty [List]s in the encoded output.
  final bool allowEmptyLists;

  /// The [List] encoding format to use.
  final ListFormat listFormat;

  /// The character encoding to use.
  final Encoding charset;

  /// Set to `true` to announce the character by including an `utf8=✓` parameter
  /// with the proper encoding of the checkmark, similar to what Ruby on Rails
  /// and others do when submitting forms.
  final bool charsetSentinel;

  /// The delimiter to use when joining key-value pairs in the encoded output.
  final String delimiter;

  /// Set to `false` to disable encoding.
  final bool encode;

  /// Encode [Map] keys using dot notation by setting [encodeDotInKeys] to `true`:
  ///
  /// Caveat: When [encodeValuesOnly] is `true` as well as [encodeDotInKeys],
  /// only dots in keys and nothing else will be encoded.
  final bool encodeDotInKeys;

  /// Encoding can be disabled for keys by setting the [encodeValuesOnly] to `true`
  final bool encodeValuesOnly;

  /// The encoding format to use.
  /// The default [format] is [Format.rfc3986] which encodes `' '` to `%20`
  /// which is backward compatible.
  /// You can also set [format] to [Format.rfc1738] which encodes `' '` to `+`.
  final Format format;

  /// Set to `true` to completely skip encoding keys with `null` values
  final bool skipNulls;

  /// Set to `true` to distinguish between `null` values and empty [String]s.
  /// This way the encoded string `null` values will have no `=` sign.
  final bool strictNullHandling;

  /// When [listFormat] is set to [ListFormat.comma], you can also set
  /// [commaRoundTrip] option to `true` or `false`, to append `[]` on
  /// single-item [List]s, so that they can round trip through a parse.
  final bool? commaRoundTrip;

  /// Set a [Sorter] to affect the order of parameter keys.
  final Sorter? sort;

  /// Use the [filter] option to restrict which keys will be included in the encoded output.
  /// If you pass a [Function], it will be called for each key to obtain the replacement value.
  /// If you pass a [List], it will be used to select properties and [List] indices to be encoded.
  final dynamic filter;

  /// If you only want to override the serialization of [DateTime] objects,
  /// you can provide a custom [DateSerializer].
  final DateSerializer? _serializeDate;

  /// Set an [Encoder] to affect the encoding of values.
  /// Note: the [encoder] option does not apply if [encode] is `false`
  final Encoder? _encoder;

  /// Convenience getter for accessing the [format]'s [Format.formatter]
  Formatter get formatter => format.formatter;

  /// Encodes a [value] to a [String].
  ///
  /// Uses the provided [encoder] if available, otherwise uses [Utils.encode].
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

  /// Serializes a [DateTime] instance to a [String].
  ///
  /// Uses the provided [serializeDate] function if available, otherwise uses
  /// [DateTime.toIso8601String].
  String serializeDate(DateTime date) =>
      _serializeDate?.call(date) ?? date.toIso8601String();

  /// Returns a new [EncodeOptions] instance with updated values.
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
