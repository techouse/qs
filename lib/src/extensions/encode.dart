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
/// - *sideChannel* ([WeakMap]): threads state through recursive calls to detect cycles
///   without retaining the entire object graph.
/// - *prefix*: current key path being built (e.g., `user[address]`), with optional `?` prefix.

extension _$Encode on QS {
  /// Core encoder (iterative, stack-based).
  ///
  /// Returns a `List<String>` of encoded fragments; the top-level caller joins
  /// them with the chosen delimiter.
  ///
  /// Parameters (most mirror Node `qs`):
  /// - [object]: The current value to encode (map/iterable/scalar/byte buffer/date).
  /// - [undefined]: Marks a *missing* value (e.g., absent map key). When `true`, nothing is emitted.
  /// - [sideChannel]: Weak side-channel used for cycle detection across recursive calls.
  /// - [prefix]: Current key path (e.g., `user[address]`). If `addQueryPrefix` is true at the root, we start with `?`.
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
    required WeakMap sideChannel,
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
    generateArrayPrefix ??= ListFormat.indices.generator;
    commaRoundTrip ??=
        identical(generateArrayPrefix, ListFormat.comma.generator);
    formatter ??= format.formatter;

    List<String>? result;
    final List<EncodeFrame> stack = [
      EncodeFrame(
        object: object,
        undefined: undefined,
        sideChannel: sideChannel,
        prefix: prefix,
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
        onResult: (List<String> value) => result = value,
      ),
    ];

