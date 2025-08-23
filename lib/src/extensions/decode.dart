// ignore_for_file: deprecated_member_use_from_same_package
part of '../qs.dart';

/// Decoder: query-string → nested Dart maps/lists (Node `qs` parity)
///
/// This module mirrors the semantics of the original `qs` (https://github.com/ljharb/qs):
/// - Bracket notation drives structure (e.g. `a[b][0]=1`).
/// - Optional dot-notation can be accepted and normalized to brackets when
///   `DecodeOptions.allowDots` is true (e.g. `a.b` → `a[b]`).
/// - Depth limiting (`depth`) behaves like `qs`: depth=0 disables splitting;
///   `strictDepth=true` throws when nesting exceeds the limit; otherwise the
///   remainder is kept as a single segment.
/// - Charset sentinel (`utf8=`) handling matches `qs`.
/// - Duplicate key handling (`duplicates`) and list parsing (`parseLists`,
///   `allowEmptyLists`, `allowSparseLists`, `listLimit`) follow the reference.
///
/// Implementation notes:
/// - We decode key parts lazily and then "reduce" right-to-left to build the
///   final structure in `_parseObject`.
/// - We never mutate caller-provided containers; fresh maps/lists are allocated for merges.
/// - The implementation aims to match `qs` semantics; comments explain how each phase maps
///   to the reference behavior.

/// Internal decoding surface grouped under the `QS` extension.
///
/// These static helpers are private to the library and orchestrate the
/// string → structure pipeline used by `QS.decode`.
extension _$Decode on QS {
  /// Interprets a single scalar value as a list element when the `comma`
  /// option is enabled and a comma is present, and enforces `listLimit`.
  ///
  /// If `throwOnLimitExceeded` is true, exceeding `listLimit` will throw a
  /// `RangeError`; otherwise the caller can decide how to degrade.
  ///
  /// The `currentListLength` is used to guard incremental growth when we are
  /// already building a list for a given key path.
  ///
  /// **Negative `listLimit` semantics:** a negative value disables numeric-index parsing
  /// elsewhere (e.g. `[2]` segments become string keys). For comma‑splits specifically:
  /// when `throwOnLimitExceeded` is `true` and `listLimit < 0`, any non‑empty split throws
  /// immediately; when `false`, growth is effectively capped at zero (the split produces
  /// an empty list). Empty‑bracket pushes (`a[]=`) are handled during structure building
  /// in `_parseObject`.
  static dynamic _parseListValue(
    dynamic val,
    DecodeOptions options,
    int currentListLength,
  ) {
    // Fast-path: split comma-separated scalars into a list when requested.
    if (val is String && val.isNotEmpty && options.comma && val.contains(',')) {
      final List<String> splitVal = val.split(',');
      if (options.throwOnLimitExceeded &&
          (currentListLength + splitVal.length) > options.listLimit) {
        throw RangeError(
          'List limit exceeded. '
          'Only ${options.listLimit} element${options.listLimit == 1 ? '' : 's'} allowed in a list.',
        );
      }
      final int remaining = options.listLimit - currentListLength;
      if (remaining <= 0) return const <String>[];
      return splitVal.length <= remaining
          ? splitVal
          : splitVal.sublist(0, remaining);
    }

    // Guard incremental growth of an existing list as we parse additional items.
    if (options.throwOnLimitExceeded &&
        currentListLength >= options.listLimit) {
      throw RangeError(
        'List limit exceeded. '
        'Only ${options.listLimit} element${options.listLimit == 1 ? '' : 's'} allowed in a list.',
      );
    }

    return val;
  }

