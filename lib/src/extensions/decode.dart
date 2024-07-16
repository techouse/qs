part of '../qs.dart';

extension _$Decode on QS {
  static String _interpretNumericEntities(String str) => str.replaceAllMapped(
        RegExp(r'&#(\d+);'),
        (Match match) => String.fromCharCode(
          int.parse(match.group(1)!),
        ),
      );

  static dynamic _parseArrayValue(dynamic val, DecodeOptions options) =>
      val is String && val.isNotEmpty && options.comma && val.contains(',')
          ? val.split(',')
          : val;

  static Map<String, dynamic> _parseQueryStringValues(
    String str, [
    DecodeOptions options = const DecodeOptions(),
  ]) {
    final Map<String, dynamic> obj = {};

    final String cleanStr =
        (options.ignoreQueryPrefix ? str.replaceFirst('?', '') : str)
            .replaceAll(RegExp(r'%5B', caseSensitive: false), '[')
            .replaceAll(RegExp(r'%5D', caseSensitive: false), ']');
    final num? limit = options.parameterLimit == double.infinity
        ? null
        : options.parameterLimit;
    final Iterable<String> parts = limit != null && limit > 0
        ? cleanStr.split(options.delimiter).take(limit.toInt())
        : cleanStr.split(options.delimiter);
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
          _parseArrayValue(part.slice(pos + 1), options),
          (dynamic val) => options.decoder(val, charset: charset),
        );
      }

      if (val != null &&
          !Utils.isEmpty(val) &&
          options.interpretNumericEntities &&
          charset == latin1) {
        val = _interpretNumericEntities(val);
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
    dynamic leaf = valuesParsed ? val : _parseArrayValue(val, options);

    for (int i = chain.length - 1; i >= 0; --i) {
      dynamic obj;
      final String root = chain[i];

      if (root == '[]' && options.parseLists) {
        obj = options.allowEmptyLists &&
                (leaf == '' || (options.strictNullHandling && leaf == null))
            ? List<dynamic>.empty(growable: true)
            : [if (leaf is Iterable) ...leaf else leaf];
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

    // If there's a remainder, just add whatever is left
    if (segment != null) {
      keys.add('[${key.slice(segment.start)}]');
    }

    return _parseObject(keys, val, options, valuesParsed);
  }
}
