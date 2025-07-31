import 'dart:collection' show SplayTreeMap, HashSet;
import 'dart:convert' show latin1, utf8, Encoding;
import 'dart:typed_data' show ByteBuffer;

import 'package:meta/meta.dart' show internal, visibleForTesting;
import 'package:qs_dart/src/enums/format.dart';
import 'package:qs_dart/src/extensions/extensions.dart';
import 'package:qs_dart/src/models/decode_options.dart';
import 'package:qs_dart/src/models/undefined.dart';

part 'constants/hex_table.dart';

/// A collection of utility methods used by the library.
@internal
final class Utils {
  static const int _segmentLimit = 1024;

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
          final SplayTreeMap<int, dynamic> target_ =
              SplayTreeMap.of(target.toList().asMap());

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
                  SplayTreeMap.of(target.toList().asMap());
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

    Map<String, dynamic> mergeTarget = target is Iterable && source is! Iterable
        ? {
            for (final (int i, dynamic item) in (target as Iterable).indexed)
              if (item is! Undefined) i.toString(): item
          }
        : {
            for (final MapEntry entry in target.entries)
              entry.key.toString(): entry.value
          };

    return source.entries.fold(mergeTarget, (Map acc, MapEntry entry) {
      acc.update(
        entry.key.toString(),
        (value) => merge(
          value,
          entry.value,
          options,
        ),
        ifAbsent: () => entry.value,
      );
      return acc;
    });
  }

  /// A Dart representation the deprecated JavaScript escape function
  /// https://developer.mozilla.org/en-US/docs/web/javascript/reference/global_objects/escape
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
        buffer.write(str[i]);
        continue;
      }

      if (c < 256) {
        buffer.writeAll([
          '%',
          c.toRadixString(16).padLeft(2, '0').toUpperCase(),
        ]);
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

  /// A Dart representation the deprecated JavaScript unescape function
  /// https://developer.mozilla.org/en-US/docs/web/javascript/reference/global_objects/unescape
  @internal
  @visibleForTesting
  @Deprecated('Use Uri.decodeComponent instead')
  static String unescape(String str) {
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
                buffer.write(str[i]);
                i++;
                continue;
              }
            } else {
              // Not enough characters for a valid %u escape: treat '%' as literal.
              buffer.write(str[i]);
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
                buffer.write(str[i]);
                i++;
                continue;
              }
            } else {
              // Not enough characters for a valid %XX escape: treat '%' as literal.
              buffer.write(str[i]);
              i++;
              continue;
            }
          }
        } else {
          // '%' is the last character; treat it as literal.
          buffer.write(str[i]);
          i++;
          continue;
        }
      }

      buffer.write(str[i]);
      i++;
    }

    return buffer.toString();
  }

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
      // ignore: deprecated_member_use_from_same_package
      return Utils.escape(str!, format: format).replaceAllMapped(
        RegExp(r'%u[0-9a-f]{4}', caseSensitive: false),
        (Match match) =>
            '%26%23${int.parse(match.group(0)!.substring(2), radix: 16)}%3B',
      );
    }

    final StringBuffer buffer = StringBuffer();

    for (int j = 0; j < str!.length; j += _segmentLimit) {
      final String segment =
          str.length >= _segmentLimit ? str.slice(j, j + _segmentLimit) : str;

      for (int i = 0; i < segment.length; ++i) {
        int c = segment.codeUnitAt(i);

        switch (c) {
          case 0x2D: // -
          case 0x2E: // .
          case 0x5F: // _
          case 0x7E: // ~
          case int c when c >= 0x30 && c <= 0x39: // 0-9
          case int c when c >= 0x41 && c <= 0x5A: // a-z
          case int c when c >= 0x61 && c <= 0x7A: // A-Z
          case int c
              when format == Format.rfc1738 && (c == 0x28 || c == 0x29): // ( )
            buffer.write(segment[i]);
            continue;
          case int c when c < 0x80: // ASCII
            buffer.write(hexTable[c]);
            continue;
          case int c when c < 0x800: // 2 bytes
            buffer.writeAll([
              hexTable[0xC0 | (c >> 6)],
              hexTable[0x80 | (c & 0x3F)],
            ]);
            continue;
          case int c when c < 0xD800 || c >= 0xE000: // 3 bytes
            buffer.writeAll([
              hexTable[0xE0 | (c >> 12)],
              hexTable[0x80 | ((c >> 6) & 0x3F)],
              hexTable[0x80 | (c & 0x3F)],
            ]);
            continue;
          default:
            i++;
            c = 0x10000 +
                (((c & 0x3FF) << 10) | (segment.codeUnitAt(i) & 0x3FF));
            buffer.writeAll([
              hexTable[0xF0 | (c >> 18)],
              hexTable[0x80 | ((c >> 12) & 0x3F)],
              hexTable[0x80 | ((c >> 6) & 0x3F)],
              hexTable[0x80 | (c & 0x3F)],
            ]);
        }
      }
    }

    return buffer.toString();
  }

  static String? decode(String? str, {Encoding? charset = utf8}) {
    final String? strWithoutPlus = str?.replaceAll('+', ' ');
    if (charset == latin1) {
      try {
        return strWithoutPlus?.replaceAllMapped(
          RegExp(r'%[0-9a-f]{2}', caseSensitive: false),
          // ignore: deprecated_member_use_from_same_package
          (Match match) => Utils.unescape(match.group(0)!),
        );
      } catch (_) {
        return strWithoutPlus;
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

  /// Iteratively removes `Undefined` from maps/lists in-place.
  /// - Identity-based visitation avoids infinite loops on cycles.
  /// - Preserves insertion order of Map/List.
  /// - Mutates the given structure (decode builds a fresh structure, so this is safe).
  static Map<String, dynamic> compact(Map<String, dynamic> root) {
    final stack = <Object>[root];

    // Identity-based visited set: ensures each concrete object is processed once
    final visited = HashSet.identity()..add(root);

    while (stack.isNotEmpty) {
      final node = stack.removeLast();

      if (node is Map) {
        // Iterate over a snapshot of entries to allow safe removal while iterating
        final entries = List.of(node.entries);
        for (final e in entries) {
          final k = e.key;
          final v = e.value;

          if (v is Undefined) {
            node.remove(k);
          } else if (v is Map || v is List) {
            if (visited.add(v)) stack.add(v);
          }
        }
      } else if (node is List) {
        var i = 0;
        while (i < node.length) {
          final v = node[i];
          if (v is Undefined) {
            node.removeAt(i); // do not increment i; next element shifts into i
          } else {
            if (v is Map || v is List) {
              if (visited.add(v)) stack.add(v);
            }
            i++;
          }
        }
      }
    }

    return root;
  }

  static List<T> combine<T>(dynamic a, dynamic b) => <T>[
        if (a is Iterable<T>) ...a else a,
        if (b is Iterable<T>) ...b else b,
      ];

  static dynamic apply<T>(dynamic val, T Function(T) fn) =>
      val is Iterable ? val.map((item) => fn(item)) : fn(val);

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

  static bool isEmpty(dynamic val) =>
      val == null ||
      val is Undefined ||
      (val is String && val.isEmpty) ||
      (val is Iterable && val.isEmpty) ||
      (val is Map && val.isEmpty);

  static String interpretNumericEntities(String s) {
    if (s.length < 4) return s;
    final sb = StringBuffer();
    var i = 0;
    while (i < s.length) {
      final ch = s.codeUnitAt(i);
      if (ch == 0x26 /* & */ &&
          i + 2 < s.length &&
          s.codeUnitAt(i + 1) == 0x23 /* # */) {
        var j = i + 2;
        if (j < s.length) {
          int code = 0;
          final start = j;
          while (j < s.length) {
            final cu = s.codeUnitAt(j);
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
}
