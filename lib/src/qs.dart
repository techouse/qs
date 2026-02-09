import 'dart:convert' show latin1, utf8, Encoding;
import 'dart:typed_data' show ByteBuffer;

import 'package:qs_dart/src/enums/duplicates.dart';
import 'package:qs_dart/src/enums/format.dart';
import 'package:qs_dart/src/enums/list_format.dart';
import 'package:qs_dart/src/enums/sentinel.dart';
import 'package:qs_dart/src/extensions/extensions.dart';
import 'package:qs_dart/src/models/decode_options.dart';
import 'package:qs_dart/src/models/encode_frame.dart';
import 'package:qs_dart/src/models/encode_options.dart';
import 'package:qs_dart/src/models/undefined.dart';
import 'package:qs_dart/src/utils.dart';
import 'package:weak_map/weak_map.dart';

// Re-export for public API: consumers can `import 'package:qs_dart/qs.dart'` and access DecodeKind
export 'package:qs_dart/src/enums/decode_kind.dart';

part 'extensions/decode.dart';
part 'extensions/encode.dart';

/// # QS (Dart)
///
/// Reference-style query‑string codec that mirrors the semantics of the
/// popular Node `qs` library. Provides two entry points: [decode] and
/// [encode].
///
/// Highlights
/// - RFC 3986 / RFC 1738 output formatting via [Format].
/// - Multiple list notations via [ListFormat].
/// - Duplicate handling on decode via [Duplicates].
/// - Pluggable encoder/decoder, custom key sorting and filtering hooks.
/// - Optional query prefix and charset sentinel emission.
final class QS {
  /// Decode a query string or a pre-parsed map into a structured map.
  ///
  /// - `input` may be:
  ///   * a query [String] (e.g. `"a=1&b[c]=2"`), or
  ///   * a pre-tokenized `Map<String, dynamic>` produced by a custom tokenizer.
  /// - When `input` is `null` or the empty string, `{}` is returned.
  /// - Throws [ArgumentError] if `input` is neither a `String` nor a
  ///   `Map<String, dynamic>`.
  ///
  /// See [DecodeOptions] for delimiter, nesting depth, numeric-entity handling,
  /// duplicates policy, and other knobs.
  static Map<String, dynamic> decode(dynamic input, [DecodeOptions? options]) {
    options ??= const DecodeOptions();
    // Default to the library's safe, Node-`qs` compatible settings.
    options.validate();

    // Fail fast on unsupported input shapes to avoid ambiguous behavior.
    if (!(input is String? || input is Map<String, dynamic>?)) {
      throw ArgumentError.value(
        input,
        'input',
        'The input must be a String or a Map<String, dynamic>',
      );
    }

    // Normalize `null` / empty string to an empty map.
    if (input?.isEmpty ?? true) {
      return <String, dynamic>{};
    }

    final Map<String, dynamic>? tempObj = input is String
        ? _$Decode._parseQueryStringValues(input, options)
        : input;

    Map<String, dynamic> obj = {};

    // Merge each parsed key into the accumulator using the same rules as Node `qs`.
    // Iterate over the keys and setup the new object
    if (tempObj?.isNotEmpty ?? false) {
      for (final MapEntry<String, dynamic> entry in tempObj!.entries) {
        final parsed = _$Decode._parseKeys(
            entry.key, entry.value, options, input is String);

        if (obj.isEmpty && parsed is Map<String, dynamic>) {
          obj = parsed; // direct assignment – no merge needed
        } else {
          obj = Utils.merge(obj, parsed, options) as Map<String, dynamic>;
        }
      }
    }

    // Drop undefined/empty leaves to match the reference behavior.
    return Utils.compact(obj);
  }

