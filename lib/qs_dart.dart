/// A faithful, cross‑port implementation of Node.js **`qs`** for Dart.
///
/// This package parses query strings into nested Dart structures and
/// stringifies Dart structures back into query strings — matching the
/// behavior of the canonical `qs` library where practical.
///
/// ### Highlights
/// - RFC 3986 encoding by default, with RFC 1738 (`+` for spaces) via [Format].
/// - Deep bracket notation for nested maps/lists (e.g. `a[b][0]=c`).
/// - Multiple list styles via [ListFormat] (brackets, indices, repeat‑key, comma).
/// - Deterministic key handling and duplicate‑key policy via [Duplicates].
/// - Charset sentinels and helpers via [Sentinel].
///
/// ### Primary API
/// - [decode] — Parse a query string into a `Map<String, dynamic>`.
/// - [encode] — Stringify a Dart value (map/list/scalars) into a query string.
///
/// Tune behavior with [DecodeOptions] and [EncodeOptions].
/// See the repository README for complete examples and edge‑case notes.
library;

export 'src/enums/duplicates.dart';
export 'src/enums/format.dart';
export 'src/enums/list_format.dart';
export 'src/enums/sentinel.dart';
export 'src/methods.dart' show decode, encode;
export 'src/models/decode_options.dart';
export 'src/models/encode_options.dart';
export 'src/models/undefined.dart';
export 'src/qs.dart';
export 'src/uri.dart';
