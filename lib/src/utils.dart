// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:collection' show SplayTreeMap, HashSet;
import 'dart:convert' show latin1, utf8, Encoding;
import 'dart:typed_data' show ByteBuffer;

import 'package:meta/meta.dart' show internal, visibleForTesting;
import 'package:qs_dart/src/enums/format.dart';
import 'package:qs_dart/src/extensions/extensions.dart';
import 'package:qs_dart/src/models/decode_options.dart';
import 'package:qs_dart/src/models/undefined.dart';

part 'constants/hex_table.dart';

/// Internal utilities and helpers used by the library.
///
/// This class gathers low-level building blocks used by the public
/// encoder/decoder. A few important notes about behavior:
///
/// - Unless explicitly stated, functions here are **pure** (no side effects).
///   The notable exception is [compact], which **mutates** the provided
///   map/list graph in place to remove `Undefined` markers.
/// - [encode] and [decode] here operate on **scalar tokens** only; traversal
///   and joining of keys/values is handled at a higher level.
/// - Several functions accept/return `dynamic` for performance and to match
///   the permissive behavior of the original Node.js `qs` implementation.
@internal
final class Utils {
  static const int _segmentLimit = 1024;

  /// Tracks array-overflow objects (from listLimit) without mutating user data.
  static final Expando<int> _overflowIndex = Expando<int>('qsOverflowIndex');

  /// Marks a map as an overflow container with the given max index.
  @visibleForTesting
  static Map<String, dynamic> markOverflow(
    Map<String, dynamic> obj,
    int maxIndex,
  ) {
    _overflowIndex[obj] = maxIndex;
    return obj;
  }

  /// Returns `true` if the given object is marked as an overflow container.
  @internal
  static bool isOverflow(dynamic obj) =>
      obj is Map && _overflowIndex[obj] != null;

  static int _getOverflowIndex(Map obj) => _overflowIndex[obj] ?? -1;

  static void _setOverflowIndex(Map obj, int maxIndex) {
    _overflowIndex[obj] = maxIndex;
  }

  static int _updateOverflowMax(int current, String key) {
    final int? parsed = int.tryParse(key);
    if (parsed == null || parsed < 0) {
      return current;
    }
    return parsed > current ? parsed : current;
  }

