part of '../utils.dart';

/// Stack frame for the iterative [Utils.merge] traversal.
///
/// Captures the current target/source pair plus intermediate iterators and
/// buffers so the merge can walk deeply nested structures without recursion.
final class _MergeFrame {
  _MergeFrame({
    required this.target,
    required this.source,
    required this.options,
    required this.onResult,
  });

  dynamic target;
  dynamic source;
  final DecodeOptions? options;
  final void Function(dynamic result) onResult;

  _MergePhase phase = _MergePhase.start;

  Map<String, dynamic>? mergeTarget;
  Iterator<MapEntry<dynamic, dynamic>>? mapIterator;
  int? overflowMax;

  SplayTreeMap<int, dynamic>? indexedTarget;
  List<dynamic>? sourceList;
  int listIndex = 0;
  bool targetIsSet = false;
}