  /// Tokenizes the raw query-string into a flat key→value map before any
  /// structural reconstruction. Handles:
  /// - query prefix removal (`?`), and kind‑aware decoding via `DecodeOptions.decodeKey` /
  ///   `DecodeOptions.decodeValue` (by default these percent‑decode)
  /// - charset sentinel detection (`utf8=`) per `qs`
  /// - duplicate key policy (combine/first/last)
  /// - parameter and list limits with optional throwing behavior
  /// - Comma‑split growth honors `throwOnLimitExceeded` (see `_parseListValue`);
  ///   empty‑bracket pushes (`[]=`) are created during structure building in `_parseObject`.
  static Map<String, dynamic> _parseQueryStringValues(
    String str, [
    DecodeOptions options = const DecodeOptions(),
  ]) {
    // 1) Normalize the incoming string (drop `?`, normalize %5B/%5D to brackets).
    final String cleanStr =
        _cleanQueryString(str, ignoreQueryPrefix: options.ignoreQueryPrefix);

    // 2) Resolve the parameter limit; `double.infinity` denotes no limit.
    final int? limit = options.parameterLimit == double.infinity
        ? null
        : options.parameterLimit.toInt();

    // `qs` treats non-positive limits as programmer error when enforced.
    if (limit != null && limit <= 0) {
      throw ArgumentError('Parameter limit must be a positive integer.');
    }

    // 3) Split by delimiter once; optionally truncate, optionally throw on overflow.
    final List<String> allParts = cleanStr.split(options.delimiter);
    late final List<String> parts;
    if (limit != null && limit > 0) {
      if (options.throwOnLimitExceeded && allParts.length > limit) {
        throw RangeError(
          'Parameter limit exceeded. Only $limit parameter${limit == 1 ? '' : 's'} allowed.',
        );
      }
      parts = allParts.take(limit).toList();
    } else {
      parts = allParts;
    }

    // Charset probing (utf8=✓ / utf8=X). Skip the sentinel pair later.
    int skipIndex = -1; // Keep track of where the utf8 sentinel was found
    int i;

    Encoding charset = options.charset;

    // 4) Scan once for a charset sentinel and adjust decoder charset accordingly.
    if (options.charsetSentinel) {
      for (i = 0; i < parts.length; ++i) {
        final String p = parts[i];
        if (p.startsWith('utf8=')) {
          if (p == Sentinel.charset.toString()) {
            charset = utf8;
          } else if (p == Sentinel.iso.toString()) {
            charset = latin1;
          }
          skipIndex = i;
          break;
        }
      }
    }

    // 5) Parse each `key=value` pair, honoring bracket-`]=` short-circuit for speed.
    final Map<String, dynamic> obj = {};
    for (i = 0; i < parts.length; ++i) {
      if (i == skipIndex) continue;
      final String part = parts[i];
      final int bracketEqualsPos = part.indexOf(']=');
      final int pos =
          bracketEqualsPos == -1 ? part.indexOf('=') : bracketEqualsPos + 1;

      late final String key;
      dynamic val;
      // Decode key/value via DecodeOptions.decodeKey/decodeValue (kind-aware).
      if (pos == -1) {
        // Decode bare key (no '=') using key-aware decoding
        key = options.decodeKey(part, charset: charset) ?? '';
        val = options.strictNullHandling ? null : '';
      } else {
        // Decode the key slice as a key; values decode as values
        key = options.decodeKey(part.slice(0, pos), charset: charset) ?? '';
        // Decode the substring *after* '=', applying list parsing and the configured decoder.
        val = Utils.apply<dynamic>(
          _parseListValue(
            part.slice(pos + 1),
            options,
            obj.containsKey(key) && obj[key] is List
                ? (obj[key] as List).length
                : 0,
          ),
          (dynamic v) => options.decodeValue(v as String?, charset: charset),
        );
      }

      // Optional HTML numeric entity interpretation (legacy Latin-1 queries).
      if (val != null &&
          !Utils.isEmpty(val) &&
          options.interpretNumericEntities &&
          charset == latin1) {
        if (val is Iterable) {
          val = Utils.interpretNumericEntities(_joinIterableToCommaString(val));
        } else {
          val = Utils.interpretNumericEntities(val.toString());
        }
      }

      // Quirk: a literal `[]=` suffix forces an array container (qs behavior).
      if (options.parseLists && part.contains('[]=')) {
        val = [val];
      }

      // Duplicate key policy: combine/first/last (default: combine).
      final bool existing = obj.containsKey(key);
      if (existing && options.duplicates == Duplicates.combine) {
        obj[key] = Utils.combine(obj[key], val);
      } else if (!existing || options.duplicates == Duplicates.last) {
        obj[key] = val;
      }
    }

    return obj;
  }

