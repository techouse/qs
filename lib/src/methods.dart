import 'package:qs_dart/src/models/decode_options.dart';
import 'package:qs_dart/src/models/encode_options.dart';
import 'package:qs_dart/src/qs.dart';

/// Top-level convenience functions that mirror the JavaScript `qs` API.
///
/// These helpers forward directly to [QS.encode] and [QS.decode] so you can
/// call `encode(...)` / `decode(...)` without referencing the [QS] class.
/// They add no extra behavior—just a terser surface that keeps parity with
/// the original Node.js library.

/// Decode a query string into a map (convenience for [QS.decode]).
///
/// - **`input`** can be a raw query string (e.g. `"a=b&c[0]=d"`), a full URL
///   (its query part will be used), or any type supported by [QS.decode].
/// - **`options`** controls parsing behavior; if omitted, sensible defaults
///   that match the JavaScript `qs` library are used.
///
/// Returns an insertion-ordered `Map<String, dynamic>` (matching Dart's
/// default `Map` semantics) so round-trips preserve key order where possible.
///
/// **Notes**
/// - A `null` or empty `input` decodes to an empty map.
/// - For duplicate keys and list parsing semantics, see [DecodeOptions].
///
/// **Examples**
/// ```dart
/// final m1 = decode('a=b');                       // => {'a': 'b'}
/// final m2 = decode('a[0]=x&a[1]=y');             // => {'a': ['x', 'y']}
/// final m3 = decode(Uri.parse('https://x?x=1'));  // => {'x': '1'}
/// ```
Map<String, dynamic> decode(dynamic input, [DecodeOptions? options]) =>
    QS.decode(input, options);

/// Encode a Dart object into a query string (convenience for [QS.encode]).
///
/// - **`object`** can be a `Map`, list/iterable, or scalar—anything the core
///   encoder supports. Nested maps/lists are serialized using bracket syntax,
///   matching the JavaScript `qs` format.
/// - **`options`** controls percent-encoding, list formatting, sorting, etc.
///   If omitted, defaults match the JavaScript `qs` behavior.
///
/// Returns a query string. Passing `null` yields an empty string.
///
/// **Examples**
/// ```dart
/// final s1 = encode({'a': 'b'});                       // 'a=b'
/// final s2 = encode({'a': ['x', 'y']});                // 'a[0]=x&a[1]=y'
/// final s3 = encode({'user': {'id': 1, 'name': 'A'}}); // 'user[id]=1&user[name]=A'
/// ```
String encode(Object? object, [EncodeOptions? options]) =>
    QS.encode(object, options);
