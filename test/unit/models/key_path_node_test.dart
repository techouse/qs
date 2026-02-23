import 'package:qs_dart/src/models/key_path_node.dart';
import 'package:test/test.dart';

void main() {
  group('KeyPathNode', () {
    test('append returns same node for empty segment', () {
      final root = KeyPathNode.fromMaterialized('a');

      expect(identical(root.append(''), root), isTrue);
    });

    test('materialize composes full path once', () {
      final node =
          KeyPathNode.fromMaterialized('a').append('[b]').append('[c]');

      final first = node.materialize();
      final second = node.materialize();

      expect(first, equals('a[b][c]'));
      expect(identical(first, second), isTrue);
    });

    test('materialize composes from nearest cached ancestor', () {
      final parent =
          KeyPathNode.fromMaterialized('a').append('[b]').append('[c]');
      final leaf = parent.append('[d]');

      expect(parent.materialize(), equals('a[b][c]'));
      final first = leaf.materialize();
      final second = leaf.materialize();

      expect(first, equals('a[b][c][d]'));
      expect(identical(first, second), isTrue);
    });

    test('asDotEncoded returns same node when there are no dots', () {
      final node = KeyPathNode.fromMaterialized('a').append('[b]');

      final encoded = node.asDotEncoded();

      expect(identical(encoded, node), isTrue);
    });

    test('asDotEncoded encodes dots in a root node', () {
      final root = KeyPathNode.fromMaterialized('a.b.c');

      expect(root.asDotEncoded().materialize(), equals('a%2Eb%2Ec'));
    });

    test('asDotEncoded caches encoded view across calls', () {
      final node =
          KeyPathNode.fromMaterialized('a.b').append('[c.d]').append('[e]');

      final first = node.asDotEncoded();
      final second = node.asDotEncoded();

      expect(first.materialize(), equals('a%2Eb[c%2Ed][e]'));
      expect(identical(first, second), isTrue);
    });

    test('asDotEncoded handles deep uncached chains without recursion', () {
      KeyPathNode node = KeyPathNode.fromMaterialized('root.part');
      for (int i = 0; i < 5000; i++) {
        node = node.append('[k$i.v$i]');
      }

      final encodedFirst = node.asDotEncoded();
      final encodedSecond = node.asDotEncoded();

      expect(identical(encodedFirst, encodedSecond), isTrue);
      expect(encodedFirst.materialize().startsWith('root%2Epart[k0%2Ev0]'),
          isTrue);
      expect(encodedFirst.materialize().contains('%2E'), isTrue);
    });

    test('deep chain materialize and asDotEncoded use cached results', () {
      final node = KeyPathNode.fromMaterialized('a.b')
          .append('[c.d]')
          .append('[e.f]')
          .append('[g.h]')
          .append('[i]');

      final materializedFirst = node.materialize();
      final materializedSecond = node.materialize();

      expect(materializedFirst, equals('a.b[c.d][e.f][g.h][i]'));
      expect(identical(materializedFirst, materializedSecond), isTrue);

      final encodedFirst = node.asDotEncoded();
      final encodedSecond = node.asDotEncoded();

      expect(
          encodedFirst.materialize(), equals('a%2Eb[c%2Ed][e%2Ef][g%2Eh][i]'));
      expect(identical(encodedFirst, encodedSecond), isTrue);
    });
  });
}