    while (stack.isNotEmpty) {
      final EncodeFrame frame = stack.last;

      if (!frame.prepared) {
        dynamic obj = frame.object;
        final bool trackObject =
            obj is Map || (obj is Iterable && obj is! String);
        if (trackObject) {
          if (frame.sideChannel.contains(obj)) {
            throw RangeError('Cyclic object value');
          }
          frame.sideChannel[obj] = true;
          frame.tracked = true;
          frame.trackedObject = obj as Object;
        }

        // Apply filter hook first. For dates, serialize them before any list/comma handling.
        if (frame.filter is Function) {
          obj = frame.filter.call(frame.prefix, obj);
        } else if (obj is DateTime) {
          obj = switch (frame.serializeDate) {
            null => obj.toIso8601String(),
            _ => frame.serializeDate!(obj),
          };
        } else if (identical(
                frame.generateArrayPrefix, ListFormat.comma.generator) &&
            obj is Iterable) {
          obj = Utils.apply(
            obj,
            (value) => value is DateTime
                ? (frame.serializeDate?.call(value) ?? value.toIso8601String())
                : value,
          );
        }

        // Present-but-null handling:
        // - If the value is *present* and null and strictNullHandling is on, emit only the key.
        // - Otherwise, treat null as an empty string.
        if (!frame.undefined && obj == null) {
          if (frame.strictNullHandling) {
            final String keyOnly =
                frame.encoder != null && !frame.encodeValuesOnly
                    ? frame.encoder!(frame.prefix)
                    : frame.prefix;
            if (frame.tracked) {
              frame.sideChannel.remove(frame.trackedObject ?? frame.object);
            }
            stack.removeLast();
            frame.onResult([keyOnly]);
            continue;
          }
          obj = '';
        }

        // Fast path for primitives and byte buffers → return a single key=value fragment.
        if (Utils.isNonNullishPrimitive(obj, frame.skipNulls) ||
            obj is ByteBuffer) {
          late final String fragment;
          if (frame.encoder != null) {
            final String keyValue = frame.encodeValuesOnly
                ? frame.prefix
                : frame.encoder!(frame.prefix);
            fragment =
                '${frame.formatter(keyValue)}=${frame.formatter(frame.encoder!(obj))}';
          } else {
            fragment =
                '${frame.formatter(frame.prefix)}=${frame.formatter(obj.toString())}';
          }
          if (frame.tracked) {
            frame.sideChannel.remove(frame.trackedObject ?? frame.object);
          }
          stack.removeLast();
          frame.onResult([fragment]);
          continue;
        }

        // Collect per-branch fragments; empty list signifies "emit nothing" for this path.
        if (frame.undefined) {
          if (frame.tracked) {
            frame.sideChannel.remove(frame.trackedObject ?? frame.object);
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
        if (identical(frame.generateArrayPrefix, ListFormat.comma.generator) &&
            obj is Iterable) {
          final Iterable<dynamic> iterableObj = obj;
          final List<dynamic> commaItems = iterableObj is List
              ? List<dynamic>.from(iterableObj)
              : iterableObj.toList(growable: false);

          final List<dynamic> filteredItems = frame.commaCompactNulls
              ? commaItems.where((dynamic item) => item != null).toList()
              : commaItems;

          commaEffectiveLength = filteredItems.length;

          final Iterable<dynamic> joinIterable = frame.encodeValuesOnly &&
                  frame.encoder != null
              ? (Utils.apply<String>(filteredItems, frame.encoder!) as Iterable)
              : filteredItems;

          final List<dynamic> joinList = joinIterable is List
              ? List<dynamic>.from(joinIterable)
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
        } else if (frame.filter is Iterable) {
          objKeys = List.of(frame.filter);
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
          objKeys = frame.sort != null
              ? (keys.toList()..sort(frame.sort))
              : keys.toList();
        }

        // Key-path formatting:
        // - Optionally encode literal dots.
        // - Under `.comma` with single-element lists and round-trip enabled, append [].
        final String encodedPrefix = frame.encodeDotInKeys
            ? frame.prefix.replaceAll('.', '%2E')
            : frame.prefix;

        final bool shouldAppendRoundTripMarker = (frame.commaRoundTrip ==
                true) &&
            seqList != null &&
            (identical(frame.generateArrayPrefix, ListFormat.comma.generator) &&
                    commaEffectiveLength != null
                ? commaEffectiveLength == 1
                : seqList.length == 1);

        final String adjustedPrefix =
            shouldAppendRoundTripMarker ? '$encodedPrefix[]' : encodedPrefix;

        // Emit `key[]` when an empty list is allowed, to preserve shape on round-trip.
        if (frame.allowEmptyLists && seqList != null && seqList.isEmpty) {
          if (frame.tracked) {
            frame.sideChannel.remove(frame.trackedObject ?? frame.object);
          }
          stack.removeLast();
          frame.onResult(['$adjustedPrefix[]']);
          continue;
        }

        frame.object = obj;
        frame.prepared = true;
        frame.objKeys = objKeys;
        frame.seqList = seqList;
        frame.commaEffectiveLength = commaEffectiveLength;
        frame.adjustedPrefix = adjustedPrefix;
        continue;
      }

      if (frame.index >= frame.objKeys.length) {
        if (frame.tracked) {
          frame.sideChannel.remove(frame.trackedObject ?? frame.object);
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

      if (frame.skipNulls && value == null) {
        continue;
      }

      // Build the next key path segment using either bracket or dot notation.
      final String encodedKey = frame.allowDots && frame.encodeDotInKeys
          ? key.toString().replaceAll('.', '%2E')
          : key.toString();

      final bool isCommaSentinel =
          key is Map<String, dynamic> && key.containsKey('value');
      final String keyPrefix = (isCommaSentinel &&
              identical(frame.generateArrayPrefix, ListFormat.comma.generator))
          ? frame.adjustedPrefix!
          : (frame.seqList != null
              ? frame.generateArrayPrefix(frame.adjustedPrefix!, encodedKey)
              : '${frame.adjustedPrefix!}${frame.allowDots ? '.$encodedKey' : '[$encodedKey]'}');

      stack.add(
        EncodeFrame(
          object: value,
          undefined: valueUndefined,
          sideChannel: frame.sideChannel,
          prefix: keyPrefix,
          generateArrayPrefix: frame.generateArrayPrefix,
          commaRoundTrip: frame.commaRoundTrip,
          commaCompactNulls: frame.commaCompactNulls,
          allowEmptyLists: frame.allowEmptyLists,
          strictNullHandling: frame.strictNullHandling,
          skipNulls: frame.skipNulls,
          encodeDotInKeys: frame.encodeDotInKeys,
          encoder: identical(
                      frame.generateArrayPrefix, ListFormat.comma.generator) &&
                  frame.encodeValuesOnly &&
                  frame.seqList != null
              ? null
              : frame.encoder,
          serializeDate: frame.serializeDate,
          sort: frame.sort,
          filter: frame.filter,
          allowDots: frame.allowDots,
          format: frame.format,
          formatter: frame.formatter,
          encodeValuesOnly: frame.encodeValuesOnly,
          charset: frame.charset,
          onResult: (List<String> encoded) {
            frame.values.addAll(encoded);
          },
        ),
      );
    }

    return result ?? const <String>[];
  }
}
