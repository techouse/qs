// ignore_for_file: deprecated_member_use_from_same_package
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
///   [allowDots] is implied and will be treated as `true` unless you explicitly
///   set `allowDots: false` — which is an invalid combination and will throw
///   when validated/used.
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
typedef Decoder = dynamic Function(
  String? value, {
  Encoding? charset,
  DecodeKind? kind,
});

/// Back‑compat adapter for `(value, charset) -> Any?` decoders.
@Deprecated(
  'Use Decoder; wrap your two‑arg lambda: '
  'Decoder((value, {charset, kind}) => legacy(value, charset: charset))',
)
typedef LegacyDecoder = dynamic Function(String? value, {Encoding? charset});

/// Options that configure the output of [QS.decode].
///
/// Invariants are asserted in debug builds and validated at runtime via
/// [validate] (used by decode entry points).
final class DecodeOptions with EquatableMixin {
  const DecodeOptions({
    bool? allowDots,
    Decoder? decoder,
    @Deprecated('Use Decoder instead; see DecodeOptions.decoder')
    LegacyDecoder? legacyDecoder,
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
        _legacyDecoder = legacyDecoder,
        assert(
          charset == utf8 || charset == latin1,
          'Invalid charset',
        ),
        assert(
          !(decodeDotInKeys ?? false) ||
              (allowDots ?? (decodeDotInKeys ?? false)),
          'decodeDotInKeys requires allowDots to be true',
        ),
        assert(
          parameterLimit > 0,
          'Parameter limit must be a positive number.',
        );

  /// When `true`, decode dot notation in keys: `a.b=c` → `{a: {b: "c"}}`.
  ///
  /// If you set [decodeDotInKeys] to `true` and do not pass [allowDots], this
  /// flag defaults to `true`. Passing `allowDots: false` while
  /// `decodeDotInKeys` is `true` is invalid and will throw when validated/used.
  final bool allowDots;

  /// When `true`, allow empty list values to be produced from inputs like
  /// `a[]=` without coercing or discarding them.
  final bool allowEmptyLists;

  /// Maximum list size/index that will be honored when decoding bracket lists.
  ///
  /// Keys like `a[9999999]` can cause excessively large sparse lists; above
  /// this limit, indices are treated as string map keys instead. The same
  /// limit also applies to empty-bracket pushes (`a[]`) and duplicate combines:
  /// once growth exceeds the limit, the list is converted to a map with string
  /// indices to preserve values (matching Node `qs` arrayLimit semantics).
  ///
  /// **Negative values:** passing a negative `listLimit` (e.g. `-1`) disables
  /// numeric‑index parsing entirely — any bracketed number like `a[0]` or
  /// `a[123]` is treated as a **string map key**, not as a list index (i.e.
  /// lists are effectively disabled).
  ///
  /// When [throwOnLimitExceeded] is `true` *and* [listLimit] is negative, any
  /// operation that would grow a list (e.g. `a[]` pushes, comma‑separated values
  /// when [comma] is `true`, or nested pushes) will throw a [RangeError].
  final int listLimit;

  /// Character encoding used to decode percent‑encoded bytes in the input.
  /// Only [utf8] and [latin1] are supported.
  final Encoding charset;

  /// Enable opt‑in charset detection via a `utf8=✓` sentinel parameter.
  ///
  /// If present anywhere in the input, the *first occurrence* will:
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
  /// This explicitly opts into dot‑notation handling and **implies** [allowDots].
  /// Passing `decodeDotInKeys: true` while forcing `allowDots: false` is an
  /// invalid combination and will throw when validated/used.
  ///
  /// Note: inside bracket segments (e.g., `a[%2E]`), percent‑decoding naturally
  /// yields `"."`. Whether a `.` causes additional splitting is a parser concern
  /// governed by [allowDots] at the *top level*; this flag does not suppress the
  /// literal dot produced by percent‑decoding inside brackets.
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

  /// When `true`, exceeding limits throws instead of applying a soft cap.
  ///
  /// This applies to:
  ///  • parameter count over [parameterLimit],
  ///  • list growth beyond [listLimit], and
  ///  • (in combination with [strictDepth]) exceeding [depth].
  ///
  /// **Note:** even when [listLimit] is **negative** (numeric‑index parsing
  /// disabled), any list‑growth path (empty‑bracket pushes like `a[]`, comma
  /// splits when [comma] is `true`, or nested pushes) will immediately throw a
  /// [RangeError].
  final bool throwOnLimitExceeded;

  /// Optional custom scalar decoder for a single token.
  /// If not provided, falls back to [Utils.decode].
  final Decoder? _decoder;

  /// Optional legacy decoder that takes only (value, {charset}).
  final LegacyDecoder? _legacyDecoder;

  /// Unified scalar decode with key/value context.
  ///
  /// Uses a provided custom [Decoder] when set; otherwise falls back to [Utils.decode].
  /// For backward compatibility, a [LegacyDecoder] can be supplied and is honored
  /// when no primary [Decoder] is provided. The [kind] will be [DecodeKind.key] for
  /// keys (and key segments) and [DecodeKind.value] for values. The default implementation
  /// does not vary decoding based on [kind]. If your decoder returns `null`, that `null`
  /// is preserved — no fallback decoding is applied.
  dynamic decode(
    String? value, {
    Encoding? charset,
    DecodeKind kind = DecodeKind.value,
  }) {
    // Validate here to cover direct decodeKey/decodeValue usage; cached via Expando.
    validate();
    if (_decoder != null) {
      return _decoder!(value, charset: charset, kind: kind);
    }
    if (_legacyDecoder != null) {
      return _legacyDecoder!(value, charset: charset);
    }
    return Utils.decode(value, charset: charset ?? this.charset);
  }

  /// Convenience: decode a key and coerce the result to String (or null).
  String? decodeKey(
    String? value, {
    Encoding? charset,
  }) =>
      decode(
        value,
        charset: charset ?? this.charset,
        kind: DecodeKind.key,
      )?.toString();

  /// Convenience: decode a value token.
  dynamic decodeValue(
    String? value, {
    Encoding? charset,
  }) =>
      decode(
        value,
        charset: charset ?? this.charset,
        kind: DecodeKind.value,
      );

  /// **Deprecated**: use [decode]. This wrapper will be removed in a future release.
  @Deprecated('Use decode(value, charset: ..., kind: ...) instead')
  dynamic decoder(
    String? value, {
    Encoding? charset,
    DecodeKind kind = DecodeKind.value,
  }) =>
      decode(value, charset: charset, kind: kind);

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
    bool? throwOnLimitExceeded,
    Decoder? decoder,
    LegacyDecoder? legacyDecoder,
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
        throwOnLimitExceeded: throwOnLimitExceeded ?? this.throwOnLimitExceeded,
        decoder: decoder ?? _decoder,
        legacyDecoder: legacyDecoder ?? _legacyDecoder,
      );

  /// Validates option invariants (used by [QS.decode] and direct decoder calls).
  void validate() {
    if (_validated[this] == true) return;

    final Encoding currentCharset = charset;
    if (currentCharset != utf8 && currentCharset != latin1) {
      throw ArgumentError.value(currentCharset, 'charset', 'Invalid charset');
    }

    if (decodeDotInKeys && !allowDots) {
      throw ArgumentError.value(
        decodeDotInKeys,
        'decodeDotInKeys',
        'Invalid combination: decodeDotInKeys=$decodeDotInKeys requires '
            'allowDots=true (currently allowDots=$allowDots).',
      );
    }

    final num limit = parameterLimit;
    if (limit.isNaN || limit <= 0) {
      throw ArgumentError.value(
        limit,
        'parameterLimit',
        'Parameter limit must be a positive number.',
      );
    }

    _validated[this] = true;
  }

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
      '  throwOnLimitExceeded: $throwOnLimitExceeded,\n'
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
        throwOnLimitExceeded,
        _decoder,
        _legacyDecoder,
      ];

  // Expando does not keep keys alive; cached flags vanish when the options
  // instance is GC'd, so this avoids repeat validation without leaking.
  static final Expando<bool> _validated =
      Expando<bool>('qsDecodeOptionsValidated');
}
