part of '../qs.dart';

/// Encoding engine used by [QS.encode].
///
/// This module mirrors the shape and behavior of the Node `qs` encoder:
/// - Stable output: caller-supplied traversal order and optional sort callback.
/// - Rich key syntax: bracket/indices/repeat/comma list formats; dotted keys; dot-encoding.
/// - Safety: cycle detection via a side-channel; depth driven by the object graph only.
/// - Ergonomics: optional custom value encoder, date serializer, and formatter.
///
/// Implementation notes:
/// - *undefined* (bool parameter): marks a missing value (e.g., absent map key) rather than
///   a present-but-null value. This affects whether we emit a key or skip it.
/// - *sideChannel* (`Set<Object>`): tracks the active traversal path for O(1)
///   cycle detection.
/// - *prefix*: seeds the root [KeyPathNode] for traversal; child paths are
///   advanced via `KeyPathNode.append(...)`.

extension _$Encode on QS {
  static final ListFormatGenerator _indicesGenerator =
      ListFormat.indices.generator;
  static final ListFormatGenerator _bracketsGenerator =
      ListFormat.brackets.generator;
  static final ListFormatGenerator _repeatGenerator =
      ListFormat.repeat.generator;
  static final ListFormatGenerator _commaGenerator = ListFormat.comma.generator;

