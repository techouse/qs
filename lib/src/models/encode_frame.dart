part of '../qs.dart';

final class _EncodeFrame {
  _EncodeFrame({
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

  dynamic object;
  final bool undefined;
  final WeakMap sideChannel;
  final String prefix;
  final ListFormatGenerator generateArrayPrefix;
  final bool commaRoundTrip;
  final bool commaCompactNulls;
  final bool allowEmptyLists;
  final bool strictNullHandling;
  final bool skipNulls;
  final bool encodeDotInKeys;
  final Encoder? encoder;
  final DateSerializer? serializeDate;
  final Sorter? sort;
  final dynamic filter;
  final bool allowDots;
  final Format format;
  final Formatter formatter;
  final bool encodeValuesOnly;
  final Encoding charset;
  final void Function(List<String> result) onResult;

  bool prepared = false;
  bool tracked = false;
  Object? trackedObject;
  List<dynamic> objKeys = const [];
  int index = 0;
  List<dynamic>? seqList;
  int? commaEffectiveLength;
  String? adjustedPrefix;
  List<String> values = [];
}