  /// Reduces a list of key segments (e.g. `["a", "[b]", "[0]"]`) and a
  /// leaf value into a nested structure. Operates right-to-left, constructing
  /// maps or lists based on segment content and `DecodeOptions`.
  ///
  /// Notes:
  /// - When `parseLists` is false, numeric segments are treated as string keys.
  /// - When `allowEmptyLists` is true, an empty string (or `null` under
  ///   `strictNullHandling`) under a `[]` segment yields an empty list.
  /// - `listLimit` applies to explicit numeric indices as an upper bound.
  /// - A negative `listLimit` disables numeric‑index parsing (bracketed numbers become map keys).
  ///   Empty‑bracket pushes (`[]`) still create lists here; this method does not enforce
  ///   `throwOnLimitExceeded` for that path. Comma‑split growth (if any) has already been
  ///   handled by `_parseListValue`.
  /// - Keys have been decoded per `DecodeOptions.decodeKey`; top‑level splitting applies to
  ///   literal `.` only (including those produced by percent‑decoding). Percent‑encoded dots may
  ///   still appear inside bracket segments here; we normalize `%2E`/`%2e` to `.` below when
  ///   `decodeDotInKeys` is enabled.
  ///   Whether top‑level dots split was decided earlier by `_splitKeyIntoSegments` (based on
  ///   `allowDots`). Numeric list indices are only honored for *bracketed* numerics like `[3]`.
  static dynamic _parseObject(
    List<String> chain,
    dynamic val,
    DecodeOptions options,
    bool valuesParsed,
  ) {
    // Determine the current list length if we are appending into `[]`.
    late final int currentListLength;

    if (chain.length >= 2 && chain.last == '[]') {
      final String prev = chain[chain.length - 2];
      final bool bracketed = prev.startsWith('[') && prev.endsWith(']');
      final int? parentIndex =
          bracketed ? int.tryParse(prev.substring(1, prev.length - 1)) : null;
      if (parentIndex != null &&
          parentIndex >= 0 &&
          val is List &&
          parentIndex < val.length) {
        final dynamic parent = val[parentIndex];
        currentListLength = parent is List ? parent.length : 0;
      } else {
        currentListLength = 0;
      }
    } else {
      currentListLength = 0;
    }

    // Lazily parse comma-lists once per leaf unless the caller already did.
    dynamic leaf = valuesParsed
        ? val
        : _parseListValue(
            val,
            options,
            currentListLength,
          );

    for (int i = chain.length - 1; i >= 0; --i) {
      dynamic obj;
      final String root = chain[i];

      // Anonymous list segment `[]` — either an empty list (when allowed) or a
      // single-element list with the leaf combined in.
      if (root == '[]' && options.parseLists) {
        obj = options.allowEmptyLists &&
                (leaf == '' || (options.strictNullHandling && leaf == null))
            ? List<dynamic>.empty(growable: true)
            : Utils.combine([], leaf);
      } else {
        obj = <String, dynamic>{};
        // Normalize bracketed segments ("[k]"). Note: depending on how key decoding is configured,
        // percent‑encoded dots *may still be present here* (e.g. `%2E` / `%2e`). We intentionally
        // handle the `%2E`→`.` mapping in this phase (see `decodedRoot` below) so that encoded
        // dots inside bracket segments can be treated as literal `.` without introducing extra
        // dot‑splits. Top‑level dot splitting (which only applies to literal `.`) already
        // happened in `_splitKeyIntoSegments`.
        final String cleanRoot = root.startsWith('[') && root.endsWith(']')
            ? root.slice(1, root.length - 1)
            : root;
        final String decodedRoot = options.decodeDotInKeys
            ? cleanRoot.replaceAll('%2E', '.').replaceAll('%2e', '.')
            : cleanRoot;
        final int? index = int.tryParse(decodedRoot);
        if (!options.parseLists && decodedRoot == '') {
          obj = <String, dynamic>{'0': leaf};
        } else if (index != null &&
            index >= 0 &&
            root != decodedRoot &&
            index.toString() == decodedRoot &&
            options.parseLists &&
            index <= options.listLimit) {
          // Numeric segment treated as list index when lists are enabled and the
          // token was actually bracketed (to disambiguate bare numeric keys).
          obj = List<dynamic>.filled(
            index + 1,
            const Undefined(),
            growable: true,
          );
          obj[index] = leaf;
        } else {
          obj[index?.toString() ?? decodedRoot] = leaf;
        }
      }

      leaf = obj;
    }

    return leaf;
  }