  /// Encode a map/iterable into a query string.
  ///
  /// - `object` may be:
  ///   * a `Map<String, dynamic>` (encoded as key/value pairs),
  ///   * an `Iterable` (encoded as an index‑keyed map: `0`, `1`, …), or
  ///   * `null` (returns the empty string).
  /// - If [EncodeOptions.filter] is a function, it is invoked like the
  ///   Node `qs` filter; if it's an iterable, it specifies the exact
  ///   key order/selection.
  /// - Keys are optionally sorted via [EncodeOptions.sort].
  /// - [EncodeOptions.addQueryPrefix] and [EncodeOptions.charsetSentinel]
  ///   control the leading `?` and sentinel token emission.
  ///
  /// See [EncodeOptions] for details about list formats, output format, and hooks.
  static String encode(Object? object, [EncodeOptions? options]) {
    options ??= const EncodeOptions();
    // Use default encoding settings unless overridden by the caller.
    options.validate();

    // Normalize supported inputs into a mutable map we can traverse.
    Map<String, dynamic> obj = switch (object) {
      Map<String, dynamic> map => {...map},
      Iterable iterable => Utils.createIndexMap(iterable),
      _ => <String, dynamic>{},
    };

    final List<String> keys = [];

    // Nothing to encode.
    if (obj.isEmpty) {
      return '';
    }

    List? objKeys;

    // Support the two `qs` filter forms: function and whitelist iterable.
    if (options.filter is Function) {
      obj = options.filter?.call('', obj);
    } else if (options.filter is Iterable) {
      objKeys = List.of(options.filter);
    }

    objKeys ??= obj.keys.toList();

    // Deterministic key order if a sorter is provided.
    if (options.sort is Function) {
      objKeys.sort(options.sort);
    }

    // Internal side-channel used by the encoder to detect cycles and share state.
    final WeakMap sideChannel = WeakMap();
    for (int i = 0; i < objKeys.length; i++) {
      final key = objKeys[i];

      if (key is! String || (obj[key] == null && options.skipNulls)) {
        continue;
      }

      final ListFormatGenerator gen = options.listFormat.generator;
      final bool crt = identical(gen, ListFormat.comma.generator) &&
          options.commaRoundTrip == true;
      final bool ccn = identical(gen, ListFormat.comma.generator) &&
          options.commaCompactNulls == true;

      final encoded = _$Encode._encode(
        obj[key],
        undefined: !obj.containsKey(key),
        prefix: key,
        generateArrayPrefix: gen,
        commaRoundTrip: crt,
        commaCompactNulls: ccn,
        allowEmptyLists: options.allowEmptyLists,
        strictNullHandling: options.strictNullHandling,
        skipNulls: options.skipNulls,
        encodeDotInKeys: options.encodeDotInKeys,
        encoder: options.encode ? options.encoder : null,
        serializeDate: options.serializeDate,
        filter: options.filter,
        sort: options.sort,
        allowDots: options.allowDots,
        format: options.format,
        formatter: options.formatter,
        encodeValuesOnly: options.encodeValuesOnly,
        charset: options.charset,
        addQueryPrefix: options.addQueryPrefix,
        sideChannel: sideChannel,
      );

      if (encoded is Iterable) {
        for (final e in encoded) {
          if (e != null) keys.add(e as String);
        }
      } else if (encoded != null) {
        keys.add(encoded as String);
      }
    }

    // Join all encoded segments with the chosen delimiter.
    final String joined = keys.join(options.delimiter);
    final StringBuffer out = StringBuffer();

    if (options.addQueryPrefix) {
      out.write('?');
    }

    // Optionally emit the charset sentinel (mirrors Node `qs`).
    if (options.charsetSentinel) {
      out.write(switch (options.charset) {
        /// encodeURIComponent('&#10003;')
        /// the "numeric entity" representation of a checkmark
        latin1 => '${Sentinel.iso}&',

        /// encodeURIComponent('✓')
        utf8 => '${Sentinel.charset}&',
        _ => '',
      });
    }

    // Append the payload after any optional prefix/sentinel.
    if (joined.isNotEmpty) {
      out.write(joined);
    }

    return out.toString();
  }
}
