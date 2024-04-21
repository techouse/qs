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

    test('encode huge string', () {
      final String hugeString = 'a' * 1000000;
      expect(Utils.encode(hugeString), equals(hugeString));
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

    test('escape huge string', () {
      final String hugeString = 'äöü' * 1000000;
      expect(Utils.escape(hugeString), equals('%E4%F6%FC' * 1000000));
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

    test('unescape huge string', () {
      final String hugeString = '%E4%F6%FC' * 1000000;
      expect(Utils.unescape(hugeString), equals('äöü' * 1000000));
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
        'merges two objects with the same key and different values into a list',
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

      test('merges null into a list', () {
        expect(
          Utils.merge(null, [42]),
          equals([null, 42]),
        );
        expect(
          Utils.merge(null, [42]),
          isA<List>(),
        );
      });

      test('merges null into a set', () {
        expect(
          Utils.merge(null, {'foo'}),
          equals([null, 'foo']),
        );
        expect(
          Utils.merge(null, {'foo'}),
          isA<List>(),
        );
      });

      test('merges String into set', () {
        expect(
          Utils.merge({'foo'}, 'bar'),
          equals({'foo', 'bar'}),
        );
        expect(
          Utils.merge({'foo'}, 'bar'),
          isA<Set>(),
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
        expect(
          Utils.merge({'a': 'b'}, {'a': 'c'}),
          contains('a'),
        );
        expect(
          Utils.merge({'a': 'b'}, {'a': 'c'})['a'],
          isA<List>(),
        );
      });

      test('merges a standalone and an object into a list', () {
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

      test('merges a standalone and two objects into a list', () {
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

      test('merges an object sandwiched by two standalones into a list', () {
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
          Utils.merge(['foo'], ['bar', 'xyzzy']),
          equals(['foo', 'bar', 'xyzzy']),
        );
        expect(
          Utils.merge(['foo'], ['bar', 'xyzzy']),
          isA<List>(),
        );

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
        expect(
          Utils.merge(
            {
              'foo': ['baz']
            },
            {
              'foo': ['bar', 'xyzzy']
            },
          ),
          contains('foo'),
        );
        expect(
          Utils.merge(
            {
              'foo': ['baz']
            },
            {
              'foo': ['bar', 'xyzzy']
            },
          )['foo'],
          isA<List>(),
        );
      });

      test('merges two sets into a list', () {
        expect(
          Utils.merge({'foo'}, {'bar', 'xyzzy'}),
          equals({'foo', 'bar', 'xyzzy'}),
        );
        expect(
          Utils.merge({'foo'}, {'bar', 'xyzzy'}),
          isA<Set>(),
        );

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
        expect(
          Utils.merge(
            {
              'foo': {'baz'}
            },
            {
              'foo': {'bar', 'xyzzy'}
            },
          ),
          contains('foo'),
        );
        expect(
          Utils.merge(
            {
              'foo': {'baz'}
            },
            {
              'foo': {'bar', 'xyzzy'}
            },
          )['foo'],
          isA<Set>(),
        );
      });

      test('merges a set into a list', () {
        expect(
          Utils.merge(
            {
              'foo': ['baz']
            },
            {
              'foo': {'bar'}
            },
          ),
          equals(
            {
              'foo': ['baz', 'bar'],
            },
          ),
        );
        expect(
          Utils.merge(
            {
              'foo': ['baz']
            },
            {
              'foo': {'bar'}
            },
          ),
          contains('foo'),
        );
        expect(
          Utils.merge(
            {
              'foo': ['baz']
            },
            {
              'foo': {'bar'}
            },
          )['foo'],
          isA<List>(),
        );
      });

      test('merges a list into a set', () {
        expect(
          Utils.merge(
            {
              'foo': {'baz'}
            },
            {
              'foo': ['bar']
            },
          ),
          equals(
            {
              'foo': {'baz', 'bar'},
            },
          ),
        );
        expect(
          Utils.merge(
            {
              'foo': {'baz'}
            },
            {
              'foo': ['bar']
            },
          ),
          contains('foo'),
        );
        expect(
          Utils.merge(
            {
              'foo': {'baz'}
            },
            {
              'foo': ['bar']
            },
          )['foo'],
          isA<Set>(),
        );
      });

      test('merges a set into a list', () {
        expect(
          Utils.merge(
            {
              'foo': ['baz']
            },
            {
              'foo': {'bar', 'xyzzy'}
            },
          ),
          equals(
            {
              'foo': ['baz', 'bar', 'xyzzy'],
            },
          ),
        );
        expect(
          Utils.merge(
            {
              'foo': ['baz']
            },
            {
              'foo': {'bar', 'xyzzy'}
            },
          ),
          contains('foo'),
        );
        expect(
          Utils.merge(
            {
              'foo': ['baz']
            },
            {
              'foo': {'bar', 'xyzzy'}
            },
          )['foo'],
          isA<List>(),
        );
      });

      test('merges an object into a list', () {
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
        expect(
          Utils.merge(
            {
              'foo': ['bar']
            },
            {
              'foo': {'baz': 'xyzzy'}
            },
          ),
          contains('foo'),
        );
        expect(
          Utils.merge(
            {
              'foo': ['bar']
            },
            {
              'foo': {'baz': 'xyzzy'}
            },
          )['foo'],
          isA<Map>(),
        );
      });

      test('merges a list into an object', () {
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
        expect(
            Utils.merge(
              {
                'foo': {'bar': 'baz'}
              },
              {
                'foo': ['xyzzy']
              },
            ),
            contains('foo'));
        expect(
          Utils.merge(
            {
              'foo': {'bar': 'baz'}
            },
            {
              'foo': ['xyzzy']
            },
          )['foo'],
          isA<Map>(),
        );
      });

      test('merge set with undefined with another set', () {
        final Undefined undefined = const Undefined();

        expect(
          Utils.merge(
            {
              'foo': {'bar'}
            },
            {
              'foo': {undefined, 'baz'}
            },
          ),
          equals(
            {
              'foo': {'bar', 'baz'},
            },
          ),
        );
        expect(
          Utils.merge(
            {
              'foo': {'bar'}
            },
            {
              'foo': {undefined, 'baz'}
            },
          ),
          contains('foo'),
        );
        expect(
          Utils.merge(
            {
              'foo': {'bar'}
            },
            {
              'foo': {undefined, 'baz'}
            },
          )['foo'],
          isA<Set>(),
        );

        expect(
          Utils.merge(
            {
              'foo': {undefined, 'bar'}
            },
            {
              'foo': {'baz'}
            },
          ),
          equals(
            {
              'foo': {'bar', 'baz'},
            },
          ),
        );
        expect(
          Utils.merge(
            {
              'foo': {undefined, 'bar'}
            },
            {
              'foo': {'baz'}
            },
          ),
          contains('foo'),
        );
        expect(
          Utils.merge(
            {
              'foo': {undefined, 'bar'}
            },
            {
              'foo': {'baz'}
            },
          )['foo'],
          isA<Set>(),
        );
      });

      test('merge set of Maps with another set of Maps', () {
        expect(
          Utils.merge(
            {
              {'bar': 'baz'}
            },
            {
              {'baz': 'xyzzy'}
            },
          ),
          equals(
            {
              {'bar': 'baz', 'baz': 'xyzzy'},
            },
          ),
        );
        expect(
          Utils.merge(
            {
              {'bar': 'baz'}
            },
            {
              {'baz': 'xyzzy'}
            },
          ),
          isA<Set>(),
        );

        expect(
          Utils.merge(
            {
              'foo': {
                {'bar': 'baz'}
              }
            },
            {
              'foo': {
                {'baz': 'xyzzy'}
              }
            },
          ),
          equals(
            {
              'foo': {
                {'bar': 'baz', 'baz': 'xyzzy'},
              },
            },
          ),
        );
        expect(
            Utils.merge(
              {
                'foo': {
                  {'bar': 'baz'}
                }
              },
              {
                'foo': {
                  {'baz': 'xyzzy'}
                }
              },
            ),
            contains('foo'));
        expect(
          Utils.merge(
            {
              'foo': {
                {'bar': 'baz'}
              }
            },
            {
              'foo': {
                {'baz': 'xyzzy'}
              }
            },
          )['foo'],
          isA<Set>(),
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