  /// Core encoder (iterative, stack-based).
  ///
  /// Returns encoded fragments as either a single `String` or a `List<String>`;
  /// the top-level caller joins fragments with the configured delimiter.
  ///
  /// Parameters (most mirror Node `qs`):
  /// - [object]: The current value to encode (map/iterable/scalar/byte buffer/date).
  /// - [undefined]: Marks a *missing* value (e.g., absent map key). When `true`, nothing is emitted.
  /// - [sideChannel]: Active-path set used for cycle detection across traversal frames.
  /// - [prefix]: Root path seed used to initialize the first [KeyPathNode].
  /// - [rootConfig]: Immutable encode options shared across traversal frames.
  static dynamic _encode(
    dynamic object, {
    required bool undefined,
    required Set<Object> sideChannel,
    required String prefix,
    required EncodeConfig rootConfig,
  }) {
    // Guarded fast path for deep single-key map chains under compatible options.
    final String? linear = _tryEncodeLinearChain(
      object,
      undefined: undefined,
      sideChannel: sideChannel,
      prefix: prefix,
      config: rootConfig,
    );
    if (linear != null) return linear;

    // Explicit DFS stack for iterative encode traversal.
    final List<EncodeFrame> stack = [
      EncodeFrame(
        object: object,
        undefined: undefined,
        sideChannel: sideChannel,
        path: KeyPathNode.fromMaterialized(prefix),
        config: rootConfig,
      ),
    ];

    // Child-to-parent result handoff for phase-driven frame traversal.
    dynamic lastResult;
    // Last key seen by bracketSegment() MRU cache.
    String? lastBracketKey;
    // Last computed bracket segment (for example "[a]") for MRU reuse.
    String? lastBracketSegment;
    // Last key seen by dotSegment() MRU cache.
    String? lastDotKey;
    // Last computed dot segment (for example ".a") for MRU reuse.
    String? lastDotSegment;

    // Single-entry MRU cache for bracket key segments:
    // if the current key matches the previous key, reuse the last "[key]"
    // string; otherwise build a new one and update the cached pair.
    String bracketSegment(String encodedKey) {
      if (lastBracketKey == encodedKey && lastBracketSegment != null) {
        return lastBracketSegment!;
      }
      final String segment = '[$encodedKey]';
      lastBracketKey = encodedKey;
      lastBracketSegment = segment;
      return segment;
    }

    // Single-entry MRU cache for dot key segments, mirroring bracketSegment.
    String dotSegment(String encodedKey) {
      if (lastDotKey == encodedKey && lastDotSegment != null) {
        return lastDotSegment!;
      }
      final String segment = '.$encodedKey';
      lastDotKey = encodedKey;
      lastDotSegment = segment;
      return segment;
    }

    // Finalize a frame: clear active-path cycle tracking for this node,
    // pop it from the stack, and publish its encoded result to the parent.
    void finishFrame(EncodeFrame frame, dynamic result) {
      final Object? tracked = frame.trackedObject;
      if (tracked != null) {
        frame.sideChannel.remove(tracked);
        frame.trackedObject = null;
      }
      stack.removeLast();
      lastResult = result;
    }

    while (stack.isNotEmpty) {
      final EncodeFrame frame = stack.last;
      final EncodeConfig config = frame.config;

      switch (frame.phase) {
        case EncodePhase.start:
          dynamic obj = frame.object;
          String? pathText;
          String materializedPath() => pathText ??= frame.path.materialize();

          final bool trackObject =
              obj is Map || (obj is Iterable && obj is! String);
          if (trackObject) {
            final Object tracked = obj as Object;
            if (frame.sideChannel.contains(tracked)) {
              throw RangeError('Cyclic object value');
            }
            frame.sideChannel.add(tracked);
            frame.trackedObject = tracked;
          }

          // After cycle detection on the original node identity, apply filter/date/comma transforms.
          if (config.filter is Function) {
            obj = config.filter.call(materializedPath(), obj);
          } else if (obj is DateTime) {
            obj = switch (config.serializeDate) {
              null => obj.toIso8601String(),
              _ => config.serializeDate!(obj),
            };
          } else if (identical(config.generateArrayPrefix, _commaGenerator) &&
              obj is Iterable) {
            obj = Utils.apply(
              obj,
              (value) => value is DateTime
                  ? (config.serializeDate?.call(value) ??
                      value.toIso8601String())
                  : value,
            );
          }

          // Present-but-null handling:
          // - If the value is *present* and null and strictNullHandling is on, emit only the key.
          // - Otherwise, treat null as an empty string.
          if (!frame.undefined && obj == null) {
            if (config.strictNullHandling) {
              final String keyOnly =
                  config.encoder != null && !config.encodeValuesOnly
                      ? config.encoder!(materializedPath())
                      : materializedPath();
              finishFrame(frame, keyOnly);
              continue;
            }
            obj = '';
          }

          // Fast path for primitives and byte buffers → return a single key=value fragment.
          if (Utils.isNonNullishPrimitive(obj, config.skipNulls) ||
              obj is ByteBuffer) {
            late final String fragment;
            if (config.encoder != null) {
              final String keyValue = config.encodeValuesOnly
                  ? materializedPath()
                  : config.encoder!(materializedPath());
              fragment =
                  '${config.formatter(keyValue)}=${config.formatter(config.encoder!(obj))}';
            } else {
              final String valueString = obj is ByteBuffer
                  ? (config.charset == utf8
                      ? utf8.decode(
                          obj.asUint8List(),
                          allowMalformed: true,
                        )
                      : latin1.decode(obj.asUint8List()))
                  : obj.toString();
              fragment =
                  '${config.formatter(materializedPath())}=${config.formatter(valueString)}';
            }
            finishFrame(frame, fragment);
            continue;
          }

          // Collect per-branch fragments; empty list signifies "emit nothing" for this path.
          if (frame.undefined) {
            finishFrame(frame, const <String>[]);
            continue;
          }

          // Cache list form once for non-Map, non-String iterables to avoid repeated enumeration
          List<dynamic>? seqList;
          int? commaEffectiveLength;
          final bool isSeq = obj is Iterable && obj is! String && obj is! Map;
          if (isSeq) {
            seqList = obj is List ? obj : obj.toList(growable: false);
          }

          late final List<dynamic> objKeys;
          // Determine the set of keys/indices to traverse at this depth:
          // - For `.comma` lists we join values in-place.
          // - If `filter` is Iterable, it constrains the key set.
          // - Otherwise derive keys from Map/Iterable, and optionally sort them.
          if (identical(config.generateArrayPrefix, _commaGenerator) &&
              obj is Iterable) {
            final List<dynamic> commaItems =
                seqList ?? (obj is List ? obj : obj.toList(growable: false));

            final List<dynamic> filteredItems = config.commaCompactNulls
                ? [
                    for (final dynamic item in commaItems)
                      if (item != null) item,
                  ]
                : commaItems;

            commaEffectiveLength = filteredItems.length;

            final Iterable<dynamic> joinIterable =
                config.encodeValuesOnly && config.encoder != null
                    ? (Utils.apply<String>(filteredItems, config.encoder!)
                        as Iterable)
                    : filteredItems;

            final List<dynamic> joinList = joinIterable is List
                ? joinIterable
                : joinIterable.toList(growable: false);

            if (joinList.isNotEmpty) {
              final String objKeysValue =
                  joinList.map((e) => e != null ? e.toString() : '').join(',');

              objKeys = [
                _ValueSentinel(
                  objKeysValue.isNotEmpty ? objKeysValue : null,
                ),
              ];
            } else {
              objKeys = [
                const _ValueSentinel(Undefined()),
              ];
            }
          } else if (config.filter is Iterable) {
            objKeys = List<dynamic>.of(config.filter as Iterable);
          } else if (obj is Map) {
            if (config.sort != null) {
              objKeys = obj.keys.toList(growable: false);
              objKeys.sort(config.sort);
            } else if (obj.length == 1) {
              objKeys = [obj.keys.first];
            } else {
              objKeys = obj.keys.toList(growable: false);
            }
          } else if (seqList != null) {
            if (config.sort != null) {
              objKeys =
                  List<int>.generate(seqList.length, (i) => i, growable: false);
              objKeys.sort(config.sort);
            } else if (seqList.length == 1) {
              objKeys = [0];
            } else {
              objKeys =
                  List<int>.generate(seqList.length, (i) => i, growable: false);
            }
          } else {
            objKeys = const [];
          }

          // Key-path formatting:
          // - Optionally encode literal dots.
          // - Under `.comma` with single-element lists and round-trip enabled, append [].
          final KeyPathNode pathForChildren =
              config.encodeDotInKeys ? frame.path.asDotEncoded() : frame.path;

          final bool shouldAppendRoundTripMarker = config.commaRoundTrip &&
              seqList != null &&
              (identical(config.generateArrayPrefix, _commaGenerator) &&
                      commaEffectiveLength != null
                  ? commaEffectiveLength == 1
                  : seqList.length == 1);

          final KeyPathNode adjustedPath = shouldAppendRoundTripMarker
              ? pathForChildren.append('[]')
              : pathForChildren;

          // Emit `key[]` when an empty list is allowed, to preserve shape on round-trip.
          if (config.allowEmptyLists && seqList != null && seqList.isEmpty) {
            finishFrame(frame, adjustedPath.append('[]').materialize());
            continue;
          }

          frame.object = obj;
          frame.objKeys = objKeys;
          frame.seqList = seqList;
          frame.commaEffectiveLength = commaEffectiveLength;
          frame.adjustedPath = adjustedPath;
          frame.index = 0;
          frame.phase = EncodePhase.iterate;
          continue;

        case EncodePhase.iterate:
          if (frame.index >= frame.objKeys.length) {
            finishFrame(frame, frame.values);
            continue;
          }

          final dynamic key = frame.objKeys[frame.index++];
          late final dynamic value;
          late final bool valueUndefined;

          if (key is _ValueSentinel) {
            if (key.value is Undefined) {
              value = null;
              valueUndefined = true;
            } else {
              value = key.value;
              valueUndefined = false;
            }
          } else {
            // Resolve value for the current key/index.
            try {
              if (frame.object is Map) {
                final Map map = frame.object as Map;
                value = map[key];
                valueUndefined = !map.containsKey(key);
              } else if (frame.seqList != null) {
                final int? idx =
                    key is int ? key : int.tryParse(key.toString());
                if (idx != null && idx >= 0 && idx < frame.seqList!.length) {
                  value = frame.seqList![idx];
                  valueUndefined = false;
                } else {
                  value = null;
                  valueUndefined = true;
                }
              } else {
                // Best-effort dynamic indexer for user-defined classes that expose `operator []`.
                // If it throws (no indexer / wrong type), we fall through to the catch and mark undefined.
                value = (frame.object as dynamic)[key];
                valueUndefined = false;
              }
            } catch (_) {
              value = null;
              valueUndefined = true;
            }
          }

          if (config.skipNulls && value == null) {
            continue;
          }

          // Build the next key path segment using either bracket or dot notation.
          final String keyString = key.toString();
          final String encodedKey = config.allowDots &&
                  config.encodeDotInKeys &&
                  keyString.contains('.')
              ? keyString.replaceAll('.', '%2E')
              : keyString;

          final bool isCommaSentinel = key is _ValueSentinel;
          final KeyPathNode adjustedPath = frame.adjustedPath!;
          // Comma lists collapse to a sentinel key and reuse `frame.adjustedPath`,
          // so `_buildSequenceChildPath` is not called with `_commaGenerator`.
          final KeyPathNode keyPath = (isCommaSentinel &&
                  identical(config.generateArrayPrefix, _commaGenerator))
              ? adjustedPath
              : (frame.seqList != null
                  ? _buildSequenceChildPath(
                      adjustedPath,
                      encodedKey,
                      config.generateArrayPrefix,
                      bracketSegment: bracketSegment,
                    )
                  : (config.allowDots
                      ? adjustedPath.append(dotSegment(encodedKey))
                      : adjustedPath.append(bracketSegment(encodedKey))));

          final Encoder? childEncoder = identical(
                    config.generateArrayPrefix,
                    _commaGenerator,
                  ) &&
                  config.encodeValuesOnly &&
                  frame.seqList != null
              ? null
              : config.encoder;
          final EncodeConfig childConfig =
              identical(childEncoder, config.encoder)
                  ? config
                  : config.withEncoder(childEncoder);

          frame.phase = EncodePhase.awaitChild;
          stack.add(
            EncodeFrame(
              object: value,
              undefined: valueUndefined,
              sideChannel: frame.sideChannel,
              path: keyPath,
              config: childConfig,
            ),
          );
          continue;

        case EncodePhase.awaitChild:
          final dynamic encoded = lastResult;
          if (encoded is Iterable) {
            for (final dynamic e in encoded) {
              if (e != null) {
                frame.values.add(e as String);
              }
            }
          } else if (encoded != null) {
            frame.values.add(encoded as String);
          }

          frame.phase = EncodePhase.iterate;
          continue;
      }
    }

    return lastResult ?? const <String>[];
  }

