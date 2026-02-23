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
  /// Returns a `List<String>` of encoded fragments; the top-level caller joins
  /// them with the chosen delimiter.
  ///
  /// Parameters (most mirror Node `qs`):
  /// - [object]: The current value to encode (map/iterable/scalar/byte buffer/date).
  /// - [undefined]: Marks a *missing* value (e.g., absent map key). When `true`, nothing is emitted.
  /// - [sideChannel]: Active-path set used for cycle detection across traversal frames.
  /// - [prefix]: Root path seed used to initialize the first [KeyPathNode].
  ///   If `addQueryPrefix` is true at the root, we start with `?`.
  /// - [generateArrayPrefix]: Strategy for array key generation (brackets/indices/repeat/comma).
  /// - [commaRoundTrip]: When true and a single-element list is encountered under `.comma`, emit `[]` to ensure the value round-trips back to an array.
  /// - [commaCompactNulls]: When true, nulls are omitted from `.comma` lists.
  /// - [allowEmptyLists]: If a list is empty, emit `key[]` instead of skipping.
  /// - [strictNullHandling]: If a present value is `null`, emit only the key (no `=`) instead of `key=`.
  /// - [skipNulls]: Skip keys whose value is `null`.
  /// - [encodeDotInKeys]: Replace literal `.` in keys with `%2E`.
  /// - [encoder]: Optional percent-encoder for values (and keys when `encodeValuesOnly == false`).
  /// - [serializeDate]: Optional serializer for `DateTime` → String *before* encoding.
  /// - [sort]: Optional comparator for determining key order at each object depth.
  /// - [filter]: Either a function `(key, value) → value` or an iterable that constrains emitted keys.
  /// - [allowDots]: When true, dot notation is used between path segments instead of brackets.
  /// - [format]: RFC3986 or RFC1738 — influences space/plus behavior via [formatter].
  /// - [formatter]: Converts scalar strings to their final on-wire form (applies percent-encoding).
  /// - [encodeValuesOnly]: When true, keys are left as-is and only values are encoded by [encoder].
  /// - [charset]: Present for parity; encoding is delegated to [encoder]/[formatter].
  /// - [addQueryPrefix]: At the root, prefix output with `?`.
  static dynamic _encode(
    dynamic object, {
    required bool undefined,
    required Set<Object> sideChannel,
    String? prefix,
    ListFormatGenerator? generateArrayPrefix,
    bool? commaRoundTrip,
    bool commaCompactNulls = false,
    bool allowEmptyLists = false,
    bool strictNullHandling = false,
    bool skipNulls = false,
    bool encodeDotInKeys = false,
    Encoder? encoder,
    DateSerializer? serializeDate,
    Sorter? sort,
    dynamic filter,
    bool allowDots = false,
    Format format = Format.rfc3986,
    Formatter? formatter,
    bool encodeValuesOnly = false,
    Encoding charset = utf8,
    bool addQueryPrefix = false,
  }) {
    prefix ??= addQueryPrefix ? '?' : '';
    generateArrayPrefix ??= _indicesGenerator;
    commaRoundTrip ??= identical(generateArrayPrefix, _commaGenerator);
    formatter ??= format.formatter;
    final EncodeConfig rootConfig = EncodeConfig(
      generateArrayPrefix: generateArrayPrefix,
      commaRoundTrip: commaRoundTrip,
      commaCompactNulls: commaCompactNulls,
      allowEmptyLists: allowEmptyLists,
      strictNullHandling: strictNullHandling,
      skipNulls: skipNulls,
      encodeDotInKeys: encodeDotInKeys,
      encoder: encoder,
      serializeDate: serializeDate,
      sort: sort,
      filter: filter,
      allowDots: allowDots,
      format: format,
      formatter: formatter,
      encodeValuesOnly: encodeValuesOnly,
      charset: charset,
    );

    List<String>? result;
    final List<EncodeFrame> stack = [
      EncodeFrame(
        object: object,
        undefined: undefined,
        sideChannel: sideChannel,
        path: KeyPathNode.fromMaterialized(prefix),
        config: rootConfig,
        onResult: (List<String> value) => result = value,
      ),
    ];

    while (stack.isNotEmpty) {
      final EncodeFrame frame = stack.last;
      final EncodeConfig config = frame.config;

      if (!frame.prepared) {
        dynamic obj = frame.object;
        String? pathText;
        String materializedPath() => pathText ??= frame.path.materialize();

        final bool trackObject =
            obj is Map || (obj is Iterable && obj is! String);
        if (trackObject) {
          final tracked = obj as Object;
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
                ? (config.serializeDate?.call(value) ?? value.toIso8601String())
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
            final tracked = frame.trackedObject;
            if (tracked != null) {
              frame.sideChannel.remove(tracked);
              frame.trackedObject = null;
            }
            stack.removeLast();
            frame.onResult([keyOnly]);
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
          final tracked = frame.trackedObject;
          if (tracked != null) {
            frame.sideChannel.remove(tracked);
            frame.trackedObject = null;
          }
          stack.removeLast();
          frame.onResult([fragment]);
          continue;
        }

        // Collect per-branch fragments; empty list signifies "emit nothing" for this path.
        if (frame.undefined) {
          final tracked = frame.trackedObject;
          if (tracked != null) {
            frame.sideChannel.remove(tracked);
            frame.trackedObject = null;
          }
          stack.removeLast();
          frame.onResult(const <String>[]);
          continue;
        }

        // Cache list form once for non-Map, non-String iterables to avoid repeated enumeration
        List<dynamic>? seqList;
        int? commaEffectiveLength;
        final bool isSeq = obj is Iterable && obj is! String && obj is! Map;
        if (isSeq) {
          seqList = obj is List ? obj : obj.toList(growable: false);
        }

        late final List objKeys;
        // Determine the set of keys/indices to traverse at this depth:
        // - For `.comma` lists we join values in-place.
        // - If `filter` is Iterable, it constrains the key set.
        // - Otherwise derive keys from Map/Iterable, and optionally sort them.
        if (identical(config.generateArrayPrefix, _commaGenerator) &&
            obj is Iterable) {
          final Iterable<dynamic> iterableObj = obj;
          final List<dynamic> commaItems = iterableObj is List
              ? iterableObj
              : iterableObj.toList(growable: false);

          final List<dynamic> filteredItems = config.commaCompactNulls
              ? commaItems.where((dynamic item) => item != null).toList()
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
              {
                'value': objKeysValue.isNotEmpty ? objKeysValue : null,
              },
            ];
          } else {
            objKeys = [
              {'value': const Undefined()},
            ];
          }
        } else if (config.filter is Iterable) {
          objKeys = List.of(config.filter);
        } else {
          late final Iterable keys;
          if (obj is Map) {
            keys = obj.keys;
          } else if (seqList != null) {
            keys =
                List<int>.generate(seqList.length, (i) => i, growable: false);
          } else {
            keys = const <int>[];
          }
          objKeys = config.sort != null
              ? (keys.toList()..sort(config.sort))
              : keys.toList();
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
          final tracked = frame.trackedObject;
          if (tracked != null) {
            frame.sideChannel.remove(tracked);
            frame.trackedObject = null;
          }
          stack.removeLast();
          frame.onResult([adjustedPath.append('[]').materialize()]);
          continue;
        }

        frame.object = obj;
        frame.prepared = true;
        frame.objKeys = objKeys;
        frame.seqList = seqList;
        frame.commaEffectiveLength = commaEffectiveLength;
        frame.adjustedPath = adjustedPath;
        continue;
      }

      if (frame.index >= frame.objKeys.length) {
        final tracked = frame.trackedObject;
        if (tracked != null) {
          frame.sideChannel.remove(tracked);
          frame.trackedObject = null;
        }
        stack.removeLast();
        frame.onResult(frame.values);
        continue;
      }

      final key = frame.objKeys[frame.index++];
      late final dynamic value;
      late final bool valueUndefined;

      if (key is Map<String, dynamic> &&
          key.containsKey('value') &&
          key['value'] is! Undefined) {
        value = key['value'];
        valueUndefined = false;
      } else {
        // Resolve value for the current key/index.
        try {
          if (frame.object is Map) {
            value = frame.object[key];
            valueUndefined = !(frame.object as Map).containsKey(key);
          } else if (frame.seqList != null) {
            final int? idx = key is int ? key : int.tryParse(key.toString());
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
      final String encodedKey = config.allowDots && config.encodeDotInKeys
          ? key.toString().replaceAll('.', '%2E')
          : key.toString();

      final bool isCommaSentinel =
          key is Map<String, dynamic> && key.containsKey('value');
      // Comma lists collapse to a sentinel key and reuse `frame.adjustedPath`,
      // so `_buildSequenceChildPath` is not called with `_commaGenerator`.
      final KeyPathNode keyPath = (isCommaSentinel &&
              identical(config.generateArrayPrefix, _commaGenerator))
          ? frame.adjustedPath!
          : (frame.seqList != null
              ? _buildSequenceChildPath(
                  frame.adjustedPath!,
                  encodedKey,
                  config.generateArrayPrefix,
                )
              : (config.allowDots
                  ? frame.adjustedPath!.append('.$encodedKey')
                  : frame.adjustedPath!.append('[$encodedKey]')));

      final Encoder? childEncoder = identical(
                config.generateArrayPrefix,
                _commaGenerator,
              ) &&
              config.encodeValuesOnly &&
              frame.seqList != null
          ? null
          : config.encoder;
      final EncodeConfig childConfig = identical(childEncoder, config.encoder)
          ? config
          : config.withEncoder(childEncoder);

      stack.add(
        EncodeFrame(
          object: value,
          undefined: valueUndefined,
          sideChannel: frame.sideChannel,
          path: keyPath,
          config: childConfig,
          onResult: (List<String> encoded) {
            frame.values.addAll(encoded);
          },
        ),
      );
    }

    return result ?? const <String>[];
  }

  /// For custom [generator] callbacks, the callback owns the full key path
  /// string and receives `adjustedPath.materialize()` as input. The fallback
  /// uses [KeyPathNode.fromMaterialized], which creates a fresh depth-1 root
  /// without sharing ancestor nodes, so incremental path caching is not reused.
  static KeyPathNode _buildSequenceChildPath(
    KeyPathNode adjustedPath,
    String encodedKey,
    ListFormatGenerator generator,
  ) =>
      switch (generator) {
        ListFormatGenerator gen when identical(gen, _indicesGenerator) =>
          adjustedPath.append('[$encodedKey]'),
        ListFormatGenerator gen when identical(gen, _bracketsGenerator) =>
          adjustedPath.append('[]'),
        ListFormatGenerator gen when identical(gen, _repeatGenerator) =>
          adjustedPath,
        _ => KeyPathNode.fromMaterialized(
            generator(adjustedPath.materialize(), encodedKey),
          ),
      };
}
