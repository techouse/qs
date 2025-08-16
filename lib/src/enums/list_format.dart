/// Signature used by [ListFormat] to construct the *key path* for a single
/// element in a list during encoding.
///
/// Parameters:
/// - [prefix]: The current container key (e.g. `"foo"`). This is always
///   provided by the encoder.
/// - [key]:   Optional element key. For [ListFormat.indices] it is the
///   element index as a string (`"0"`, `"1"`, …). Other formats ignore it.
///
/// Returns the key path string to be written for that element (without the
/// `'='` or the value), e.g. `"foo[0]"`, `"foo[]"`, or `"foo"`.
typedef ListFormatGenerator = String Function(String prefix, [String? key]);

/// Shapes how list/array keys are written during query-string encoding.
///
/// `ListFormat` does **not** decide how values are joined (that is handled by
/// the encoder). Instead, each case exposes a small `generator` that
/// determines the *key path* used for each element in a list under a given
/// `prefix`.
///
/// Examples below assume a list under key `foo` with values `[123, 456, 789]`:
///
/// * [ListFormat.brackets] → `foo[]=123&foo[]=456&foo[]=789`
/// * [ListFormat.comma]    → `foo=123,456,789` (single key; values comma-joined)
/// * [ListFormat.repeat]   → `foo=123&foo=456&foo=789` (repeat the key)
/// * [ListFormat.indices]  → `foo[0]=123&foo[1]=456&foo[2]=789`
///
/// The encoder passes `prefix` as the current key (e.g. `"foo"`). For
/// [ListFormat.indices], it also supplies `key` as the *index* (`"0"`,
/// `"1"`, ...). Other formats ignore `key`.
///
/// This mirrors the list formatting strategies used by other `qs` ports and the
/// original Node implementation.
enum ListFormat {
  /// Use brackets with no index for each element key, e.g.
  /// `foo[]=123&foo[]=456&foo[]=789`.
  brackets(_brackets),

  /// Keep the key as-is and rely on the encoder to comma-join the *values* into
  /// a single assignment, e.g. `foo=123,456,789`.
  comma(_comma),

  /// Repeat the same key for each element, e.g.
  /// `foo=123&foo=456&foo=789`.
  repeat(_repeat),

  /// Write a numeric index inside brackets, e.g.
  /// `foo[0]=123&foo[1]=456&foo[2]=789`.
  indices(_indices);

  const ListFormat(this.generator);

  /// Returns a function that transforms a container `prefix` (e.g. `"foo"`)
  /// and an optional element `key` into the key path for a single list item.
  ///
  /// * For [ListFormat.indices], `key` is the element index string.
  /// * For other formats, `key` is ignored.
  final ListFormatGenerator generator;

  @override
  String toString() => name;

  /// `foo[]`
  static String _brackets(String prefix, [String? key]) => '$prefix[]';

  /// `foo` (the encoder will join values with commas)
  static String _comma(String prefix, [String? key]) => prefix;

  /// `foo[<index>]`
  static String _indices(String prefix, [String? key]) => '$prefix[$key]';

  /// `foo` (the encoder will repeat the key per element)
  static String _repeat(String prefix, [String? key]) => prefix;
}
