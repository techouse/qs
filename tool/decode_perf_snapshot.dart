import 'package:qs_dart/qs_dart.dart';

const int _warmupSamples = 5;
const int _measurementSamples = 7;

const List<_DecodeCase> _cases = <_DecodeCase>[
  _DecodeCase(
    name: 'C1',
    count: 100,
    comma: false,
    utf8Sentinel: false,
    valueLen: 8,
    iterations: 120,
  ),
  _DecodeCase(
    name: 'C2',
    count: 1000,
    comma: false,
    utf8Sentinel: false,
    valueLen: 40,
    iterations: 16,
  ),
  _DecodeCase(
    name: 'C3',
    count: 1000,
    comma: true,
    utf8Sentinel: true,
    valueLen: 40,
    iterations: 16,
  ),
];

final class _DecodeCase {
  const _DecodeCase({
    required this.name,
    required this.count,
    required this.comma,
    required this.utf8Sentinel,
    required this.valueLen,
    required this.iterations,
  });

  final String name;
  final int count;
  final bool comma;
  final bool utf8Sentinel;
  final int valueLen;
  final int iterations;
}

String _makeValue(int length, int seed) {
  final StringBuffer out = StringBuffer();
  int state = (seed * 2654435761 + 1013904223) & 0xFFFFFFFF;

  for (int i = 0; i < length; i++) {
    state ^= (state << 13) & 0xFFFFFFFF;
    state ^= (state >> 17) & 0xFFFFFFFF;
    state ^= (state << 5) & 0xFFFFFFFF;

    final int x = state % 62;
    final int ch = switch (x) {
      < 10 => 0x30 + x,
      < 36 => 0x41 + (x - 10),
      _ => 0x61 + (x - 36),
    };
    out.writeCharCode(ch);
  }

  return out.toString();
}

String _buildQuery({
  required int count,
  required bool commaLists,
  required bool utf8Sentinel,
  required int valueLen,
}) {
  final StringBuffer sb = StringBuffer();
  bool first = true;

  if (utf8Sentinel) {
    sb.write('utf8=%E2%9C%93');
    first = false;
  }

  for (int i = 0; i < count; i++) {
    if (!first) sb.write('&');
    first = false;

    final String key = 'k$i';
    final String value =
        (commaLists && i % 10 == 0) ? 'a,b,c' : _makeValue(valueLen, i);
    sb
      ..write(key)
      ..write('=')
      ..write(value);
  }

  return sb.toString();
}

double _median(List<double> values) {
  values.sort();
  return values[values.length ~/ 2];
}

void main() {
  print('qs.dart decode perf snapshot (median of 7 samples)');
  print('Decode (public API):');

  for (final _DecodeCase c in _cases) {
    final String query = _buildQuery(
      count: c.count,
      commaLists: c.comma,
      utf8Sentinel: c.utf8Sentinel,
      valueLen: c.valueLen,
    );

    final DecodeOptions options = DecodeOptions(
      comma: c.comma,
      parseLists: true,
      parameterLimit: double.infinity,
      throwOnLimitExceeded: false,
      interpretNumericEntities: false,
      charsetSentinel: c.utf8Sentinel,
      ignoreQueryPrefix: false,
    );

    for (int i = 0; i < _warmupSamples; i++) {
      QS.decode(query, options);
    }

    final List<double> samples = <double>[];
    int keyCount = 0;

    for (int s = 0; s < _measurementSamples; s++) {
      final Stopwatch sw = Stopwatch()..start();
      Map<String, dynamic> decoded = const <String, dynamic>{};
      for (int i = 0; i < c.iterations; i++) {
        decoded = QS.decode(query, options);
      }
      sw.stop();

      keyCount = decoded.length;
      samples.add(sw.elapsedMicroseconds / 1000.0 / c.iterations);
    }

    print(
      '  ${c.name}: count=${c.count.toString().padLeft(4)}, '
      'comma=${c.comma.toString().padRight(5)}, '
      'utf8=${c.utf8Sentinel.toString().padRight(5)}, '
      'len=${c.valueLen.toString().padLeft(2)}: '
      '${_median(samples).toStringAsFixed(3).padLeft(7)} ms/op | keys=$keyCount',
    );
  }
}
