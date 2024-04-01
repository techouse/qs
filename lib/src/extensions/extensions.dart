import 'package:qs_dart/src/models/undefined.dart';

extension IterableExtension<T> on Iterable<T> {
  Iterable<T> whereNotUndefined() => where((T el) => el is! Undefined);
}

extension ListExtension<T> on List<T> {
  List<T> whereNotUndefined() => where((T el) => el is! Undefined).toList();
}