  /// Splits a raw key into bracket segments (respecting dot-notation and
  /// depth constraints) and delegates to `_parseObject` to build the value.
  /// Returns `null` for empty keys.
  static dynamic _parseKeys(
    String? givenKey,
    dynamic val,
    DecodeOptions options, [
    bool valuesParsed = false,
  ]) {
    if (givenKey == null || givenKey.isEmpty) return null;

    final segments = _splitKeyIntoSegments(
      originalKey: givenKey,
      allowDots: options.allowDots,
      maxDepth: options.depth,
      strictDepth: options.strictDepth,
    );

    return _parseObject(segments, val, options, valuesParsed);
  }

  /// Splits a key like `a[b][0][c]` into `['a', '[b]', '[0]', '[c]']` with:
  /// - dot‑notation normalization (`a.b` → `a[b]`) when `allowDots` is true (runs before splitting)
  /// - depth limiting (depth=0 returns the whole key as a single segment)
  /// - balanced bracket grouping; an unterminated `[` causes the *entire key* to be treated as a
  ///   single literal segment (matching `qs`)
  /// - when there are additional groups/text beyond `maxDepth`:
  ///     • if `strictDepth` is true, we throw;
  ///     • otherwise the remainder is wrapped as one final bracket segment (e.g., `"[rest]"`)
  static List<String> _splitKeyIntoSegments({
    required String originalKey,
    required bool allowDots,
    required int maxDepth,
    required bool strictDepth,
  }) {
    // Depth==0 → do not split at all (reference `qs` behavior).
    // Important: return the *original* key with no dot→bracket normalization.
    if (maxDepth <= 0) {
      return <String>[originalKey];
    }

    // Optionally normalize `a.b` to `a[b]` before splitting (only when depth > 0).
    final String key =
        allowDots ? _dotToBracketTopLevel(originalKey) : originalKey;

    final List<String> segments = [];

    // Parent token before the first '[' (may be empty when key starts with '[')
    final int first = key.indexOf('[');
    final String parent = first >= 0 ? key.substring(0, first) : key;
    if (parent.isNotEmpty) segments.add(parent);

    final int n = key.length;
    int open = first;
    int collected = 0;
    int lastClose = -1;

    while (open >= 0 && collected < maxDepth) {
      int level = 1;
      int i = open + 1;
      int close = -1;

      // Balance nested '[' and ']' within this group.
      while (i < n) {
        final int cu = key.codeUnitAt(i);
        if (cu == 0x5B) {
          level++;
        } else if (cu == 0x5D) {
          level--;
          if (level == 0) {
            close = i;
            break;
          }
        }
        i++;
      }

      if (close < 0) {
        // Unterminated group: treat the entire key as a single literal segment (qs semantics).
        return <String>[key];
      }

      segments
          .add(key.substring(open, close + 1)); // balanced group, includes [ ]
      lastClose = close;
      collected++;

      // Find the next '[' after this balanced group.
      open = key.indexOf('[', close + 1);
    }

    // Trailing text after the last balanced group → one final bracket segment (unless it's just '.').
    if (lastClose >= 0 && lastClose + 1 < n) {
      final String remainder = key.substring(lastClose + 1);
      if (remainder != '.') {
        if (strictDepth && open >= 0) {
          throw RangeError(
              'Input depth exceeded $maxDepth and strictDepth is true');
        }
        segments.add('[$remainder]');
      }
    } else if (open >= 0) {
      // There are more groups beyond the collected depth.
      if (strictDepth) {
        throw RangeError(
            'Input depth exceeded $maxDepth and strictDepth is true');
      }
      // Wrap the remaining bracket groups as a single literal segment.
      // Example: key="a[b][c][d]", depth=2 → segment="[[c][d]]" which becomes "[c][d]" later.
      segments.add('[${key.substring(open)}]');
    }

    return segments;
  }

