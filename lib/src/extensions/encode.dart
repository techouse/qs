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
  // Side-channel anchor used to thread cycle-detection state through recursion.
  // We store nested WeakMaps under this key to walk back up the call stack.
  static const Map _sentinel = {};

  /// Core encoder (recursive).
  ///
  /// Returns either a `String` (single key=value) or `List<String>` fragments, which the
  /// top-level caller ultimately joins with the chosen delimiter.
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

    dynamic obj = object;

    WeakMap? tmpSc = sideChannel;
    int step = 0;
    bool findFlag = false;

    // Walk the nested WeakMap chain to see if the current object already appeared
    // in the traversal path. If so, either throw (direct cycle) or stop descending.
    while ((tmpSc = tmpSc?.get(_sentinel)) != null && !findFlag) {
      // Where object last appeared in the ref tree
      final int? pos = tmpSc?.get(object) as int?;
      step += 1;
      if (pos != null) {
        if (pos == step) {
          throw RangeError('Cyclic object value');
        } else {
          findFlag = true; // Break while
        }
      }
      if (tmpSc?.get(_sentinel) == null) {
        step = 0;
      }
    }

    // Apply filter hook first. For dates, serialize them before any list/comma handling.
    if (filter is Function) {
      obj = filter.call(prefix, obj);
    } else if (obj is DateTime) {
      obj = switch (serializeDate) {
        null => obj.toIso8601String(),
        _ => serializeDate(obj),
      };
    } else if (identical(generateArrayPrefix, ListFormat.comma.generator) &&
        obj is Iterable) {
      obj = Utils.apply(
        obj,
        (value) => value is DateTime
            ? (serializeDate?.call(value) ?? value.toIso8601String())
            : value,
      );
    }

    // Present-but-null handling:
    // - If the value is *present* and null and strictNullHandling is on, emit only the key.
    // - Otherwise, treat null as an empty string.
    if (!undefined && obj == null) {
      if (strictNullHandling) {
        return encoder != null && !encodeValuesOnly ? encoder(prefix) : prefix;
      }

      obj = '';
    }

    // Fast path for primitives and byte buffers → return a single key=value fragment.
    if (Utils.isNonNullishPrimitive(obj, skipNulls) || obj is ByteBuffer) {
      if (encoder != null) {
        final String keyValue = encodeValuesOnly ? prefix : encoder(prefix);
        return ['${formatter(keyValue)}=${formatter(encoder(obj))}'];
      }
      return ['${formatter(prefix)}=${formatter(obj.toString())}'];
    }

    // Collect per-branch fragments; empty list signifies "emit nothing" for this path.
    final List values = [];

    if (undefined) {
      return values;
    }

    // Cache list form once for non-Map, non-String iterables to avoid repeated enumeration
    List<dynamic>? seqList_;
    int? commaEffectiveLength;
    final bool isSeq_ = obj is Iterable && obj is! String && obj is! Map;
    if (isSeq_) {
      if (obj is List) {
        seqList_ = obj;
      } else {
        seqList_ = obj.toList(growable: false);
      }
    }

    late final List objKeys;
    // Determine the set of keys/indices to traverse at this depth:
    // - For `.comma` lists we join values in-place.
    // - If `filter` is Iterable, it constrains the key set.
    // - Otherwise derive keys from Map/Iterable, and optionally sort them.
    if (identical(generateArrayPrefix, ListFormat.comma.generator) &&
        obj is Iterable) {
      final Iterable<dynamic> iterableObj = obj;
      final List<dynamic> commaItems = iterableObj is List
          ? List<dynamic>.from(iterableObj)
          : iterableObj.toList(growable: false);

      final List<dynamic> filteredItems = commaCompactNulls
          ? commaItems.where((dynamic item) => item != null).toList()
          : commaItems;

      commaEffectiveLength = filteredItems.length;

      final Iterable<dynamic> joinIterable = encodeValuesOnly && encoder != null
          ? (Utils.apply<String>(filteredItems, encoder) as Iterable)
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
    } else if (filter is Iterable) {
      objKeys = List.of(filter);
    } else {
      late final Iterable keys;
      if (obj is Map) {
        keys = obj.keys;
      } else if (seqList_ != null) {
        keys = List<int>.generate(seqList_.length, (i) => i, growable: false);
      } else {
        keys = const <int>[];
      }
      objKeys = sort != null ? (keys.toList()..sort(sort)) : keys.toList();
    }

    // Key-path formatting:
    // - Optionally encode literal dots.
    // - Under `.comma` with single-element lists and round-trip enabled, append [].
    final String encodedPrefix =
        encodeDotInKeys ? prefix.replaceAll('.', '%2E') : prefix;

    final bool shouldAppendRoundTripMarker = (commaRoundTrip == true) &&
        seqList_ != null &&
        (identical(generateArrayPrefix, ListFormat.comma.generator) &&
                commaEffectiveLength != null
            ? commaEffectiveLength == 1
            : seqList_.length == 1);

    final String adjustedPrefix =
        shouldAppendRoundTripMarker ? '$encodedPrefix[]' : encodedPrefix;

    // Emit `key[]` when an empty list is allowed, to preserve shape on round-trip.
    if (allowEmptyLists && seqList_ != null && seqList_.isEmpty) {
      return '$adjustedPrefix[]';
    }

    for (int i = 0; i < objKeys.length; i++) {
      final key = objKeys[i];
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
          if (obj is Map) {
            value = obj[key];
            valueUndefined = !obj.containsKey(key);
          } else if (seqList_ != null) {
            final int? idx = key is int ? key : int.tryParse(key.toString());
            if (idx != null && idx >= 0 && idx < seqList_.length) {
              value = seqList_[idx];
              valueUndefined = false;
            } else {
              value = null;
              valueUndefined = true;
            }
          } else {
            // Best-effort dynamic indexer for user-defined classes that expose `operator []`.
            // If it throws (no indexer / wrong type), we fall through to the catch and mark undefined.
            value = obj[key];
            valueUndefined = false;
          }
        } catch (_) {
          value = null;
          valueUndefined = true;
        }
      }

      if (skipNulls && value == null) {
        continue;
      }

      // Build the next key path segment using either bracket or dot notation.
      final String encodedKey = allowDots && encodeDotInKeys
          ? key.toString().replaceAll('.', '%2E')
          : key.toString();

      final bool isCommaSentinel =
          key is Map<String, dynamic> && key.containsKey('value');
      final String keyPrefix = (isCommaSentinel &&
              identical(generateArrayPrefix, ListFormat.comma.generator))
          ? adjustedPrefix
          : (seqList_ != null
              ? generateArrayPrefix(adjustedPrefix, encodedKey)
              : '$adjustedPrefix${allowDots ? '.$encodedKey' : '[$encodedKey]'}');

      // Thread cycle-detection state into recursive calls without keeping strong references.
      sideChannel[object] = step;
      final WeakMap valueSideChannel = WeakMap();
      valueSideChannel.add(key: _sentinel, value: sideChannel);

      final encoded = _encode(
        value,
        undefined: valueUndefined,
        prefix: keyPrefix,
        generateArrayPrefix: generateArrayPrefix,
        commaRoundTrip: commaRoundTrip,
        commaCompactNulls: commaCompactNulls,
        allowEmptyLists: allowEmptyLists,
        strictNullHandling: strictNullHandling,
        skipNulls: skipNulls,
        encodeDotInKeys: encodeDotInKeys,
        encoder: identical(generateArrayPrefix, ListFormat.comma.generator) &&
                encodeValuesOnly &&
                seqList_ != null
            ? null
            : encoder,
        serializeDate: serializeDate,
        filter: filter,
        sort: sort,
        allowDots: allowDots,
        format: format,
        formatter: formatter,
        encodeValuesOnly: encodeValuesOnly,
        charset: charset,
        sideChannel: valueSideChannel,
      );

      // Flatten nested results (each recursion returns a list of fragments or a single fragment).
      if (encoded is Iterable) {
        values.addAll(encoded);
      } else {
        values.add(encoded);
      }
    }

    return values;
  }
}
