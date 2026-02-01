part of '../utils.dart';

/// Internal phases for the iterative merge walker.
///
/// These drive the state machine used by [Utils.merge] to avoid recursion
/// while preserving `qs` merge semantics for maps and iterables.
enum _MergePhase {
  /// Initial dispatch and shape normalization.
  start,

  /// Iterating over map entries during a merge step.
  mapIter,

  /// Iterating over list/set indices during a merge step.
  listIter,
}