  /// Convert top‑level dots to bracket segments (depth‑aware).
  /// - Only dots at depth == 0 split.
  /// - Dots inside `[...]` are preserved.
  /// - Degenerate cases are preserved and do not create empty segments:
  ///   * ".[" (e.g., "a.[b]") skips the dot so "a.[b]" behaves like "a[b]".
  ///   * leading '.' (e.g., ".a") starts a new segment → "[a]" (leading dot is ignored).
  ///   * double dots ("a..b") keep the first dot literal.
  ///   * trailing dot ("a.") keeps the trailing dot (ignored by the splitter).
  /// - Only literal `.` are considered for splitting here. In this library, keys are normally
  ///   percent‑decoded before this step; thus a top‑level `%2E` typically becomes a literal `.`
  ///   and will split when `allowDots` is true.
  static String _dotToBracketTopLevel(String s) {
    if (s.isEmpty || !s.contains('.')) return s;
    final StringBuffer sb = StringBuffer();
    int depth = 0;
    int i = 0;
    while (i < s.length) {
      final ch = s[i];
      if (ch == '[') {
        depth++;
        sb.write(ch);
        i++;
      } else if (ch == ']') {
        if (depth > 0) depth--;
        sb.write(ch);
        i++;
      } else if (ch == '.') {
        if (depth == 0) {
          final bool hasNext = i + 1 < s.length;
          final String next = hasNext ? s[i + 1] : '\u0000';

          if (hasNext && next == '[') {
            // Degenerate ".[" → skip the dot so "a.[b]" behaves like "a[b]".
            i++; // consume the '.'
          } else if (!hasNext || next == '.') {
            // Preserve literal dot for trailing/duplicate dots.
            sb.write('.');
            i++;
          } else {
            // Normal split: convert top-level ".a" or "a.b" into a bracket segment.
            final int start = ++i;
            int j = start;
            while (j < s.length && s[j] != '.' && s[j] != '[') {
              j++;
            }
            sb.write('[');
            sb.write(s.substring(start, j));
            sb.write(']');
            i = j;
          }
        } else {
          // Inside brackets, keep '.' as content.
          sb.write('.');
          i++;
        }
      } else {
        sb.write(ch);
        i++;
      }
    }
    return sb.toString();
  }

  /// Normalizes the raw query-string prior to tokenization:
  /// - Optionally drops exactly one leading `?` (when `ignoreQueryPrefix` is true).
  /// - Rewrites percent-encoded bracket characters (%5B/%5b → '[', %5D/%5d → ']')
  ///   in a single pass for faster downstream bracket parsing.
  static String _cleanQueryString(
    String str, {
    required bool ignoreQueryPrefix,
  }) {
    // Drop exactly one leading '?' (qs semantics) — not all leading question marks.
    if (ignoreQueryPrefix &&
        str.isNotEmpty &&
        str.codeUnitAt(0) == 0x3F /* '?' */) {
      // Remove leading '?' only once (qs semantics)
      str = str.substring(1);
    }
    if (str.length < 3) return str;

    // Single-pass scan; we avoid full percent-decoding and only normalize
    // bracket tokens that matter for key splitting.
    final StringBuffer sb = StringBuffer();
    final int n = str.length;
    int i = 0;

    while (i < n) {
      final int c = str.codeUnitAt(i);

      // Match "%5B" / "%5b" -> '['  and  "%5D" / "%5d" -> ']'
      if (c == 0x25 /* '%' */ && i + 2 < n) {
        final c1 = str.codeUnitAt(i + 1);
        if (c1 == 0x35 /* '5' */) {
          final c2 = str.codeUnitAt(i + 2);
          if (c2 == 0x42 /* 'B' */ || c2 == 0x62 /* 'b' */) {
            sb.writeCharCode(0x5B); // '['
            i += 3;
            continue;
          } else if (c2 == 0x44 /* 'D' */ || c2 == 0x64 /* 'd' */) {
            sb.writeCharCode(0x5D); // ']'
            i += 3;
            continue;
          }
        }
      }

      sb.writeCharCode(c);
      i++;
    }

    return sb.toString();
  }

  /// Joins an iterable of objects into a comma-separated string.
  static String _joinIterableToCommaString(Iterable it) {
    final StringBuffer sb = StringBuffer();
    bool first = true;
    for (final e in it) {
      if (!first) sb.write(',');
      sb.write(e == null ? '' : e.toString());
      first = false;
    }
    return sb.toString();
  }
}
