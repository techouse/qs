import 'dart:convert';
import 'dart:typed_data';

import 'package:euc/jis.dart';
import 'package:qs_dart/src/enums/duplicates.dart';
import 'package:qs_dart/src/models/decode_options.dart';
import 'package:qs_dart/src/qs.dart';
import 'package:qs_dart/src/utils.dart';
import 'package:test/test.dart';

import '../fixtures/data/empty_test_cases.dart';

void main() {
  group('decode', () {
    test('throws ArgumentError when parameter limit is not positive', () {
      expect(
        () => QS.decode(
          'a=b&c=d',
          DecodeOptions(parameterLimit: 0),
        ),
        throwsA(anyOf(
          isA<ArgumentError>(),
          isA<StateError>(),
          isA<AssertionError>(),
        )),
      );
    });

    test('Nested list handling in _parseObject method', () {
      // This test targets lines 154-156 in decode.dart
      // We need to create a scenario where val is a List and parentKey exists in the list

      // First, create a list with a nested list at index 0
      final list = [
        ['nested']
      ];

      // Convert to a query string
      final queryString = QS.encode({'a': list});

      // Now decode it back, which should exercise the code path we're targeting
      final result = QS.decode(queryString);

      // Verify the result
      expect(result, {
        'a': [
          ['nested']
        ]
      });

      // Try another approach with a more complex structure
      // This creates a query string like 'a[0][0]=value'
      final result2 = QS.decode(
        'a[0][0]=value',
        const DecodeOptions(depth: 5),
      );

      // This should create a nested list structure
      expect(result2, {
        'a': [
          ['value']
        ]
      });

      // Try a more complex approach that should trigger the specific code path
      // First, create a query string that will create a list with a specific index
      final queryString3 = 'a[0][]=first&a[0][]=second';

      // Now decode it, which should create a list with a nested list
      final result3 = QS.decode(queryString3);

      // Verify the result
      expect(result3, {
        'a': [
          ['first', 'second']
        ]
      });

      // Now try to add to the existing list
      final queryString4 = 'a[0][2]=third';

      // Decode it with the existing result as the input
      final result4 = QS.decode(queryString4);

      // Verify the result
      expect(result4, {
        'a': [
          ['third']
        ]
      });
    });
    test('throws an ArgumentError if the input is not a String or a Map', () {
      expect(() => QS.decode(123), throwsArgumentError);
    });

    test('parses a simple string', () {
      expect(QS.decode('0=foo'), equals({'0': 'foo'}));
      expect(QS.decode('foo=c++'), equals({'foo': 'c  '}));
      expect(
        QS.decode('a[>=]=23'),
        equals({
          'a': {'>=': '23'}
        }),
      );
      expect(
        QS.decode('a[<=>]==23'),
        equals({
          'a': {'<=>': '=23'}
        }),
      );
      expect(
        QS.decode('a[==]=23'),
        equals({
          'a': {'==': '23'}
        }),
      );
      expect(
        QS.decode(
          'foo',
          const DecodeOptions(strictNullHandling: true),
        ),
        equals({'foo': null}),
      );
      expect(QS.decode('foo'), equals({'foo': ''}));
      expect(QS.decode('foo='), equals({'foo': ''}));
      expect(QS.decode('foo=bar'), equals({'foo': 'bar'}));
      expect(QS.decode(' foo = bar = baz '), equals({' foo ': ' bar = baz '}));
      expect(QS.decode('foo=bar=baz'), equals({'foo': 'bar=baz'}));
      expect(
        QS.decode('foo=bar&bar=baz'),
        equals({'foo': 'bar', 'bar': 'baz'}),
      );
      expect(
        QS.decode('foo2=bar2&baz2='),
        equals({'foo2': 'bar2', 'baz2': ''}),
      );
      expect(
        QS.decode('foo=bar&baz', const DecodeOptions(strictNullHandling: true)),
        equals({'foo': 'bar', 'baz': null}),
      );
      expect(
        QS.decode('foo=bar&baz'),
        equals({'foo': 'bar', 'baz': ''}),
      );
      expect(
        QS.decode('cht=p3&chd=t:60,40&chs=250x100&chl=Hello|World'),
        equals({
          'cht': 'p3',
          'chd': 't:60,40',
          'chs': '250x100',
          'chl': 'Hello|World'
        }),
      );
    });

    test('comma: false', () {
      expect(
        QS.decode('a[]=b&a[]=c'),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        QS.decode('a[0]=b&a[1]=c'),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(QS.decode('a=b,c'), equals({'a': 'b,c'}));
      expect(
        QS.decode('a=b&a=c'),
        equals({
          'a': ['b', 'c']
        }),
      );
    });

    test('comma: true', () {
      expect(
        QS.decode('a[]=b&a[]=c', const DecodeOptions(comma: true)),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        QS.decode('a[0]=b&a[1]=c', const DecodeOptions(comma: true)),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        QS.decode('a=b,c', const DecodeOptions(comma: true)),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        QS.decode('a=b&a=c', const DecodeOptions(comma: true)),
        equals({
          'a': ['b', 'c']
        }),
      );
    });

    test('comma: true with list limit exceeded throws error', () {
      expect(
        () => QS.decode(
          'a=b,c,d,e,f',
          const DecodeOptions(
            comma: true,
            throwOnLimitExceeded: true,
            listLimit: 3,
          ),
        ),
        throwsA(
          isA<RangeError>().having(
            (e) => e.message,
            'message',
            'List limit exceeded. Only 3 elements allowed in a list.',
          ),
        ),
      );
    });

    test('allows enabling dot notation', () {
      expect(QS.decode('a.b=c'), equals({'a.b': 'c'}));
      expect(
        QS.decode('a.b=c', const DecodeOptions(allowDots: true)),
        equals({
          'a': {'b': 'c'}
        }),
      );
    });

    test('decode dot keys correctly', () {
      expect(
        QS.decode(
          'name%252Eobj.first=John&name%252Eobj.last=Doe',
          const DecodeOptions(allowDots: false, decodeDotInKeys: false),
        ),
        equals({'name%2Eobj.first': 'John', 'name%2Eobj.last': 'Doe'}),
      );
      expect(
        QS.decode(
          'name.obj.first=John&name.obj.last=Doe',
          const DecodeOptions(allowDots: true, decodeDotInKeys: false),
        ),
        equals({
          'name': {
            'obj': {'first': 'John', 'last': 'Doe'}
          }
        }),
      );
      expect(
        QS.decode(
          'name%252Eobj.first=John&name%252Eobj.last=Doe',
          const DecodeOptions(allowDots: true, decodeDotInKeys: false),
        ),
        equals({
          'name%2Eobj': {'first': 'John', 'last': 'Doe'}
        }),
      );
      expect(
        QS.decode(
          'name%252Eobj.first=John&name%252Eobj.last=Doe',
          const DecodeOptions(allowDots: true, decodeDotInKeys: true),
        ),
        equals({
          'name.obj': {'first': 'John', 'last': 'Doe'}
        }),
      );

      expect(
        QS.decode(
          'name%252Eobj%252Esubobject.first%252Egodly%252Ename=John&name%252Eobj%252Esubobject.last=Doe',
          const DecodeOptions(allowDots: false, decodeDotInKeys: false),
        ),
        equals({
          'name%2Eobj%2Esubobject.first%2Egodly%2Ename': 'John',
          'name%2Eobj%2Esubobject.last': 'Doe'
        }),
      );
      expect(
        QS.decode(
          'name.obj.subobject.first.godly.name=John&name.obj.subobject.last=Doe',
          const DecodeOptions(allowDots: true, decodeDotInKeys: false),
        ),
        equals({
          'name': {
            'obj': {
              'subobject': {
                'first': {
                  'godly': {'name': 'John'}
                },
                'last': 'Doe'
              }
            }
          }
        }),
      );
      expect(
        QS.decode(
          'name%252Eobj%252Esubobject.first%252Egodly%252Ename=John&name%252Eobj%252Esubobject.last=Doe',
          const DecodeOptions(allowDots: true, decodeDotInKeys: true),
        ),
        equals({
          'name.obj.subobject': {'first.godly.name': 'John', 'last': 'Doe'}
        }),
      );
      expect(
        QS.decode('name%252Eobj.first=John&name%252Eobj.last=Doe'),
        equals({'name%2Eobj.first': 'John', 'name%2Eobj.last': 'Doe'}),
      );
      expect(
        QS.decode(
          'name%252Eobj.first=John&name%252Eobj.last=Doe',
          const DecodeOptions(decodeDotInKeys: false),
        ),
        equals({'name%2Eobj.first': 'John', 'name%2Eobj.last': 'Doe'}),
      );
      expect(
        QS.decode(
          'name%252Eobj.first=John&name%252Eobj.last=Doe',
          const DecodeOptions(decodeDotInKeys: true),
        ),
        equals({
          'name.obj': {'first': 'John', 'last': 'Doe'}
        }),
      );
    });

    test(
        'should decode dot in key of map, and allow enabling dot notation when decodeDotInKeys is set to true and allowDots is undefined',
        () {
      expect(
        QS.decode(
          'name%252Eobj%252Esubobject.first%252Egodly%252Ename=John&name%252Eobj%252Esubobject.last=Doe',
          const DecodeOptions(decodeDotInKeys: true),
        ),
        equals({
          'name.obj.subobject': {'first.godly.name': 'John', 'last': 'Doe'}
        }),
      );
    });

    test('allows empty lists in obj values', () {
      expect(
        QS.decode('foo[]&bar=baz', const DecodeOptions(allowEmptyLists: true)),
        equals({'foo': [], 'bar': 'baz'}),
      );
      expect(
        QS.decode('foo[]&bar=baz', const DecodeOptions(allowEmptyLists: false)),
        equals({
          'foo': [''],
          'bar': 'baz'
        }),
      );
    });

    test(
      'allowEmptyLists + strictNullHandling',
      () {
        expect(
          QS.decode(
            'testEmptyList[]',
            const DecodeOptions(
              strictNullHandling: true,
              allowEmptyLists: true,
            ),
          ),
          equals({'testEmptyList': []}),
        );
      },
    );

    test('parses a single nested string', () {
      expect(
        QS.decode('a[b]=c'),
        equals({
          'a': {'b': 'c'}
        }),
      );
    });

    test('parses a double nested string', () {
      expect(
        QS.decode('a[b][c]=d'),
        equals({
          'a': {
            'b': {'c': 'd'}
          }
        }),
      );
    });

    test('defaults to a depth of 5', () {
      expect(
        QS.decode('a[b][c][d][e][f][g][h]=i'),
        equals({
          'a': {
            'b': {
              'c': {
                'd': {
                  'e': {
                    'f': {'[g][h]': 'i'}
                  }
                }
              }
            }
          }
        }),
      );
    });

    test('only parses one level when depth = 1', () {
      expect(
        QS.decode('a[b][c]=d', const DecodeOptions(depth: 1)),
        equals({
          'a': {
            'b': {'[c]': 'd'}
          }
        }),
      );
      expect(
        QS.decode('a[b][c][d]=e', const DecodeOptions(depth: 1)),
        equals({
          'a': {
            'b': {'[c][d]': 'e'}
          }
        }),
      );
    });

    test('uses original key when depth = 0', () {
      expect(
        QS.decode('a[0]=b&a[1]=c', const DecodeOptions(depth: 0)),
        equals({'a[0]': 'b', 'a[1]': 'c'}),
      );
      expect(
        QS.decode(
          'a[0][0]=b&a[0][1]=c&a[1]=d&e=2',
          const DecodeOptions(depth: 0),
        ),
        equals({
          'a[0][0]': 'b',
          'a[0][1]': 'c',
          'a[1]': 'd',
          'e': '2',
        }),
      );
    });

    test('parses a simple list', () {
      expect(
        QS.decode('a=b&a=c'),
        equals({
          'a': ['b', 'c']
        }),
      );
    });

    test('parses an explicit list', () {
      expect(
        QS.decode('a[]=b'),
        equals({
          'a': ['b']
        }),
      );
      expect(
        QS.decode('a[]=b&a[]=c'),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        QS.decode('a[]=b&a[]=c&a[]=d'),
        equals({
          'a': ['b', 'c', 'd']
        }),
      );
    });

    test('parses a mix of simple and explicit lists', () {
      expect(
        QS.decode('a=b&a[]=c'),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        QS.decode('a[]=b&a=c'),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        QS.decode('a[0]=b&a=c'),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        QS.decode('a=b&a[0]=c'),
        equals({
          'a': ['b', 'c']
        }),
      );

      expect(
        QS.decode('a[1]=b&a=c', const DecodeOptions(listLimit: 20)),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        QS.decode('a[]=b&a=c', const DecodeOptions(listLimit: 0)),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        QS.decode('a[]=b&a=c'),
        equals({
          'a': ['b', 'c']
        }),
      );

      expect(
        QS.decode('a=b&a[1]=c', const DecodeOptions(listLimit: 20)),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        QS.decode('a=b&a[]=c', const DecodeOptions(listLimit: 0)),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        QS.decode('a=b&a[]=c'),
        equals({
          'a': ['b', 'c']
        }),
      );
    });

    test('parses a nested list', () {
      expect(
        QS.decode('a[b][]=c&a[b][]=d'),
        equals({
          'a': {
            'b': ['c', 'd']
          }
        }),
      );
      expect(
        QS.decode('a[>=]=25'),
        equals({
          'a': {'>=': '25'}
        }),
      );
    });

    test('decodes nested lists with parentKey not null', () {
      expect(
        QS.decode('a[0][]=b'),
        equals({
          'a': [
            ['b']
          ]
        }),
      );
    });

    test('allows to specify list indices', () {
      expect(
        QS.decode('a[1]=c&a[0]=b&a[2]=d'),
        equals({
          'a': ['b', 'c', 'd']
        }),
      );
      expect(
        QS.decode('a[1]=c&a[0]=b'),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        QS.decode('a[1]=c', const DecodeOptions(listLimit: 20)),
        equals({
          'a': ['c']
        }),
      );
      expect(
        QS.decode('a[1]=c', const DecodeOptions(listLimit: 0)),
        equals({
          'a': {'1': 'c'}
        }),
      );
      expect(
        QS.decode('a[1]=c'),
        equals({
          'a': ['c']
        }),
      );
      expect(
        QS.decode('a[0]=b&a[2]=c', const DecodeOptions(parseLists: false)),
        equals({
          'a': {'0': 'b', '2': 'c'}
        }),
      );
      expect(
        QS.decode('a[0]=b&a[2]=c', const DecodeOptions(parseLists: true)),
        equals({
          'a': ['b', 'c'],
        }),
      );
      expect(
        QS.decode('a[1]=b&a[15]=c', const DecodeOptions(parseLists: false)),
        equals({
          'a': {'1': 'b', '15': 'c'}
        }),
      );
      expect(
        QS.decode('a[1]=b&a[15]=c', const DecodeOptions(parseLists: true)),
        equals({
          'a': ['b', 'c']
        }),
      );
    });

    test('limits specific list indices to listLimit', () {
      expect(
        QS.decode('a[20]=a', const DecodeOptions(listLimit: 20)),
        equals({
          'a': ['a']
        }),
      );
      expect(
        QS.decode('a[21]=a', const DecodeOptions(listLimit: 20)),
        equals({
          'a': {'21': 'a'}
        }),
      );

      expect(
        QS.decode('a[20]=a'),
        equals({
          'a': ['a']
        }),
      );
      expect(
        QS.decode('a[21]=a'),
        equals({
          'a': {'21': 'a'}
        }),
      );
    });

    test('supports keys that begin with a number', () {
      expect(
        QS.decode('a[12b]=c'),
        equals({
          'a': {'12b': 'c'}
        }),
      );
    });

    test('supports encoded = signs', () {
      expect(
        QS.decode('he%3Dllo=th%3Dere'),
        equals({'he=llo': 'th=ere'}),
      );
    });

    test('is ok with url encoded strings', () {
      expect(
        QS.decode('a[b%20c]=d'),
        equals({
          'a': {'b c': 'd'}
        }),
      );
      expect(
        QS.decode('a[b]=c%20d'),
        equals({
          'a': {'b': 'c d'}
        }),
      );
    });

    test('allows brackets in the value', () {
      expect(
        QS.decode('pets=["tobi"]'),
        equals({'pets': '["tobi"]'}),
      );
      expect(
        QS.decode('operators=[">=", "<="]'),
        equals({'operators': '[">=", "<="]'}),
      );
    });

    test('allows empty values', () {
      expect(QS.decode(''), equals({}));
      expect(QS.decode(null), equals({}));
    });

    test('transforms lists to maps', () {
      expect(
        QS.decode('foo[0]=bar&foo[bad]=baz'),
        equals({
          'foo': {'0': 'bar', 'bad': 'baz'}
        }),
      );
      expect(
        QS.decode('foo[bad]=baz&foo[0]=bar'),
        equals({
          'foo': {'bad': 'baz', '0': 'bar'}
        }),
      );
      expect(
        QS.decode('foo[bad]=baz&foo[]=bar'),
        equals({
          'foo': {'bad': 'baz', '0': 'bar'}
        }),
      );
      expect(
        QS.decode('foo[]=bar&foo[bad]=baz'),
        equals({
          'foo': {'0': 'bar', 'bad': 'baz'}
        }),
      );
      expect(
        QS.decode('foo[bad]=baz&foo[]=bar&foo[]=foo'),
        equals({
          'foo': {'bad': 'baz', '0': 'bar', '1': 'foo'}
        }),
      );
      expect(
        QS.decode(
          'foo[0][a]=a&foo[0][b]=b&foo[1][a]=aa&foo[1][b]=bb',
        ),
        equals({
          'foo': [
            {'a': 'a', 'b': 'b'},
            {'a': 'aa', 'b': 'bb'}
          ]
        }),
      );
    });

    test('transforms lists to maps (dot notation)', () {
      expect(
        QS.decode('foo[0].baz=bar&fool.bad=baz',
            const DecodeOptions(allowDots: true)),
        equals({
          'foo': [
            {'baz': 'bar'}
          ],
          'fool': {'bad': 'baz'}
        }),
      );
      expect(
        QS.decode('foo[0].baz=bar&fool.bad.boo=baz',
            const DecodeOptions(allowDots: true)),
        equals({
          'foo': [
            {'baz': 'bar'}
          ],
          'fool': {
            'bad': {'boo': 'baz'}
          }
        }),
      );
      expect(
        QS.decode('foo[0][0].baz=bar&fool.bad=baz',
            const DecodeOptions(allowDots: true)),
        equals({
          'foo': [
            [
              {'baz': 'bar'}
            ]
          ],
          'fool': {'bad': 'baz'}
        }),
      );
      expect(
        QS.decode('foo[0].baz[0]=15&foo[0].bar=2',
            const DecodeOptions(allowDots: true)),
        equals({
          'foo': [
            {
              'baz': ['15'],
              'bar': '2'
            }
          ]
        }),
      );
      expect(
        QS.decode('foo[0].baz[0]=15&foo[0].baz[1]=16&foo[0].bar=2',
            const DecodeOptions(allowDots: true)),
        equals({
          'foo': [
            {
              'baz': ['15', '16'],
              'bar': '2'
            }
          ]
        }),
      );
      expect(
        QS.decode(
            'foo.bad=baz&foo[0]=bar', const DecodeOptions(allowDots: true)),
        equals({
          'foo': {'bad': 'baz', '0': 'bar'}
        }),
      );
      expect(
        QS.decode(
            'foo.bad=baz&foo[]=bar', const DecodeOptions(allowDots: true)),
        equals({
          'foo': {'bad': 'baz', '0': 'bar'}
        }),
      );
      expect(
        QS.decode(
            'foo[]=bar&foo.bad=baz', const DecodeOptions(allowDots: true)),
        equals({
          'foo': {'0': 'bar', 'bad': 'baz'}
        }),
      );
      expect(
        QS.decode('foo.bad=baz&foo[]=bar&foo[]=foo',
            const DecodeOptions(allowDots: true)),
        equals({
          'foo': {'bad': 'baz', '0': 'bar', '1': 'foo'}
        }),
      );
      expect(
        QS.decode('foo[0].a=a&foo[0].b=b&foo[1].a=aa&foo[1].b=bb',
            const DecodeOptions(allowDots: true)),
        equals({
          'foo': [
            {'a': 'a', 'b': 'b'},
            {'a': 'aa', 'b': 'bb'}
          ]
        }),
      );
    });

    test('correctly prunes undefined values when converting a list to a map',
        () {
      expect(
        QS.decode('a[2]=b&a[99999999]=c'),
        equals({
          'a': {'2': 'b', '99999999': 'c'}
        }),
      );
    });

    test('supports malformed uri characters', () {
      expect(
        QS.decode('{%:%}', const DecodeOptions(strictNullHandling: true)),
        equals({'{%:%}': null}),
      );
      expect(QS.decode('{%:%}='), equals({'{%:%}': ''}));
      expect(QS.decode('foo=%:%}'), equals({'foo': '%:%}'}));
    });

    test('does not produce empty keys', () {
      expect(QS.decode('_r=1&'), equals({'_r': '1'}));
    });

    test('parses lists of maps', () {
      expect(
        QS.decode('a[][b]=c'),
        equals({
          'a': [
            {'b': 'c'}
          ]
        }),
      );
      expect(
        QS.decode('a[0][b]=c'),
        equals({
          'a': [
            {'b': 'c'}
          ]
        }),
      );
    });

    test('allows for empty strings in lists', () {
      expect(
        QS.decode('a[]=b&a[]=&a[]=c'),
        equals({
          'a': ['b', '', 'c']
        }),
      );

      expect(
        QS.decode(
          'a[0]=b&a[1]&a[2]=c&a[19]=',
          const DecodeOptions(strictNullHandling: true, listLimit: 20),
        ),
        equals({
          'a': ['b', null, 'c', '']
        }),
      );

      expect(
        QS.decode(
          'a[]=b&a[]&a[]=c&a[]=',
          const DecodeOptions(strictNullHandling: true, listLimit: 0),
        ),
        equals({
          'a': ['b', null, 'c', '']
        }),
      );

      expect(
        QS.decode(
          'a[0]=b&a[1]=&a[2]=c&a[19]',
          const DecodeOptions(strictNullHandling: true, listLimit: 20),
        ),
        equals({
          'a': ['b', '', 'c', null]
        }),
      );

      expect(
        QS.decode(
          'a[]=b&a[]=&a[]=c&a[]',
          const DecodeOptions(strictNullHandling: true, listLimit: 0),
        ),
        equals({
          'a': ['b', '', 'c', null]
        }),
      );

      expect(
        QS.decode('a[]=&a[]=b&a[]=c'),
        equals({
          'a': ['', 'b', 'c']
        }),
      );
    });

    test('compacts sparse lists', () {
      expect(
        QS.decode('a[10]=1&a[2]=2', const DecodeOptions(listLimit: 20)),
        equals({
          'a': ['2', '1']
        }),
      );
      expect(
        QS.decode(
          'a[1][b][2][c]=1',
          const DecodeOptions(listLimit: 20),
        ),
        equals({
          'a': [
            {
              'b': [
                {'c': '1'}
              ]
            }
          ]
        }),
      );
      expect(
        QS.decode(
          'a[1][2][3][c]=1',
          const DecodeOptions(listLimit: 20),
        ),
        equals({
          'a': [
            [
              [
                {'c': '1'}
              ]
            ]
          ]
        }),
      );
      expect(
        QS.decode(
          'a[1][2][3][c][1]=1',
          const DecodeOptions(listLimit: 20),
        ),
        equals({
          'a': [
            [
              [
                {
                  'c': ['1']
                }
              ]
            ]
          ]
        }),
      );
    });

    test('parses semi-parsed strings', () {
      expect(
        QS.decode('a[b]=c'),
        equals({
          'a': {'b': 'c'}
        }),
      );
      expect(
        QS.decode('a[b]=c&a[d]=e'),
        equals({
          'a': {'b': 'c', 'd': 'e'}
        }),
      );
    });

    test('parses buffers correctly', () {
      final ByteBuffer b = utf8.encode('test').buffer;
      expect(QS.decode({'a': b}), equals({'a': b}));
    });

    test('parses jquery-param strings', () {
      // final String readable = 'filter[0][]=int1&filter[0][]==&filter[0][]=77&filter[]=and&filter[2][]=int2&filter[2][]==&filter[2][]=8';
      final String encoded =
          'filter%5B0%5D%5B%5D=int1&filter%5B0%5D%5B%5D=%3D&filter%5B0%5D%5B%5D=77&filter%5B%5D=and&filter%5B2%5D%5B%5D=int2&filter%5B2%5D%5B%5D=%3D&filter%5B2%5D%5B%5D=8';
      final Map<String, dynamic> expected = {
        'filter': [
          ['int1', '=', '77'],
          'and',
          ['int2', '=', '8']
        ]
      };
      expect(QS.decode(encoded), equals(expected));
    });

    test('continues parsing when no parent is found', () {
      expect(QS.decode('[]=&a=b'), equals({'0': '', 'a': 'b'}));
      expect(
        QS.decode(
          '[]&a=b',
          const DecodeOptions(strictNullHandling: true),
        ),
        equals({'0': null, 'a': 'b'}),
      );
      expect(QS.decode('[foo]=bar'), equals({'foo': 'bar'}));
    });

    test('does not error when parsing a very long list', () {
      final StringBuffer str = StringBuffer('a[]=a');
      while (utf8.encode(str.toString()).length < 128 * 1024) {
        str.write('&');
        str.write(str);
      }

      expect(() => QS.decode(str.toString()), returnsNormally);
    });

    test('parses a string with an alternative string delimiter', () {
      expect(
        QS.decode('a=b;c=d', const DecodeOptions(delimiter: ';')),
        equals({'a': 'b', 'c': 'd'}),
      );
    });

    test('parses a string with an alternative RegExp delimiter', () {
      expect(
        QS.decode('a=b; c=d', DecodeOptions(delimiter: RegExp(r'[;,] *'))),
        equals({'a': 'b', 'c': 'd'}),
      );
    });

    test('allows overriding parameter limit', () {
      expect(
        QS.decode('a=b&c=d', const DecodeOptions(parameterLimit: 1)),
        equals({'a': 'b'}),
      );
    });

    test('allows setting the parameter limit to Infinity', () {
      expect(
        QS.decode(
          'a=b&c=d',
          const DecodeOptions(parameterLimit: double.infinity),
        ),
        equals({'a': 'b', 'c': 'd'}),
      );
    });

    test('allows overriding list limit', () {
      expect(
        QS.decode('a[0]=b', const DecodeOptions(listLimit: -1)),
        equals({
          'a': {'0': 'b'}
        }),
      );
      expect(
        QS.decode('a[0]=b', const DecodeOptions(listLimit: 0)),
        equals({
          'a': ['b']
        }),
      );

      expect(
        QS.decode('a[-1]=b', const DecodeOptions(listLimit: -1)),
        equals({
          'a': {'-1': 'b'}
        }),
      );
      expect(
        QS.decode('a[-1]=b', const DecodeOptions(listLimit: 0)),
        equals({
          'a': {'-1': 'b'}
        }),
      );

      expect(
        QS.decode('a[0]=b&a[1]=c', const DecodeOptions(listLimit: -1)),
        equals({
          'a': {'0': 'b', '1': 'c'}
        }),
      );
      expect(
        QS.decode('a[0]=b&a[1]=c', const DecodeOptions(listLimit: 0)),
        equals({
          'a': {'0': 'b', '1': 'c'}
        }),
      );
    });

    test('allows disabling list parsing', () {
      expect(
        QS.decode(
          'a[0]=b&a[1]=c',
          const DecodeOptions(parseLists: false),
        ),
        equals({
          'a': {'0': 'b', '1': 'c'}
        }),
      );
      expect(
        QS.decode(
          'a[]=b',
          const DecodeOptions(parseLists: false),
        ),
        equals({
          'a': {'0': 'b'}
        }),
      );
    });

    test('allows for query string prefix', () {
      expect(
        QS.decode('?foo=bar', const DecodeOptions(ignoreQueryPrefix: true)),
        equals({'foo': 'bar'}),
      );
      expect(
        QS.decode('foo=bar', const DecodeOptions(ignoreQueryPrefix: true)),
        equals({'foo': 'bar'}),
      );
      expect(
        QS.decode('?foo=bar', const DecodeOptions(ignoreQueryPrefix: false)),
        equals({'?foo': 'bar'}),
      );
    });

    test('parses a map', () {
      final Map<String, dynamic> input = {
        'user[name]': {'pop[bob]': 3},
        'user[email]': null
      };

      final Map<String, dynamic> expected = {
        'user': {
          'name': {'pop[bob]': 3},
          'email': null
        }
      };

      expect(QS.decode(input), equals(expected));
    });

    test('parses string with comma as list divider', () {
      expect(
        QS.decode('foo=bar,tee', const DecodeOptions(comma: true)),
        equals({
          'foo': ['bar', 'tee']
        }),
      );
      expect(
        QS.decode('foo[bar]=coffee,tee', const DecodeOptions(comma: true)),
        equals({
          'foo': {
            'bar': ['coffee', 'tee']
          }
        }),
      );
      expect(
        QS.decode('foo=', const DecodeOptions(comma: true)),
        equals({'foo': ''}),
      );
      expect(
        QS.decode('foo', const DecodeOptions(comma: true)),
        equals({'foo': ''}),
      );
      expect(
        QS.decode(
            'foo', const DecodeOptions(comma: true, strictNullHandling: true)),
        equals({'foo': null}),
      );

      expect(
        QS.decode('a[0]=c'),
        equals({
          'a': ['c']
        }),
      );
      expect(
        QS.decode('a[]=c'),
        equals({
          'a': ['c']
        }),
      );
      expect(
        QS.decode('a[]=c', const DecodeOptions(comma: true)),
        equals({
          'a': ['c']
        }),
      );

      expect(
        QS.decode('a[0]=c&a[1]=d'),
        equals({
          'a': ['c', 'd']
        }),
      );
      expect(
        QS.decode('a[]=c&a[]=d'),
        equals({
          'a': ['c', 'd']
        }),
      );
      expect(
        QS.decode('a=c,d', const DecodeOptions(comma: true)),
        equals({
          'a': ['c', 'd']
        }),
      );
    });

    test('parses values with comma as list divider', () {
      expect(
        QS.decode({'foo': 'bar,tee'}, const DecodeOptions(comma: false)),
        equals({'foo': 'bar,tee'}),
      );
      expect(
        QS.decode({'foo': 'bar,tee'}, const DecodeOptions(comma: true)),
        equals({
          'foo': ['bar', 'tee']
        }),
      );
    });

    test(
      'use number decoder, parses string that has one number with comma option enabled',
      () {
        dynamic decoder(String? str, {Encoding? charset}) =>
            num.tryParse(str ?? '') ?? Utils.decode(str, charset: charset);

        expect(
          QS.decode('foo=1', DecodeOptions(comma: true, decoder: decoder)),
          equals({'foo': 1}),
        );
        expect(
          QS.decode('foo=0', DecodeOptions(comma: true, decoder: decoder)),
          equals({'foo': 0}),
        );
      },
    );

    test(
        'parses brackets holds list of lists when having two parts of strings with comma as list divider',
        () {
      expect(
        QS.decode('foo[]=1,2,3&foo[]=4,5,6', const DecodeOptions(comma: true)),
        equals({
          'foo': [
            ['1', '2', '3'],
            ['4', '5', '6']
          ]
        }),
      );
      expect(
        QS.decode('foo[]=1,2,3&foo[]=', const DecodeOptions(comma: true)),
        equals({
          'foo': [
            ['1', '2', '3'],
            ''
          ]
        }),
      );
      expect(
        QS.decode('foo[]=1,2,3&foo[]=', const DecodeOptions(comma: true)),
        equals({
          'foo': [
            ['1', '2', '3'],
            ''
          ]
        }),
      );
      expect(
        QS.decode('foo[]=1,2,3&foo[]=,', const DecodeOptions(comma: true)),
        equals({
          'foo': [
            ['1', '2', '3'],
            ['', '']
          ]
        }),
      );
      expect(
        QS.decode('foo[]=1,2,3&foo[]=a', const DecodeOptions(comma: true)),
        equals({
          'foo': [
            ['1', '2', '3'],
            'a'
          ]
        }),
      );
    });

    test(
        'parses comma delimited list while having percent-encoded comma treated as normal text',
        () {
      expect(
        QS.decode('foo=a%2Cb', const DecodeOptions(comma: true)),
        equals({'foo': 'a,b'}),
      );
      expect(
        QS.decode('foo=a%2C%20b,d', const DecodeOptions(comma: true)),
        equals({
          'foo': ['a, b', 'd']
        }),
      );
      expect(
        QS.decode('foo=a%2C%20b,c%2C%20d', const DecodeOptions(comma: true)),
        equals({
          'foo': ['a, b', 'c, d']
        }),
      );
    });

    test('parses a map in dot notation', () {
      expect(
        QS.decode({
          'user.name': {'pop[bob]': 3},
          'user.email.': null
        }, const DecodeOptions(allowDots: true)),
        equals(
          {
            'user': {
              'name': {'pop[bob]': 3},
              'email': null
            }
          },
        ),
      );
    });

    test('parses a map and not child values', () {
      expect(
        QS.decode({
          'user[name]': {
            'pop[bob]': {'test': 3}
          },
          'user[email]': null
        }),
        equals(
          {
            'user': {
              'name': {
                'pop[bob]': {'test': 3}
              },
              'email': null
            }
          },
        ),
      );
    });

    test('does not crash when parsing circular references', () {
      final Map<String, dynamic> a = {};
      a['b'] = a;

      late final Map parsed;

      expect(() {
        parsed = QS.decode({'foo[bar]': 'baz', 'foo[baz]': a});
      }, returnsNormally);

      expect(parsed.containsKey('foo'), isTrue);
      expect(parsed['foo']!.containsKey('bar'), isTrue);
      expect(parsed['foo']!.containsKey('baz'), isTrue);
      expect(parsed['foo']!['bar'], 'baz');
      expect(parsed['foo']!['baz'], a);
    });

    test('does not crash when parsing deep maps', () {
      const int depth = 5000;

      final StringBuffer str = StringBuffer('foo');
      for (int i = 0; i < depth; i++) {
        str.write('[p]');
      }
      str.write('=bar');

      late final Map parsed;

      expect(
        () {
          parsed = QS.decode(str.toString(), const DecodeOptions(depth: depth));
        },
        returnsNormally,
      );

      expect(parsed.containsKey('foo'), isTrue);

      int actualDepth = 0;
      dynamic ref = parsed['foo'];
      while (ref != null && ref is Map && ref.containsKey('p')) {
        ref = ref['p'];
        actualDepth++;
      }

      expect(actualDepth, depth);
    });

    test('parses null maps correctly', () {
      final Map<String, dynamic> a = {'b': 'c'};
      expect(QS.decode(a), equals({'b': 'c'}));
      expect(QS.decode({'a': a}), equals({'a': a}));
    });

    test('parses dates correctly', () {
      final DateTime now = DateTime.now();
      expect(QS.decode({'a': now}), equals({'a': now}));
    });

    test('parses regular expressions correctly', () {
      final RegExp re = RegExp(r'^test$');
      expect(QS.decode({'a': re}), equals({'a': re}));
    });

    test('params starting with a closing bracket', () {
      expect(QS.decode(']=toString'), equals({']': 'toString'}));
      expect(QS.decode(']]=toString'), equals({']]': 'toString'}));
      expect(QS.decode(']hello]=toString'), equals({']hello]': 'toString'}));
    });

    test('params starting with a starting bracket', () {
      expect(QS.decode('[=toString'), equals({'[': 'toString'}));
      expect(QS.decode('[[=toString'), equals({'[[': 'toString'}));
      expect(QS.decode('[hello[=toString'), equals({'[hello[': 'toString'}));
    });

    test('add keys to maps', () {
      expect(
        QS.decode('a[b]=c'),
        equals({
          'a': {'b': 'c'}
        }),
      );
    });

    test('can return null maps', () {
      final Map<String, dynamic> expected = {};
      expected['a'] = {};
      expected['a']['b'] = 'c';
      expected['a']['hasOwnProperty'] = 'd';
      expect(
        QS.decode('a[b]=c&a[hasOwnProperty]=d'),
        equals(expected),
      );

      expect(QS.decode(null), equals({}));

      final Map<String, dynamic> expectedlist = {};
      expectedlist['a'] = {};
      expectedlist['a']['0'] = 'b';
      expectedlist['a']['c'] = 'd';
      expect(
        QS.decode('a[]=b&a[c]=d'),
        equals(expectedlist),
      );
    });

    test('can parse with custom encoding', () {
      final Map<String, dynamic> expected = {'県': '大阪府'};

      String? decode(String? str, {Encoding? charset}) {
        if (str == null) {
          return null;
        }

        final RegExp reg = RegExp(r'%([0-9A-F]{2})', caseSensitive: false);
        final List<int> result = [];
        Match? parts;
        while ((parts = reg.firstMatch(str!)) != null && parts != null) {
          result.add(int.parse(parts.group(1)!, radix: 16));
          str = str.substring(parts.end);
        }
        return ShiftJIS().decode(
          Uint8List.fromList(result),
        );
      }

      expect(
        QS.decode(
          '%8c%a7=%91%e5%8d%e3%95%7b',
          DecodeOptions(decoder: decode),
        ),
        equals(expected),
      );
    });

    test('parses an iso-8859-1 string if asked to', () {
      final Map<String, dynamic> expected = {'¢': '½'};

      expect(
        QS.decode('%A2=%BD', const DecodeOptions(charset: latin1)),
        equals(expected),
      );
    });

    group('charset', () {
      test('throws an AssertionError when given an unknown charset', () {
        expect(
          () => QS.decode('a=b', DecodeOptions(charset: ShiftJIS())),
          throwsA(isA<AssertionError>()),
        );
      });

      const String urlEncodedCheckmarkInUtf8 = '%E2%9C%93';
      const String urlEncodedOSlashInUtf8 = '%C3%B8';
      const String urlEncodedNumCheckmark = '%26%2310003%3B';
      const String urlEncodedNumSmiley = '%26%239786%3B';

      test(
        'prefers an utf-8 charset specified by the utf8 sentinel to a default charset of iso-8859-1',
        () {
          expect(
            QS.decode(
              'utf8=$urlEncodedCheckmarkInUtf8&$urlEncodedOSlashInUtf8=$urlEncodedOSlashInUtf8',
              const DecodeOptions(charsetSentinel: true, charset: latin1),
            ),
            equals({'ø': 'ø'}),
          );
        },
      );

      test(
        'prefers an iso-8859-1 charset specified by the utf8 sentinel to a default charset of utf-8',
        () {
          expect(
            QS.decode(
              'utf8=$urlEncodedNumCheckmark&$urlEncodedOSlashInUtf8=$urlEncodedOSlashInUtf8',
              const DecodeOptions(charsetSentinel: true, charset: utf8),
            ),
            equals({'Ã¸': 'Ã¸'}),
          );
        },
      );

      test(
        'does not require the utf8 sentinel to be defined before the parameters whose decoding it affects',
        () {
          expect(
            QS.decode(
              'a=$urlEncodedOSlashInUtf8&utf8=$urlEncodedNumCheckmark',
              const DecodeOptions(charsetSentinel: true, charset: utf8),
            ),
            equals({'a': 'Ã¸'}),
          );
        },
      );

      test(
        'should ignore an utf8 sentinel with an unknown value',
        () {
          expect(
            QS.decode(
              'utf8=foo&$urlEncodedOSlashInUtf8=$urlEncodedOSlashInUtf8',
              const DecodeOptions(charsetSentinel: true, charset: utf8),
            ),
            equals({'ø': 'ø'}),
          );
        },
      );

      test(
        'uses the utf8 sentinel to switch to utf-8 when no default charset is given',
        () {
          expect(
            QS.decode(
              'utf8=$urlEncodedCheckmarkInUtf8&$urlEncodedOSlashInUtf8=$urlEncodedOSlashInUtf8',
              const DecodeOptions(charsetSentinel: true),
            ),
            equals({'ø': 'ø'}),
          );
        },
      );

      test(
        'uses the utf8 sentinel to switch to iso-8859-1 when no default charset is given',
        () {
          expect(
            QS.decode(
              'utf8=$urlEncodedNumCheckmark&$urlEncodedOSlashInUtf8=$urlEncodedOSlashInUtf8',
              const DecodeOptions(charsetSentinel: true),
            ),
            equals({'Ã¸': 'Ã¸'}),
          );
        },
      );

      test(
        'interprets numeric entities in iso-8859-1 when `interpretNumericEntities`',
        () {
          expect(
            QS.decode(
              'foo=$urlEncodedNumSmiley',
              const DecodeOptions(
                  charset: latin1, interpretNumericEntities: true),
            ),
            equals({'foo': '☺'}),
          );
        },
      );

      test(
        'handles a custom decoder returning `null`, in the `iso-8859-1` charset, when `interpretNumericEntities`',
        () {
          expect(
            QS.decode(
              'foo=&bar=$urlEncodedNumSmiley',
              DecodeOptions(
                charset: latin1,
                decoder: (String? str, {Encoding? charset}) =>
                    str?.isNotEmpty ?? false
                        ? Utils.decode(str!, charset: charset)
                        : null,
                interpretNumericEntities: true,
              ),
            ),
            equals({'foo': null, 'bar': '☺'}),
          );
        },
      );

      test(
        'does not interpret numeric entities in iso-8859-1 when `interpretNumericEntities` is absent',
        () {
          expect(
            QS.decode(
              'foo=$urlEncodedNumSmiley',
              const DecodeOptions(charset: latin1),
            ),
            equals({'foo': '&#9786;'}),
          );
        },
      );

      test(
        '`interpretNumericEntities` with comma:true and iso-8859-1 charset does not crash',
        () {
          expect(
            QS.decode(
              'b&a[]=1,$urlEncodedNumSmiley',
              const DecodeOptions(
                comma: true,
                charset: latin1,
                interpretNumericEntities: true,
              ),
            ),
            equals({
              'b': '',
              'a': ['1,☺']
            }),
          );
        },
      );

      test(
        'does not interpret numeric entities when the charset is utf-8, even when `interpretNumericEntities`',
        () {
          expect(
            QS.decode(
              'foo=$urlEncodedNumSmiley',
              const DecodeOptions(
                  charset: utf8, interpretNumericEntities: true),
            ),
            equals({'foo': '&#9786;'}),
          );
        },
      );

      test('does not interpret %uXXXX syntax in iso-8859-1 mode', () {
        expect(
          QS.decode('%u263A=%u263A', const DecodeOptions(charset: latin1)),
          equals({'%u263A': '%u263A'}),
        );
      });
    });
  });

  group('parses empty keys', () {
    for (Map<String, dynamic> element in emptyTestCases) {
      test('skips empty string key with ${element['input']}', () {
        expect(
          QS.decode(element['input']),
          equals(element['noEmptyKeys']),
        );
      });
    }
  });

  group('`duplicates` option', () {
    test(
      'duplicates: default, combine',
      () {
        expect(
          QS.decode('foo=bar&foo=baz'),
          equals({
            'foo': ['bar', 'baz']
          }),
        );
      },
    );

    test(
      'duplicates: combine',
      () {
        expect(
          QS.decode('foo=bar&foo=baz',
              const DecodeOptions(duplicates: Duplicates.combine)),
          equals({
            'foo': ['bar', 'baz']
          }),
        );
      },
    );

    test(
      'duplicates: first',
      () {
        expect(
          QS.decode('foo=bar&foo=baz',
              const DecodeOptions(duplicates: Duplicates.first)),
          equals({'foo': 'bar'}),
        );
      },
    );

    test(
      'duplicates: last',
      () {
        expect(
          QS.decode(
            'foo=bar&foo=baz',
            const DecodeOptions(duplicates: Duplicates.last),
          ),
          equals({'foo': 'baz'}),
        );
      },
    );
  });

  group('strictDepth option - throw cases', () {
    test(
      'throws an exception for multiple nested objects with strictDepth: true',
      () {
        expect(
          () => QS.decode(
            'a[b][c][d][e][f][g][h][i]=j',
            const DecodeOptions(depth: 1, strictDepth: true),
          ),
          throwsA(isA<RangeError>()),
        );
      },
    );

    test(
      'throws an exception for multiple nested lists with strictDepth: true',
      () {
        expect(
          () => QS.decode(
            'a[0][1][2][3][4]=b',
            const DecodeOptions(depth: 3, strictDepth: true),
          ),
          throwsA(isA<RangeError>()),
        );
      },
    );

    test(
      'throws an exception for nested maps and lists with strictDepth: true',
      () {
        expect(
          () => QS.decode(
            'a[b][c][0][d][e]=f',
            const DecodeOptions(depth: 3, strictDepth: true),
          ),
          throwsA(isA<RangeError>()),
        );
      },
    );

    test(
      'throws an exception for different types of values with strictDepth: true',
      () {
        expect(
          () => QS.decode(
            'a[b][c][d][e]=true&a[b][c][d][f]=42',
            const DecodeOptions(depth: 3, strictDepth: true),
          ),
          throwsA(isA<RangeError>()),
        );
      },
    );
  });

  group('strictDepth option - non-throw cases', () {
    test('when depth is 0 and strictDepth true, do not throw', () {
      expect(
        () => QS.decode(
          'a[b][c][d][e]=true&a[b][c][d][f]=42',
          const DecodeOptions(depth: 0, strictDepth: true),
        ),
        returnsNormally,
      );
    });

    test(
      'parses successfully when depth is within the limit with strictDepth: true',
      () {
        expect(
          QS.decode(
            'a[b]=c',
            const DecodeOptions(depth: 1, strictDepth: true),
          ),
          equals({
            'a': {'b': 'c'}
          }),
        );
      },
    );

    test(
      'does not throw an exception when depth exceeds the limit with strictDepth: false',
      () {
        expect(
          QS.decode(
              'a[b][c][d][e][f][g][h][i]=j', const DecodeOptions(depth: 1)),
          equals({
            'a': {
              'b': {'[c][d][e][f][g][h][i]': 'j'}
            }
          }),
        );
      },
    );

    test(
      'parses successfully when depth is within the limit with strictDepth: false',
      () {
        expect(
          QS.decode('a[b]=c', const DecodeOptions(depth: 1)),
          equals({
            'a': {'b': 'c'}
          }),
        );
      },
    );

    test(
      'does not throw when depth is exactly at the limit with strictDepth: true',
      () {
        expect(
          QS.decode(
            'a[b][c]=d',
            const DecodeOptions(depth: 2, strictDepth: true),
          ),
          equals({
            'a': {
              'b': {'c': 'd'}
            }
          }),
        );
      },
    );
  });

  group('parameter limit', () {
    test('does not throw error when within parameter limit', () {
      expect(
        QS.decode('a=1&b=2&c=3',
            const DecodeOptions(parameterLimit: 5, throwOnLimitExceeded: true)),
        equals({'a': '1', 'b': '2', 'c': '3'}),
      );
    });

    test('throws error when parameter limit exceeded', () {
      expect(
        () => QS.decode(
          'a=1&b=2&c=3&d=4&e=5&f=6',
          const DecodeOptions(parameterLimit: 3, throwOnLimitExceeded: true),
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('silently truncates when throwOnLimitExceeded is not given', () {
      expect(
        QS.decode(
          'a=1&b=2&c=3&d=4&e=5',
          const DecodeOptions(parameterLimit: 3),
        ),
        equals({'a': '1', 'b': '2', 'c': '3'}),
      );
    });

    test('silently truncates when parameter limit exceeded without error', () {
      expect(
        QS.decode(
          'a=1&b=2&c=3&d=4&e=5',
          const DecodeOptions(parameterLimit: 3, throwOnLimitExceeded: false),
        ),
        equals({'a': '1', 'b': '2', 'c': '3'}),
      );
    });

    test('allows unlimited parameters when parameterLimit set to Infinity', () {
      expect(
        QS.decode(
          'a=1&b=2&c=3&d=4&e=5&f=6',
          const DecodeOptions(parameterLimit: double.infinity),
        ),
        equals({'a': '1', 'b': '2', 'c': '3', 'd': '4', 'e': '5', 'f': '6'}),
      );
    });
  });

  group('list limit tests', () {
    test('does not throw error when list is within limit', () {
      expect(
        QS.decode(
          'a[]=1&a[]=2&a[]=3',
          const DecodeOptions(listLimit: 5, throwOnLimitExceeded: true),
        ),
        equals({
          'a': ['1', '2', '3']
        }),
      );
    });

    test('throws error when list limit exceeded', () {
      expect(
        () => QS.decode(
          'a[]=1&a[]=2&a[]=3&a[]=4',
          const DecodeOptions(listLimit: 3, throwOnLimitExceeded: true),
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('converts list to map if length is greater than limit', () {
      expect(
        QS.decode(
          'a[1]=1&a[2]=2&a[3]=3&a[4]=4&a[5]=5&a[6]=6',
          const DecodeOptions(listLimit: 5),
        ),
        equals({
          'a': {'1': '1', '2': '2', '3': '3', '4': '4', '5': '5', '6': '6'}
        }),
      );
    });

    test('handles list limit of zero correctly', () {
      expect(
        QS.decode(
          'a[]=1&a[]=2',
          const DecodeOptions(listLimit: 0),
        ),
        equals({
          'a': ['1', '2']
        }),
      );
    });

    test('handles negative list limit correctly', () {
      expect(
        () => QS.decode(
          'a[]=1&a[]=2',
          const DecodeOptions(listLimit: -1, throwOnLimitExceeded: true),
        ),
        throwsA(isA<RangeError>()),
      );
    });

    test('applies list limit to nested lists', () {
      expect(
        () => QS.decode(
          'a[0][]=1&a[0][]=2&a[0][]=3&a[0][]=4',
          const DecodeOptions(listLimit: 3, throwOnLimitExceeded: true),
        ),
        throwsA(isA<RangeError>()),
      );
    });
  });

  group('key-aware decoder + options isolation', () {
    test('custom decoder receives kind for keys and values', () {
      final kinds = <DecodeKind>[];
      dynamic dec(String? v, {Encoding? charset, DecodeKind? kind}) {
        kinds.add(kind ?? DecodeKind.value);
        return Utils.decode(v, charset: charset);
      }

      expect(QS.decode('a=b&c=d', DecodeOptions(decoder: dec)), {
        'a': 'b',
        'c': 'd',
      });

      expect(kinds, [
        DecodeKind.key, DecodeKind.value, // a=b
        DecodeKind.key, DecodeKind.value, // c=d
      ]);
    });

    test('legacy single-arg decoder still works', () {
      String? dec(String? v) => v?.toUpperCase();
      expect(QS.decode('a=b', DecodeOptions(decoder: dec)), {'A': 'B'});
    });

    test('decoder that only accepts kind also works', () {
      dynamic dec(String? v, {DecodeKind? kind}) =>
          kind == DecodeKind.key ? v?.toUpperCase() : v;

      expect(QS.decode('aa=bb', DecodeOptions(decoder: dec)), {'AA': 'bb'});
    });

    test('parseLists toggle does not leak across calls (string input)', () {
      // Build a query with many top-level params to trigger the internal guardrail
      final bigQuery = List.generate(25, (i) => 'k$i=v$i').join('&');
      final opts = const DecodeOptions(listLimit: 20);

      final res1 = QS.decode(bigQuery, opts);
      expect(res1.length, 25);

      // The same options instance should still parse lists on the next call
      final res2 = QS.decode('a[]=1&a[]=2', opts);
      expect(res2, {
        'a': ['1', '2']
      });
    });
  });

  group('DecodeKind scenarios', () {
    test('uses KEY for bare key without = (strictNullHandling true)', () {
      final kinds = <DecodeKind>[];
      dynamic dec(String? v, {Encoding? charset, DecodeKind? kind}) {
        kinds.add(kind ?? DecodeKind.value);
        return Utils.decode(v, charset: charset);
      }

      final res = QS.decode(
          'foo', DecodeOptions(strictNullHandling: true, decoder: dec));
      expect(res, {'foo': null});
      expect(kinds, [DecodeKind.key]);
    });

    test('comma-split invokes VALUE for each segment', () {
      final kinds = <DecodeKind>[];
      dynamic dec(String? v, {Encoding? charset, DecodeKind? kind}) {
        kinds.add(kind ?? DecodeKind.value);
        return Utils.decode(v, charset: charset);
      }

      final res = QS.decode('a=b,c', DecodeOptions(comma: true, decoder: dec));
      expect(res, {
        'a': ['b', 'c']
      });
      // Order: key, value(b), value(c)
      expect(kinds, [DecodeKind.key, DecodeKind.value, DecodeKind.value]);
    });

    test('custom decoder can mutate keys only (KEY) without touching values',
        () {
      dynamic dec(String? v, {Encoding? charset, DecodeKind? kind}) {
        if (kind == DecodeKind.key) return v?.toUpperCase();
        return v;
      }

      expect(QS.decode('a=b&c=d', DecodeOptions(decoder: dec)), {
        'A': 'b',
        'C': 'd',
      });
    });

    test('custom decoder returning null for VALUE preserves null in result',
        () {
      dynamic dec(String? v, {Encoding? charset, DecodeKind? kind}) {
        if (kind == DecodeKind.value) return null;
        return v;
      }

      expect(QS.decode('a=b', DecodeOptions(decoder: dec)), {'a': null});
    });

    test('decoder is not invoked for Map input', () {
      dynamic dec(String? v, {Encoding? charset, DecodeKind? kind}) {
        throw StateError('decoder should not be called for Map input');
      }

      final input = {'a': 'b'};
      expect(QS.decode(input, DecodeOptions(decoder: dec)), equals(input));
    });

    test('duplicates=combine yields KEY,VALUE per pair', () {
      final kinds = <DecodeKind>[];
      dynamic dec(String? v, {Encoding? charset, DecodeKind? kind}) {
        kinds.add(kind ?? DecodeKind.value);
        return v;
      }

      final res = QS.decode('foo=bar&foo=baz', DecodeOptions(decoder: dec));
      expect(res, {
        'foo': ['bar', 'baz']
      });
      expect(kinds, [
        DecodeKind.key, DecodeKind.value, // first
        DecodeKind.key, DecodeKind.value, // second
      ]);
    });

    test('charset sentinel switches charset observed by decoder', () {
      final seen = <Encoding?>[];
      dynamic dec(String? v, {Encoding? charset, DecodeKind? kind}) {
        seen.add(charset);
        return v; // pass through
      }

      // Numeric entity sentinel implies latin1
      final res = QS.decode(
        'utf8=%26%2310003%3B&x=%C3%B8',
        DecodeOptions(charsetSentinel: true, charset: utf8, decoder: dec),
      );
      expect(res, contains('x'));
      // We expect at least one latin1 observation (for the x pair after sentinel)
      expect(seen.any((e) => e == latin1), isTrue);
    });

    test('parseLists=false still passes KEY for keys and VALUE for values', () {
      final kinds = <DecodeKind>[];
      dynamic dec(String? v, {Encoding? charset, DecodeKind? kind}) {
        kinds.add(kind ?? DecodeKind.value);
        return v;
      }

      final res =
          QS.decode('a[0]=b', DecodeOptions(parseLists: false, decoder: dec));
      expect(res, {
        'a': {'0': 'b'}
      });
      expect(kinds, [DecodeKind.key, DecodeKind.value]);
    });
  });

  group('decoder dynamic fallback', () {
    test(
        'callable object with mismatching named params falls back to (value) only',
        () {
      final calls = <String?>[];
      // A callable object whose named parameters do not match the library typedefs.
      final res = QS.decode('a=b', DecodeOptions(decoder: _Loose1(calls).call));
      // Since the dynamic path ends up invoking `(value)` with no named args,
      // both key and value get prefixed with 'X'.
      expect(res, {'Xa': 'Xb'});
      expect(calls, ['a', 'b']);
    });

    test(
        'callable object with a required named param triggers Utils.decode fallback',
        () {
      final res = QS.decode('a=b', DecodeOptions(decoder: _Loose2().call));
      expect(res, {'a': 'b'});
    });
  });

  group('C# parity: encoded dot behavior in keys (%2E / %2e)', () {
    test(
      'top-level: allowDots=true, decodeDotInKeys=true → plain dot splits; encoded dot also splits (upper/lower)',
      () {
        const opt = DecodeOptions(allowDots: true, decodeDotInKeys: true);
        expect(
            QS.decode('a.b=c', opt),
            equals({
              'a': {'b': 'c'}
            }));
        expect(
            QS.decode('a%2Eb=c', opt),
            equals({
              'a': {'b': 'c'}
            }));
        expect(
            QS.decode('a%2eb=c', opt),
            equals({
              'a': {'b': 'c'}
            }));
      },
    );

    test(
      'top-level: allowDots=true, decodeDotInKeys=false → encoded dot also splits (upper/lower)',
      () {
        const opt = DecodeOptions(allowDots: true, decodeDotInKeys: false);
        expect(
            QS.decode('a%2Eb=c', opt),
            equals({
              'a': {'b': 'c'}
            }));
        expect(
            QS.decode('a%2eb=c', opt),
            equals({
              'a': {'b': 'c'}
            }));
      },
    );

    test('allowDots=false, decodeDotInKeys=true is invalid', () {
      expect(
        () => QS.decode(
            'a%2Eb=c', DecodeOptions(allowDots: false, decodeDotInKeys: true)),
        throwsA(anyOf(
          isA<ArgumentError>(),
          isA<StateError>(),
          isA<AssertionError>(),
        )),
      );
    });

    test(
        'bracket segment: maps to \'.\' when decodeDotInKeys=true (case-insensitive)',
        () {
      const opt = DecodeOptions(allowDots: true, decodeDotInKeys: true);
      expect(
          QS.decode('a[%2E]=x', opt),
          equals({
            'a': {'.': 'x'}
          }));
      expect(
          QS.decode('a[%2e]=x', opt),
          equals({
            'a': {'.': 'x'}
          }));
    });

    test(
      'bracket segment: when decodeDotInKeys=false, percent-decoding inside brackets yields \'.\' (case-insensitive)',
      () {
        const opt = DecodeOptions(allowDots: true, decodeDotInKeys: false);
        expect(
            QS.decode('a[%2E]=x', opt),
            equals({
              'a': {'.': 'x'}
            }));
        expect(
            QS.decode('a[%2e]=x', opt),
            equals({
              'a': {'.': 'x'}
            }));
      },
    );

    test('value tokens always decode %2E → \'.\'', () {
      expect(QS.decode('x=%2E'), equals({'x': '.'}));
    });

    test(
      'latin1: allowDots=true, decodeDotInKeys=true behaves like UTF-8 for top-level & bracket segment',
      () {
        const opt = DecodeOptions(
            allowDots: true, decodeDotInKeys: true, charset: latin1);
        expect(
            QS.decode('a%2Eb=c', opt),
            equals({
              'a': {'b': 'c'}
            }));
        expect(
            QS.decode('a[%2E]=x', opt),
            equals({
              'a': {'.': 'x'}
            }));
      },
    );

    test(
      'latin1: allowDots=true, decodeDotInKeys=false also splits top-level and decodes inside brackets',
      () {
        const opt = DecodeOptions(
            allowDots: true, decodeDotInKeys: false, charset: latin1);
        expect(
            QS.decode('a%2Eb=c', opt),
            equals({
              'a': {'b': 'c'}
            }));
        expect(
            QS.decode('a[%2E]=x', opt),
            equals({
              'a': {'.': 'x'}
            }));
      },
    );

    test('percent-decoding applies inside brackets for keys', () {
      // Equivalent of Kotlin's DecodeOptions.decode(KEY) assertions using QS.decode
      const o1 = DecodeOptions(allowDots: false, decodeDotInKeys: false);
      const o2 = DecodeOptions(allowDots: true, decodeDotInKeys: false);

      expect(
          QS.decode('a[%2Eb]=v', o1),
          equals({
            'a': {'.b': 'v'}
          }));
      expect(
          QS.decode('a[b%2Ec]=v', o1),
          equals({
            'a': {'b.c': 'v'}
          }));

      expect(
          QS.decode('a[%2Eb]=v', o2),
          equals({
            'a': {'.b': 'v'}
          }));
      expect(
          QS.decode('a[b%2Ec]=v', o2),
          equals({
            'a': {'b.c': 'v'}
          }));
    });

    test(
      'mixed-case encoded brackets + encoded dot after brackets (allowDots=true, decodeDotInKeys=true)',
      () {
        const opt = DecodeOptions(allowDots: true, decodeDotInKeys: true);
        expect(
          QS.decode('a%5Bb%5D%5Bc%5D%2Ed=x', opt),
          equals({
            'a': {
              'b': {
                'c': {'d': 'x'}
              }
            }
          }),
        );
        expect(
          QS.decode('a%5bb%5d%5bc%5d%2ed=x', opt),
          equals({
            'a': {
              'b': {
                'c': {'d': 'x'}
              }
            }
          }),
        );
      },
    );

    test('nested brackets inside a bracket segment (balanced as one segment)',
        () {
      const opt = DecodeOptions(allowDots: true, decodeDotInKeys: true);
      // "a[b%5Bc%5D].e=x" → key "b[c]" stays a single segment; then ".e" splits
      expect(
        QS.decode('a[b%5Bc%5D].e=x', opt),
        equals({
          'a': {
            'b[c]': {'e': 'x'}
          }
        }),
      );
    });

    test(
      'mixed-case encoded brackets + encoded dot with allowDots=false & decodeDotInKeys=true throws',
      () {
        expect(
          () => QS.decode('a%5Bb%5D%5Bc%5D%2Ed=x',
              DecodeOptions(allowDots: false, decodeDotInKeys: true)),
          throwsA(anyOf(
            isA<ArgumentError>(),
            isA<StateError>(),
            isA<AssertionError>(),
          )),
        );
      },
    );

    test(
        'top-level encoded dot splits when allowDots=true, decodeDotInKeys=true',
        () {
      const opt = DecodeOptions(allowDots: true, decodeDotInKeys: true);
      expect(
          QS.decode('a%2Eb=c', opt),
          equals({
            'a': {'b': 'c'}
          }));
    });

    test(
        'top-level encoded dot also splits when allowDots=true, decodeDotInKeys=false',
        () {
      const opt = DecodeOptions(allowDots: true, decodeDotInKeys: false);
      expect(
          QS.decode('a%2Eb=c', opt),
          equals({
            'a': {'b': 'c'}
          }));
    });

    test(
        'top-level encoded dot does not split when allowDots=false, decodeDotInKeys=false',
        () {
      const opt = DecodeOptions(allowDots: false, decodeDotInKeys: false);
      expect(QS.decode('a%2Eb=c', opt), equals({'a.b': 'c'}));
    });

    test('bracket then encoded dot to next segment with allowDots=true', () {
      const opt = DecodeOptions(allowDots: true, decodeDotInKeys: true);
      expect(
          QS.decode('a[b]%2Ec=x', opt),
          equals({
            'a': {
              'b': {'c': 'x'}
            }
          }));
      expect(
          QS.decode('a[b]%2ec=x', opt),
          equals({
            'a': {
              'b': {'c': 'x'}
            }
          }));
    });

    test('mixed-case: top-level encoded dot then bracket with allowDots=true',
        () {
      const opt = DecodeOptions(allowDots: true, decodeDotInKeys: true);
      expect(
          QS.decode('a%2E[b]=x', opt),
          equals({
            'a': {'b': 'x'}
          }));
    });

    test(
        'top-level lowercase encoded dot splits when allowDots=true (decodeDotInKeys=false)',
        () {
      const opt = DecodeOptions(allowDots: true, decodeDotInKeys: false);
      expect(
          QS.decode('a%2eb=c', opt),
          equals({
            'a': {'b': 'c'}
          }));
    });

    test('dot before index with allowDots=true: index remains index', () {
      const opt = DecodeOptions(allowDots: true);
      expect(
        QS.decode('foo[0].baz[0]=15&foo[0].bar=2', opt),
        equals({
          'foo': [
            {
              'baz': ['15'],
              'bar': '2',
            }
          ]
        }),
      );
    });

    test('trailing dot ignored when allowDots=true', () {
      const opt = DecodeOptions(allowDots: true);
      expect(
          QS.decode('user.email.=x', opt),
          equals({
            'user': {'email': 'x'}
          }));
    });

    test(
        'bracket segment: encoded dot mapped to \'.\' (allowDots=true, decodeDotInKeys=true)',
        () {
      const opt = DecodeOptions(allowDots: true, decodeDotInKeys: true);
      expect(
          QS.decode('a[%2E]=x', opt),
          equals({
            'a': {'.': 'x'}
          }));
      expect(
          QS.decode('a[%2e]=x', opt),
          equals({
            'a': {'.': 'x'}
          }));
    });

    test('top-level encoded dot before bracket (lowercase) with allowDots=true',
        () {
      const opt = DecodeOptions(allowDots: true, decodeDotInKeys: true);
      expect(
          QS.decode('a%2e[b]=x', opt),
          equals({
            'a': {'b': 'x'}
          }));
    });

    test('plain dot before bracket with allowDots=true', () {
      const opt = DecodeOptions(allowDots: true, decodeDotInKeys: true);
      expect(
          QS.decode('a.[b]=x', opt),
          equals({
            'a': {'b': 'x'}
          }));
    });

    test('kind-aware decoder receives KEY for top-level and bracketed keys',
        () {
      final calls = <List<dynamic>>[]; // [String? s, DecodeKind kind]
      dynamic dec(String? s, {Encoding? charset, DecodeKind? kind}) {
        calls.add([s, kind ?? DecodeKind.value]);
        return s;
      }

      QS.decode('a%2Eb=c&a[b]=d',
          DecodeOptions(allowDots: true, decodeDotInKeys: true, decoder: dec));

      expect(
        calls.any((it) =>
            it[1] == DecodeKind.key && (it[0] == 'a%2Eb' || it[0] == 'a[b]')),
        isTrue,
      );
      expect(
        calls.any((it) =>
            it[1] == DecodeKind.value && (it[0] == 'c' || it[0] == 'd')),
        isTrue,
      );
    });
  });
}

// Helper callable used to exercise the dynamic function fallback in DecodeOptions.decoder.
// Named parameters intentionally do not match `charset`/`kind` so the typed branches
// are skipped and the dynamic ladder is exercised.
class _Loose1 {
  final List<String?> sink;

  _Loose1(this.sink);

  dynamic call(String? v, {Encoding? cs, DecodeKind? kd}) {
    sink.add(v);
    return v == null ? null : 'X$v';
  }
}

// Helper callable that requires an unsupported named parameter; all dynamic attempts
// should throw, causing the code to fall back to Utils.decode.
class _Loose2 {
  dynamic call(String? v, {required int must}) => 'Y$v';
}
