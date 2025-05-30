part of '../qs.dart';

extension _$Decode on QS {
  static String _interpretNumericEntities(String str) => str.replaceAllMapped(
        RegExp(r'&#(\d+);'),
        (Match match) => String.fromCharCode(
          int.parse(match.group(1)!),
        ),
      );

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
        (options.ignoreQueryPrefix ? str.replaceFirst('?', '') : str)
            .replaceAll(RegExp(r'%5B', caseSensitive: false), '[')
            .replaceAll(RegExp(r'%5D', caseSensitive: false), ']');

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
        val = _interpretNumericEntities(
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
    DecodeOptions options,
    bool valuesParsed,
  ) {
    if (givenKey?.isEmpty ?? true) {
      return;
    }

    // Transform dot notation to bracket notation
    String key = options.allowDots
        ? givenKey!.replaceAllMapped(
            RegExp(r'\.([^.[]+)'),
            (Match match) => '[${match[1]}]',
          )
        : givenKey!;

    // The regex chunks
    final RegExp brackets = RecursiveRegex(
      startDelimiter: '[',
      endDelimiter: ']',
    );

    // Get the parent
    Match? segment = options.depth > 0 ? brackets.firstMatch(key) : null;
    final String parent = segment != null ? key.slice(0, segment.start) : key;

    // Stash the parent if it exists
    final List<String> keys = [];
    if (parent.isNotEmpty) {
      keys.add(parent);
    }

    // Loop through children appending to the array until we hit depth
    int i = 0;
    while (options.depth > 0 &&
        (segment = brackets.firstMatch(key)) != null &&
        i < options.depth) {
      i += 1;
      if (segment != null) {
        keys.add(segment.group(0)!);
        // Update the key to start searching from the next position
        key = key.slice(segment.end);
      }
    }

    // If there's a remainder, check strictDepth option for throw, else just add whatever is left
    if (segment != null) {
      if (options.strictDepth) {
        throw RangeError(
          'Input depth exceeded depth option of ${options.depth} and strictDepth is true',
        );
      }
      keys.add('[${key.slice(segment.start)}]');
    }

    return _parseObject(keys, val, options, valuesParsed);
  }
}
