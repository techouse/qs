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
      // Basic alphanumerics (remain unchanged)
      expect(
        Utils.escape(
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@*_+-./',
        ),
        equals(
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@*_+-./',
        ),
      );
      // Basic alphanumerics (remain unchanged)
      expect(Utils.escape('abc123'), equals('abc123'));
      // Accented characters (Latin-1 range uses %XX)
      expect(Utils.escape('äöü'), equals('%E4%F6%FC'));
      // Non-ASCII that falls outside Latin-1 uses %uXXXX
      expect(Utils.escape('ć'), equals('%u0107'));
      // Characters that are defined as safe
      expect(Utils.escape('@*_+-./'), equals('@*_+-./'));
      // Parentheses: in RFC3986 they are encoded
      expect(Utils.escape('('), equals('%28'));
      expect(Utils.escape(')'), equals('%29'));
      // Space character
      expect(Utils.escape(' '), equals('%20'));
      // Tilde is safe
      expect(Utils.escape('~'), equals('%7E'));
      // Punctuation that is not safe: exclamation and comma
      expect(Utils.escape('!'), equals('%21'));
      expect(Utils.escape(','), equals('%2C'));
      // Mixed safe and unsafe characters
      expect(Utils.escape('hello world!'), equals('hello%20world%21'));
      // Multiple spaces are each encoded
      expect(Utils.escape('a b c'), equals('a%20b%20c'));
      // A string with various punctuation
      expect(Utils.escape('Hello, World!'), equals('Hello%2C%20World%21'));
      // Null character should be encoded
      expect(Utils.escape('\x00'), equals('%00'));
      // Emoji (e.g. 😀 U+1F600)
      expect(Utils.escape('😀'), equals('%uD83D%uDE00'));
      // Test RFC1738 format: Parentheses are safe (left unchanged)
      expect(Utils.escape('(', format: Format.rfc1738), equals('('));
      expect(Utils.escape(')', format: Format.rfc1738), equals(')'));
      // Mixed test with RFC1738: other unsafe characters are still encoded
      expect(
        Utils.escape('(hello)!', format: Format.rfc1738),
        equals('(hello)%21'),
      );
    });

    test('escape huge string', () {
      final String hugeString = 'äöü' * 1000000;
      expect(Utils.escape(hugeString), equals('%E4%F6%FC' * 1000000));
    });

    test('unescape', () {
      // No escapes.
      expect(Utils.unescape('abc123'), equals('abc123'));
      // Hex escapes with uppercase hex digits.
      expect(Utils.unescape('%E4%F6%FC'), equals('äöü'));
      // Hex escapes with lowercase hex digits.
      expect(Utils.unescape('%e4%f6%fc'), equals('äöü'));
      // Unicode escape.
      expect(Utils.unescape('%u0107'), equals('ć'));
      // Unicode escape with lowercase digits.
      expect(Utils.unescape('%u0061'), equals('a'));
      // Characters that do not need escaping.
      expect(Utils.unescape('@*_+-./'), equals('@*_+-./'));
      // Hex escapes for punctuation.
      expect(Utils.unescape('%28'), equals('('));
      expect(Utils.unescape('%29'), equals(')'));
      expect(Utils.unescape('%20'), equals(' '));
      expect(Utils.unescape('%7E'), equals('~'));
      // A long string with only safe characters.
      expect(
        Utils.unescape(
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@*_+-./',
        ),
        equals(
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@*_+-./',
        ),
      );
      // A mix of Unicode and hex escapes.
      expect(Utils.unescape('%u0041%20%42'), equals('A B'));
      // A mix of literal text and hex escapes.
      expect(Utils.unescape('hello%20world'), equals('hello world'));
      // A literal percent sign that is not followed by a valid escape remains unchanged.
      expect(Utils.unescape('100% sure'), equals('100% sure'));
      // Mixed Unicode and hex escapes.
      expect(Utils.unescape('%u0041%65'), equals('Ae'));
      // Escaped percent signs that do not form a valid escape remain unchanged.
      expect(Utils.unescape('50%% off'), equals('50%% off'));
      // Consecutive escapes producing multiple spaces.
      expect(Utils.unescape('%20%u0020'), equals('  '));
      // An invalid escape sequence should remain unchanged.
      expect(Utils.unescape('abc%g'), equals('abc%g'));

      // The input "%uZZZZ" is 6 characters long so it passes the length check.
      // However, "ZZZZ" is not valid hex so int.parse will throw a FormatException.
      // In that case, the catch block writes the literal '%' and increments i by 1.
      // The remainder of the string is then processed normally.
      // For input "%uZZZZ", the processing is:
      // - At i = 0, encounter '%', then since i+1 is 'u' and there are 6 characters, try block is entered.
      // - int.parse("ZZZZ", radix: 16) fails, so the catch writes '%' and i becomes 1.
      // - Then the rest of the string ("uZZZZ") is appended as literal.
      // The expected result is "%uZZZZ".
      expect(Utils.unescape('%uZZZZ'), equals('%uZZZZ'));

      // Input "%u12" has only 4 characters.
      // For a valid %u escape we need 6 characters.
      // Thus, the branch "Not enough characters for a valid %u escape" is triggered,
      // which writes the literal '%' and increments i.
      // The remainder of the string ("u12") is then appended as literal.
      // Expected output is "%u12".
      expect(Utils.unescape('%u12'), equals('%u12'));

      // When "%" is the last character of the string (with no following characters),
      // the code writes it as literal.
      // For example, "abc%" should remain "abc%".
      expect(Utils.unescape('abc%'), equals('abc%'));
    });

    test('unescape huge string', () {
      final String hugeString = '%E4%F6%FC' * 1000000;
      expect(Utils.unescape(hugeString), equals('äöü' * 1000000));
    });

    group('merge', () {
      test('merges SplayTreeMap with List', () {
        expect(
          Utils.merge({'0': 'a'}, [const Undefined(), 'b']),
          equals({'0': 'a', '1': 'b'}),
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
                '0': 'bar',
                '1': {'first': '123'},
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
              'foo': {'0': 'bar', 'baz': 'xyzzy'},
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
              'foo': {'bar': 'baz', '0': 'xyzzy'},
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

    test('decode', () {
      expect(Utils.decode('a+b'), equals('a b'));
      expect(Utils.decode('name%2Eobj'), equals('name.obj'));
      expect(Utils.decode('name%2Eobj%2Efoo', charset: latin1),
          equals('name.obj.foo'));
    });

    test('encode', () {
      expect(Utils.encode(''), equals(''));

      expect(Utils.encode('(abc)'), equals('%28abc%29'));

      expect(
        Utils.encode('abc 123 💩', charset: latin1),
        equals('abc%20123%20%26%2355357%3B%26%2356489%3B'),
      );

      expect(
        Utils.encode('abc 123 💩'),
        equals('abc%20123%20%F0%9F%92%A9'),
      );

      final StringBuffer longString = StringBuffer();
      final StringBuffer expectedString = StringBuffer();
      for (int i = 0; i < 1500; i++) {
        longString.write(' ');
        expectedString.write('%20');
      }
      expect(
        Utils.encode(longString.toString()),
        equals(expectedString.toString()),
      );

      expect(Utils.encode('\x28\x29'), equals('%28%29'));

      expect(Utils.encode('\x28\x29', format: Format.rfc1738), equals('()'));

      expect(Utils.encode('Āက豈'), equals('%C4%80%E1%80%80%EF%A4%80'));

      expect(Utils.encode('\uD83D\uDCA9'), equals('%F0%9F%92%A9'));

      expect(Utils.encode('💩'), equals('%F0%9F%92%A9'));

      expect(
        Utils.encode('💩', charset: latin1),
        equals('%26%2355357%3B%26%2356489%3B'),
      );
    });

    group('interpretNumericEntities', () {
      test('returns input unchanged when there are no entities', () {
        expect(Utils.interpretNumericEntities('hello world'), 'hello world');
        expect(Utils.interpretNumericEntities('100% sure'), '100% sure');
      });

      test('decodes a single decimal entity', () {
        expect(Utils.interpretNumericEntities('A = &#65;'), 'A = A');
        expect(Utils.interpretNumericEntities('&#48;&#49;&#50;'), '012');
      });

      test('decodes multiple entities in a sentence', () {
        const input = 'Hello &#87;&#111;&#114;&#108;&#100;!';
        const expected = 'Hello World!';
        expect(Utils.interpretNumericEntities(input), expected);
      });

      test('surrogate pair as two decimal entities (emoji)', () {
        // U+1F4A9 (💩) is represented as two decimal entities:
        // 55357 (0xD83D) and 56489 (0xDCA9)
        expect(Utils.interpretNumericEntities('&#55357;&#56489;'), '💩');
      });

      test('entities can appear at string boundaries', () {
        expect(Utils.interpretNumericEntities('&#65;BC'), 'ABC');
        expect(Utils.interpretNumericEntities('ABC&#33;'), 'ABC!');
        expect(Utils.interpretNumericEntities('&#65;'), 'A');
      });

      test('mixes literals and entities', () {
        // '=' is 61
        expect(Utils.interpretNumericEntities('x&#61;y'), 'x=y');
        expect(Utils.interpretNumericEntities('x=&#61;y'), 'x==y');
      });

      test('malformed patterns remain unchanged', () {
        // No digits
        expect(Utils.interpretNumericEntities('&#;'), '&#;');
        // Missing semicolon
        expect(Utils.interpretNumericEntities('&#12'), '&#12');
        // Hex form not supported by this decoder
        expect(Utils.interpretNumericEntities('&#x41;'), '&#x41;');
        // Space inside
        expect(Utils.interpretNumericEntities('&# 12;'), '&# 12;');
        // Negative / non-digit after '#'
        expect(Utils.interpretNumericEntities('&#-12;'), '&#-12;');
        // Mixed garbage
        expect(Utils.interpretNumericEntities('&#+;'), '&#+;');
      });

      test('out-of-range code points remain unchanged', () {
        // Max valid is 0x10FFFF (1114111). One above should be left as literal.
        expect(Utils.interpretNumericEntities('&#1114112;'), '&#1114112;');
      });
    });

    group('compact', () {
      test('removes Undefined from flat map', () {
        final m = <String, dynamic>{
          'a': 1,
          'b': const Undefined(),
          'c': null,
        };
        final out = Utils.compact(m);
        expect(out, equals({'a': 1, 'c': null}));
        // in-place
        expect(identical(out, m), isTrue);
      });

      test('removes Undefined from nested map/list', () {
        final m = <String, dynamic>{
          'a': [
            1,
            const Undefined(),
            {'x': const Undefined(), 'y': 2},
            [const Undefined(), 3],
          ],
          'b': {'k': const Undefined(), 'z': 0},
        };
        final out = Utils.compact(m);
        expect(
          out,
          equals({
            'a': [
              1,
              {'y': 2},
              [3],
            ],
            'b': {'z': 0},
          }),
        );
      });

      test('handles cycles without infinite loop', () {
        final a = <String, dynamic>{};
        final b = <String, dynamic>{'child': a, 'u': const Undefined()};
        a['parent'] = b;
        a['keep'] = 1;

        final out = Utils.compact(a);
        expect(out['keep'], 1);
        expect((out['parent'] as Map)['child'], same(out)); // cycle preserved
        expect((out['parent'] as Map).containsKey('u'), isFalse);
      });

      test('preserves order', () {
        final m = <String, dynamic>{
          'first': 1,
          'second': const Undefined(),
          'third': 3,
        };
        final out = Utils.compact(m);

        // insertion order: first, third
        expect(out.keys.toList(), equals(['first', 'third']));
      });

      test('shared substructures are visited once', () {
        final shared = <String, dynamic>{'x': const Undefined(), 'y': 1};
        final m = <String, dynamic>{
          'a': shared,
          'b': shared,
        };

        final out = Utils.compact(m);
        expect((out['a'] as Map).containsKey('x'), isFalse);
        expect((out['a'] as Map)['y'], 1);
        // 'b' points to the same (mutated) object
        expect(identical(out['a'], out['b']), isTrue);
      });
    });
  });
}
