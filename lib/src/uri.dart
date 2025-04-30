import 'package:qs_dart/qs_dart.dart';

extension UriExtension on Uri {
  /// The URI query split into a map.
  /// Providing custom [options] will override the default behavior.
  Map<String, dynamic> queryParametersQs([DecodeOptions? options]) =>
      query.isNotEmpty ? QS.decode(query, options) : const <String, dynamic>{};

  /// The normalized string representation of the URI.
  /// Providing custom [options] will override the default behavior.
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
