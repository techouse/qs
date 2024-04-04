import 'package:equatable/equatable.dart';

/// Internal model to distinguish between [null] and not set value
final class Undefined with EquatableMixin {
  const Undefined();

  Undefined copyWith() => const Undefined();

  @override
  List<Object> get props => [];
}
