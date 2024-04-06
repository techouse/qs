import 'dart:convert' show Encoding, latin1, utf8;

import 'package:equatable/equatable.dart';
import 'package:qs_dart/src/enums/duplicates.dart';
import 'package:qs_dart/src/utils.dart';

typedef Decoder = dynamic Function(String? value, {Encoding? charset});

/// Options that configure the output of [QS.decode].
final class DecodeOptions with EquatableMixin {
  const DecodeOptions({
    bool? allowDots,
    Decoder? decoder,
    bool? decodeDotInKeys,
    this.allowEmptyLists = false,
    this.listLimit = 20,
    this.charset = utf8,
    this.charsetSentinel = false,
    this.comma = false,
    this.delimiter = '&',
    this.depth = 5,
    this.duplicates = Duplicates.combine,
    this.ignoreQueryPrefix = false,
    this.interpretNumericEntities = false,
    this.parameterLimit = 1000,
    this.parseLists = true,
    this.strictNullHandling = false,
  })  : allowDots = allowDots ?? decodeDotInKeys == true || false,
        decodeDotInKeys = decodeDotInKeys ?? true,
        _decoder = decoder,
        assert(
          charset == utf8 || charset == latin1,
          'Invalid charset',
        );

  /// Set to [true] to decode dot [Map] notation in the encoded input.
  final bool allowDots;

  /// Set to [true] to allow empty [List] values inside [Map]s in the encoded input.
  final bool allowEmptyLists;

  /// [QS] will limit specifying indices in a [List] to a maximum index of `20`.
  /// Any [List] members with an index of greater than `20` will instead be converted to a [Map] with the index as the key.
  /// This is needed to handle cases when someone sent, for example, `a[999999999]` and it will take significant time to iterate
  /// over this huge [List].
  /// This limit can be overridden by passing an [listLimit] option.
  final int listLimit;

  /// The character encoding to use when decoding the input.
  final Encoding charset;

  /// Some services add an initial `utf8=✓` value to forms so that old InternetExplorer versions are more likely to submit the
  /// form as [utf8]. Additionally, the server can check the value against wrong encodings of the checkmark character and detect
  /// that a query string or `application/x-www-form-urlencoded` body was *not* sent as [utf8], eg. if the form had an
  /// `accept-charset` parameter or the containing page had a different character set.
  ///
  /// [QS] supports this mechanism via the [charsetSentinel] option.
  /// If specified, the [utf8] parameter will be omitted from the returned [Map].
  /// It will be used to switch to [latin1]/[utf8] mode depending on how the checkmark is encoded.
  ///
  /// Important: When you specify both the [charset] option and the [charsetSentinel] option,
  /// the [charset] will be overridden when the request contains a [utf8] parameter from which the actual charset
  /// can be deduced. In that sense the [charset] will behave as the default charset rather than the authoritative
  /// charset.
  final bool charsetSentinel;

  /// Set to [true] to parse the input as a comma-separated value.
  ///
  /// Note: nested [Map]s, such as `'a={b:1},{c:d}'` are not supported.
  final bool comma;

  /// Set to [true] to decode dots in keys.
  ///
  /// Note: it implies [allowDots], so [QS.decode] will error if you set
  /// [decodeDotInKeys] to [true], and [allowDots] to [false].
  final bool decodeDotInKeys;

  /// The delimiter to use when splitting key-value pairs in the encoded input.
  /// Can be a [String] or a [RegExp].
  final Pattern delimiter;

  /// By default, when nesting [Map]s [QS] will only decode up to 5 children deep.
  /// This depth can be overridden by setting the [depth].
  /// The depth limit helps mitigate abuse when qs is used to parse user input,
  /// and it is recommended to keep it a reasonably small number.
  final int depth;

  /// For similar reasons, by default [QS] will only parse up to 1000
  /// parameters. This can be overridden by passing a [parameterLimit]
  /// option.
  final num parameterLimit;

  /// Change the duplicate key handling strategy
  final Duplicates duplicates;

  /// Set to [true] to ignore the leading question mark query prefix in the encoded input.
  final bool ignoreQueryPrefix;

  /// Set to [true] to interpret HTML numeric entities (`&#...;`) in the encoded input.
  final bool interpretNumericEntities;

  /// To disable [List] parsing entirely, set [parseLists] to [false].
  final bool parseLists;

  /// Set to true to decode values without `=` to `null`.
  final bool strictNullHandling;

  /// Set a [Decoder] to affect the decoding of the input.
  final Decoder? _decoder;

  /// Decode the input using the specified [Decoder].
  dynamic decoder(String? value, {Encoding? charset}) => _decoder is Function
      ? _decoder?.call(value, charset: charset)
      : Utils.decode(value, charset: charset);

  /// Returns a new [DecodeOptions] instance with updated values.
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