  // Fast path for deep single-key map chains under strict option constraints.
  // Returns `null` when unsupported so the caller can use the generic encoder.
  static String? _tryEncodeLinearChain(
    dynamic object, {
    required bool undefined,
    required Set<Object> sideChannel,
    required String prefix,
    required EncodeConfig config,
  }) {
    if (undefined ||
        config.encoder != null ||
        config.sort != null ||
        config.filter != null ||
        config.allowDots ||
        config.encodeDotInKeys ||
        !identical(config.generateArrayPrefix, _indicesGenerator) ||
        config.commaRoundTrip ||
        config.commaCompactNulls ||
        config.allowEmptyLists ||
        config.strictNullHandling ||
        config.skipNulls ||
        config.encodeValuesOnly) {
      return null;
    }

    dynamic current = object;
    final StringBuffer path = StringBuffer(prefix);
    final List<Object> tracked = [];

    void cleanupTracked() {
      for (int i = tracked.length - 1; i >= 0; i--) {
        sideChannel.remove(tracked[i]);
      }
      tracked.clear();
    }

    try {
      while (true) {
        if (current == null) {
          final String out = '${config.formatter(path.toString())}=';
          return out;
        }

        if (current is DateTime) {
          current =
              config.serializeDate?.call(current) ?? current.toIso8601String();
          continue;
        }

        if (Utils.isNonNullishPrimitive(current, false) ||
            current is ByteBuffer) {
          final String valueString = current is ByteBuffer
              ? (config.charset == utf8
                  ? utf8.decode(
                      current.asUint8List(),
                      allowMalformed: true,
                    )
                  : latin1.decode(current.asUint8List()))
              : current.toString();
          final String out =
              '${config.formatter(path.toString())}=${config.formatter(valueString)}';
          return out;
        }

        if (current is Map) {
          final Object trackedObject = current;
          if (sideChannel.contains(trackedObject)) {
            throw RangeError('Cyclic object value');
          }
          sideChannel.add(trackedObject);
          tracked.add(trackedObject);

          if (current.length != 1) {
            return null;
          }

          final MapEntry<dynamic, dynamic> entry = current.entries.first;
          path
            ..write('[')
            ..write(entry.key.toString())
            ..write(']');
          current = entry.value;
          continue;
        }

        if (current is Iterable && current is! String) {
          return null;
        }

        return null;
      }
    } finally {
      cleanupTracked();
    }
  }

  /// For custom [generator] callbacks, the callback owns the full key path
  /// string and receives `adjustedPath.materialize()` as input. The fallback
  /// uses [KeyPathNode.fromMaterialized], which creates a fresh depth-1 root
  /// without sharing ancestor nodes, so incremental path caching is not reused.
  static KeyPathNode _buildSequenceChildPath(
    KeyPathNode adjustedPath,
    String encodedKey,
    ListFormatGenerator generator, {
    required String Function(String encodedKey) bracketSegment,
  }) =>
      switch (generator) {
        ListFormatGenerator gen when identical(gen, _indicesGenerator) =>
          adjustedPath.append(bracketSegment(encodedKey)),
        ListFormatGenerator gen when identical(gen, _bracketsGenerator) =>
          adjustedPath.append('[]'),
        ListFormatGenerator gen when identical(gen, _repeatGenerator) =>
          adjustedPath,
        _ => KeyPathNode.fromMaterialized(
            generator(adjustedPath.materialize(), encodedKey),
          ),
      };
}

// Internal marker used for synthetic "value" entries (for example comma-list
// joins) so traversal can distinguish sentinel payloads from normal keys.
final class _ValueSentinel {
  const _ValueSentinel(this.value);

  final dynamic value;
}
