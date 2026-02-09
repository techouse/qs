import 'package:meta/meta.dart' show internal;

/// Internal phases for the iterative merge walker.
///
/// These drive the state machine used by [Utils.merge] to avoid recursion
/// while preserving `qs` merge semantics for maps and iterables.
@internal
enum MergePhase {
  /// Initial dispatch and shape normalization.
  start,

  /// Iterating over map entries during a merge step.
  mapIter,

  /// Iterating over list/set indices during a merge step.
  listIter,
}
