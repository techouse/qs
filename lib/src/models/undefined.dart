import 'package:equatable/equatable.dart';

/// Sentinel used to distinguish between a **missing** value and an explicit `null`.
///
/// The encoder/merger treats `Undefined` as “omit this key entirely”, whereas
/// `null` is typically serialized as an empty value (e.g. `a=`) unless strict
/// null handling is enabled. This mirrors the behaviour of other ports of `qs`.
///
/// The type is immutable and intentionally trivial. Equality is structural via
/// `Equatable`; all instances of [Undefined] compare equal, so you can freely
/// create them with `const Undefined()`.
final class Undefined with EquatableMixin {
  /// Creates a new sentinel instance. All instances are equal.
  const Undefined();

  /// No-op copy that returns another equal sentinel. Kept for API symmetry.
  Undefined copyWith() => const Undefined();

  /// No distinguishing fields — all [Undefined] instances are equal.
  @override
  List<Object> get props => const [];
}
