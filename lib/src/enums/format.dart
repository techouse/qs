/// Signature for a *post–percent-encoding* formatter that normalizes a single
/// URI component string.
///
/// The `value` must already be percent-encoded (i.e. spaces are `%20`, reserved
/// characters are escaped as needed). A formatter may then apply output
/// normalization such as converting `%20` to `+` for the classic
/// `application/x-www-form-urlencoded` style.
///
/// Return the formatted string to be emitted in the final query.
typedef Formatter = String Function(String value);

/// Output formatting strategies applied *after* RFC 3986 percent-encoding.
///
/// The encoder encodes components according to RFC 3986 and then applies the
/// selected `Format.formatter` to each token when building the final string.
/// Use:
///  * [Format.rfc3986] for strict, standards-compliant output (default).
///  * [Format.rfc1738] to emulate legacy `x-www-form-urlencoded` where
///    spaces are rendered as `+`.
enum Format {
  /// https://datatracker.ietf.org/doc/html/rfc1738
  ///
  /// Legacy `application/x-www-form-urlencoded` style: converts `%20` to `+`
  /// for spaces and leaves all other percent-escapes intact. Useful when
  /// interoperating with systems that still expect `+` for spaces.
  rfc1738(_rfc1738Formatter),

  /// https://datatracker.ietf.org/doc/html/rfc3986
  /// (default)
  ///
  /// Strict RFC 3986 output: leaves the percent-encoded string unchanged,
  /// including spaces as `%20`. Prefer this unless you must match legacy forms.
  rfc3986(_rfc3986Formatter);

  /// Constructs a `Format` with the function that will be applied to each
  /// already-encoded component during emission.
  const Format(this.formatter);

  /// The normalization function applied to each percent-encoded token.
  final Formatter formatter;

  /// Returns the case name (`"rfc1738"` / `"rfc3986"`), handy for logging.
  @override
  String toString() => name;

  /// Rewrites `%20` to `+` (space) and returns the result unchanged otherwise.
  /// No decoding is performed.
  static String _rfc1738Formatter(String value) => value.replaceAll('%20', '+');

  /// Identity formatter: returns the input unchanged.
  static String _rfc3986Formatter(String value) => value;
}
