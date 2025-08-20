/// Decoding context used by the query string parser and utilities.
///
/// This enum indicates whether a piece of text is being decoded as a **key**
/// (or key segment) or as a **value**. The distinction matters for
/// percent‑encoded dots (`%2E` / `%2e`) that appear **in keys**:
///
/// * When decoding **keys**, implementations often *preserve* encoded dots so
///   higher‑level options like `allowDots` and `decodeDotInKeys` can be applied
///   consistently during key‑splitting.
/// * When decoding **values**, implementations typically perform full percent
///   decoding.
///
/// ### Usage
///
/// ```dart
/// import 'package:qs_dart/qs.dart';
///
/// DecodeKind k = DecodeKind.key; // decode a key/segment
/// DecodeKind v = DecodeKind.value; // decode a value
/// ```
///
/// ### Notes
///
/// Prefer identity comparisons with enum members (e.g. `kind == DecodeKind.key`).
/// The underlying `name`/`index` are implementation details and should not be
/// relied upon for logic.
enum DecodeKind {
  /// Decode a **key** (or key segment). Implementations may preserve
  /// percent‑encoded dots (`%2E` / `%2e`) so that dot‑splitting semantics can be
  /// applied later according to parser options.
  key,

  /// Decode a **value**. Implementations typically perform full percent
  /// decoding.
  value,
}
