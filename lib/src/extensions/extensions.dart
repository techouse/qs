import 'package:qs_dart/src/models/undefined.dart';

extension IterableExtension<T> on Iterable<T> {
  /// Returns a new [Iterable] without [Undefined] elements.
  Iterable<T> whereNotUndefined() => where((T el) => el is! Undefined);
}

extension ListExtension<T> on List<T> {
  /// Returns a new [List] without [Undefined] elements.
  List<T> whereNotUndefined() => where((T el) => el is! Undefined).toList();
}
