// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:convert';
import 'dart:typed_data';

import 'package:euc/jis.dart';
import 'package:qs_dart/qs_dart.dart';
import 'package:test/test.dart';

/// This file doubles as executable documentation for `qs_dart`.
/// Each example pairs an input with the expected output to show how decoding,
/// encoding, and option flags behave. Feel free to copy snippets into your app.
void main() {
  test('Simple examples', () {
    expect(QS.decode('a=c'), equals({'a': 'c'}));

    expect(QS.encode({'a': 'c'}), equals('a=c'));
  });

  group('Decoding', () {
    test('Maps', () {
      /// [QS] allows you to create nested [Map]s within your query strings,
      /// by surrounding the name of sub-keys with square brackets `[]`. For example,
      /// the string `'foo[bar]=baz'` converts to
      expect(
        QS.decode('foo[bar]=baz'),
        equals({
          'foo': {'bar': 'baz'},
        }),
      );

      /// URI encoded strings work too:
      expect(
        QS.decode('a%5Bb%5D=c'),
        equals({
          'a': {'b': 'c'},
        }),
      );

      /// You can also nest your [Map]s, like 'foo[bar][baz]=foobarbaz':
      expect(
        QS.decode('foo[bar][baz]=foobarbaz'),
        equals({
          'foo': {
            'bar': {'baz': 'foobarbaz'},
          },
        }),
      );

      /// By default, nested [Map]s are decoded up to 5 levels deep.
      /// For example, decoding `'a[b][c][d][e][f][g][h][i]=j'` yields:
      expect(
        QS.decode('a[b][c][d][e][f][g][h][i]=j'),
        equals({
          'a': {
            'b': {
              'c': {
                'd': {
                  'e': {
                    'f': {'[g][h][i]': 'j'},
                  },
                },
              },
            },
          },
        }),
      );

      /// Override the limit with [DecodeOptions.depth]. Keeping this small helps guard
      /// against maliciously deep inputs when parsing untrusted data:
      expect(
        QS.decode('a[b][c][d][e][f][g][h][i]=j', const DecodeOptions(depth: 1)),
        equals({
          'a': {
            'b': {'[c][d][e][f][g][h][i]': 'j'},
          },
        }),
      );

      /// QS parses at most 1000 parameters by default. Override via
      /// [DecodeOptions.parameterLimit]:
      expect(
        QS.decode('a=b&c=d', const DecodeOptions(parameterLimit: 1)),
        equals({'a': 'b'}),
      );

      /// To bypass the leading question mark, use [DecodeOptions.ignoreQueryPrefix]:
      expect(
        QS.decode('?a=b&c=d', const DecodeOptions(ignoreQueryPrefix: true)),
        equals({'a': 'b', 'c': 'd'}),
      );

      /// You can provide a custom [DecodeOptions.delimiter]:
      expect(
        QS.decode('a=b;c=d', const DecodeOptions(delimiter: ';')),
        equals({'a': 'b', 'c': 'd'}),
      );

      /// [DecodeOptions.delimiter] can be a regular expression too:
      expect(
        QS.decode('a=b;c=d', DecodeOptions(delimiter: RegExp(r'[;,]'))),
        equals({'a': 'b', 'c': 'd'}),
      );

      /// Enable dot notation with [DecodeOptions.allowDots]:
      expect(
        QS.decode('a.b=c', const DecodeOptions(allowDots: true)),
        equals({
          'a': {'b': 'c'},
        }),
      );

      /// Decode percent-encoded dots in *keys* with [DecodeOptions.decodeDotInKeys].
      ///
      /// Note: this implies [DecodeOptions.allowDots]. `decode` will throw if
      /// `decodeDotInKeys` is `true` while `allowDots` is `false`.
      expect(
        QS.decode(
          'name%252Eobj.first=John&name%252Eobj.last=Doe',
          const DecodeOptions(decodeDotInKeys: true),
        ),
        equals({
          'name.obj': {'first': 'John', 'last': 'Doe'},
        }),
      );

      /// Allow empty list values in a [Map] with [DecodeOptions.allowEmptyLists].
      expect(
        QS.decode('foo[]&bar=baz', const DecodeOptions(allowEmptyLists: true)),
        equals({'foo': [], 'bar': 'baz'}),
      );

      /// Option [DecodeOptions.duplicates] can be used to change the behavior when
      /// duplicate keys are encountered
      expect(
        QS.decode('foo=bar&foo=baz'),
        equals({
          'foo': ['bar', 'baz'],
        }),
      );
      expect(
        QS.decode(
          'foo=bar&foo=baz',
          const DecodeOptions(duplicates: Duplicates.combine),
        ),
        equals({
          'foo': ['bar', 'baz'],
        }),
      );
      expect(
        QS.decode(
          'foo=bar&foo=baz',
          const DecodeOptions(duplicates: Duplicates.first),
        ),
        equals({'foo': 'bar'}),
      );
      expect(
        QS.decode(
          'foo=bar&foo=baz',
          const DecodeOptions(duplicates: Duplicates.last),
        ),
        equals({'foo': 'baz'}),
      );

      /// If you have to deal with legacy browsers or services, there's also support
      /// for decoding percent-encoded octets as latin1 (iso-8859-1):
      expect(
        QS.decode('a=%A7', const DecodeOptions(charset: latin1)),
        equals({'a': '§'}),
      );

      /// Some services add an initial `utf8=%E2%9C%93` (a checkmark - `✓`) parameter so legacy Internet Explorer versions
      /// are more likely to submit the form as UTF-8. Servers can also check the value against mis-encodings to detect
      /// when a query string or `application/x-www-form-urlencoded` body was *not* sent as UTF-8 (e.g. when the form
      /// `accept-charset` parameter or the containing page had a different character set.
      ///
      /// [QS] supports this mechanism via the [DecodeOptions.charsetSentinel] option.
      /// If specified, the [utf8] parameter will be omitted from the returned [Map].
      /// It will be used to switch to [latin1]/[utf8] mode depending on how the checkmark is encoded.
      ///
      /// Important: When you specify both the [DecodeOptions.charset] option and the [DecodeOptions.charsetSentinel] option,
      /// the [DecodeOptions.charset] will be overridden when the request contains a [utf8] parameter from which the actual charset
      /// can be deduced. In that sense the [DecodeOptions.charset] will behave as the default charset rather than the authoritative
      /// charset.
      expect(
        QS.decode(
          'utf8=%E2%9C%93&a=%C3%B8',
          const DecodeOptions(charset: latin1, charsetSentinel: true),
        ),
        equals({'a': 'ø'}),
      );
      expect(
        QS.decode(
          'utf8=%26%2310003%3B&a=%F8',
          const DecodeOptions(charset: utf8, charsetSentinel: true),
        ),
        equals({'a': 'ø'}),
      );

      /// If you want to decode the `&#...;` syntax to the actual character, you can specify
      /// the [DecodeOptions.interpretNumericEntities] option as well:
      ///
      /// It also works when the charset has been detected in [DecodeOptions.charsetSentinel] mode.
      expect(
        QS.decode(
          'a=%26%239786%3B',
          const DecodeOptions(charset: latin1, interpretNumericEntities: true),
        ),
        equals({'a': '☺'}),
      );
    });

    test('Lists', () {
      /// [QS] can also parse lists using a similar `[]` notation:
      expect(
        QS.decode('a[]=b&a[]=c'),
        equals({
          'a': ['b', 'c'],
        }),
      );

      /// You may specify an index as well:
      expect(
        QS.decode('a[1]=c&a[0]=b'),
        equals({
          'a': ['b', 'c'],
        }),
      );

      /// Note that the only difference between an index in a [List] and a key in a [Map] is that the value between the brackets
      /// must be a number to create a [List]. When creating [List]s with specific indices, QS will compact a sparse
      /// [List] to only the existing values preserving their order:
      expect(
        QS.decode('a[1]=b&a[15]=c'),
        equals({
          'a': ['b', 'c'],
        }),
      );

      /// Note that an empty string is also a value, and will be preserved:
      expect(
        QS.decode('a[]=&a[]=b'),
        equals({
          'a': ['', 'b'],
        }),
      );
      expect(
        QS.decode('a[0]=b&a[1]=&a[2]=c'),
        equals({
          'a': ['b', '', 'c'],
        }),
      );

      /// QS will also limit specifying indices in a [List] to a maximum index of `20`.
      /// Any [List] members with an index of greater than `20` will instead be converted to a [Map] with the index as the key.
      /// This is needed to handle cases when someone sent, for example, `a[999999999]` and it will take significant time to iterate
      /// over this huge [List].
      expect(
        QS.decode('a[100]=b'),
        equals({
          'a': {'100': 'b'},
        }),
      );

      /// Override this limit via the [DecodeOptions.listLimit] option:
      expect(
        QS.decode('a[1]=b', const DecodeOptions(listLimit: 0)),
        equals({
          'a': {'1': 'b'},
        }),
      );

      /// To disable [List] parsing entirely, set [DecodeOptions.parseLists] to `false`.
      expect(
        QS.decode('a[]=b', const DecodeOptions(parseLists: false)),
        equals({
          'a': {'0': 'b'},
        }),
      );

      /// If you mix notations, QS will merge the two items into a [Map]:
      expect(
        QS.decode('a[0]=b&a[b]=c'),
        equals({
          'a': {'0': 'b', 'b': 'c'},
        }),
      );

      /// You can also create [List]s of [Map]s:
      expect(
        QS.decode('a[][b]=c'),
        equals({
          'a': [
            {'b': 'c'},
          ],
        }),
      );

      /// Some systems join list items with commas; QS can parse that.
      /// (Nested maps like `'a={b:1},{c:d}'` are not supported here.)
      expect(
        QS.decode('a=b,c', const DecodeOptions(comma: true)),
        equals({
          'a': ['b', 'c'],
        }),
      );
    });

    test('Primitive/Scalar values', () {
      /// By default, all values are parsed as [String]s.
      expect(
        QS.decode('a=15&b=true&c=null'),
        equals({'a': '15', 'b': 'true', 'c': 'null'}),
      );
    });
  });

  test('Encoding', () {
    /// When encoding, QS by default URI encodes output.
    /// [Map]s are stringified as you would expect:
    expect(QS.encode({'a': 'b'}), equals('a=b'));
    expect(
      QS.encode({
        'a': {'b': 'c'},
      }),
      equals('a%5Bb%5D=c'),
    );

    /// This encoding can be disabled by setting the [EncodeOptions.encode] option to `false`:
    expect(
      QS.encode({
        'a': {'b': 'c'},
      }, const EncodeOptions(encode: false)),
      equals('a[b]=c'),
    );

    /// Encoding can be disabled for keys by setting the [EncodeOptions.encodeValuesOnly] option to `true`:
    expect(
      QS.encode({
        'a': 'b',
        'c': ['d', 'e=f'],
        'f': [
          ['g'],
          ['h'],
        ],
      }, const EncodeOptions(encodeValuesOnly: true)),
      equals('a=b&c[0]=d&c[1]=e%3Df&f[0][0]=g&f[1][0]=h'),
    );

    /// Provide a custom [Encoder] via [EncodeOptions.encoder] to control how tokens are percent-encoded.
    ///
    /// (Note: the custom encoder is ignored when [EncodeOptions.encode] is `false`.)
    expect(
      QS.encode(
        {
          'a': {'b': 'č'},
        },
        EncodeOptions(
          encoder: (str, {Encoding? charset, Format? format}) => switch (str) {
            'č' => 'c',
            _ => str,
          },
        ),
      ),
      equals('a[b]=c'),
    );

    /// When [List]s are encoded, they follow the [EncodeOptions.listFormat]
    /// option, which defaults to [ListFormat.indices]:
    expect(
      QS.encode({
        'a': ['b', 'c', 'd'],
      }, const EncodeOptions(encode: false)),
      equals('a[0]=b&a[1]=c&a[2]=d'),
    );

    /// You may override this by setting the [EncodeOptions.indices] option to
    /// `false`, or to be more explicit, the [EncodeOptions.listFormat] option
    /// to [ListFormat.repeat]
    expect(
      QS.encode({
        'a': ['b', 'c', 'd'],
      }, const EncodeOptions(encode: false, indices: false)),
      equals('a=b&a=c&a=d'),
    );

    /// You may use the [EncodeOptions.listFormat] option to specify the
    /// format of the output [List]:
    expect(
      QS.encode({
        'a': ['b', 'c'],
      }, const EncodeOptions(encode: false, listFormat: ListFormat.indices)),
      equals('a[0]=b&a[1]=c'),
    );
    expect(
      QS.encode({
        'a': ['b', 'c'],
      }, const EncodeOptions(encode: false, listFormat: ListFormat.brackets)),
      equals('a[]=b&a[]=c'),
    );
    expect(
      QS.encode({
        'a': ['b', 'c'],
      }, const EncodeOptions(encode: false, listFormat: ListFormat.repeat)),
      equals('a=b&a=c'),
    );
    expect(
      QS.encode({
        'a': ['b', 'c'],
      }, const EncodeOptions(encode: false, listFormat: ListFormat.comma)),
      equals('a=b,c'),
    );

    /// When [Map]s are encoded, by default they use bracket notation:
    expect(
      QS.encode({
        'a': {
          'b': {'c': 'd', 'e': 'f'},
        },
      }, const EncodeOptions(encode: false)),
      equals('a[b][c]=d&a[b][e]=f'),
    );

    /// You may override this to use dot notation by setting the
    /// [EncodeOptions.allowDots] option to `true`:
    expect(
      QS.encode({
        'a': {
          'b': {'c': 'd', 'e': 'f'},
        },
      }, const EncodeOptions(encode: false, allowDots: true)),
      equals('a.b.c=d&a.b.e=f'),
    );

    /// Encode literal dots in keys by setting [EncodeOptions.encodeDotInKeys] to `true` (use with [EncodeOptions.allowDots]).
    ///
    /// Caveat: when [EncodeOptions.encodeValuesOnly] is `true`, only dots in keys are encoded—values are left as-is.
    expect(
      QS.encode({
        'name.obj': {'first': 'John', 'last': 'Doe'},
      }, const EncodeOptions(allowDots: true, encodeDotInKeys: true)),
      equals('name%252Eobj.first=John&name%252Eobj.last=Doe'),
    );

    /// You may allow empty [List] values by setting the [EncodeOptions.allowEmptyLists]
    /// option to `true`:
    expect(
      QS.encode({
        'foo': [],
        'bar': 'baz',
      }, const EncodeOptions(encode: false, allowEmptyLists: true)),
      equals('foo[]&bar=baz'),
    );

    /// Empty strings and null values will omit the value, but the equals
    /// sign (`=`) remains in place:
    expect(QS.encode({'a': ''}), equals('a='));

    /// Keys with no values (e.g., empty [Map]s or [List]s) produce no output:    expect(QS.encode({'a': []}), equals(''));
    expect(QS.encode({'a': {}}), equals(''));
    expect(
      QS.encode({
        'a': [{}],
      }),
      equals(''),
    );
    expect(
      QS.encode({
        'a': {'b': []},
      }),
      equals(''),
    );
    expect(
      QS.encode({
        'a': {'b': {}},
      }),
      equals(''),
    );

    /// Properties that are `Undefined` will be omitted entirely:
    expect(QS.encode({'a': null, 'b': const Undefined()}), equals('a='));

    /// The query string may optionally be prepended with a question mark:
    expect(
      QS.encode({
        'a': 'b',
        'c': 'd',
      }, const EncodeOptions(addQueryPrefix: true)),
      equals('?a=b&c=d'),
    );

    /// The delimiter may be overridden as well:
    expect(
      QS.encode({'a': 'b', 'c': 'd'}, const EncodeOptions(delimiter: ';')),
      equals('a=b;c=d'),
    );

    /// If you only want to override the serialization of [DateTime] objects, you can provide a custom [DateSerializer] in the
    /// [EncodeOptions.serializeDate] option:
    expect(
      QS.encode({
        'a': DateTime.fromMillisecondsSinceEpoch(7).toUtc(),
      }, const EncodeOptions(encode: false)),
      equals('a=1970-01-01T00:00:00.007Z'),
    );
    expect(
      QS.encode(
        {'a': DateTime.fromMillisecondsSinceEpoch(7).toUtc()},
        EncodeOptions(
          encode: false,
          serializeDate: (DateTime date) =>
              date.millisecondsSinceEpoch.toString(),
        ),
      ),
      equals('a=7'),
    );

    /// Control parameter sort order with [EncodeOptions.sort]:
    expect(
      QS.encode({
        'a': 'c',
        'z': 'y',
        'b': 'f',
      }, EncodeOptions(encode: false, sort: (a, b) => a.compareTo(b))),
      equals('a=c&b=f&z=y'),
    );

    /// Finally, you can use the [EncodeOptions.filter] option to restrict which keys will be included in the encoded output.
    /// If you pass a [Function], it will be called for each key to obtain the replacement value.
    /// Otherwise, if you pass a [List], it will be used to select properties and [List] indices to be encoded:
    expect(
      QS.encode(
        {
          'a': 'b',
          'c': 'd',
          'e': {
            'f': DateTime.fromMillisecondsSinceEpoch(123),
            'g': [2],
          },
        },
        EncodeOptions(
          encode: false,
          filter: (prefix, value) => switch (prefix) {
            'b' => const Undefined(),
            'e[f]' => (value as DateTime).millisecondsSinceEpoch,
            'e[g][0]' => (value as num) * 2,
            _ => value,
          },
        ),
      ),
      equals('a=b&c=d&e[f]=123&e[g][0]=4'),
    );
    expect(
      QS.encode({
        'a': 'b',
        'c': 'd',
        'e': 'f',
      }, const EncodeOptions(encode: false, filter: ['a', 'e'])),
      equals('a=b&e=f'),
    );
    expect(
      QS.encode({
        'a': ['b', 'c', 'd'],
        'e': 'f',
      }, const EncodeOptions(encode: false, filter: ['a', 0, 2])),
      equals('a[0]=b&a[2]=d'),
    );
  });

  test('null values', () {
    /// By default, `null` values are treated like empty strings
    expect(QS.encode({'a': null, 'b': ''}), equals('a=&b='));

    /// Decoding does not distinguish between parameters with and without equal signs.
    /// Both are converted to empty strings.
    expect(QS.decode('a&b='), equals({'a': '', 'b': ''}));

    /// To distinguish between `null` values and empty [String]s use the [EncodeOptions.strictNullHandling] flag.
    /// In the result string the `null` values have no `=` sign:
    expect(
      QS.encode({
        'a': null,
        'b': '',
      }, const EncodeOptions(strictNullHandling: true)),
      equals('a&b='),
    );

    /// To decode values without `=` back to `null` use the [DecodeOptions.strictNullHandling] flag:
    expect(
      QS.decode('a&b=', const DecodeOptions(strictNullHandling: true)),
      equals({'a': null, 'b': ''}),
    );

    /// To completely skip rendering keys with `null` values, use the [EncodeOptions.skipNulls] flag:
    expect(
      QS.encode({'a': 'b', 'c': null}, const EncodeOptions(skipNulls: true)),
      equals('a=b'),
    );
  });

  test('Charset', () {
    /// If you're communicating with legacy systems, you can switch to [latin1]
    /// using the `EncodeOptions.charset` option:
    expect(
      QS.encode({'æ': 'æ'}, const EncodeOptions(charset: latin1)),
      equals('%E6=%E6'),
    );

    /// Characters that don't exist in `latin1` will be converted to numeric
    /// entities, similar to what browsers do:
    expect(
      QS.encode({'a': '☺'}, const EncodeOptions(charset: latin1)),
      equals('a=%26%239786%3B'),
    );

    /// Announce the character set with [EncodeOptions.charsetSentinel] by including an `utf8=%E2%9C%93` parameter (a checkmark),
    /// similar to what Rails and others do when submitting forms.
    expect(
      QS.encode({'a': '☺'}, const EncodeOptions(charsetSentinel: true)),
      equals('utf8=%E2%9C%93&a=%E2%98%BA'),
    );
    expect(
      QS.encode({
        'a': 'æ',
      }, const EncodeOptions(charset: latin1, charsetSentinel: true)),
      equals('utf8=%26%2310003%3B&a=%E6'),
    );

    /// If you wish to encode query strings to a different character set (i.e.
    /// [Shift JIS](https://en.wikipedia.org/wiki/Shift_JIS)) you can use the
    /// [euc](https://pub.dev/packages/euc) package
    expect(
      QS.encode(
        {'a': 'こんにちは！'},
        EncodeOptions(
          encoder: (str, {Encoding? charset, Format? format}) {
            if ((str as String?)?.isNotEmpty ?? false) {
              final Uint8List buf = Uint8List.fromList(ShiftJIS().encode(str!));
              final List<String> result = [
                for (int i = 0; i < buf.length; ++i) buf[i].toRadixString(16),
              ];
              return '%${result.join('%')}';
            }
            return '';
          },
        ),
      ),
      equals('%61=%82%b1%82%f1%82%c9%82%bf%82%cd%81%49'),
    );

    /// This also works for decoding of query strings:
    expect(
      QS.decode(
        '%61=%82%b1%82%f1%82%c9%82%bf%82%cd%81%49',
        DecodeOptions(
          decoder: (str, {Encoding? charset}) {
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
            return ShiftJIS().decode(Uint8List.fromList(result));
          },
        ),
      ),
      equals({'a': 'こんにちは！'}),
    );
  });

  test('RFC 3986 and RFC 1738 space encoding', () {
    /// The default [EncodeOptions.format] is [Format.rfc3986] which encodes `' '` to `%20` which is backward compatible.
    /// You can also set the [EncodeOptions.format] to [Format.rfc1738] which encodes `' '` to `+`.
    expect(QS.encode({'a': 'b c'}), equals('a=b%20c'));

    expect(
      QS.encode({'a': 'b c'}, const EncodeOptions(format: Format.rfc3986)),
      equals('a=b%20c'),
    );

    expect(
      QS.encode({'a': 'b c'}, const EncodeOptions(format: Format.rfc1738)),
      equals('a=b+c'),
    );
  });
}
