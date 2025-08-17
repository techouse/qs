// Utilities mirroring small JavaScript conveniences used across the qs Dart port.
//
// - `IterableExtension.whereNotType<Q>()`: filters out elements of a given type
//   while preserving order (useful when handling heterogeneous collections during
//   parsing).
// - `ListExtension.slice(start, [end])`: JS-style `Array.prototype.slice` for
//   lists. Supports negative indices, clamps to bounds, and never throws for
//   out-of-range values. Returns a new list that references the same element
//   objects (non-deep copy).
// - `StringExtension.slice(start, [end])`: JS-style `String.prototype.slice`
//   for strings with the same semantics (negative indices and clamping).
//
// These helpers are intentionally tiny and non-mutating so the compiler can
// inline them; they keep call sites close to the semantics of the original
// Node `qs` implementation.

extension IterableExtension<T> on Iterable<T> {
  /// Returns a **lazy** [Iterable] view that filters out all elements of type [Q].
  ///
  /// Preserves iteration order and performs no allocation until iterated. Handy
  /// for discarding sentinels or mixed-type values during parsing.
  ///
  /// Example:
  /// ```dart
  /// final xs = [1, 'x', 2, null];
  /// final it = xs.whereNotType<String>();
  /// // iterates as: 1, 2, null
  /// ```
  Iterable<T> whereNotType<Q>() => where((T el) => el is! Q);
}

extension ListExtension<T> on List<T> {
  /// JS-style `Array.prototype.slice` for lists that never throws on bounds.
  ///
  /// * Supports negative indices for [start] and [end].
  /// * Both indices are clamped into `[0, length]`.
  /// * Returns a **new** list containing references to the original elements
  ///   (no deep copy).
  ///
  /// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/slice
  ///
  /// Examples:
  /// ```dart
  /// ['a','b','c'].slice(1);        // ['b','c']
  /// ['a','b','c'].slice(-2, -1);   // ['b']
  /// ['a','b','c'].slice(0, 99);    // ['a','b','c']
  /// ```
  List<T> slice([int start = 0, int? end]) {
    final int l = length;
    int s = start < 0 ? l + start : start;
    int e = end == null ? l : (end < 0 ? l + end : end);

    if (s < 0) {
      s = 0;
    } else if (s > l) {
      s = l;
    }
    if (e < 0) {
      e = 0;
    } else if (e > l) {
      e = l;
    }

    if (e <= s) return <T>[];
    return sublist(s, e);
  }
}

extension StringExtension on String {
  /// JS-style `String.prototype.slice` with negative indices and clamping.
  ///
  /// Behaves like JavaScript: negative [start]/[end] are offset from the end;
  /// indices are clamped to `[0, length]`; the operation never throws for
  /// out-of-range values.
  ///
  /// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/slice
  ///
  /// Examples:
  /// ```dart
  /// 'hello'.slice(1);        // 'ello'
  /// 'hello'.slice(-2);       // 'lo'
  /// 'hello'.slice(0, 99);    // 'hello'
  /// ```
  String slice(int start, [int? end]) {
    final int l = length;
    int s = start < 0 ? l + start : start;
    int e = end == null ? l : (end < 0 ? l + end : end);

    if (s < 0) {
      s = 0;
    } else if (s > l) {
      s = l;
    }
    if (e < 0) {
      e = 0;
    } else if (e > l) {
      e = l;
    }

    if (e <= s) return '';
    return substring(s, e);
  }
}
