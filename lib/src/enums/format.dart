typedef Formatter = String Function(String value);

/// An enum of all supported URI component encoding formats.
enum Format {
  rfc1738(_rfc1738Formatter),

  /// default
  rfc3986(_rfc3986Formatter);

  const Format(this.formatter);

  final Formatter formatter;

  @override
  String toString() => name;

  static String _rfc1738Formatter(String value) => value.replaceAll('%20', '+');

  static String _rfc3986Formatter(String value) => value;
}
