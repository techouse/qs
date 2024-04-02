part of '../qs.dart';

extension _$Encode on QS {
  static const Map _sentinel = {};

  /// Returns either dynamic or List<dynamic> based on the object.
  static dynamic _encode(
    dynamic object, {
    required bool undefined,
    required WeakMap sideChannel,
    String? prefix,
    ListFormatGenerator? generateArrayPrefix,
    bool? commaRoundTrip,
    bool allowEmptyArrays = false,
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
    commaRoundTrip ??= generateArrayPrefix == ListFormat.comma.generator;
    formatter ??= format.formatter;

    dynamic obj = object;

    WeakMap? tmpSc = sideChannel;
    int step = 0;
    bool findFlag = false;

    while ((tmpSc = tmpSc?.get(_sentinel)) != null && !findFlag) {
      // Where object last appeared in the ref tree
      final int? pos = tmpSc?.get(object);
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

    if (filter is Function) {
      obj = filter.call(prefix, obj);
    } else if (obj is DateTime) {
      obj = serializeDate?.call(obj) ?? obj.toIso8601String();
    } else if (generateArrayPrefix == ListFormat.comma.generator &&
        obj is Iterable) {
      obj = Utils.maybeMap(
        obj,
        (value) => value is DateTime
            ? (serializeDate?.call(value) ?? value.toIso8601String())
            : value,
      );
    }

    if (!undefined && obj == null) {
      if (strictNullHandling) {
        return encoder != null && !encodeValuesOnly ? encoder(prefix) : prefix;
      }

      obj = '';
    }

    if (Utils.isNonNullishPrimitive(obj, skipNulls) || obj is ByteBuffer) {
      if (encoder != null) {
        final String keyValue = encodeValuesOnly ? prefix : encoder(prefix);
        return ['${formatter(keyValue)}=${formatter(encoder(obj))}'];
      }
      return ['${formatter(prefix)}=${formatter(obj.toString())}'];
    }

    final List values = [];

    if (undefined) {
      return values;
    }

    late List objKeys;
    if (generateArrayPrefix == ListFormat.comma.generator && obj is Iterable) {
      // we need to join elements in
      if (encodeValuesOnly && encoder != null) {
        obj = Utils.maybeMap<String>(obj, encoder);
      }

      if ((obj as Iterable).isNotEmpty) {
        final String objKeysValue =
            obj.map((e) => e != null ? e.toString() : '').join(',');

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
    } else if (filter is List) {
      objKeys = filter;
    } else {
      late final Iterable keys;
      if (obj is Map) {
        keys = obj.keys;
      } else if (obj is Iterable) {
        keys = [for (int index = 0; index < obj.length; index++) index];
      } else {
        keys = [];
      }
      objKeys = sort != null ? (keys.toList()..sort(sort)) : keys.toList();
    }

    final String encodedPrefix =
        encodeDotInKeys ? prefix.replaceAll('.', '%2E') : prefix;

    final String adjustedPrefix =
        commaRoundTrip && obj is Iterable && obj.length == 1
            ? '$encodedPrefix[]'
            : encodedPrefix;

    if (allowEmptyArrays && obj is Iterable && obj.isEmpty) {
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
        try {
          if (obj is Map) {
            value = obj[key];
            valueUndefined = !obj.containsKey(key);
          } else if (obj is Iterable) {
            value = obj.elementAt(key);
            valueUndefined = false;
          } else {
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

      final String encodedKey = allowDots && encodeDotInKeys
          ? key.toString().replaceAll('.', '%2E')
          : key.toString();

      final String keyPrefix = obj is Iterable
          ? generateArrayPrefix(adjustedPrefix, encodedKey)
          : '$adjustedPrefix${allowDots ? '.$encodedKey' : '[$encodedKey]'}';

      sideChannel[object] = step;
      final WeakMap valueSideChannel = WeakMap();
      valueSideChannel.add(key: _sentinel, value: sideChannel);

      final encoded = _encode(
        value,
        undefined: valueUndefined,
        prefix: keyPrefix,
        generateArrayPrefix: generateArrayPrefix,
        commaRoundTrip: commaRoundTrip,
        allowEmptyArrays: allowEmptyArrays,
        strictNullHandling: strictNullHandling,
        skipNulls: skipNulls,
        encodeDotInKeys: encodeDotInKeys,
        encoder: generateArrayPrefix == ListFormat.comma.generator &&
                encodeValuesOnly &&
                obj is Iterable
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

      if (encoded is Iterable) {
        values.addAll(encoded);
      } else {
        values.add(encoded);
      }
    }

    return values;
  }
}
