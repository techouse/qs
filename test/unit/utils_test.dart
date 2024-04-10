// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:convert' show latin1, utf8;

import 'package:qs_dart/qs_dart.dart';
import 'package:qs_dart/src/utils.dart';
import 'package:test/test.dart';

import '../fixtures/dummy_enum.dart';

void main() {
  group('Utils', () {
    test('encode', () {
      expect(Utils.encode('foo+bar'), equals('foo%2Bbar'));
      // exceptions
      expect(Utils.encode('foo-bar'), equals('foo-bar'));
      expect(Utils.encode('foo_bar'), equals('foo_bar'));
      expect(Utils.encode('foo~bar'), equals('foo~bar'));
      expect(Utils.encode('foo.bar'), equals('foo.bar'));
      // space
      expect(Utils.encode('foo bar'), equals('foo%20bar'));
      // parentheses
      expect(Utils.encode('foo(bar)'), equals('foo%28bar%29'));
      expect(
        Utils.encode('foo(bar)', format: Format.rfc1738),
        equals('foo(bar)'),
      );
      expect(DummyEnum.lorem, isA<Enum>());
      expect(Utils.encode(DummyEnum.lorem), equals('lorem'));

      // does not encode
      // Iterable
      expect(Utils.encode([1, 2]), equals(''));
      // Map
      expect(Utils.encode({'a': 'b'}), equals(''));
      // Symbol
      expect(Utils.encode(#a), equals(''));
      // Record
      expect(Utils.encode(('a', 'b')), equals(''));
      // Future
      expect(
        Utils.encode(Future.value('b')),
        equals(''),
      );
      // Undefined
      expect(
        Utils.encode(const Undefined()),
        equals(''),
      );
    });

    test('decode', () {
      expect(Utils.decode('foo%2Bbar'), equals('foo+bar'));
      // exceptions
      expect(Utils.decode('foo-bar'), equals('foo-bar'));
      expect(Utils.decode('foo_bar'), equals('foo_bar'));
      expect(Utils.decode('foo~bar'), equals('foo~bar'));
      expect(Utils.decode('foo.bar'), equals('foo.bar'));
      // space
      expect(Utils.decode('foo%20bar'), equals('foo bar'));
      // parentheses
      expect(Utils.decode('foo%28bar%29'), equals('foo(bar)'));
    });

    test('encode utf8', () {
      expect(Utils.encode('foo+bar', charset: utf8), equals('foo%2Bbar'));
      // exceptions
      expect(Utils.encode('foo-bar', charset: utf8), equals('foo-bar'));
      expect(Utils.encode('foo_bar', charset: utf8), equals('foo_bar'));
      expect(Utils.encode('foo~bar', charset: utf8), equals('foo~bar'));
      expect(Utils.encode('foo.bar', charset: utf8), equals('foo.bar'));
      // space
      expect(Utils.encode('foo bar', charset: utf8), equals('foo%20bar'));
      // parentheses
      expect(Utils.encode('foo(bar)', charset: utf8), equals('foo%28bar%29'));
      expect(
        Utils.encode('foo(bar)', charset: utf8, format: Format.rfc1738),
        equals('foo(bar)'),
      );
    });

    test('decode utf8', () {
      expect(Utils.decode('foo%2Bbar', charset: utf8), equals('foo+bar'));
      // exceptions
      expect(Utils.decode('foo-bar', charset: utf8), equals('foo-bar'));
      expect(Utils.decode('foo_bar', charset: utf8), equals('foo_bar'));
      expect(Utils.decode('foo~bar', charset: utf8), equals('foo~bar'));
      expect(Utils.decode('foo.bar', charset: utf8), equals('foo.bar'));
      // space
      expect(Utils.decode('foo%20bar', charset: utf8), equals('foo bar'));
      // parentheses
      expect(Utils.decode('foo%28bar%29', charset: utf8), equals('foo(bar)'));
    });

    test('encode latin1', () {
      expect(Utils.encode('foo+bar', charset: latin1), equals('foo+bar'));
      // exceptions
      expect(Utils.encode('foo-bar', charset: latin1), equals('foo-bar'));
      expect(Utils.encode('foo_bar', charset: latin1), equals('foo_bar'));
      expect(Utils.encode('foo~bar', charset: latin1), equals('foo%7Ebar'));
      expect(Utils.encode('foo.bar', charset: latin1), equals('foo.bar'));
      // space
      expect(Utils.encode('foo bar', charset: latin1), equals('foo%20bar'));
      // parentheses
      expect(Utils.encode('foo(bar)', charset: latin1), equals('foo%28bar%29'));
      expect(
        Utils.encode('foo(bar)', charset: latin1, format: Format.rfc1738),
        equals('foo(bar)'),
      );
    });

    test('decode latin1', () {
      expect(Utils.decode('foo+bar', charset: latin1), equals('foo bar'));
      // exceptions
      expect(Utils.decode('foo-bar', charset: latin1), equals('foo-bar'));
      expect(Utils.decode('foo_bar', charset: latin1), equals('foo_bar'));
      expect(Utils.decode('foo%7Ebar', charset: latin1), equals('foo~bar'));
      expect(Utils.decode('foo.bar', charset: latin1), equals('foo.bar'));
      // space
      expect(Utils.decode('foo%20bar', charset: latin1), equals('foo bar'));
      // parentheses
      expect(Utils.decode('foo%28bar%29', charset: latin1), equals('foo(bar)'));
    });

    test('escape', () {
      expect(Utils.escape('abc123'), equals('abc123'));
      expect(Utils.escape('äöü'), equals('%E4%F6%FC'));
      expect(Utils.escape('ć'), equals('%u0107'));
      // special characters
      expect(Utils.escape('@*_+-./'), equals('@*_+-./'));
      expect(Utils.escape('('), equals('%28'));
      expect(Utils.escape(')'), equals('%29'));
      expect(Utils.escape(' '), equals('%20'));
      expect(Utils.escape('~'), equals('%7E'));

      expect(
        Utils.escape(
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@*_+-./',
        ),
        equals(
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@*_+-./',
        ),
      );
    });

    test('unescape', () {
      expect(Utils.unescape('abc123'), equals('abc123'));
      expect(Utils.unescape('%E4%F6%FC'), equals('äöü'));
      expect(Utils.unescape('%u0107'), equals('ć'));
      // special characters
      expect(Utils.unescape('@*_+-./'), equals('@*_+-./'));
      expect(Utils.unescape('%28'), equals('('));
      expect(Utils.unescape('%29'), equals(')'));
      expect(Utils.unescape('%20'), equals(' '));
      expect(Utils.unescape('%7E'), equals('~'));

      expect(
        Utils.unescape(
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@*_+-./',
        ),
        equals(
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@*_+-./',
        ),
      );
    });

    group('merge', () {
      test('merges SplayTreeMap with List', () {
        expect(
          Utils.merge({0: 'a'}, [const Undefined(), 'b']),
          equals({0: 'a', 1: 'b'}),
        );
      });

      test('merges two objects with the same key and different values', () {
        expect(
          Utils.merge(
            {
              'foo': [
                {'a': 'a', 'b': 'b'},
                {'a': 'aa'}
              ]
            },
            {
              'foo': [
                const Undefined(),
                {'b': 'bb'}
              ]
            },
          ),
          equals(
            {
              'foo': [
                {'a': 'a', 'b': 'b'},
                {'a': 'aa', 'b': 'bb'}
              ]
            },
          ),
        );
      });

      test(
        'merges two objects with the same key and different list values',
        () {
          expect(
            Utils.merge(
              {
                'foo': [
                  {
                    'baz': ['15'],
                  }
                ]
              },
              {
                'foo': [
                  {
                    'baz': [const Undefined(), '16'],
                  }
                ]
              },
            ),
            equals(
              {
                'foo': [
                  {
                    'baz': ['15', '16'],
                  }
                ]
              },
            ),
          );
        },
      );

      test(
        'merges two objects with the same key and different values into an list',
        () {
          expect(
            Utils.merge(
              {
                'foo': [
                  {'a': 'b'},
                ],
              },
              {
                'foo': [
                  {'c': 'd'},
                ],
              },
            ),
            equals({
              'foo': [
                {
                  'a': 'b',
                  'c': 'd',
                },
              ],
            }),
          );
        },
      );

      test('merges true into null', () {
        expect(
          Utils.merge(null, true),
          equals([null, true]),
        );
      });

      test('merges null into an list', () {
        expect(
          Utils.merge(null, [42]),
          equals([null, 42]),
        );
      });

      test('merges two objects with the same key', () {
        expect(
          Utils.merge({'a': 'b'}, {'a': 'c'}),
          equals(
            {
              'a': ['b', 'c'],
            },
          ),
        );
      });

      test('merges a standalone and an object into an list', () {
        expect(
          Utils.merge(
            {'foo': 'bar'},
            {
              'foo': {'first': '123'}
            },
          ),
          equals(
            {
              'foo': [
                'bar',
                {'first': '123'}
              ],
            },
          ),
        );
      });

      test('merges a standalone and two objects into an list', () {
        expect(
          Utils.merge(
            {
              'foo': [
                'bar',
                {'first': '123'}
              ]
            },
            {
              'foo': {'second': '456'}
            },
          ),
          equals(
            {
              'foo': {
                0: 'bar',
                1: {'first': '123'},
                'second': '456'
              }
            },
          ),
        );
      });

      test('merges an object sandwiched by two standalones into an list', () {
        expect(
          Utils.merge(
            {
              'foo': [
                'bar',
                {'first': '123', 'second': '456'}
              ]
            },
            {'foo': 'baz'},
          ),
          equals(
            {
              'foo': [
                'bar',
                {'first': '123', 'second': '456'},
                'baz'
              ],
            },
          ),
        );
      });

      test('merges two lists into a list', () {
        expect(
          Utils.merge(
            {
              'foo': ['baz']
            },
            {
              'foo': ['bar', 'xyzzy']
            },
          ),
          equals(
            {
              'foo': ['baz', 'bar', 'xyzzy'],
            },
          ),
        );
      });

      test('merges two sets into a list', () {
        expect(
          Utils.merge(
            {
              'foo': {'baz'}
            },
            {
              'foo': {'bar', 'xyzzy'}
            },
          ),
          equals(
            {
              'foo': {'baz', 'bar', 'xyzzy'},
            },
          ),
        );
      });

      test('merges an object into an list', () {
        expect(
          Utils.merge(
            {
              'foo': ['bar']
            },
            {
              'foo': {'baz': 'xyzzy'}
            },
          ),
          equals(
            {
              'foo': {0: 'bar', 'baz': 'xyzzy'},
            },
          ),
        );
      });

      test('merges an list into an object', () {
        expect(
          Utils.merge(
            {
              'foo': {'bar': 'baz'}
            },
            {
              'foo': ['xyzzy']
            },
          ),
          equals(
            {
              'foo': {'bar': 'baz', 0: 'xyzzy'},
            },
          ),
        );
      });
    });

    group('combine', () {
      test('both lists', () {
        const List<int> a = [1];
        const List<int> b = [2];
        final List<int> combined = Utils.combine(a, b);

        expect(a, equals([1]));
        expect(b, equals([2]));
        expect(a, isNot(same(combined)));
        expect(b, isNot(same(combined)));
        expect(combined, equals([1, 2]));
      });

      test('one list, one non-list', () {
        const int aN = 1;
        const List<int> a = [aN];
        const int bN = 2;
        const List<int> b = [bN];

        final List<int> combinedAnB = Utils.combine(aN, b);
        expect(b, equals([bN]));
        expect(aN, isNot(same(combinedAnB)));
        expect(a, isNot(same(combinedAnB)));
        expect(bN, isNot(same(combinedAnB)));
        expect(b, isNot(same(combinedAnB)));
        expect(combinedAnB, equals([1, 2]));

        final List<int> combinedABn = Utils.combine(a, bN);
        expect(a, equals([aN]));
        expect(aN, isNot(same(combinedABn)));
        expect(a, isNot(same(combinedABn)));
        expect(bN, isNot(same(combinedABn)));
        expect(b, isNot(same(combinedABn)));
        expect(combinedABn, equals([1, 2]));
      });

      test('neither is a list', () {
        const int a = 1;
        const int b = 2;
        final List<int> combined = Utils.combine(a, b);

        expect(a, isNot(same(combined)));
        expect(b, isNot(same(combined)));
        expect(combined, equals([1, 2]));
      });
    });
  });
}
