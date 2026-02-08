import 'dart:collection' show SplayTreeMap;

import 'package:meta/meta.dart' show internal;
import 'package:qs_dart/qs_dart.dart' show DecodeOptions;
import 'package:qs_dart/src/enums/merge_phase.dart';

/// Stack frame for the iterative [Utils.merge] traversal.
///
/// Captures the current target/source pair plus intermediate iterators and
/// buffers so the merge can walk deeply nested structures without recursion.
@internal
final class MergeFrame {
  MergeFrame({
    required this.target,
    required this.source,
    required this.options,
    required this.onResult,
  });

  dynamic target;
  dynamic source;
  final DecodeOptions? options;
  final void Function(dynamic result) onResult;

  MergePhase phase = MergePhase.start;

  Map<String, dynamic>? mergeTarget;
  Iterator<MapEntry<dynamic, dynamic>>? mapIterator;
  int? overflowMax;

  SplayTreeMap<int, dynamic>? indexedTarget;
  List<dynamic>? sourceList;
  int listIndex = 0;
  bool targetIsSet = false;
}
