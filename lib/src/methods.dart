import 'package:qs_dart/src/models/decode_options.dart';
import 'package:qs_dart/src/models/encode_options.dart';
import 'package:qs_dart/src/qs.dart';

/// Convenience method for [QS.decode]
Map<String, dynamic> decode(dynamic input, [DecodeOptions? options]) =>
    QS.decode(input, options);

/// Convenience method for [QS.encode]
String encode(Object? object, [EncodeOptions? options]) =>
    QS.encode(object, options);
