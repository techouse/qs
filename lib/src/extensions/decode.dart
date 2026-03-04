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
    final dynamic val,
    final DecodeOptions options,
    final int currentListLength,
    final bool isListGrowthPath,
  ) {
    // Fast-path: split comma-separated scalars into a list when requested.
    if (val is String && val.isNotEmpty && options.comma && val.contains(',')) {
      final int remaining = options.listLimit - currentListLength;

      if (options.throwOnLimitExceeded) {
        if (remaining < 0) {
          throw RangeError(_listLimitExceededMessage(options.listLimit));
        }
        final List<String> splitVal = _splitCommaValue(
          val,
          maxParts: remaining == 0 ? 1 : remaining + 1,
        );
        if (splitVal.length > remaining) {
          throw RangeError(_listLimitExceededMessage(options.listLimit));
        }
        return splitVal;
      }

      if (remaining <= 0) return const <String>[];
      return _splitCommaValue(val, maxParts: remaining);
    }

    // Guard incremental growth of an existing list as we parse additional items.
    if (options.throwOnLimitExceeded &&
        isListGrowthPath &&
        currentListLength >= options.listLimit) {
      throw RangeError(_listLimitExceededMessage(options.listLimit));
    }

    return val;
  }

  /// Helper to generate consistent error messages for list limit violations,
  /// based on the configured `listLimit`.
  static String _listLimitExceededMessage(final int listLimit) => listLimit < 0
      ? 'List parsing is disabled (listLimit < 0).'
      : 'List limit exceeded. Only $listLimit '
          'element${listLimit == 1 ? '' : 's'} allowed in a list.';

  /// Splits a comma-separated value into parts, respecting an optional `maxParts` limit.
  static List<String> _splitCommaValue(
    final String value, {
    final int? maxParts,
  }) {
    if (maxParts != null && maxParts <= 0) return const <String>[];

    final List<String> parts = <String>[];
    int start = 0;
    while (true) {
      if (maxParts != null && parts.length >= maxParts) break;

      final int comma = value.indexOf(',', start);
      final int end = comma == -1 ? value.length : comma;
      parts.add(value.substring(start, end));

      if (comma == -1) break;
      start = comma + 1;
    }

    return parts;
  }

  /// Splits the input string by the specified delimiter (string or pattern),
  /// collecting only non-empty parts and respecting an optional `maxParts` limit.
  static List<String> _collectNonEmptyParts(
    final String input,
    final Pattern delimiter, {
    final int? maxParts,
  }) {
    return switch (delimiter) {
      String d => _collectNonEmptyStringParts(input, d, maxParts: maxParts),
      _ => _collectNonEmptyPatternParts(input, delimiter, maxParts: maxParts),
    };
  }

  /// Optimized splitter for string delimiters that collects only non-empty
  /// parts and respects `maxParts`.
  static List<String> _collectNonEmptyStringParts(
    final String input,
    final String delimiter, {
    final int? maxParts,
  }) {
    if (delimiter.isEmpty) {
      throw ArgumentError('Delimiter must not be empty.');
    }
    if (maxParts != null && maxParts <= 0) return const <String>[];

    final List<String> parts = <String>[];
    int start = 0;
    while (true) {
      if (maxParts != null && parts.length >= maxParts) break;

      final int next = input.indexOf(delimiter, start);
      final int end = next == -1 ? input.length : next;
      if (end > start) {
        parts.add(input.substring(start, end));
      }

      if (next == -1) break;
      start = next + delimiter.length;
    }

    return parts;
  }

  /// General splitter for pattern delimiters that collects only non-empty parts
  static List<String> _collectNonEmptyPatternParts(
    final String input,
    final Pattern delimiter, {
    final int? maxParts,
  }) {
    if (maxParts != null && maxParts <= 0) return const <String>[];

    final List<String> out = <String>[];
    int start = 0;

    for (final Match match in delimiter.allMatches(input)) {
      final int matchStart = match.start;
      final int matchEnd = match.end;

      if (matchStart < start) continue;

      if (matchStart > start) {
        out.add(input.substring(start, matchStart));
        if (maxParts != null && out.length >= maxParts) return out;
      }

      // Defensive handling for zero-width matches to guarantee forward progress.
      if (matchEnd <= start) {
        if (start >= input.length) break;
        start++;
      } else {
        start = matchEnd;
      }
    }

    if (start < input.length && (maxParts == null || out.length < maxParts)) {
      out.add(input.substring(start));
    }

    return out;
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
    final String str, [
    final DecodeOptions options = const DecodeOptions(),
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
    final int? takeCount = limit == null
        ? null
        : (options.throwOnLimitExceeded ? limit + 1 : limit);
    final List<String> parts = _collectNonEmptyParts(
      cleanStr,
      options.delimiter,
      maxParts: takeCount,
    );
    if (options.throwOnLimitExceeded && limit != null && parts.length > limit) {
      throw RangeError(
        'Parameter limit exceeded. Only $limit parameter${limit == 1 ? '' : 's'} allowed.',
      );
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
        final String rawKey = part.substring(0, pos);
        key = options.decodeKey(rawKey, charset: charset) ?? '';
        // Decode the substring *after* '=', applying list parsing and the configured decoder.
        final bool existingKey = obj.containsKey(key);
        final bool combiningDuplicates =
            existingKey && options.duplicates == Duplicates.combine;
        final int currentListLength = combiningDuplicates
            ? (obj[key] is List ? (obj[key] as List).length : 1)
            : 0;
        final bool listGrowthFromKey = combiningDuplicates ||
            (options.parseLists && rawKey.endsWith('[]'));

        val = Utils.apply<dynamic>(
          _parseListValue(
            part.substring(pos + 1),
            options,
            currentListLength,
            listGrowthFromKey,
          ),
          (final dynamic v) =>
              options.decodeValue(v as String?, charset: charset),
        );
      }
      if (key.isEmpty) continue;

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

      // Quirk: a key ending in `[]` forces an array container (qs behavior).
      if (options.parseLists &&
          pos != -1 &&
          part.substring(0, pos).endsWith('[]')) {
        val = [val];
      }

      // Duplicate key policy: combine/first/last (default: combine).
      final bool existing = obj.containsKey(key);
      switch ((existing, options.duplicates)) {
        case (true, Duplicates.combine):
          // Existing key + `combine` policy: merge old/new values.
          obj[key] = Utils.combine(obj[key], val, listLimit: options.listLimit);
          break;
        case (false, _):
        case (true, Duplicates.last):
          // New key, or `last` policy: store the current value.
          obj[key] = val;
          break;
        case (true, Duplicates.first):
          // Existing key + `first` policy: keep the original value.
          break;
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
  /// - `listLimit` applies to explicit numeric indices and list growth via `[]`;
  ///   when exceeded, lists are converted into maps with string indices.
  /// - A negative `listLimit` disables numeric‑index parsing (bracketed numbers become map keys).
  /// - List-growth context is forwarded to `_parseListValue` before reduction:
  ///   `chain.last == '[]'` (with `options.parseLists`) and `options.throwOnLimitExceeded`
  ///   can cause `_parseListValue` to throw on strict list growth checks.
  ///   Reviewers should trace `chain`/`options` into `_parseObject` and then into
  ///   `_parseListValue` for the exact throw paths.
  /// - Keys have been decoded per `DecodeOptions.decodeKey`; top‑level splitting applies to
  ///   literal `.` only (including those produced by percent‑decoding). Percent‑encoded dots may
  ///   still appear inside bracket segments here; we normalize `%2E`/`%2e` to `.` below when
  ///   `decodeDotInKeys` is enabled.
  ///   Whether top‑level dots split was decided earlier by `_splitKeyIntoSegments` (based on
  ///   `allowDots`). Numeric list indices are only honored for *bracketed* numerics like `[3]`.
  static dynamic _parseObject(
    final List<String> chain,
    final dynamic val,
    final DecodeOptions options,
    final bool valuesParsed,
  ) {
    final bool isListGrowthPath =
        chain.isNotEmpty && chain.last == '[]' && options.parseLists;

    // Determine the current list length if we are appending into `[]`.
    late final int currentListLength;

    if (isListGrowthPath && chain.length >= 2) {
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
            isListGrowthPath,
          );

    for (int i = chain.length - 1; i >= 0; --i) {
      dynamic obj;
      final String root = chain[i];

      // Anonymous list segment `[]` — either an empty list (when allowed) or a
      // single-element list with the leaf combined in.
      if (root == '[]' && options.parseLists) {
        if (Utils.isOverflow(leaf)) {
          // leaf can already be overflow (e.g. duplicates combine/listLimit),
          // so preserve it instead of re-wrapping into a list.
          obj = leaf;
        } else {
          obj = options.allowEmptyLists &&
                  (leaf == '' || (options.strictNullHandling && leaf == null))
              ? List<dynamic>.empty(growable: true)
              : Utils.combine([], leaf, listLimit: options.listLimit);
        }
      } else {
        obj = <String, dynamic>{};
        // Normalize bracketed segments ("[k]"). Note: depending on how key decoding is configured,
        // percent‑encoded dots *may still be present here* (e.g. `%2E` / `%2e`). We intentionally
        // handle the `%2E`→`.` mapping in this phase (see `decodedRoot` below) so that encoded
        // dots inside bracket segments can be treated as literal `.` without introducing extra
        // dot‑splits. Top‑level dot splitting (which only applies to literal `.`) already
        // happened in `_splitKeyIntoSegments`.
        final bool wasBracketed = root.startsWith('[') && root.endsWith(']');
        final String cleanRoot =
            wasBracketed ? root.substring(1, root.length - 1) : root;
        String decodedRoot = options.decodeDotInKeys && cleanRoot.contains('%2')
            ? cleanRoot.replaceAll('%2E', '.').replaceAll('%2e', '.')
            : cleanRoot;

        // Synthetic remainder normalization:
        // If this segment originated from an unterminated bracket group, it will look like
        // "[[...]]" after wrapping. After stripping the outermost brackets above, `decodedRoot`
        // can end with a trailing ']' that does not have a matching opening bracket in the
        // same string (e.g., "[b[c]"). In that case, drop the trailing ']' so the literal key
        // becomes "[b[c" (matches Kotlin/Python ports).
        if (wasBracketed &&
            root.startsWith('[[') &&
            decodedRoot.endsWith(']')) {
          int opens = 0, closes = 0;
          for (int k = 0; k < decodedRoot.length; k++) {
            final cu = decodedRoot.codeUnitAt(k);
            if (cu == 0x5B) opens++; // '['
            if (cu == 0x5D) closes++; // ']'
          }
          if (opens > closes) {
            decodedRoot = decodedRoot.substring(0, decodedRoot.length - 1);
          }
        }

        final int? index = (wasBracketed && options.parseLists)
            ? int.tryParse(decodedRoot)
            : null;
        if (!options.parseLists && decodedRoot == '') {
          obj = <String, dynamic>{'0': leaf};
        } else if (index != null &&
            index >= 0 &&
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
          // Normalise numeric-looking keys back to their canonical string form when not a list index
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
    final String? givenKey,
    final dynamic val,
    final DecodeOptions options, [
    final bool valuesParsed = false,
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
    required final String originalKey,
    required final bool allowDots,
    required final int maxDepth,
    required final bool strictDepth,
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
        if (cu == 0x5B /* '[' */) {
          level++;
        } else if (cu == 0x5D /* ']' */) {
          level--;
          if (level == 0) {
            close = i;
            break;
          }
        }
        i++;
      }

      if (close < 0) {
        // Unterminated group: keep the already-captured parent (if any),
        // and wrap the raw remainder starting at `open` as a single synthetic
        // bracket segment. Do not throw even if `strictDepth=true`.
        segments.add('[${key.substring(open)}]');
        return segments;
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
        // Note: if there are still uncollected bracket groups (open >= 0),
        // they are part of this same remainder path; no separate overflow
        // branch is needed.
        if (strictDepth && open >= 0) {
          throw RangeError(
              'Input depth exceeded $maxDepth and strictDepth is true');
        }
        segments.add('[$remainder]');
      }
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
  static String _dotToBracketTopLevel(final String s) {
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
            // Accept [A-Za-z0-9_] at the start of a segment; otherwise, keep '.' literal.
            bool isIdentStart(final int cu) => switch (cu) {
                  (>= 0x41 && <= 0x5A) || // A-Z
                  (>= 0x61 && <= 0x7A) || // a-z
                  (>= 0x30 && <= 0x39) || // 0-9
                  0x5F || // _
                  0x2D => // -
                    true,
                  _ => false,
                };
            if (start >= s.length || !isIdentStart(s.codeUnitAt(start))) {
              // keep as literal if next char isn't an ident start
              sb.write('.');
              continue;
            }
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
    required final bool ignoreQueryPrefix,
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

  /// Returns the earliest index in [key] that signals structured syntax.
  ///
  /// Structured syntax is:
  /// - `[` always
  /// - `.` when [allowDots] is true
  /// - `%2E`/`%2e` when [allowDots] is true and keys are still encoded
  ///
  /// Returns `-1` when no structured marker is present.
  static int _firstStructuredSplitIndex(
    final String key,
    final bool allowDots,
  ) {
    int splitAt = key.indexOf('[');
    if (!allowDots) return splitAt;

    final int dotIndex = key.indexOf('.');
    if (dotIndex >= 0 && (splitAt < 0 || dotIndex < splitAt)) {
      splitAt = dotIndex;
    }

    int encodedDotIndex = -1;
    if (key.contains('%')) {
      final int upper = key.indexOf('%2E');
      final int lower = key.indexOf('%2e');
      if (upper >= 0 && lower >= 0) {
        encodedDotIndex = upper < lower ? upper : lower;
      } else {
        encodedDotIndex = upper >= 0 ? upper : lower;
      }
    }

    if (encodedDotIndex >= 0 && (splitAt < 0 || encodedDotIndex < splitAt)) {
      splitAt = encodedDotIndex;
    }

    return splitAt;
  }

  /// Computes the collision root for a structured [key].
  ///
  /// This uses `_splitKeyIntoSegments` so root extraction follows the same
  /// dot/bracket/depth rules as full decode. For leading bracket keys like
  /// `[]` the root normalizes to `'0'` to match existing merge semantics.
  static String _leadingStructuredRoot(
    final String key,
    final DecodeOptions options,
  ) {
    final List<String> segments = _$Decode._splitKeyIntoSegments(
      originalKey: key,
      allowDots: options.allowDots,
      maxDepth: options.depth,
      strictDepth: options.strictDepth,
    );
    if (segments.isEmpty) return key;

    final String first = segments.first;
    if (!first.startsWith('[')) return first;

    final int last = first.lastIndexOf(']');
    final String cleanRoot =
        last > 0 ? first.substring(1, last) : first.substring(1);
    return cleanRoot.isEmpty ? '0' : cleanRoot;
  }

  /// Pre-scans tokenized keys for decode fast-path decisions.
  ///
  /// Produces:
  /// - [StructuredKeyScan.hasAnyStructuredSyntax] for flat-query early return
  /// - [StructuredKeyScan.structuredKeys] for per-key bypass checks
  /// - [StructuredKeyScan.structuredRoots] to preserve flat/structured root
  ///   collision behavior (for example `a=1` with `a[b]=2`)
  static StructuredKeyScan _scanStructuredKeys(
    final Map<String, dynamic> tempObj,
    final DecodeOptions options,
  ) {
    if (tempObj.isEmpty) return const StructuredKeyScan.empty();

    final bool allowDots = options.allowDots;
    final Set<String> roots = <String>{};
    final Set<String> structuredKeys = <String>{};
    for (final String key in tempObj.keys) {
      final int splitAt = _firstStructuredSplitIndex(key, allowDots);

      if (splitAt < 0) continue;
      structuredKeys.add(key);
      if (splitAt == 0) {
        roots.add(_leadingStructuredRoot(key, options));
      } else {
        roots.add(key.substring(0, splitAt));
      }
    }

    if (structuredKeys.isEmpty) return const StructuredKeyScan.empty();
    return StructuredKeyScan(
      hasAnyStructuredSyntax: true,
      structuredRoots: roots,
      structuredKeys: structuredKeys,
    );
  }
}
