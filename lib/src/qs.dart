import 'dart:convert' show latin1, utf8, Encoding;
import 'dart:typed_data' show ByteBuffer;

import 'package:collection/collection.dart' show IterableExtension;
import 'package:qs_dart/src/enums/duplicates.dart';
import 'package:qs_dart/src/enums/format.dart';
import 'package:qs_dart/src/enums/list_format.dart';
import 'package:qs_dart/src/enums/sentinel.dart';
import 'package:qs_dart/src/extensions/extensions.dart';
import 'package:qs_dart/src/models/decode_options.dart';
import 'package:qs_dart/src/models/encode_options.dart';
import 'package:qs_dart/src/models/undefined.dart';
import 'package:qs_dart/src/utils.dart';
import 'package:recursive_regex/recursive_regex.dart';
import 'package:weak_map/weak_map.dart';

part 'extensions/decode.dart';

part 'extensions/encode.dart';

/// A query string decoder (parser) and encoder (stringifier) class.
final class QS {
  /// Decodes a [String] or [Map<String, dynamic>] into a [Map<String, dynamic>].
  /// Providing custom [options] will override the default behavior.
  static Map<String, dynamic> decode(
    dynamic input, [
    DecodeOptions options = const DecodeOptions(),
  ]) {
    if (!(input is String? || input is Map<String, dynamic>?)) {
      throw ArgumentError.value(
        input,
        'input',
        'The input must be a String or a Map<String, dynamic>',
      );
    }

    if (input?.isEmpty ?? true) {
      return <String, dynamic>{};
    }

    Map<String, dynamic>? tempObj = input is String
        ? _$Decode._parseQueryStringValues(input, options)
        : input;
    Map<String, dynamic> obj = {};

    // Iterate over the keys and setup the new object
    if (tempObj?.isNotEmpty ?? false) {
      for (final MapEntry<String, dynamic> entry in tempObj!.entries) {
        final newObj = _$Decode._parseKeys(
          entry.key,
          entry.value,
          options,
          input is String,
        );

        obj = Utils.merge(
          obj,
          newObj,
          options,
        );
      }
    }

    return Utils.compact(obj);
  }

  /// Encodes an [Object] into a query [String].
  /// Providing custom [options] will override the default behavior.
  static String encode(
    Object? object, [
    EncodeOptions options = const EncodeOptions(),
  ]) {
    if (object == null) {
      return '';
    }

    late Map<String, dynamic> obj;
    if (object is Map<String, dynamic>) {
      obj = {...?object as Map<String, dynamic>?};
    } else if (object is Iterable) {
      obj = object.toList().asMap().map((k, v) => MapEntry(k.toString(), v));
    } else {
      obj = {};
    }

    final List keys = [];

    if (obj.isEmpty) {
      return '';
    }

    List? objKeys;

    if (options.filter is Function) {
      obj = options.filter?.call('', obj);
    } else if (options.filter is Iterable) {
      objKeys = List.of(options.filter);
    }

    final bool commaRoundTrip =
        options.listFormat.generator == ListFormat.comma.generator &&
            options.commaRoundTrip == true;

    objKeys ??= obj.keys.toList();

    if (options.sort is Function) {
      objKeys.sort(options.sort);
    }

    final WeakMap sideChannel = WeakMap();
    for (int i = 0; i < objKeys.length; i++) {
      final key = objKeys[i];
      if (key is! String?) {
        continue;
      }
      if (obj[key] == null && options.skipNulls) {
        continue;
      }

      final encoded = _$Encode._encode(
        obj[key],
        undefined: !obj.containsKey(key),
        prefix: key,
        generateArrayPrefix: options.listFormat.generator,
        commaRoundTrip: commaRoundTrip,
        allowEmptyLists: options.allowEmptyLists,
        strictNullHandling: options.strictNullHandling,
        skipNulls: options.skipNulls,
        encodeDotInKeys: options.encodeDotInKeys,
        encoder: options.encode ? options.encoder : null,
        serializeDate: options.serializeDate,
        filter: options.filter,
        sort: options.sort,
        allowDots: options.allowDots,
        format: options.format,
        formatter: options.formatter,
        encodeValuesOnly: options.encodeValuesOnly,
        charset: options.charset,
        addQueryPrefix: options.addQueryPrefix,
        sideChannel: sideChannel,
      );

      if (encoded is Iterable) {
        keys.addAll(encoded);
      } else {
        keys.add(encoded);
      }
    }

    final String joined = keys.join(options.delimiter);
    String prefix = options.addQueryPrefix ? '?' : '';

    if (options.charsetSentinel) {
      prefix += switch (options.charset) {
        /// encodeURIComponent('&#10003;')
        /// the "numeric entity" representation of a checkmark
        latin1 => '${Sentinel.iso}&',

        /// encodeURIComponent('✓')
        utf8 => '${Sentinel.charset}&',
        _ => '',
      };
    }

    return joined.isNotEmpty ? prefix + joined : '';
  }
}
