import 'dart:convert' show Encoding, latin1, utf8;

import 'package:equatable/equatable.dart';
import 'package:qs_dart/src/enums/decode_kind.dart';
import 'package:qs_dart/src/enums/duplicates.dart';
import 'package:qs_dart/src/utils.dart';

/// Decoding options for [QS.decode].
///
/// This mirrors the behavior of the reference `qs` library and provides a few
/// guard rails against untrusted input (parameter count, nesting depth, list
/// index limits). The defaults aim to be safe and predictable while matching
/// the semantics used across the ports in this repository.
///
/// Highlights
/// - **Dot notation**: set [allowDots] to treat `a.b=c` like `{a: {b: "c"}}`.
///   If you *explicitly* request dot decoding in keys via [decodeDotInKeys],
///   [allowDots] is implied and will be treated as `true`.
/// - **Charset handling**: [charset] selects UTF‑8 or Latin‑1 decoding. When
///   [charsetSentinel] is `true`, a leading `utf8=✓` token (in either UTF‑8 or
///   Latin‑1 form) can override [charset] as a compatibility escape hatch.
/// - **Limits**: [parameterLimit], [depth], and [listLimit] are DoS guards.
///   If you want hard failures instead of soft limiting, enable
///   [throwOnLimitExceeded] and/or [strictDepth].
/// - **Duplicates**: use [duplicates] to pick a strategy when the same key is
///   present multiple times in the input.
///
/// See also: the options types in other ports for parity, and the individual
/// doc comments below for precise semantics.

/// Preferred signature for a custom scalar decoder used by [DecodeOptions].
///
/// Implementations may choose to ignore [charset] or [kind], but both are
/// provided to enable key-aware decoding when desired.
typedef Decoder = dynamic Function(String? value,
    {Encoding? charset, DecodeKind? kind});

/// Back-compat: single-argument decoder (value only).
typedef DecoderV1 = dynamic Function(String? value);

/// Back-compat: decoder with optional [charset] only.
typedef DecoderV2 = dynamic Function(String? value, {Encoding? charset});

/// Full-featured: decoder with [charset] and key/value [kind].
typedef DecoderV3 = dynamic Function(String? value,
    {Encoding? charset, DecodeKind? kind});

/// Decoder that accepts only [kind] (no [charset]).
typedef DecoderV4 = dynamic Function(String? value, {DecodeKind? kind});

/// Options that configure the output of [QS.decode].
final class DecodeOptions with EquatableMixin {
  const DecodeOptions({
    bool? allowDots,
    Object? decoder,
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
    this.strictDepth = false,
    this.strictNullHandling = false,
    this.throwOnLimitExceeded = false,
  })  : allowDots = allowDots ?? (decodeDotInKeys ?? false),
        decodeDotInKeys = decodeDotInKeys ?? false,
        _decoder = decoder,
        assert(
          charset == utf8 || charset == latin1,
          'Invalid charset',
        );

  /// When `true`, decode dot notation in keys: `a.b=c` → `{a: {b: "c"}}`.
  ///
  /// If you set [decodeDotInKeys] to `true`, this flag is implied and will be
  /// treated as enabled even if you pass `allowDots: false`.
  final bool allowDots;

  /// When `true`, allow empty list values to be produced from inputs like
  /// `a[]=` without coercing or discarding them.
  final bool allowEmptyLists;

  /// Maximum list index that will be honored when decoding bracket indices.
  ///
  /// Keys like `a[9999999]` can cause excessively large sparse lists; above
  /// this limit, indices are treated as string map keys instead.
  final int listLimit;

  /// Character encoding used to decode percent‑encoded bytes in the input.
  /// Only [utf8] and [latin1] are supported.
  final Encoding charset;

  /// Enable opt‑in charset detection via the `utf8=✓` sentinel.
  ///
  /// If present at the start of the input, the sentinel will:
  ///  * be omitted from the result map, and
  ///  * override [charset] based on how the checkmark was encoded (UTF‑8 or
  ///    Latin‑1).
  ///
  /// If both [charset] and [charsetSentinel] are provided, the sentinel wins
  /// when found; otherwise [charset] is used as the default.
  final bool charsetSentinel;

