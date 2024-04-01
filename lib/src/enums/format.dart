typedef Formatter = String Function(String value);

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