  /// Deeply merges `source` into `target` while preserving insertion order
  /// and list semantics used by `qs`.
  ///
  /// Rules of thumb:
  /// - If `source == null`, returns `target` unchanged.
  /// - When **both** sides are maps, keys are stringified and values are merged
  ///   recursively.
  /// - When `target` is an **Iterable** and `source` is **not** a map:
  ///   - If either side is a list/set of maps, items are merged **by index**.
  ///   - Otherwise values are **appended** (keeping iteration order).
  ///   - Presence of [Undefined] acts like a hole; if `options.parseLists == false`
  ///     and any `Undefined` remain after merging, the result is normalized to
  ///     a map with string indices (`"0"`, `"1"`, …) to force object-shape.
  /// - When `target` is a **map** and `source` is an **Iterable**, the iterable
  ///   is promoted to an object using string indices and merged in.
  /// - If neither side is a map/iterable, the two values are wrapped into a
  ///   two-element list `[target, source]`.
  ///
  /// Ordering guarantees:
  /// - Uses `SplayTreeMap` for temporary index maps to keep keys predictable.
  ///
  /// This mirrors the behavior of the original Node.js `qs` merge routine,
  /// including treatment of `Undefined` sentinels.
  static dynamic merge(
    dynamic target,
    dynamic source, [
    DecodeOptions? options = const DecodeOptions(),
  ]) {
    if (source == null) {
      return target;
    }

    if (source is! Map) {
      if (target is Iterable) {
        if (target.any((el) => el is Undefined)) {
          // use a SplayTreeMap to keep the keys in order
          final SplayTreeMap<int, dynamic> target_ = _toIndexedTreeMap(target);

          if (source is Iterable) {
            for (final (int i, dynamic item) in source.indexed) {
              if (item is! Undefined) {
                target_[i] = item;
              }
            }
          } else {
            target_[target_.length] = source;
          }

          target = options?.parseLists == false &&
                  target_.values.any((el) => el is Undefined)
              ? SplayTreeMap.from({
                  for (final MapEntry<int, dynamic> entry in target_.entries)
                    if (entry.value is! Undefined) entry.key: entry.value,
                })
              : target is Set
                  ? target_.values.toSet()
                  : target_.values.toList();
        } else {
          if (source is Iterable) {
            // check if source is a list of maps and target is a list of maps
            if (target.every((el) => el is Map || el is Undefined) &&
                source.every((el) => el is Map || el is Undefined)) {
              // loop through the target list and merge the maps
              // then loop through the source list and add any new maps
              final SplayTreeMap<int, dynamic> target_ =
                  _toIndexedTreeMap(target);
              for (final (int i, dynamic item) in source.indexed) {
                target_.update(
                  i,
                  (value) => merge(value, item, options),
                  ifAbsent: () => item,
                );
              }
              if (target is Set) {
                target = target_.values.toSet();
              } else {
                target = target_.values.toList();
              }
            } else {
              if (target is Set) {
                target = Set.of(target)
                  ..addAll(source.whereNotType<Undefined>());
              } else {
                target = List.of(target)
                  ..addAll(source.whereNotType<Undefined>());
              }
            }
          } else if (source != null) {
            if (target is List) {
              target.add(source);
            } else if (target is Set) {
              target.add(source);
            } else {
              target = [target, source];
            }
          }
        }
      } else if (target is Map) {
        if (isOverflow(target)) {
          final int newIndex = _getOverflowIndex(target) + 1;
          target[newIndex.toString()] = source;
          _setOverflowIndex(target, newIndex);
          return target;
        }
        if (source is Iterable) {
          target = <String, dynamic>{
            for (final MapEntry entry in target.entries)
              entry.key.toString(): entry.value,
            for (final (int i, dynamic item) in source.indexed)
              if (item is! Undefined) i.toString(): item
          };
        }
      } else if (source != null) {
        if (target is! Iterable && source is Iterable) {
          return [target, ...source.whereNotType<Undefined>()];
        }
        return [target, source];
      }

      return target;
    }

    if (target == null || target is! Map) {
      if (target is Iterable) {
        return Map<String, dynamic>.of({
          for (final (int i, dynamic item) in target.indexed)
            if (item is! Undefined) i.toString(): item,
          ...source,
        });
      }

      if (isOverflow(source)) {
        final int sourceMax = _getOverflowIndex(source);
        final Map<String, dynamic> result = {
          if (target != null) '0': target,
        };
        for (final MapEntry entry in source.entries) {
          final String key = entry.key.toString();
          final int? oldIndex = int.tryParse(key);
          if (oldIndex == null) {
            result[key] = entry.value;
          } else {
            result[(oldIndex + 1).toString()] = entry.value;
          }
        }
        return markOverflow(result, sourceMax + 1);
      }

      return [
        if (target is Iterable)
          ...target.whereNotType<Undefined>()
        else if (target != null)
          target,
        if (source is Iterable)
          ...(source as Iterable).whereNotType<Undefined>()
        else
          source,
      ];
    }

    final bool targetOverflow = isOverflow(target);
    int? overflowMax = targetOverflow ? _getOverflowIndex(target) : null;

    Map<String, dynamic> mergeTarget = target is Iterable && source is! Iterable
        ? {
            for (final (int i, dynamic item) in (target as Iterable).indexed)
              if (item is! Undefined) i.toString(): item
          }
        : {
            for (final MapEntry entry in target.entries)
              entry.key.toString(): entry.value
          };

    for (final MapEntry entry in source.entries) {
      if (overflowMax != null) {
        overflowMax = _updateOverflowMax(overflowMax, entry.key.toString());
      }
      mergeTarget.update(
        entry.key.toString(),
        (value) => merge(
          value,
          entry.value,
          options,
        ),
        ifAbsent: () => entry.value,
      );
    }
    if (overflowMax != null) {
      markOverflow(mergeTarget, overflowMax);
    }
    return mergeTarget;
  }

  /// Converts an iterable to a zero-indexed [SplayTreeMap].
  static SplayTreeMap<int, dynamic> _toIndexedTreeMap(Iterable iterable) {
    final SplayTreeMap<int, dynamic> map = SplayTreeMap<int, dynamic>();
    int i = 0;
    for (final v in iterable) {
      map[i++] = v;
    }
    return map;
  }

