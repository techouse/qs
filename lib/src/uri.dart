import 'package:qs_dart/qs_dart.dart';

/// Extensions that integrate `qs_dart` with `Uri`.
///
/// - `queryParametersQs` decodes the raw `query` string using `QS.decode`.
/// - `toStringQs` re-encodes `queryParametersAll` using `QS.encode` with configurable options.
///
/// These helpers avoid the lossy behavior of `Uri.queryParameters` (which flattens duplicate keys)
/// and let you round‑trip complex nested structures.

extension UriExtension on Uri {
  /// Decodes the raw `query` string into a `Map<String, dynamic>` using `QS.decode`.
  ///
  /// If the URI has no query, returns an empty map.
  /// Pass [options] to customize decoding (delimiters, list handling, depth, etc.).
  ///
  /// Example:
  /// ```dart
  /// final uri = Uri.parse('https://x.dev/search?tags[0]=a&tags[1]=b');
  /// final m = uri.queryParametersQs(); // => { "tags": ["a","b"] }
  /// ```
  Map<String, dynamic> queryParametersQs([DecodeOptions? options]) =>
      query.isNotEmpty ? QS.decode(query, options) : const <String, dynamic>{};

  /// Returns a normalized string for this `Uri` with the query encoded by `QS.encode`.
  ///
  /// Uses `queryParametersAll` (not `queryParameters`) so duplicate keys and ordered lists are preserved.
  /// When there are no query parameters, the resulting URI has no `?` section.
  ///
  /// The default [options] mirror common web conventions:
  /// - `listFormat: ListFormat.repeat`  → `a=1&a=2`
  /// - `skipNulls: false`               → keep `null` keys as empty
  /// - `strictNullHandling: false`      → `null` serializes as empty value, not omitted
  ///
  /// Example:
  /// ```dart
  /// final uri = Uri.https('example.com', '/p', {'a': ['1','2']});
  /// uri.toStringQs(); // => 'https://example.com/p?a=1&a=2'
  /// ```
  String toStringQs([
    EncodeOptions? options = const EncodeOptions(
      listFormat: ListFormat.repeat,
      skipNulls: false,
      strictNullHandling: false,
    ),
  ]) =>
      replace(
        query: queryParameters.isNotEmpty
            ? QS.encode(queryParametersAll, options)
            : null,
        queryParameters: null,
      ).toString();
}
