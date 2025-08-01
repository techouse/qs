part of '../qs.dart';

typedef SplitResult = ({List<String> parts, bool exceeded});

final RegExp _dotToBracket = RegExp(r'\.([^.\[]+)');

extension _$Decode on QS {
  static dynamic _parseListValue(
    dynamic val,
    DecodeOptions options,
    int currentListLength,
  ) {
    if (val is String && val.isNotEmpty && options.comma && val.contains(',')) {
      final List<String> splitVal = val.split(',');
      if (options.throwOnLimitExceeded && splitVal.length > options.listLimit) {
        throw RangeError(
          'List limit exceeded. '
          'Only ${options.listLimit} element${options.listLimit == 1 ? '' : 's'} allowed in a list.',
        );
      }
      return splitVal;
    }

    if (options.throwOnLimitExceeded &&
        currentListLength >= options.listLimit) {
      throw RangeError(
        'List limit exceeded. '
        'Only ${options.listLimit} element${options.listLimit == 1 ? '' : 's'} allowed in a list.',
      );
    }

    return val;
  }

  static Map<String, dynamic> _parseQueryStringValues(
    String str, [
    DecodeOptions options = const DecodeOptions(),
  ]) {
    final Map<String, dynamic> obj = {};

    final String cleanStr =
        _cleanQueryString(str, ignoreQueryPrefix: options.ignoreQueryPrefix);

    final int? limit = options.parameterLimit == double.infinity
        ? null
        : options.parameterLimit.toInt();

    if (limit != null && limit <= 0) {
      throw ArgumentError('Parameter limit must be a positive integer.');
    }

    final Iterable<String> parts = limit != null && limit > 0
        ? cleanStr
            .split(options.delimiter)
            .take(options.throwOnLimitExceeded ? limit + 1 : limit)
        : cleanStr.split(options.delimiter);

    if (options.throwOnLimitExceeded && limit != null && parts.length > limit) {
      throw RangeError(
        'Parameter limit exceeded. Only $limit parameter${limit == 1 ? '' : 's'} allowed.',
      );
    }

    int skipIndex = -1; // Keep track of where the utf8 sentinel was found
    int i;

    Encoding charset = options.charset;

    if (options.charsetSentinel) {
      for (i = 0; i < parts.length; ++i) {
        if (parts.elementAt(i).startsWith('utf8=')) {
          if (parts.elementAt(i) == Sentinel.charset.toString()) {
            charset = utf8;
          } else if (parts.elementAt(i) == Sentinel.iso.toString()) {
            charset = latin1;
          }
          skipIndex = i;
          break;
        }
      }
    }

    for (i = 0; i < parts.length; ++i) {
      if (i == skipIndex) {
        continue;
      }
      final String part = parts.elementAt(i);
      final int bracketEqualsPos = part.indexOf(']=');
      final int pos =
          bracketEqualsPos == -1 ? part.indexOf('=') : bracketEqualsPos + 1;

      late final String key;
      dynamic val;
      if (pos == -1) {
        key = options.decoder(part, charset: charset);
        val = options.strictNullHandling ? null : '';
      } else {
        key = options.decoder(part.slice(0, pos), charset: charset);
        val = Utils.apply<dynamic>(
          _parseListValue(
            part.slice(pos + 1),
            options,
            obj.containsKey(key) && obj[key] is List
                ? (obj[key] as List).length
                : 0,
          ),
          (dynamic val) => options.decoder(val, charset: charset),
        );
      }

      if (val != null &&
          !Utils.isEmpty(val) &&
          options.interpretNumericEntities &&
          charset == latin1) {
        val = Utils.interpretNumericEntities(
          val is Iterable
              ? val.map((e) => e.toString()).join(',')
              : val.toString(),
        );
      }

      if (part.contains('[]=')) {
        val = val is Iterable ? [val] : val;
      }

      final bool existing = obj.containsKey(key);
      if (existing && options.duplicates == Duplicates.combine) {
        obj[key] = Utils.combine(obj[key], val);
      } else if (!existing || options.duplicates == Duplicates.last) {
        obj[key] = val;
      }
    }

    return obj;
  }

  static dynamic _parseObject(
    List<String> chain,
    dynamic val,
    DecodeOptions options,
    bool valuesParsed,
  ) {
    late final int currentListLength;

    if (chain.isNotEmpty && chain.last == '[]') {
      final int? parentKey = int.tryParse(chain.slice(0, -1).join(''));

      currentListLength = parentKey != null &&
              val is List &&
              val.firstWhereIndexedOrNull((int i, _) => i == parentKey) != null
          ? val.elementAt(parentKey).length
          : 0;
    } else {
      currentListLength = 0;
    }

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

      if (root == '[]' && options.parseLists) {
        obj = options.allowEmptyLists &&
                (leaf == '' || (options.strictNullHandling && leaf == null))
            ? List<dynamic>.empty(growable: true)
            : Utils.combine([], leaf);
      } else {
        obj = <String, dynamic>{};
        final String cleanRoot = root.startsWith('[') && root.endsWith(']')
            ? root.slice(1, root.length - 1)
            : root;
        final String decodedRoot = options.decodeDotInKeys
            ? cleanRoot.replaceAll('%2E', '.')
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

  static List<String> _splitKeyIntoSegments({
    required String originalKey,
    required bool allowDots,
    required int maxDepth,
    required bool strictDepth,
  }) {
    final String key = allowDots
        ? originalKey.replaceAllMapped(_dotToBracket, (m) => '[${m[1]}]')
        : originalKey;

    // Depth=0: do not split and do not throw (qs semantics)
    if (maxDepth <= 0) {
      return <String>[key];
    }

    final List<String> segments = [];

    // Parent (everything before first '['), may be empty
    final int first = key.indexOf('[');
    final String parent = first >= 0 ? key.substring(0, first) : key;
    if (parent.isNotEmpty) segments.add(parent);

    final int n = key.length;
    int open = first;
    int depth = 0;

    while (open >= 0 && depth < maxDepth) {
      // Balance nested brackets inside this group: "[ ... possibly [] ... ]"
      int level = 1;
      int i = open + 1;
      int close = -1;

      while (i < n) {
        final int ch = key.codeUnitAt(i);
        if (ch == 0x5B) {
          // '['
          level++;
        } else if (ch == 0x5D) {
          // ']'
          level--;
          if (level == 0) {
            close = i;
            break;
          }
        }
        i++;
      }

      if (close < 0) {
        // Unterminated group, stop collecting groups
        break;
      }

      segments.add(key.substring(open, close + 1)); // includes enclosing [ ]
      depth++;

      // find next group, starting after this one
      open = key.indexOf('[', close + 1);
    }

    if (open >= 0) {
      // We still have remainder starting with '['
      if (strictDepth) {
        throw RangeError(
            'Input depth exceeded $maxDepth and strictDepth is true');
      }
      // Stash the remainder as a single segment (qs behavior)
      segments.add('[${key.substring(open)}]');
    }

    return segments;
  }

  /// Drops a leading '?' if requested, then replaces %5B/%5b -> '[' and
  /// %5D/%5d -> ']' in a single pass (case-insensitive).
  static String _cleanQueryString(
    String str, {
    required bool ignoreQueryPrefix,
  }) {
    // Remove leading '?' only once (qs semantics)
    if (ignoreQueryPrefix &&
        str.isNotEmpty &&
        str.codeUnitAt(0) == 0x3F /* '?' */) {
      str = str.substring(1);
    }
    if (str.length < 3) return str;

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
}