  /// Dart representation of JavaScript’s deprecated `escape` function.
  ///
  /// See MDN: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/escape
  ///
  /// - Kept only for RFC1738/latin1 compatibility paths.
  /// - Prefer `Uri.encodeComponent`; this helper is used internally when
  ///   `charset == latin1` to mirror legacy behavior.
  @internal
  @visibleForTesting
  @Deprecated('Use Uri.encodeComponent instead')
  static String escape(String str, {Format? format = Format.rfc3986}) {
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < str.length; ++i) {
      final int c = str.codeUnitAt(i);

      /// These 69 characters are safe for escaping
      /// ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@*_+-./
      if ((c >= 0x30 && c <= 0x39) || // 0-9
          (c >= 0x41 && c <= 0x5A) || // A-Z
          (c >= 0x61 && c <= 0x7A) || // a-z
          c == 0x40 || // @
          c == 0x2A || // *
          c == 0x5F || // _
          c == 0x2D || // -
          c == 0x2B || // +
          c == 0x2E || // .
          c == 0x2F || // /
          (format == Format.rfc1738 && (c == 0x28 || c == 0x29))) {
        buffer.writeCharCode(c);
        continue;
      }

      if (c < 256) {
        buffer.write(hexTable[c]);
        continue;
      }

      buffer.writeAll(
        [
          '%u',
          c.toRadixString(16).padLeft(4, '0').toUpperCase(),
        ],
      );
    }

