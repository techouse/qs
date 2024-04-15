import 'dart:math' show min;
import 'package:qs_dart/src/models/undefined.dart';

extension IterableExtension<T> on Iterable<T> {
  /// Returns a new [Iterable] without [Undefined] elements.
  Iterable<T> whereNotUndefined() => where((T el) => el is! Undefined);
}

extension ListExtension<T> on List<T> {
  /// Returns a new [List] without [Undefined] elements.
  List<T> whereNotUndefined() => where((T el) => el is! Undefined).toList();
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
