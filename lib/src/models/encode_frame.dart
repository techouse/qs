import 'dart:convert' show Encoding;

import 'package:meta/meta.dart' show internal;
import 'package:qs_dart/src/enums/format.dart';
import 'package:qs_dart/src/enums/list_format.dart';
import 'package:qs_dart/src/models/encode_options.dart';
import 'package:weak_map/weak_map.dart';

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
    required this.prefix,
    required this.generateArrayPrefix,
    required this.commaRoundTrip,
    required this.commaCompactNulls,
    required this.allowEmptyLists,
    required this.strictNullHandling,
    required this.skipNulls,
    required this.encodeDotInKeys,
    required this.encoder,
    required this.serializeDate,
    required this.sort,
    required this.filter,
    required this.allowDots,
    required this.format,
    required this.formatter,
    required this.encodeValuesOnly,
    required this.charset,
    required this.onResult,
  });

  /// Current value being encoded at this stack level.
  dynamic object;

  /// Whether the value is "missing" rather than explicitly present (qs semantics).
  final bool undefined;

  /// Weak side-channel for cycle detection across the traversal path.
  final WeakMap sideChannel;

  /// Fully-qualified key path prefix for this frame.
  final String prefix;

  /// List key generator (indices/brackets/repeat/comma).
  final ListFormatGenerator generateArrayPrefix;

  /// Emit a round-trip marker for comma lists with a single element.
  final bool commaRoundTrip;

  /// Drop nulls before joining comma lists.
  final bool commaCompactNulls;

  /// Whether empty lists should emit `key[]`.
  final bool allowEmptyLists;

  /// Emit bare keys for explicit nulls (no `=`).
  final bool strictNullHandling;

  /// Skip keys whose values are null.
  final bool skipNulls;

  /// Encode literal dots in keys as `%2E`.
  final bool encodeDotInKeys;

  /// Optional value encoder (and key encoder when `encodeValuesOnly` is false).
  final Encoder? encoder;

  /// Optional serializer for DateTime values.
  final DateSerializer? serializeDate;

  /// Optional key sorter for deterministic ordering.
  final Sorter? sort;

  /// Filter hook or whitelist for keys at this level.
  final dynamic filter;

  /// Whether to use dot notation between segments.
  final bool allowDots;

  /// Output formatting mode.
  final Format format;

  /// Formatter applied to already-encoded tokens.
  final Formatter formatter;

  /// Encode values only (leave keys unencoded).
  final bool encodeValuesOnly;

  /// Declared charset (used by encoder/formatter hooks).
  final Encoding charset;

  /// Callback invoked with this frame's encoded fragments.
  final void Function(List<String> result) onResult;

  /// Whether this frame has been initialized (keys computed, prefix adjusted).
  bool prepared = false;

  /// Whether this frame registered a cycle-tracking entry.
  bool tracked = false;

  /// The object used for cycle tracking (after filter/date transforms).
  Object? trackedObject;

  /// Keys/indices to iterate at this level.
  List<dynamic> objKeys = const [];

  /// Current index into [objKeys].
  int index = 0;

  /// Cached list form for iterable values (to avoid re-iteration).
  List<dynamic>? seqList;

  /// Effective comma list length after filtering nulls.
  int? commaEffectiveLength;

  /// Prefix after dot-encoding and comma round-trip adjustment.
  String? adjustedPrefix;

  /// Accumulated encoded fragments from child frames.
  List<String> values = [];
}