    return buffer.toString();
  }

  /// Dart representation of JavaScript’s deprecated `unescape` function.
  ///
  /// See MDN: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/unescape
  ///
  /// Used only for latin1 compatibility in [decode]. Prefer
  /// `Uri.decodeComponent` for UTF‑8.
  @internal
  @visibleForTesting
  @Deprecated('Use Uri.decodeComponent instead')
  static String unescape(String str) {
    if (!str.contains('%')) return str;
    final StringBuffer buffer = StringBuffer();
    int i = 0;

    while (i < str.length) {
      final int c = str.codeUnitAt(i);

      if (c == 0x25) {
        // '%'
        // Ensure there's at least one character after '%'
        if (i + 1 < str.length) {
          if (str[i + 1] == 'u') {
            // Check that there are at least 6 characters for "%uXXXX"
            if (i + 6 <= str.length) {
              try {
                final int charCode =
                    int.parse(str.substring(i + 2, i + 6), radix: 16);
                buffer.writeCharCode(charCode);
                i += 6;
                continue;
              } on FormatException {
                // Not a valid %u escape: treat '%' as literal.
                buffer.writeCharCode(0x25);
                i++;
                continue;
              }
            } else {
              // Not enough characters for a valid %u escape: treat '%' as literal.
              buffer.writeCharCode(0x25);
              i++;
              continue;
            }
          } else {
            // For %XX escape: check that there are at least 3 characters.
            if (i + 3 <= str.length) {
              try {
                final int charCode =
                    int.parse(str.substring(i + 1, i + 3), radix: 16);
                buffer.writeCharCode(charCode);
                i += 3;
                continue;
              } on FormatException {
                // Parsing failed: treat '%' as literal.
                buffer.writeCharCode(0x25);
                i++;
                continue;
              }
            } else {
              // Not enough characters for a valid %XX escape: treat '%' as literal.
              buffer.writeCharCode(0x25);
              i++;
              continue;
            }
          }
        } else {
          // '%' is the last character; treat it as literal.
          buffer.writeCharCode(0x25);
          i++;
          continue;
        }
      }

      buffer.writeCharCode(c);
      i++;
    }

    return buffer.toString();
  }

  /// Percent-encodes a **scalar** value into a query-safe token.
  ///
  /// - Returns `''` for container/sentinel types (Map/Iterable/Symbol/Record/Future/Undefined).
  /// - Accepts `ByteBuffer` (decoded using `charset`) and any other scalar via `toString()`.
  /// - Chunks long strings in `_segmentLimit` pieces for throughput.
  /// - When `format == Format.rfc1738`, allows `(` and `)` as unreserved.
  /// - When `charset == latin1`, falls back to [escape] and converts JavaScript
  ///   `%uXXXX` sequences into percent-encoded numeric entities
  ///   (`%26%23NNNN%3B`, i.e. `&#NNNN;`) to match Node’s `qs`.
  ///
  /// Note: Higher-level encoders are responsible for key assembly and joining.
  static String encode(
    dynamic value, {
    Encoding charset = utf8,
    Format? format = Format.rfc3986,
  }) {
    // these can not be encoded
    if (value is Iterable ||
        value is Map ||
        value is Symbol ||
        value is Record ||
        value is Future ||
        value is Undefined) {
      return '';
    }

    final String? str = value is ByteBuffer
        ? charset.decode(value.asUint8List())
        : value?.toString();

    if (str?.isEmpty ?? true) {
      return '';
    }

    if (charset == latin1) {
      return Utils.escape(str!, format: format).replaceAllMapped(
        RegExp(r'%u[0-9a-f]{4}', caseSensitive: false),
        (Match match) =>
            '%26%23${int.parse(match.group(0)!.substring(2), radix: 16)}%3B',
      );
    }

    final StringBuffer buffer = StringBuffer();
    final String s = str!;
    final int len = s.length;
    if (len <= _segmentLimit) {
      _writeEncodedSegment(s, buffer, format);
    } else {
      int j = 0;
      while (j < len) {
        int end = j + _segmentLimit;
        if (end > len) end = len;
        // Avoid splitting a UTF-16 surrogate pair across segment boundary.
        if (end < len) {
          final int last = s.codeUnitAt(end - 1);
          if (last >= 0xD800 && last <= 0xDBFF) {
            // keep the high surrogate with its low surrogate in next segment
            end--;
          }
        }
        _writeEncodedSegment(s.substring(j, end), buffer, format);
        j = end; // advance to the adjusted end
      }
    }

    return buffer.toString();
  }

  static void _writeEncodedSegment(
      String segment, StringBuffer buffer, Format? format) {
    for (int i = 0; i < segment.length; ++i) {
      int c = segment.codeUnitAt(i);

      switch (c) {
        case 0x2D: // -
        case 0x2E: // .
        case 0x5F: // _
        case 0x7E: // ~
        case int v when v >= 0x30 && v <= 0x39: // 0-9
        case int v when v >= 0x41 && v <= 0x5A: // A-Z
        case int v when v >= 0x61 && v <= 0x7A: // a-z
        case int v
            when format == Format.rfc1738 && (v == 0x28 || v == 0x29): // ( )
          buffer.writeCharCode(c);
          continue;
        case int v when v < 0x80: // ASCII
          buffer.write(hexTable[v]);
          continue;
        case int v when v < 0x800: // 2 bytes
          buffer.writeAll([
            hexTable[0xC0 | (v >> 6)],
            hexTable[0x80 | (v & 0x3F)],
          ]);
          continue;
        case int v
            when v < 0xD800 || v >= 0xE000: // 3 bytes (BMP, non-surrogates)
          buffer.writeAll([
            hexTable[0xE0 | (v >> 12)],
            hexTable[0x80 | ((v >> 6) & 0x3F)],
            hexTable[0x80 | (v & 0x3F)],
          ]);
          continue;

        case int v when v >= 0xD800 && v <= 0xDBFF: // high surrogate
          if (i + 1 < segment.length) {
            final int w = segment.codeUnitAt(i + 1);
            if (w >= 0xDC00 && w <= 0xDFFF) {
              final int code = 0x10000 + (((v & 0x3FF) << 10) | (w & 0x3FF));
              buffer.writeAll([
                hexTable[0xF0 | (code >> 18)],
                hexTable[0x80 | ((code >> 12) & 0x3F)],
                hexTable[0x80 | ((code >> 6) & 0x3F)],
                hexTable[0x80 | (code & 0x3F)],
              ]);
              i++; // consume low surrogate
              continue;
            }
          }
          // Lone high surrogate: encode as a 3-byte sequence of the code unit
          buffer.writeAll([
            hexTable[0xE0 | (v >> 12)],
            hexTable[0x80 | ((v >> 6) & 0x3F)],
            hexTable[0x80 | (v & 0x3F)],
          ]);
          continue;

        case int v when v >= 0xDC00 && v <= 0xDFFF: // lone low surrogate
          buffer.writeAll([
            hexTable[0xE0 | (v >> 12)],
            hexTable[0x80 | ((v >> 6) & 0x3F)],
            hexTable[0x80 | (v & 0x3F)],
          ]);
          continue;

        default:
          // Fallback: encode as 3 bytes of the code unit (should not be hit)
          buffer.writeAll([
            hexTable[0xE0 | (c >> 12)],
            hexTable[0x80 | ((c >> 6) & 0x3F)],
            hexTable[0x80 | (c & 0x3F)],
          ]);
          continue;
      }
    }
  }

  /// Fast latin1 percent-decoder
  static String _decodeLatin1Percent(String s) {
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final int ch = s.codeUnitAt(i);
      if (ch == 0x25 /* % */ && i + 2 < s.length) {
        final int h1 = _hexVal(s.codeUnitAt(i + 1));
        final int h2 = _hexVal(s.codeUnitAt(i + 2));
        if (h1 >= 0 && h2 >= 0) {
          sb.writeCharCode((h1 << 4) | h2);
          i += 2;
          continue;
        }
      }
      sb.writeCharCode(ch);
    }
    return sb.toString();
  }

  static int _hexVal(int cu) {
    if (cu >= 0x30 && cu <= 0x39) return cu - 0x30; // '0'..'9'
    if (cu >= 0x41 && cu <= 0x46) return cu - 0x41 + 10; // 'A'..'F'
    if (cu >= 0x61 && cu <= 0x66) return cu - 0x61 + 10; // 'a'..'f'
    return -1;
  }

  /// Decodes a percent-encoded token back to a scalar string.
  ///
  /// - Treats `'+'` as space before decoding (URL form semantics).
  /// - UTF‑8 path uses `Uri.decodeComponent`; on parse errors the original
  ///   string (with `'+'` → space) is returned.
  /// - latin1 path replaces `%XX` sequences via [unescape]; failures fall back
  ///   to returning the input unchanged (after `'+'` handling).
  ///
  /// Returns `null` if `str` is `null`.
  static String? decode(String? str, {Encoding? charset = utf8}) {
    final String? strWithoutPlus = str?.replaceAll('+', ' ');
    if (charset == latin1) {
      final String? s = strWithoutPlus;
      if (s == null) return null;
      if (!s.contains('%')) return s; // fast path: nothing to decode
      try {
        return _decodeLatin1Percent(s);
      } catch (_) {
        return s;
      }
    }
    try {
      return strWithoutPlus != null
          ? Uri.decodeComponent(strWithoutPlus)
          : null;
    } catch (_) {
      return strWithoutPlus;
    }
  }

  /// Removes [Undefined] markers from maps/lists **in place**.
  ///
  /// - Traverses iteratively with an **identity-based** visited set to tolerate
  ///   cycles without recursion.
  /// - Preserves insertion order of `Map`/`List`.
  /// - Safe for decode results (decode builds a fresh structure), but be careful
  ///   when calling with shared objects because this mutates them.
  ///
  /// Returns the same `root` instance for chaining.
  static Map<String, dynamic> compact(Map<String, dynamic> root) {
    final List<Object> stack = [root];

    // Identity-based visited set: ensures each concrete object is processed once
    final HashSet visited = HashSet.identity()..add(root);

    while (stack.isNotEmpty) {
      final Object node = stack.removeLast();

      if (node is Map) {
        for (final key in List<String>.from(node.keys)) {
          final value = node[key];
          switch (value) {
            case Undefined():
              node.remove(key);
            case Map() || List() when visited.add(value):
              stack.add(value);
            default:
              break;
          }
        }
      } else if (node is List) {
        for (int i = node.length - 1; i >= 0; i--) {
          final v = node[i];
          switch (v) {
            case Undefined():
              node.removeAt(i);
            case Map() || List() when visited.add(v):
              stack.add(v);
            default:
              break;
          }
        }
      }
    }

    return root;
  }

  /// Concatenates two values, spreading iterables.
  ///
  /// When [listLimit] is provided and exceeded, returns a map with numeric keys.
  ///
  /// Examples:
  /// ```dart
  /// combine([1,2], 3); // [1,2,3]
  /// combine('a', ['b','c']); // ['a','b','c']
  /// ```
  static dynamic combine(dynamic a, dynamic b, {int? listLimit}) {
    if (isOverflow(a)) {
      int newIndex = _getOverflowIndex(a);
      if (b is Iterable) {
        for (final item in b) {
          newIndex++;
          a[newIndex.toString()] = item;
        }
      } else {
        newIndex++;
        a[newIndex.toString()] = b;
      }
      _setOverflowIndex(a, newIndex);
      return a;
    }

    final List<dynamic> result = <dynamic>[
      if (a is Iterable) ...a else a,
      if (b is Iterable) ...b else b,
    ];

    if (listLimit != null && listLimit >= 0 && result.length > listLimit) {
      final Map<String, dynamic> overflow = createIndexMap(result);
      return markOverflow(overflow, result.length - 1);
    }

    return result;
  }

  /// Applies `fn` to a scalar or maps it over an iterable, returning the result.
  ///
  /// Handy when a caller may pass a single value or a collection.
  static dynamic apply<T>(dynamic val, T Function(T) fn) =>
      val is Iterable ? val.map((item) => fn(item)) : fn(val);

  /// Returns `true` if `val` is a scalar we should encode as-is.
  ///
  /// Scalars include: `num`, `BigInt`, `bool`, `Enum`, `DateTime`, `Duration`,
  /// `String` (optionally empty handling via `skipNulls`), and `Uri`.
  /// Containers (`Iterable`, `Map`) and special cases (`Symbol`, `Record`,
  /// `Future`, [Undefined]) return `false`.
  ///
  /// When `skipNulls == true`, empty strings and empty `Uri.toString()` return `false`.
  static bool isNonNullishPrimitive(dynamic val, [bool skipNulls = false]) {
    if (val is String) {
      return skipNulls ? val.isNotEmpty : true;
    }

    if (val is num ||
        val is BigInt ||
        val is bool ||
        val is Enum ||
        val is DateTime ||
        val is Duration) {
      return true;
    }

    if (val is Uri) {
      return skipNulls ? val.toString().isNotEmpty : true;
    }

    if (val is Object) {
      if (val is Iterable ||
          val is Map ||
          val is Symbol ||
          val is Record ||
          val is Future ||
          val is Undefined) {
        return false;
      }
      return true;
    }

    return false;
  }

  /// Generic emptiness predicate for values handled by the encoder.
  ///
  /// Treats `null`, [Undefined], empty strings, empty iterables and empty maps
  /// as “empty”.
  static bool isEmpty(dynamic val) =>
      val == null ||
      val is Undefined ||
      (val is String && val.isEmpty) ||
      (val is Iterable && val.isEmpty) ||
      (val is Map && val.isEmpty);

  /// Decodes numeric HTML entities like `&#169;` into Unicode characters.
  ///
  /// - Only decimal entities are recognized.
  /// - Gracefully leaves malformed/partial sequences untouched.
  /// - Produces surrogate pairs for code points &gt; `0xFFFF`.
  static String interpretNumericEntities(String s) {
    if (s.length < 4) return s;
    if (!s.contains('&#')) return s;
    final StringBuffer sb = StringBuffer();
    int i = 0;
    while (i < s.length) {
      final int ch = s.codeUnitAt(i);
      if (ch == 0x26 /* & */ &&
          i + 2 < s.length &&
          s.codeUnitAt(i + 1) == 0x23 /* # */) {
        int j = i + 2;
        if (j < s.length) {
          int code = 0;
          final int start = j;
          while (j < s.length) {
            final int cu = s.codeUnitAt(j);
            if (cu < 0x30 || cu > 0x39) break; // 0..9
            code = code * 10 + (cu - 0x30);
            j++;
          }
          if (j < s.length && s.codeUnitAt(j) == 0x3B /* ; */ && j > start) {
            if (code <= 0xFFFF) {
              sb.writeCharCode(code);
            } else if (code <= 0x10FFFF) {
              final v = code - 0x10000;
              sb.writeCharCode(0xD800 | (v >> 10)); // high surrogate
              sb.writeCharCode(0xDC00 | (v & 0x3FF)); // low surrogate
            } else {
              // out of range: keep literal '&' and continue
              sb.writeCharCode(0x26);
              i++;
              continue;
            }
            i = j + 1;
            continue;
          }
        }
        // not a well-formed entity: keep literal '&'
        sb.writeCharCode(0x26);
        i++;
      } else {
        sb.writeCharCode(ch);
        i++;
      }
    }
    return sb.toString();
  }

  /// Create an index-keyed map from an iterable.
  static Map<String, dynamic> createIndexMap(Iterable iterable) {
    if (iterable is List) {
      final list = iterable;
      final map = <String, dynamic>{};
      for (var i = 0; i < list.length; i++) {
        map[i.toString()] = list[i];
      }
      return map;
    } else {
      final map = <String, dynamic>{};
      var i = 0;
      for (final v in iterable) {
        map[i.toString()] = v;
        i++;
      }
      return map;
    }
  }
}
