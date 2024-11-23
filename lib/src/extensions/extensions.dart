import 'dart:math' show min;

extension IterableExtension<T> on Iterable<T> {
  /// Returns a new [Iterable] without elements of type [Q].
  Iterable<T> whereNotType<Q>() => where((T el) => el is! Q);
}

extension ListExtension<T> on List<T> {
  /// Extracts a section of a list and returns a new list.
  ///
  /// Modeled after JavaScript's `Array.prototype.slice()` method.
  /// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/slice
  List<T> slice([int start = 0, int? end]) => sublist(
        (start < 0 ? length + start : start).clamp(0, length),
        (end == null ? length : (end < 0 ? length + end : end))
            .clamp(0, length),
      );
}

extension StringExtension on String {
  /// Extracts a section of a string and returns a new string.
  ///
  /// Modeled after JavaScript's `String.prototype.slice()` method.
  /// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/slice
  String slice(int start, [int? end]) {
    end ??= length;
    if (end < 0) {
      end = length + end;
    }
    if (start < 0) {
      start = length + start;
    }
    return substring(start, min(end, length));
  }
}
