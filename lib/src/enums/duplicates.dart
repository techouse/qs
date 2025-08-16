/// Strategy to resolve repeated keys when **decoding** a query string.
///
/// When a query contains the same key more than once (e.g. `a=1&a=2&a=3`),
/// the decoder must decide whether to keep all values or collapse them into
/// a single value. `Duplicates` expresses that choice.
///
/// Notes:
/// - Order is preserved as it appears in the source string.
/// - This affects **decoding** only. The encoder may legitimately produce
///   repeated keys when `ListFormat.repeatKey` is chosen.
///
/// See also: `DecodeOptions.duplicates`, `ListFormat`.
enum Duplicates {
  /// Keep **all** values as a `List`, preserving order.
  ///
  /// Example: `a=1&a=2` → `{ "a": ["1", "2"] }`
  combine,

  /// Keep the **first** value and ignore the rest.
  ///
  /// Example: `a=1&a=2` → `{ "a": "1" }`
  first,

  /// Keep the **last** value, overwriting earlier ones.
  ///
  /// Example: `a=1&a=2` → `{ "a": "2" }`
  last;

  @override
  String toString() => name;
}
