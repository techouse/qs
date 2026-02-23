import 'package:meta/meta.dart' show internal;
import 'package:qs_dart/src/models/encode_config.dart';
import 'package:qs_dart/src/models/key_path_node.dart';

/// Internal encoder stack frame used by the iterative `_encode` traversal.
///
/// Stores the current object, derived key paths, and accumulated child results
/// so the encoder can walk deep graphs without recursion while preserving
/// Node `qs` ordering and cycle detection behavior.
@internal
final class EncodeFrame {
  EncodeFrame({
    required this.object,
    required this.undefined,
    required this.sideChannel,
    required this.path,
    required this.config,
    required this.onResult,
  });

  /// Current value being encoded at this stack level.
  dynamic object;

  /// Whether the value is "missing" rather than explicitly present (qs semantics).
  final bool undefined;

  /// Active-path set used for cycle detection across the traversal path.
  final Set<Object> sideChannel;

  /// Fully-qualified key path for this frame.
  final KeyPathNode path;

  /// Shared immutable options for this frame and its siblings.
  final EncodeConfig config;

  /// Callback invoked with this frame's encoded fragments.
  final void Function(List<String> result) onResult;

  /// Whether this frame has been initialized (keys/path computed).
  bool prepared = false;

  /// The object identity registered in [sideChannel] for cycle tracking.
  Object? trackedObject;

  /// Keys/indices to iterate at this level.
  List<dynamic> objKeys = const [];

  /// Current index into [objKeys].
  int index = 0;

  /// Cached list form for iterable values (to avoid re-iteration).
  List<dynamic>? seqList;

  /// Effective comma list length after filtering nulls.
  int? commaEffectiveLength;

  /// Path after dot-encoding and comma round-trip adjustment.
  KeyPathNode? adjustedPath;

  /// Accumulated encoded fragments from child frames.
  List<String> values = [];
}
