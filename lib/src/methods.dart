import 'package:qs_dart/src/models/decode_options.dart';
import 'package:qs_dart/src/models/encode_options.dart';
import 'package:qs_dart/src/qs.dart';

/// Convenience method for [QS.decode]
Map decode(
  dynamic input, [
  DecodeOptions options = const DecodeOptions(),
]) =>
    QS.decode(input, options);

/// Convenience method for [QS.encode]
String encode(
  Object? object, [
  EncodeOptions options = const EncodeOptions(),
]) =>
    QS.encode(object, options);
