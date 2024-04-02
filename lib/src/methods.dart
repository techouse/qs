import 'package:qs_dart/src/models/decode_options.dart';
import 'package:qs_dart/src/models/encode_options.dart';
import 'package:qs_dart/src/qs.dart';

Map decode(
  dynamic input, [
  DecodeOptions options = const DecodeOptions(),
]) =>
    QS.decode(input, options);

String encode(
  Object? object, [
  EncodeOptions options = const EncodeOptions(),
]) =>
    QS.encode(object, options);
