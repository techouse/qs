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
  Iterable<T> whereNotType<Q>() => where((final T el) => el is! Q);
}
