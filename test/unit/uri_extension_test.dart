import 'dart:convert' show Encoding, latin1, utf8;
import 'dart:typed_data' show Uint8List;

import 'package:euc/jis.dart';
import 'package:qs_dart/src/models/decode_options.dart';
import 'package:qs_dart/src/qs.dart';
import 'package:qs_dart/src/uri.dart';
import 'package:qs_dart/src/utils.dart';
import 'package:test/test.dart';

void main() {
  const String authority = 'test.local';
  const String path = '/example';
  const String testUrl = 'https://$authority$path';

  group('Uri.queryParametersQs', () {
    test('parses a simple string', () {
      expect(
        Uri.parse('$testUrl?0=foo').queryParametersQs(),
        equals({'0': 'foo'}),
      );
      expect(
        Uri.parse('$testUrl?foo=c++').queryParametersQs(),
        equals({'foo': 'c  '}),
      );
      expect(
        Uri.parse('$testUrl?a[${Uri.encodeComponent('>=')}]=23')
            .queryParametersQs(),
        equals({
          'a': {'>=': '23'}
        }),
      );
      expect(
        Uri.parse('$testUrl?a[${Uri.encodeComponent('<=>')}]==23')
            .queryParametersQs(),
        equals({
          'a': {'<=>': '=23'}
        }),
      );
      expect(
        Uri.parse('$testUrl?a[${Uri.encodeComponent('==')}]=23')
            .queryParametersQs(),
        equals({
          'a': {'==': '23'}
        }),
      );
      expect(
        Uri.parse('$testUrl?foo').queryParametersQs(
          const DecodeOptions(strictNullHandling: true),
        ),
        equals({'foo': null}),
      );
      expect(
        Uri.parse('$testUrl?foo').queryParametersQs(),
        equals({'foo': ''}),
      );
      expect(
        Uri.parse('$testUrl?foo=').queryParametersQs(),
        equals({'foo': ''}),
      );
      expect(
        Uri.parse('$testUrl?foo=bar').queryParametersQs(),
        equals({'foo': 'bar'}),
      );
      expect(
        Uri.parse('$testUrl? foo = bar = baz ').queryParametersQs(),
        equals({' foo ': ' bar = baz '}),
      );
      expect(
        Uri.parse('$testUrl?foo=bar=baz').queryParametersQs(),
        equals({'foo': 'bar=baz'}),
      );
      expect(
        Uri.parse('$testUrl?foo=bar&bar=baz').queryParametersQs(),
        equals({'foo': 'bar', 'bar': 'baz'}),
      );
      expect(
        Uri.parse('$testUrl?foo2=bar2&baz2=').queryParametersQs(),
        equals({'foo2': 'bar2', 'baz2': ''}),
      );
      expect(
        Uri.parse('$testUrl?foo=bar&baz')
            .queryParametersQs(const DecodeOptions(strictNullHandling: true)),
        equals({'foo': 'bar', 'baz': null}),
      );
      expect(
        Uri.parse('$testUrl?foo=bar&baz').queryParametersQs(),
        equals({'foo': 'bar', 'baz': ''}),
      );
      expect(
        Uri.parse('$testUrl?cht=p3&chd=t:60,40&chs=250x100&chl=Hello|World')
            .queryParametersQs(),
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
        Uri.parse('$testUrl?a[]=b&a[]=c').queryParametersQs(),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        Uri.parse('$testUrl?a[0]=b&a[1]=c').queryParametersQs(),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        Uri.parse('$testUrl?a=b,c').queryParametersQs(),
        equals({'a': 'b,c'}),
      );
      expect(
        Uri.parse('$testUrl?a=b&a=c').queryParametersQs(),
        equals({
          'a': ['b', 'c']
        }),
      );
    });

    test('comma: true', () {
      expect(
        Uri.parse('$testUrl?a[]=b&a[]=c')
            .queryParametersQs(const DecodeOptions(comma: true)),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        Uri.parse('$testUrl?a[0]=b&a[1]=c')
            .queryParametersQs(const DecodeOptions(comma: true)),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        Uri.parse('$testUrl?a=b,c')
            .queryParametersQs(const DecodeOptions(comma: true)),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        Uri.parse('$testUrl?a=b&a=c')
            .queryParametersQs(const DecodeOptions(comma: true)),
        equals({
          'a': ['b', 'c']
        }),
      );
    });

    test('allows enabling dot notation', () {
      expect(
        Uri.parse('$testUrl?a.b=c').queryParametersQs(),
        equals({'a.b': 'c'}),
      );
      expect(
        Uri.parse('$testUrl?a.b=c')
            .queryParametersQs(const DecodeOptions(allowDots: true)),
        equals({
          'a': {'b': 'c'}
        }),
      );
    });

    test('decode dot keys correctly', () {
      expect(
        Uri.parse('$testUrl?name%252Eobj.first=John&name%252Eobj.last=Doe')
            .queryParametersQs(
          const DecodeOptions(allowDots: false, decodeDotInKeys: false),
        ),
        equals({'name%2Eobj.first': 'John', 'name%2Eobj.last': 'Doe'}),
      );
      expect(
        Uri.parse('$testUrl?name.obj.first=John&name.obj.last=Doe')
            .queryParametersQs(
          const DecodeOptions(allowDots: true, decodeDotInKeys: false),
        ),
        equals({
          'name': {
            'obj': {'first': 'John', 'last': 'Doe'}
          }
        }),
      );
      expect(
        Uri.parse('$testUrl?name%252Eobj.first=John&name%252Eobj.last=Doe')
            .queryParametersQs(
          const DecodeOptions(allowDots: true, decodeDotInKeys: false),
        ),
        equals({
          'name%2Eobj': {'first': 'John', 'last': 'Doe'}
        }),
      );
      expect(
        Uri.parse('$testUrl?name%252Eobj.first=John&name%252Eobj.last=Doe')
            .queryParametersQs(
          const DecodeOptions(allowDots: true, decodeDotInKeys: true),
        ),
        equals({
          'name.obj': {'first': 'John', 'last': 'Doe'}
        }),
      );

      expect(
        Uri.parse(
          '$testUrl?name%252Eobj%252Esubobject.first%252Egodly%252Ename=John&name%252Eobj%252Esubobject.last=Doe',
        ).queryParametersQs(
          const DecodeOptions(allowDots: false, decodeDotInKeys: false),
        ),
        equals({
          'name%2Eobj%2Esubobject.first%2Egodly%2Ename': 'John',
          'name%2Eobj%2Esubobject.last': 'Doe'
        }),
      );
      expect(
        Uri.parse(
          '$testUrl?name.obj.subobject.first.godly.name=John&name.obj.subobject.last=Doe',
        ).queryParametersQs(
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
        Uri.parse(
          '$testUrl?name%252Eobj%252Esubobject.first%252Egodly%252Ename=John&name%252Eobj%252Esubobject.last=Doe',
        ).queryParametersQs(
          const DecodeOptions(allowDots: true, decodeDotInKeys: true),
        ),
        equals({
          'name.obj.subobject': {'first.godly.name': 'John', 'last': 'Doe'}
        }),
      );
      expect(
        Uri.parse('$testUrl?name%252Eobj.first=John&name%252Eobj.last=Doe')
            .queryParametersQs(),
        equals({'name%2Eobj.first': 'John', 'name%2Eobj.last': 'Doe'}),
      );
      expect(
        Uri.parse('$testUrl?name%252Eobj.first=John&name%252Eobj.last=Doe')
            .queryParametersQs(
          const DecodeOptions(decodeDotInKeys: false),
        ),
        equals({'name%2Eobj.first': 'John', 'name%2Eobj.last': 'Doe'}),
      );
      expect(
        Uri.parse('$testUrl?name%252Eobj.first=John&name%252Eobj.last=Doe')
            .queryParametersQs(
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
        Uri.parse(
          '$testUrl?name%252Eobj%252Esubobject.first%252Egodly%252Ename=John&name%252Eobj%252Esubobject.last=Doe',
        ).queryParametersQs(
          const DecodeOptions(decodeDotInKeys: true),
        ),
        equals({
          'name.obj.subobject': {'first.godly.name': 'John', 'last': 'Doe'}
        }),
      );
    });

    test('allows empty lists in obj values', () {
      expect(
        Uri.parse('$testUrl?foo[]&bar=baz')
            .queryParametersQs(const DecodeOptions(allowEmptyLists: true)),
        equals({'foo': [], 'bar': 'baz'}),
      );
      expect(
        Uri.parse('$testUrl?foo[]&bar=baz')
            .queryParametersQs(const DecodeOptions(allowEmptyLists: false)),
        equals({
          'foo': [''],
          'bar': 'baz'
        }),
      );
    });

    test('parses a single nested string', () {
      expect(
        Uri.parse('$testUrl?a[b]=c').queryParametersQs(),
        equals({
          'a': {'b': 'c'}
        }),
      );
    });

    test('parses a double nested string', () {
      expect(
        Uri.parse('$testUrl?a[b][c]=d').queryParametersQs(),
        equals({
          'a': {
            'b': {'c': 'd'}
          }
        }),
      );
    });

    test('defaults to a depth of 5', () {
      expect(
        Uri.parse('$testUrl?a[b][c][d][e][f][g][h]=i').queryParametersQs(),
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
        Uri.parse('$testUrl?a[b][c]=d')
            .queryParametersQs(const DecodeOptions(depth: 1)),
        equals({
          'a': {
            'b': {'[c]': 'd'}
          }
        }),
      );
      expect(
        Uri.parse('$testUrl?a[b][c][d]=e')
            .queryParametersQs(const DecodeOptions(depth: 1)),
        equals({
          'a': {
            'b': {'[c][d]': 'e'}
          }
        }),
      );
    });

    test('uses original key when depth = 0', () {
      expect(
        Uri.parse('$testUrl?a[0]=b&a[1]=c')
            .queryParametersQs(const DecodeOptions(depth: 0)),
        equals({'a[0]': 'b', 'a[1]': 'c'}),
      );
      expect(
        Uri.parse('$testUrl?a[0][0]=b&a[0][1]=c&a[1]=d&e=2')
            .queryParametersQs(const DecodeOptions(depth: 0)),
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
        Uri.parse('$testUrl?a=b&a=c').queryParametersQs(),
        equals({
          'a': ['b', 'c']
        }),
      );
    });

    test('parses an explicit list', () {
      expect(
        Uri.parse('$testUrl?a[]=b').queryParametersQs(),
        equals({
          'a': ['b']
        }),
      );
      expect(
        Uri.parse('$testUrl?a[]=b&a[]=c').queryParametersQs(),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        Uri.parse('$testUrl?a[]=b&a[]=c&a[]=d').queryParametersQs(),
        equals({
          'a': ['b', 'c', 'd']
        }),
      );
    });

    test('parses a mix of simple and explicit lists', () {
      expect(
        Uri.parse('$testUrl?a=b&a[]=c').queryParametersQs(),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        Uri.parse('$testUrl?a[]=b&a=c').queryParametersQs(),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        Uri.parse('$testUrl?a[0]=b&a=c').queryParametersQs(),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        Uri.parse('$testUrl?a=b&a[0]=c').queryParametersQs(),
        equals({
          'a': ['b', 'c']
        }),
      );

      expect(
        Uri.parse('$testUrl?a[1]=b&a=c')
            .queryParametersQs(const DecodeOptions(listLimit: 20)),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        Uri.parse('$testUrl?a[]=b&a=c')
            .queryParametersQs(const DecodeOptions(listLimit: 0)),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        Uri.parse('$testUrl?a[]=b&a=c').queryParametersQs(),
        equals({
          'a': ['b', 'c']
        }),
      );

      expect(
        Uri.parse('$testUrl?a=b&a[1]=c')
            .queryParametersQs(const DecodeOptions(listLimit: 20)),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        Uri.parse('$testUrl?a=b&a[]=c')
            .queryParametersQs(const DecodeOptions(listLimit: 0)),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        Uri.parse('$testUrl?a=b&a[]=c').queryParametersQs(),
        equals({
          'a': ['b', 'c']
        }),
      );
    });

    test('parses a nested list', () {
      expect(
        Uri.parse('$testUrl?a[b][]=c&a[b][]=d').queryParametersQs(),
        equals({
          'a': {
            'b': ['c', 'd']
          }
        }),
      );
      expect(
        Uri.parse('$testUrl?a[${Uri.encodeComponent('>=')}]=25')
            .queryParametersQs(),
        equals({
          'a': {'>=': '25'}
        }),
      );
    });

    test('allows to specify list indices', () {
      expect(
        Uri.parse('$testUrl?a[1]=c&a[0]=b&a[2]=d').queryParametersQs(),
        equals({
          'a': ['b', 'c', 'd']
        }),
      );
      expect(
        Uri.parse('$testUrl?a[1]=c&a[0]=b').queryParametersQs(),
        equals({
          'a': ['b', 'c']
        }),
      );
      expect(
        Uri.parse('$testUrl?a[1]=c')
            .queryParametersQs(const DecodeOptions(listLimit: 20)),
        equals({
          'a': ['c']
        }),
      );
      expect(
        Uri.parse('$testUrl?a[1]=c')
            .queryParametersQs(const DecodeOptions(listLimit: 0)),
        equals({
          'a': {'1': 'c'}
        }),
      );
      expect(
        Uri.parse('$testUrl?a[1]=c').queryParametersQs(),
        equals({
          'a': ['c']
        }),
      );
    });

    test('limits specific list indices to listLimit', () {
      expect(
        Uri.parse('$testUrl?a[20]=a')
            .queryParametersQs(const DecodeOptions(listLimit: 20)),
        equals({
          'a': ['a']
        }),
      );
      expect(
        Uri.parse('$testUrl?a[21]=a')
            .queryParametersQs(const DecodeOptions(listLimit: 20)),
        equals({
          'a': {'21': 'a'}
        }),
      );

      expect(
        Uri.parse('$testUrl?a[20]=a').queryParametersQs(),
        equals({
          'a': ['a']
        }),
      );
      expect(
        Uri.parse('$testUrl?a[21]=a').queryParametersQs(),
        equals({
          'a': {'21': 'a'}
        }),
      );
    });

    test('supports keys that begin with a number', () {
      expect(
        Uri.parse('$testUrl?a[12b]=c').queryParametersQs(),
        equals({
          'a': {'12b': 'c'}
        }),
      );
    });

    test('supports encoded = signs', () {
      expect(
        Uri.parse('$testUrl?he%3Dllo=th%3Dere').queryParametersQs(),
        equals({'he=llo': 'th=ere'}),
      );
    });

    test('is ok with url encoded strings', () {
      expect(
        Uri.parse('$testUrl?a[b%20c]=d').queryParametersQs(),
        equals({
          'a': {'b c': 'd'}
        }),
      );
      expect(
        Uri.parse('$testUrl?a[b]=c%20d').queryParametersQs(),
        equals({
          'a': {'b': 'c d'}
        }),
      );
    });

    test('allows brackets in the value', () {
      expect(
        Uri.parse('$testUrl?pets=["tobi"]').queryParametersQs(),
        equals({'pets': '["tobi"]'}),
      );
      expect(
        Uri.parse('$testUrl?operators=[">=", "<="]').queryParametersQs(),
        equals({'operators': '[">=", "<="]'}),
      );
    });

    test('allows empty values', () {
      expect(Uri.parse(testUrl).queryParametersQs(), equals({}));
    });

    test('transforms lists to maps', () {
      expect(
        Uri.parse('$testUrl?foo[0]=bar&foo[bad]=baz').queryParametersQs(),
        equals({
          'foo': {'0': 'bar', 'bad': 'baz'}
        }),
      );
      expect(
        Uri.parse('$testUrl?foo[bad]=baz&foo[0]=bar').queryParametersQs(),
        equals({
          'foo': {'bad': 'baz', '0': 'bar'}
        }),
      );
      expect(
        Uri.parse('$testUrl?foo[bad]=baz&foo[]=bar').queryParametersQs(),
        equals({
          'foo': {'bad': 'baz', '0': 'bar'}
        }),
      );
      expect(
        Uri.parse('$testUrl?foo[]=bar&foo[bad]=baz').queryParametersQs(),
        equals({
          'foo': {'0': 'bar', 'bad': 'baz'}
        }),
      );
      expect(
        Uri.parse('$testUrl?foo[bad]=baz&foo[]=bar&foo[]=foo')
            .queryParametersQs(),
        equals({
          'foo': {'bad': 'baz', '0': 'bar', '1': 'foo'}
        }),
      );
      expect(
        Uri.parse(
          '$testUrl?foo[0][a]=a&foo[0][b]=b&foo[1][a]=aa&foo[1][b]=bb',
        ).queryParametersQs(),
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
        Uri.parse('$testUrl?foo[0].baz=bar&fool.bad=baz')
            .queryParametersQs(const DecodeOptions(allowDots: true)),
        equals({
          'foo': [
            {'baz': 'bar'}
          ],
          'fool': {'bad': 'baz'}
        }),
      );
      expect(
        Uri.parse('$testUrl?foo[0].baz=bar&fool.bad.boo=baz')
            .queryParametersQs(const DecodeOptions(allowDots: true)),
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
        Uri.parse('$testUrl?foo[0][0].baz=bar&fool.bad=baz')
            .queryParametersQs(const DecodeOptions(allowDots: true)),
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
        Uri.parse('$testUrl?foo[0].baz[0]=15&foo[0].bar=2')
            .queryParametersQs(const DecodeOptions(allowDots: true)),
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
        Uri.parse(
          '$testUrl?foo[0].baz[0]=15&foo[0].baz[1]=16&foo[0].bar=2',
        ).queryParametersQs(const DecodeOptions(allowDots: true)),
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
        Uri.parse('$testUrl?foo.bad=baz&foo[0]=bar')
            .queryParametersQs(const DecodeOptions(allowDots: true)),
        equals({
          'foo': {'bad': 'baz', '0': 'bar'}
        }),
      );
      expect(
        Uri.parse('$testUrl?foo.bad=baz&foo[]=bar')
            .queryParametersQs(const DecodeOptions(allowDots: true)),
        equals({
          'foo': {'bad': 'baz', '0': 'bar'}
        }),
      );
      expect(
        Uri.parse('$testUrl?foo[]=bar&foo.bad=baz')
            .queryParametersQs(const DecodeOptions(allowDots: true)),
        equals({
          'foo': {'0': 'bar', 'bad': 'baz'}
        }),
      );
      expect(
        Uri.parse('$testUrl?foo.bad=baz&foo[]=bar&foo[]=foo')
            .queryParametersQs(const DecodeOptions(allowDots: true)),
        equals({
          'foo': {'bad': 'baz', '0': 'bar', '1': 'foo'}
        }),
      );
      expect(
        Uri.parse(
          '$testUrl?foo[0].a=a&foo[0].b=b&foo[1].a=aa&foo[1].b=bb',
        ).queryParametersQs(const DecodeOptions(allowDots: true)),
        equals({
          'foo': [
            {'a': 'a', 'b': 'b'},
            {'a': 'aa', 'b': 'bb'}
          ]
        }),
      );
    });

    test(
      'correctly prunes undefined values when converting a list to a map',
      () {
        expect(
          Uri.parse('$testUrl?a[2]=b&a[99999999]=c').queryParametersQs(),
          equals({
            'a': {'2': 'b', '99999999': 'c'}
          }),
        );
      },
    );

    test('supports malformed uri characters', () {
      expect(
        Uri.parse('$testUrl?{%:%}')
            .queryParametersQs(const DecodeOptions(strictNullHandling: true)),
        equals({'{%:%}': null}),
      );
      expect(
        Uri.parse('$testUrl?{%:%}=').queryParametersQs(),
        equals({'{%:%}': ''}),
      );
      expect(
        Uri.parse('$testUrl?foo=%:%}').queryParametersQs(),
        equals({'foo': '%:%}'}),
      );
    });

    test('does not produce empty keys', () {
      expect(
        Uri.parse('$testUrl?_r=1&').queryParametersQs(),
        equals({'_r': '1'}),
      );
    });

    test('parses lists of maps', () {
      expect(
        Uri.parse('$testUrl?a[][b]=c').queryParametersQs(),
        equals({
          'a': [
            {'b': 'c'}
          ]
        }),
      );
      expect(
        Uri.parse('$testUrl?a[0][b]=c').queryParametersQs(),
        equals({
          'a': [
            {'b': 'c'}
          ]
        }),
      );
    });

    test('allows for empty strings in lists', () {
      expect(
        Uri.parse('$testUrl?a[]=b&a[]=&a[]=c').queryParametersQs(),
        equals({
          'a': ['b', '', 'c']
        }),
      );

      expect(
        Uri.parse('$testUrl?a[0]=b&a[1]&a[2]=c&a[19]=').queryParametersQs(
          const DecodeOptions(strictNullHandling: true, listLimit: 20),
        ),
        equals({
          'a': ['b', null, 'c', '']
        }),
      );

      expect(
        Uri.parse('$testUrl?a[]=b&a[]&a[]=c&a[]=').queryParametersQs(
          const DecodeOptions(strictNullHandling: true, listLimit: 0),
        ),
        equals({
          'a': ['b', null, 'c', '']
        }),
      );

      expect(
        Uri.parse('$testUrl?a[0]=b&a[1]=&a[2]=c&a[19]').queryParametersQs(
          const DecodeOptions(strictNullHandling: true, listLimit: 20),
        ),
        equals({
          'a': ['b', '', 'c', null]
        }),
      );

      expect(
        Uri.parse('$testUrl?a[]=b&a[]=&a[]=c&a[]').queryParametersQs(
          const DecodeOptions(strictNullHandling: true, listLimit: 0),
        ),
        equals({
          'a': ['b', '', 'c', null]
        }),
      );

      expect(
        Uri.parse('$testUrl?a[]=&a[]=b&a[]=c').queryParametersQs(),
        equals({
          'a': ['', 'b', 'c']
        }),
      );
    });

    test('compacts sparse lists', () {
      expect(
        Uri.parse('$testUrl?a[10]=1&a[2]=2')
            .queryParametersQs(const DecodeOptions(listLimit: 20)),
        equals({
          'a': ['2', '1']
        }),
      );
      expect(
        Uri.parse('$testUrl?a[1][b][2][c]=1')
            .queryParametersQs(const DecodeOptions(listLimit: 20)),
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
        Uri.parse('$testUrl?a[1][2][3][c]=1')
            .queryParametersQs(const DecodeOptions(listLimit: 20)),
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
        Uri.parse('$testUrl?a[1][2][3][c][1]=1')
            .queryParametersQs(const DecodeOptions(listLimit: 20)),
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
        Uri.parse('$testUrl?a[b]=c').queryParametersQs(),
        equals({
          'a': {'b': 'c'}
        }),
      );
      expect(
        Uri.parse('$testUrl?a[b]=c&a[d]=e').queryParametersQs(),
        equals({
          'a': {'b': 'c', 'd': 'e'}
        }),
      );
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
      expect(
          Uri.parse('$testUrl?$encoded').queryParametersQs(), equals(expected));
    });

    test('continues parsing when no parent is found', () {
      expect(QS.decode('[]=&a=b'), equals({'0': '', 'a': 'b'}));
      expect(
        Uri.parse('$testUrl?[]&a=b').queryParametersQs(
          const DecodeOptions(strictNullHandling: true),
        ),
        equals({'0': null, 'a': 'b'}),
      );
      expect(Uri.parse('$testUrl?[foo]=bar').queryParametersQs(),
          equals({'foo': 'bar'}));
    });

    test('does not error when parsing a very long list', () {
      final StringBuffer str = StringBuffer('a[]=a');
      while (utf8.encode(str.toString()).length < 128 * 1024) {
        str.write('&');
        str.write(str);
      }

      expect(
        () => Uri.parse('$testUrl?$str').queryParametersQs(),
        returnsNormally,
      );
    });

    test('parses a string with an alternative string delimiter', () {
      expect(
        Uri.parse('$testUrl?a=b;c=d')
            .queryParametersQs(const DecodeOptions(delimiter: ';')),
        equals({'a': 'b', 'c': 'd'}),
      );
    });

    test('parses a string with an alternative RegExp delimiter', () {
      expect(
        Uri.parse('$testUrl?a=b; c=d').queryParametersQs(
            DecodeOptions(delimiter: RegExp(r'[;,][%20|+]*'))),
        equals({'a': 'b', 'c': 'd'}),
      );
    });

    test('allows overriding parameter limit', () {
      expect(
        Uri.parse('$testUrl?a=b&c=d')
            .queryParametersQs(const DecodeOptions(parameterLimit: 1)),
        equals({'a': 'b'}),
      );
    });

    test('allows setting the parameter limit to Infinity', () {
      expect(
        Uri.parse('$testUrl?a=b&c=d').queryParametersQs(
            const DecodeOptions(parameterLimit: double.infinity)),
        equals({'a': 'b', 'c': 'd'}),
      );
    });

    test('allows overriding list limit', () {
      expect(
        Uri.parse('$testUrl?a[0]=b')
            .queryParametersQs(const DecodeOptions(listLimit: -1)),
        equals({
          'a': {'0': 'b'}
        }),
      );
      expect(
        Uri.parse('$testUrl?a[0]=b')
            .queryParametersQs(const DecodeOptions(listLimit: 0)),
        equals({
          'a': ['b']
        }),
      );

      expect(
        Uri.parse('$testUrl?a[-1]=b')
            .queryParametersQs(const DecodeOptions(listLimit: -1)),
        equals({
          'a': {'-1': 'b'}
        }),
      );
      expect(
        Uri.parse('$testUrl?a[-1]=b')
            .queryParametersQs(const DecodeOptions(listLimit: 0)),
        equals({
          'a': {'-1': 'b'}
        }),
      );

      expect(
        Uri.parse('$testUrl?a[0]=b&a[1]=c')
            .queryParametersQs(const DecodeOptions(listLimit: -1)),
        equals({
          'a': {'0': 'b', '1': 'c'}
        }),
      );
      expect(
        Uri.parse('$testUrl?a[0]=b&a[1]=c')
            .queryParametersQs(const DecodeOptions(listLimit: 0)),
        equals({
          'a': {'0': 'b', '1': 'c'}
        }),
      );
    });

    test('allows disabling list parsing', () {
      expect(
        Uri.parse('$testUrl?a[0]=b&a[1]=c')
            .queryParametersQs(const DecodeOptions(parseLists: false)),
        equals({
          'a': {'0': 'b', '1': 'c'}
        }),
      );
      expect(
        Uri.parse('$testUrl?a[]=b')
            .queryParametersQs(const DecodeOptions(parseLists: false)),
        equals({
          'a': {'0': 'b'}
        }),
      );
    });

    test('allows for query string prefix', () {
      expect(
        Uri.parse('$testUrl??foo=bar')
            .queryParametersQs(const DecodeOptions(ignoreQueryPrefix: true)),
        equals({'foo': 'bar'}),
      );
      expect(
        Uri.parse('$testUrl?foo=bar')
            .queryParametersQs(const DecodeOptions(ignoreQueryPrefix: true)),
        equals({'foo': 'bar'}),
      );
      expect(
        Uri.parse('$testUrl??foo=bar')
            .queryParametersQs(const DecodeOptions(ignoreQueryPrefix: false)),
        equals({'?foo': 'bar'}),
      );
    });

    test('parses string with comma as list divider', () {
      expect(
        Uri.parse('$testUrl?foo=bar,tee')
            .queryParametersQs(const DecodeOptions(comma: true)),
        equals({
          'foo': ['bar', 'tee']
        }),
      );
      expect(
        Uri.parse('$testUrl?foo[bar]=coffee,tee')
            .queryParametersQs(const DecodeOptions(comma: true)),
        equals({
          'foo': {
            'bar': ['coffee', 'tee']
          }
        }),
      );
      expect(
        Uri.parse('$testUrl?foo=')
            .queryParametersQs(const DecodeOptions(comma: true)),
        equals({'foo': ''}),
      );
      expect(
        Uri.parse('$testUrl?foo')
            .queryParametersQs(const DecodeOptions(comma: true)),
        equals({'foo': ''}),
      );
      expect(
        Uri.parse('$testUrl?foo').queryParametersQs(
            const DecodeOptions(comma: true, strictNullHandling: true)),
        equals({'foo': null}),
      );

      expect(
        Uri.parse('$testUrl?a[0]=c').queryParametersQs(),
        equals({
          'a': ['c']
        }),
      );
      expect(
        Uri.parse('$testUrl?a[]=c').queryParametersQs(),
        equals({
          'a': ['c']
        }),
      );
      expect(
        Uri.parse('$testUrl?a[]=c')
            .queryParametersQs(const DecodeOptions(comma: true)),
        equals({
          'a': ['c']
        }),
      );

      expect(
        Uri.parse('$testUrl?a[0]=c&a[1]=d').queryParametersQs(),
        equals({
          'a': ['c', 'd']
        }),
      );
      expect(
        Uri.parse('$testUrl?a[]=c&a[]=d').queryParametersQs(),
        equals({
          'a': ['c', 'd']
        }),
      );
      expect(
        Uri.parse('$testUrl?a=c,d')
            .queryParametersQs(const DecodeOptions(comma: true)),
        equals({
          'a': ['c', 'd']
        }),
      );
    });

    test(
      'use number decoder, parses string that has one number with comma option enabled',
      () {
        dynamic decoder(String? str, {Encoding? charset}) =>
            num.tryParse(str ?? '') ?? Utils.decode(str, charset: charset);

        expect(
          Uri.parse('$testUrl?foo=1')
              .queryParametersQs(DecodeOptions(comma: true, decoder: decoder)),
          equals({'foo': 1}),
        );
        expect(
          Uri.parse('$testUrl?foo=0')
              .queryParametersQs(DecodeOptions(comma: true, decoder: decoder)),
          equals({'foo': 0}),
        );
      },
    );

    test(
        'parses brackets holds list of lists when having two parts of strings with comma as list divider',
        () {
      expect(
        Uri.parse('$testUrl?foo[]=1,2,3&foo[]=4,5,6')
            .queryParametersQs(const DecodeOptions(comma: true)),
        equals({
          'foo': [
            ['1', '2', '3'],
            ['4', '5', '6']
          ]
        }),
      );
      expect(
        Uri.parse('$testUrl?foo[]=1,2,3&foo[]=')
            .queryParametersQs(const DecodeOptions(comma: true)),
        equals({
          'foo': [
            ['1', '2', '3'],
            ''
          ]
        }),
      );
      expect(
        Uri.parse('$testUrl?foo[]=1,2,3&foo[]=')
            .queryParametersQs(const DecodeOptions(comma: true)),
        equals({
          'foo': [
            ['1', '2', '3'],
            ''
          ]
        }),
      );
      expect(
        Uri.parse('$testUrl?foo[]=1,2,3&foo[]=,')
            .queryParametersQs(const DecodeOptions(comma: true)),
        equals({
          'foo': [
            ['1', '2', '3'],
            ['', '']
          ]
        }),
      );
      expect(
        Uri.parse('$testUrl?foo[]=1,2,3&foo[]=a')
            .queryParametersQs(const DecodeOptions(comma: true)),
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
        Uri.parse('$testUrl?foo=a%2Cb')
            .queryParametersQs(const DecodeOptions(comma: true)),
        equals({'foo': 'a,b'}),
      );
      expect(
        Uri.parse('$testUrl?foo=a%2C%20b,d')
            .queryParametersQs(const DecodeOptions(comma: true)),
        equals({
          'foo': ['a, b', 'd']
        }),
      );
      expect(
        Uri.parse('$testUrl?foo=a%2C%20b,c%2C%20d')
            .queryParametersQs(const DecodeOptions(comma: true)),
        equals({
          'foo': ['a, b', 'c, d']
        }),
      );
    });

    test('params starting with a closing bracket', () {
      expect(Uri.parse('$testUrl?]=toString').queryParametersQs(),
          equals({']': 'toString'}));
      expect(Uri.parse('$testUrl?]]=toString').queryParametersQs(),
          equals({']]': 'toString'}));
      expect(Uri.parse('$testUrl?]hello]=toString').queryParametersQs(),
          equals({']hello]': 'toString'}));
    });

    test('params starting with a starting bracket', () {
      expect(Uri.parse('$testUrl?[=toString').queryParametersQs(),
          equals({'[': 'toString'}));
      expect(Uri.parse('$testUrl?[[=toString').queryParametersQs(),
          equals({'[[': 'toString'}));
      expect(Uri.parse('$testUrl?[hello[=toString').queryParametersQs(),
          equals({'[hello[': 'toString'}));
    });

    test('add keys to maps', () {
      expect(
        Uri.parse('$testUrl?a[b]=c').queryParametersQs(),
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
        Uri.parse('$testUrl?a[b]=c&a[hasOwnProperty]=d').queryParametersQs(),
        equals(expected),
      );

      final Map<String, dynamic> expectedList = {};
      expectedList['a'] = {};
      expectedList['a']['0'] = 'b';
      expectedList['a']['c'] = 'd';
      expect(
        Uri.parse('$testUrl?a[]=b&a[c]=d').queryParametersQs(),
        equals(expectedList),
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
        Uri.parse('$testUrl?%8c%a7=%91%e5%8d%e3%95%7b').queryParametersQs(
          DecodeOptions(decoder: decode),
        ),
        equals(expected),
      );
    });

    test('parses an iso-8859-1 string if asked to', () {
      final Map<String, dynamic> expected = {'¢': '½'};

      expect(
        Uri.parse('$testUrl?%A2=%BD')
            .queryParametersQs(const DecodeOptions(charset: latin1)),
        equals(expected),
      );
    });

    group('charset', () {
      test('throws an AssertionError when given an unknown charset', () {
        expect(
          () => Uri.parse('$testUrl?a=b')
              .queryParametersQs(DecodeOptions(charset: ShiftJIS())),
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
            Uri.parse(
                    '$testUrl?utf8=$urlEncodedCheckmarkInUtf8&$urlEncodedOSlashInUtf8=$urlEncodedOSlashInUtf8')
                .queryParametersQs(
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
            Uri.parse(
              '$testUrl?utf8=$urlEncodedNumCheckmark&$urlEncodedOSlashInUtf8=$urlEncodedOSlashInUtf8',
            ).queryParametersQs(
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
            Uri.parse(
              '$testUrl?a=$urlEncodedOSlashInUtf8&utf8=$urlEncodedNumCheckmark',
            ).queryParametersQs(
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
            Uri.parse(
              '$testUrl?utf8=foo&$urlEncodedOSlashInUtf8=$urlEncodedOSlashInUtf8',
            ).queryParametersQs(
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
            Uri.parse(
              '$testUrl?utf8=$urlEncodedCheckmarkInUtf8&$urlEncodedOSlashInUtf8=$urlEncodedOSlashInUtf8',
            ).queryParametersQs(
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
            Uri.parse(
              '$testUrl?utf8=$urlEncodedNumCheckmark&$urlEncodedOSlashInUtf8=$urlEncodedOSlashInUtf8',
            ).queryParametersQs(
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
            Uri.parse('$testUrl?foo=$urlEncodedNumSmiley').queryParametersQs(
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
            Uri.parse('$testUrl?foo=&bar=$urlEncodedNumSmiley')
                .queryParametersQs(
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
            Uri.parse('$testUrl?foo=$urlEncodedNumSmiley').queryParametersQs(
              const DecodeOptions(charset: latin1),
            ),
            equals({'foo': '&#9786;'}),
          );
        },
      );

      test(
        'does not interpret numeric entities when the charset is utf-8, even when `interpretNumericEntities`',
        () {
          expect(
            Uri.parse('$testUrl?foo=$urlEncodedNumSmiley').queryParametersQs(
              const DecodeOptions(
                charset: utf8,
                interpretNumericEntities: true,
              ),
            ),
            equals({'foo': '&#9786;'}),
          );
        },
      );

      test('does not interpret %uXXXX syntax in iso-8859-1 mode', () {
        expect(
          Uri.parse('$testUrl?%u263A=%u263A')
              .queryParametersQs(const DecodeOptions(charset: latin1)),
          equals({'%u263A': '%u263A'}),
        );
      });
    });
  });

  group('Uri.toStringQs', () {
    test('encodes a query string object', () {
      expect(
        Uri.https(authority, path, {'a': 'b'}).toStringQs(),
        equals('$testUrl?a=b'),
      );
      expect(
        Uri.https(authority, path, {'a': '1'}).toStringQs(),
        equals('$testUrl?a=1'),
      );
      expect(
        Uri.https(authority, path, {'a': '1', 'b': '2'}).toStringQs(),
        equals('$testUrl?a=1&b=2'),
      );
      expect(
        Uri.https(authority, path, {'a': 'A_Z'}).toStringQs(),
        equals('$testUrl?a=A_Z'),
      );
      expect(
        Uri.https(authority, path, {'a': '€'}).toStringQs(),
        equals('$testUrl?a=%E2%82%AC'),
      );
      expect(
        Uri.https(authority, path, {'a': ''}).toStringQs(),
        equals('$testUrl?a=%EE%80%80'),
      );
      expect(
        Uri.https(authority, path, {'a': 'א'}).toStringQs(),
        equals('$testUrl?a=%D7%90'),
      );
      expect(
        Uri.https(authority, path, {'a': '𐐷'}).toStringQs(),
        equals('$testUrl?a=%F0%90%90%B7'),
      );
      expect(
        Uri.https(authority, path, {'a': 'b', 'c': 'd'}).toStringQs(),
        equals('$testUrl?a=b&c=d'),
      );
      expect(
        Uri.https(authority, path, {'a': 'b', 'c': 'd', 'e': 'f'}).toStringQs(),
        equals('$testUrl?a=b&c=d&e=f'),
      );
      expect(
        Uri.https(authority, path, {'a': 'b', 'c': 'd', 'e': 'f', 'g': 'h'})
            .toStringQs(),
        equals('$testUrl?a=b&c=d&e=f&g=h'),
      );
      expect(
        Uri.https(authority, path, {
          'a': ['b', 'c', 'd'],
          'e': 'f'
        }).toStringQs(),
        equals('$testUrl?a=b&a=c&a=d&e=f'),
      );
    });
    test('empty map yields no query string', () {
      expect(
        Uri.https(authority, path, {}).toStringQs(),
        Uri.https(authority, path, {}).toString(),
      );
    });

    test('single key with empty string value', () {
      expect(Uri.https(authority, path, {'a': ''}).toStringQs(),
          equals('$testUrl?a='));
    });

    test('null value is not skipped', () {
      expect(Uri.https(authority, path, {'a': null, 'b': '2'}).toStringQs(),
          equals('$testUrl?a=&b=2'));
    });

    test('keys with special characters are encoded', () {
      expect(Uri.https(authority, path, {'a b': 'c d'}).toStringQs(),
          equals('$testUrl?a%20b=c%20d'));
      expect(Uri.https(authority, path, {'ä': 'ö'}).toStringQs(),
          equals('$testUrl?%C3%A4=%C3%B6'));
    });

    test('values containing reserved characters', () {
      expect(Uri.https(authority, path, {'q': 'foo@bar.com'}).toStringQs(),
          equals('$testUrl?q=foo%40bar.com'));
      expect(Uri.https(authority, path, {'path': '/home'}).toStringQs(),
          equals('$testUrl?path=%2Fhome'));
    });

    test('plus sign and space in value', () {
      expect(Uri.https(authority, path, {'v': 'a+b c'}).toStringQs(),
          equals('$testUrl?v=a%2Bb%20c'));
    });

    test('list values including numbers and empty strings', () {
      expect(
          Uri.https(authority, path, {
            'x': ['1', '', '3']
          }).toStringQs(),
          equals('$testUrl?x=1&x=&x=3'));
    });

    test('multiple keys maintain insertion order', () {
      expect(
          Uri.https(authority, path, {
            'first': '1',
            'second': '2',
            'third': '3',
          }).toStringQs(),
          equals('$testUrl?first=1&second=2&third=3'));
    });
  });
}
