import 'package:qs_dart/qs_dart.dart';

const int _warmupSamples = 5;
const int _measurementSamples = 7;
const List<({int depth, int iterations})> _deepCases =
    <({int depth, int iterations})>[
  (depth: 2000, iterations: 20),
  (depth: 5000, iterations: 20),
  (depth: 12000, iterations: 8),
];

Map<String, dynamic> _buildNested(int depth) {
  Map<String, dynamic> current = <String, dynamic>{'leaf': 'x'};
  for (int i = 0; i < depth; i++) {
    current = <String, dynamic>{'a': current};
  }
  return current;
}

double _median(List<double> values) {
  values.sort();
  return values[values.length ~/ 2];
}

void main() {
  const EncodeOptions options = EncodeOptions(encode: false);

  print('qs.dart perf snapshot (median of 7 samples)');
  print('Encode (encode=false, deep nesting):');

  for (final testCase in _deepCases) {
    final Map<String, dynamic> payload = _buildNested(testCase.depth);

    for (int i = 0; i < _warmupSamples; i++) {
      QS.encode(payload, options);
    }

    final List<double> samples = <double>[];
    int outputLength = 0;

    for (int s = 0; s < _measurementSamples; s++) {
      final Stopwatch sw = Stopwatch()..start();
      String encoded = '';
      for (int i = 0; i < testCase.iterations; i++) {
        encoded = QS.encode(payload, options);
      }
      sw.stop();

      outputLength = encoded.length;
      samples.add(
        sw.elapsedMicroseconds / 1000.0 / testCase.iterations,
      );
    }

    print(
      '  depth=${testCase.depth.toString().padLeft(5)}: '
      '${_median(samples).toStringAsFixed(3).padLeft(8)} ms/op | '
      'len=$outputLength',
    );
  }
}