  /// Parse the entire input as a comma‑separated value instead of key/value
  /// pairs. Nested maps (e.g., `a={b:1},{c:d}`) are **not** supported in this
  /// mode.
  final bool comma;

  /// Decode dots that appear in *keys* (e.g., `a.b=c`).
  ///
  /// This explicitly opts into dot‑notation handling and implies [allowDots].
  /// Setting [decodeDotInKeys] to `true` while forcing [allowDots] to `false`
  /// is invalid and will cause an error in [QS.decode].
  final bool decodeDotInKeys;

  /// Delimiter used to split key/value pairs. May be a [String] (e.g., `"&"`)
  /// or a [RegExp] for pattern‑based splitting.
  final Pattern delimiter;

  /// Maximum nesting depth when constructing maps from bracket notation.
  /// The default (5) is a protective limit against abuse; raise it only when
  /// you control the inputs.
  final int depth;

  /// Maximum number of parameters to parse before applying limits.
  /// Defaults to 1000 to guard against excessively long inputs.
  final num parameterLimit;

  /// Strategy to apply when the same key appears multiple times.
  final Duplicates duplicates;

  /// Ignore a leading `?` query prefix if present.
  final bool ignoreQueryPrefix;

  /// Interpret HTML numeric entities like `&#...;` in tokens before decoding.
  final bool interpretNumericEntities;

  /// Disable list parsing entirely when `false` (treat bracket indices as
  /// string keys).
  final bool parseLists;

  /// When `true`, exceeding [depth] results in a thrown error instead of a
  /// soft limit.
  final bool strictDepth;

  /// When `true`, tokens without an `=` (e.g., `?flag`) decode to `null`
  /// rather than `""`.
  final bool strictNullHandling;

  /// When `true`, exceeding *any* limit (like [parameterLimit] or [listLimit])
  /// throws instead of applying a soft cap.
  final bool throwOnLimitExceeded;

  /// Optional custom scalar decoder for a single token.
  /// If not provided, falls back to [Utils.decode].
  final Object? _decoder;

  /// Decode a single scalar using either the custom decoder or the default
  /// implementation in [Utils.decode]. The [kind] indicates whether the token
  /// is a key (or key segment) or a value.
  dynamic decoder(String? value,
      {Encoding? charset, DecodeKind kind = DecodeKind.value}) {
    final d = _decoder;
    if (d == null) {
      return Utils.decode(value, charset: charset);
    }

    // Prefer strongly-typed variants first
    if (d is DecoderV3) {
      return d(value, charset: charset, kind: kind);
    }
    if (d is DecoderV2) {
      return d(value, charset: charset);
    }
    if (d is DecoderV4) {
      return d(value, kind: kind);
    }
    if (d is DecoderV1) {
      return d(value);
    }

    // Dynamic callable or class with `call` method
    try {
      // Try full shape (value, {charset, kind})
      return (d as dynamic)(value, charset: charset, kind: kind);
    } on NoSuchMethodError catch (_) {
      // fall through
    } on TypeError catch (_) {
      // fall through
    }
    try {
      // Try (value, {charset})
      return (d as dynamic)(value, charset: charset);
    } on NoSuchMethodError catch (_) {
      // fall through
    } on TypeError catch (_) {
      // fall through
    }
    try {
      // Try (value, {kind})
      return (d as dynamic)(value, kind: kind);
    } on NoSuchMethodError catch (_) {
      // fall through
    } on TypeError catch (_) {
      // fall through
    }
    try {
      // Try (value)
      return (d as dynamic)(value);
    } on NoSuchMethodError catch (_) {
      // Fallback to default
      return Utils.decode(value, charset: charset);
    } on TypeError catch (_) {
      // Fallback to default
      return Utils.decode(value, charset: charset);
    }
  }

  /// Return a new [DecodeOptions] with the provided overrides.
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
    bool? strictDepth,
    Object? decoder,
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
        strictDepth: strictDepth ?? this.strictDepth,
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
      '  strictDepth: $strictDepth,\n'
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
        strictDepth,
        strictNullHandling,
        _decoder,
      ];
}
