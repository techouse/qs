/// Sentinels for signalling the character set of form/query submissions.
///
/// Many back-ends historically inspect a hidden "utf8" field in an
/// `application/x-www-form-urlencoded` payload to infer the charset used by the
/// client. Two conventions emerged:
///
/// - HTML entity for CHECK MARK (U+2713) when the page’s charset does not
///   contain U+2713 (e.g. ISO‑8859‑1). Example raw value: `&#10003;`
/// - Percent-encoded UTF‑8 octets for U+2713 when the page is UTF‑8.
///
/// This enum models both conventions and exposes:
///  - `value`   → the *unencoded* form control value as it appears in the DOM
///  - `encoded` → the ready-to-append query fragment (e.g. `utf8=%E2%9C%93`)
///
/// References: Ruby on Rails' authenticity utf8 param and similar middleware in
/// historical web stacks.
///
/// Charset detection sentinels used by form encoders/servers.
///
/// Use these constants to append or compare against the conventional `utf8`
/// parameter that indicates how a request was encoded.
enum Sentinel {
  /// HTML entity for CHECK MARK (U+2713), used when the page (or form’s
  /// `accept-charset`) is ISO‑8859‑1 or another charset that lacks U+2713.
  ///
  /// Raw form control value: `&#10003;`
  /// Encoded query fragment: `utf8=%26%2310003%3B`
  iso(
    value: r'&#10003;',
    encoded: r'utf8=%26%2310003%3B',
  ),

  /// Percent-encoded UTF‑8 octets for CHECK MARK (U+2713), indicating the
  /// request itself is UTF‑8 encoded.
  ///
  /// Raw form control value: `✓` (U+2713)
  /// Encoded query fragment: `utf8=%E2%9C%93`
  charset(
    value: r'✓',
    encoded: r'utf8=%E2%9C%93',
  );

  const Sentinel({
    required this.value,
    required this.encoded,
  });

  /// Unencoded form control value (as it would appear in the page/DOM).
  final String value;

  /// Fully encoded query fragment to append, including the `utf8=` key.
  final String encoded;

  /// Returns the encoded query fragment (same as [encoded]).
  @override
  String toString() => encoded;
}
