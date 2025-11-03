# qs_dart

<p align="center">
    <img src="https://github.com/techouse/qs/raw/main/logo.png?raw=true?raw=true" width="256" alt="qs_dart" />
</p>

A query string encoding and decoding library for Dart.

Ported from [qs](https://www.npmjs.com/package/qs) for JavaScript.

[![Pub Version](https://img.shields.io/pub/v/qs_dart)](https://pub.dev/packages/qs_dart)
[![Pub Publisher](https://img.shields.io/pub/publisher/qs_dart)](https://pub.dev/publishers/tusar.dev/packages)
[![Pub Likes](https://img.shields.io/pub/likes/qs_dart)](https://pub.dev/packages/qs_dart/score)
[![Pub Points](https://img.shields.io/pub/points/qs_dart)](https://pub.dev/packages/qs_dart/score)
[![Pub Monthly Downloads](https://img.shields.io/pub/dm/qs_dart)](https://pub.dev/packages/qs_dart/score)
[![PubStats Popularity](https://pubstats.dev/badges/packages/qs_dart/popularity.svg)](https://pubstats.dev/packages/qs_dart)
[![PubStats Rank](https://pubstats.dev/badges/packages/qs_dart/rank.svg)](https://pubstats.dev/packages/qs_dart)
[![PubStats Dependents](https://pubstats.dev/badges/packages/qs_dart/dependents.svg)](https://pubstats.dev/packages/qs_dart)
[![Test](https://github.com/techouse/qs/actions/workflows/test.yml/badge.svg)](https://github.com/techouse/qs/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/techouse/qs/graph/badge.svg?token=e8KkRgZzPf)](https://codecov.io/gh/techouse/qs)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/3630ce1150f840e08c94f40754d24688)](https://app.codacy.com/gh/techouse/qs/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
[![GitHub](https://img.shields.io/github/license/techouse/qs)](LICENSE)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/techouse)](https://github.com/sponsors/techouse)
[![GitHub Repo stars](https://img.shields.io/github/stars/techouse/qs)](https://github.com/techouse/qs/stargazers)

## Highlights

- **Nested maps & lists**: `a[b][c]=d` ⇄ `{ 'a': { 'b': { 'c': 'd' } } }`; arrays via `a[]=b&a[]=c` or `a[0]=b&a[1]=c`.
- **Multiple list formats**: `indices` (`a[0]=x`), `brackets` (`a[]=x`), `repeat` (`a=x&a=y`), `comma` (`a=x,y`) with optional comma round‑trip.
- **Dot notation**: parse/encode `a.b=c` as nested; options to encode or decode literal dots in keys (`encodeDotInKeys` / `decodeDotInKeys`).
- **Charset & sentinel**: UTF‑8 (default) and Latin‑1; `charsetSentinel` (`utf8=✓`) to auto‑detect encoding.
- **Hooks & controls**: custom `encoder`/`decoder`, encode keys‑only or values‑only, alternate delimiters (string or `RegExp`), ignore leading `?`.
- **Duplicates & empties**: strategies for duplicates (`combine`/`first`/`last`); allow empty list items (`foo[]`) with `allowEmptyLists`.
- **Null handling**: `strictNullHandling`, `skipNulls`, and clear empty‑string behavior.
- **Safety limits**: configurable `depth`, `strictDepth`, `parameterLimit`, `listLimit`, and `parseLists` toggle.
- **Dates & ordering**: pluggable `serializeDate`, stable key ordering with `sort`, selective output via `filter`.
- **RFC modes**: spaces as `%20` (RFC 3986, default) or `+` (RFC 1738).
- **Dart‑friendly**: `Uri.queryParametersQs()` and `Uri.toStringQs()` extensions for idiomatic usage in Dart/Flutter.

## Installation

Add the package to your project:

### For Dart projects:
```sh
dart pub add qs_dart
```

### For Flutter projects:
```sh
flutter pub add qs_dart
```

## Usage

A simple usage example:

```dart
import 'package:qs_dart/qs_dart.dart';
import 'package:test/test.dart';

void main() {
  test('Simple example', () {
    expect(
      QS.decode('a=c'),
      equals({'a': 'c'}),
    );

    expect(
      QS.encode({'a': 'c'}),
      equals('a=c'),
    );
  });
  
  test('Uri Extension usage', () {
    expect(
      Uri.parse('https://test.local/example?a[b][c]=d').queryParametersQs(),
      equals({
        'a': {
          'b': {'c': 'd'}
        }
      }),
    );
    
    expect(
      Uri.https('test.local', '/example', {'a': '1', 'b': '2'}).toStringQs(), 
      equals('https://test.local/example?a=1&b=2'),
    );
  });
}
```

### Decoding Maps

```dart
Map<String, dynamic> decode(
  dynamic str, [
  DecodeOptions options = const DecodeOptions(),
]);
```

[decode] allows you to create nested [Map]s within your query strings, by surrounding the name of sub-keys with 
square brackets `[]`. For example, the string `'foo[bar]=baz'` converts to:

```dart
expect(
  QS.decode('foo[bar]=baz'),
  equals({'foo': {'bar': 'baz'}}),
);
```

URI encoded strings work too:

```dart
expect(
  QS.decode('a%5Bb%5D=c'),
  equals({'a': {'b': 'c'}}),
);
```

You can also nest your [Map]s, like `'foo[bar][baz]=foobarbaz'`:

```dart
expect(
  QS.decode('foo[bar][baz]=foobarbaz'),
  equals({'foo': {'bar': {'baz': 'foobarbaz'}}}),
);
```

By default, nested [Map]s are decoded up to 5 levels deep. For example, decoding
a string like `'a[b][c][d][e][f][g][h][i]=j'` yields the following [Map]:

```dart
expect(
  QS.decode('a[b][c][d][e][f][g][h][i]=j'),
  equals({
    'a': {
      'b': {
        'c': {
          'd': {
            'e': {
              'f': {
                '[g][h][i]': 'j'
              }
            }
          }
        }
      }
    }
  }),
);
```

You can override this limit with [DecodeOptions.depth]:

```dart
expect(
  QS.decode(
    'a[b][c][d][e][f][g][h][i]=j',
    const DecodeOptions(depth: 1),
  ),
  equals({
    'a': {
      'b': {'[c][d][e][f][g][h][i]': 'j'},
    },
  }),
);
```

You can configure [decode] to throw an error when parsing nested input beyond this depth using
[DecodeOptions.strictDepth] (defaults to false):

```dart
expect(
  () => QS.decode(
    'a[b][c][d][e][f][g][h][i]=j',
    const DecodeOptions(
      depth: 1,
      strictDepth: true,
    ),
  ),
  throwsA(isA<RangeError>()),
);
```

The depth limit helps mitigate abuse when [decode] is used to parse user input, and it is recommended to keep it a
reasonably small number. [DecodeOptions.strictDepth] adds a layer of protection by throwing a [RangeError] when the
limit is exceeded, allowing you to catch and handle such cases.

For similar reasons, by default [decode] parses up to **1000** parameters. Override with
[DecodeOptions.parameterLimit]:

```dart
expect(
  QS.decode(
    'a=b&c=d',
    const DecodeOptions(parameterLimit: 1),
  ),
  equals({'a': 'b'}),
);
```

To bypass the leading question mark, use [DecodeOptions.ignoreQueryPrefix]:

```dart
expect(
  QS.decode(
    '?a=b&c=d',
    const DecodeOptions(ignoreQueryPrefix: true),
  ),
  equals(
    {'a': 'b', 'c': 'd'},
  ),
);
```

You can provide a custom [DecodeOptions.delimiter]:

```dart
expect(
  QS.decode(
    'a=b;c=d',
    const DecodeOptions(delimiter: ';'),
  ),
  equals({'a': 'b', 'c': 'd'}),
);
```

[DecodeOptions.delimiter] can be a [RegExp] too:

```dart
expect(
  QS.decode(
    'a=b;c=d',
    DecodeOptions(delimiter: RegExp(r'[;,]')),
  ),
  equals({'a': 'b', 'c': 'd'}),
);
```

Enable dot notation with [DecodeOptions.allowDots]:

```dart
expect(
  QS.decode(
    'a.b=c',
    const DecodeOptions(allowDots: true),
  ),
  equals({'a': {'b': 'c'}}),
);
```

Decode percent-encoded dots in keys with [DecodeOptions.decodeDotInKeys].

**Note:** it implies [DecodeOptions.allowDots], so [decode] will error if you set [DecodeOptions.decodeDotInKeys] 
to `true`, and `DecodeOptions.allowDots` to `false`.

```dart
expect(
  QS.decode(
    'name%252Eobj.first=John&name%252Eobj.last=Doe',
    const DecodeOptions(decodeDotInKeys: true),
  ),
  equals({
    'name.obj': {'first': 'John', 'last': 'Doe'}
  }),
);
```

Allow empty [List] values within a [Map] with [DecodeOptions.allowEmptyLists].

```dart
expect(
  QS.decode(
    'foo[]&bar=baz',
    const DecodeOptions(allowEmptyLists: true),
  ),
  equals({
    'foo': [],
    'bar': 'baz',
  }),
);
```

Option [DecodeOptions.duplicates] can be used to change the behavior when duplicate keys are encountered.

```dart
expect(
  QS.decode('foo=bar&foo=baz'),
  equals({
    'foo': ['bar', 'baz']
  }),
);

expect(
  QS.decode(
    'foo=bar&foo=baz',
    const DecodeOptions(duplicates: Duplicates.combine),
  ),
  equals({
    'foo': ['bar', 'baz']
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
```

If you have to deal with legacy browsers or services, there's also support for decoding percent-encoded octets as
[latin1]:

```dart
expect(
  QS.decode(
    'a=%A7',
    const DecodeOptions(charset: latin1),
  ),
  equals({'a': '§'}),
);
```

Some services add an initial `utf8=✓` value to forms so that old Internet Explorer versions are more likely to submit the
form as utf-8. Additionally, the server can check the value against wrong encodings of the checkmark character and detect 
that a query string or `application/x-www-form-urlencoded` body was *not* sent as utf-8, eg. if the form had an 
`accept-charset` parameter or the containing page had a different character set.

**QS** supports this mechanism via the [DecodeOptions.charsetSentinel] option.
If specified, the `utf8` parameter will be omitted from the returned [Map].
It will be used to switch to [latin1] or [utf8] mode depending on how the checkmark is encoded.

**Important**: When you specify both the [DecodeOptions.charset] option and the [DecodeOptions.charsetSentinel] option, 
the [DecodeOptions.charset] will be overridden when the request contains a `utf8` parameter from which the actual charset 
can be deduced. In that sense the [DecodeOptions.charset] will behave as the default charset rather than the authoritative 
charset.

```dart
expect(
  QS.decode(
    'utf8=%E2%9C%93&a=%C3%B8',
    const DecodeOptions(
      charset: latin1,
      charsetSentinel: true,
    ),
  ),
  equals({'a': 'ø'}),
);

expect(
  QS.decode(
    'utf8=%26%2310003%3B&a=%F8',
    const DecodeOptions(
      charset: utf8,
      charsetSentinel: true,
    ),
  ),
  equals({'a': 'ø'}),
);
```

If you want to decode the [`&#...;`](https://www.w3schools.com/html/html_entities.asp) syntax to the actual character,
you can specify the [DecodeOptions.interpretNumericEntities] option as well:

```dart
expect(
  QS.decode(
    'a=%26%239786%3B',
    const DecodeOptions(
      charset: latin1,
      interpretNumericEntities: true,
    ),
  ),
  equals({'a': '☺'}),
);
```

It also works when the charset has been detected in [DecodeOptions.charsetSentinel] mode.

### Decoding Lists

[decode] can also decode [List]s using a similar `[]` notation:

```dart
expect(
  QS.decode('a[]=b&a[]=c'),
  equals({
    'a': ['b', 'c']
  }),
);
```

You may specify an index as well:

```dart
expect(
  QS.decode('a[1]=c&a[0]=b'),
  equals({
    'a': ['b', 'c']
  }),
);
```

Note that the only difference between an index in a [List] and a key in a [Map] is that the value between the brackets
must be a number to create a [List]. When creating [List]s with specific indices, [decode] will compact a sparse 
[List] to only the existing values preserving their order:

```dart
expect(
  QS.decode('a[1]=b&a[15]=c'),
  equals({
    'a': ['b', 'c']
  }),
);
```

Note that an empty string is also a value, and will be preserved:

```dart
expect(
  QS.decode('a[]=&a[]=b'),
  equals({
    'a': ['', 'b']
  }),
);
expect(
  QS.decode('a[0]=b&a[1]=&a[2]=c'),
  equals({
    'a': ['b', '', 'c']
  }),
);
```

[decode] will also limit specifying indices in a [List] to a maximum index of **20**.
Any [List] members with an index of greater than **20** will instead be converted to a [Map] with the index as the key.
This is needed to handle cases when someone sent, for example, `a[999999999]` and it will take significant time to iterate 
over this huge [List].

```dart
expect(
  QS.decode('a[100]=b'),
  equals({
    'a': {'100': 'b'}
  }),
);
```

This limit can be overridden by passing an [DecodeOptions.listLimit] option:

```dart
expect(
  QS.decode(
    'a[1]=b',
    const DecodeOptions(listLimit: 0),
  ),
  equals({
    'a': {'1': 'b'}
  }),
);
```

To disable List parsing entirely, set [DecodeOptions.parseLists] to `false`.

```dart
expect(
  QS.decode(
    'a[]=b',
    const DecodeOptions(parseLists: false),
  ),
  equals({
    'a': {'0': 'b'}
  }),
);
```

If you mix notations, [decode] will merge the two items into a [Map]:

```dart
expect(
  QS.decode('a[0]=b&a[b]=c'),
  equals({
    'a': {'0': 'b', 'b': 'c'}
  }),
);
```

You can also create [List]s of [Map]s:

```dart
expect(
  QS.decode('a[][b]=c'),
  equals({
    'a': [
      {'b': 'c'}
    ]
  }),
);
```

Some systems join list items with commas; [decode] can parse this when [DecodeOptions.comma] is set to `true`:

```dart
expect(
  QS.decode(
    'a=b,c',
    const DecodeOptions(comma: true),
  ),
  equals({
    'a': ['b', 'c']
  }),
);
```

(_[decode] cannot convert nested [Map]s, such as `'a={b:1},{c:d}'`_)

### Decoding primitive/scalar values (`num`, `bool`, `null`, etc.)

By default, all values are parsed as [String]s.

```dart
expect(
  QS.decode('a=15&b=true&c=null'),
  equals({
    'a': '15',
    'b': 'true',
    'c': 'null',
  }),
);
```

### Encoding

```dart
String encode(
  Object? object, [
  EncodeOptions options = const EncodeOptions(),
]);
```

[encode] will by default URI encode the output. [Map]s are stringified as you would expect:

```dart
expect(
  QS.encode({'a': 'b'}),
  equals('a=b'),
);
expect(
  QS.encode({'a': {'b': 'c'}}),
  equals('a%5Bb%5D=c'),
);
```

This encoding can be disabled by setting the [EncodeOptions.encode] option to `false`:

```dart
expect(
  QS.encode(
    {
      'a': {'b': 'c'}
    },
    const EncodeOptions(encode: false),
  ),
  equals('a[b]=c'),
);
```

Encoding can be disabled for keys by setting the [EncodeOptions.encodeValuesOnly] option to `true`:

```dart
expect(
  QS.encode(
    {
      'a': 'b',
      'c': ['d', 'e=f'],
      'f': [
        ['g'],
        ['h']
      ]
    },
    const EncodeOptions(encodeValuesOnly: true),
  ),
  equals('a=b&c[0]=d&c[1]=e%3Df&f[0][0]=g&f[1][0]=h'),
);
```

You can supply a custom [Encoder] via [EncodeOptions.encoder]:

```dart
expect(
  QS.encode(
    {
      'a': {'b': 'č'}
    },
    EncodeOptions(
      encoder: (
        str, {
        Encoding? charset,
        Format? format,
      }) =>
          switch (str) {
        'č' => 'c',
        _ => str,
      },
    ),
  ),
  equals('a[b]=c'),
);
```

_(Note: [EncodeOptions.encoder] is ignored when [EncodeOptions.encode] is `false`.)_

Similar to [EncodeOptions.encoder] there is a [DecodeOptions.decoder] option for [decode] to override decoding of 
properties and values:

```dart
expect(
  QS.decode(
    'foo=123', 
    DecodeOptions(
      decoder: (String? str, {Encoding? charset}) =>
        num.tryParse(str ?? '') ?? str,
    ),
  ),
  equals({'foo': 123}),
);
```

Examples beyond this point will be shown as though the output is not URI encoded for clarity.
Please note that the return values in these cases *will* be URI encoded during real usage.

When [List]s are encoded, they follow the [EncodeOptions.listFormat] option, which defaults to [ListFormat.indices]:

```dart
expect(
  QS.encode(
    {
      'a': ['b', 'c', 'd']
    },
    const EncodeOptions(encode: false),
  ),
  equals('a[0]=b&a[1]=c&a[2]=d'),
);
```

You can override this by setting [EncodeOptions.indices] to `false`, or, more explicitly, the
[EncodeOptions.listFormat] option to [ListFormat.repeat]:

```dart
expect(
  QS.encode(
    {
      'a': ['b', 'c', 'd']
    },
    const EncodeOptions(
      encode: false,
      indices: false,
    ),
  ),
  equals('a=b&a=c&a=d'),
);
```

You can choose the list encoding style with [EncodeOptions.listFormat]:

```dart
expect(
  QS.encode(
    {
      'a': ['b', 'c']
    },
    const EncodeOptions(
      encode: false,
      listFormat: ListFormat.indices,
    ),
  ),
  equals('a[0]=b&a[1]=c'),
);

expect(
  QS.encode(
    {
      'a': ['b', 'c']
    },
    const EncodeOptions(
      encode: false,
      listFormat: ListFormat.brackets,
    ),
  ),
  equals('a[]=b&a[]=c'),
);

expect(
  QS.encode(
    {
      'a': ['b', 'c']
    },
    const EncodeOptions(
      encode: false,
      listFormat: ListFormat.repeat,
    ),
  ),
  equals('a=b&a=c'),
);

expect(
  QS.encode(
    {
      'a': ['b', 'c']
    },
    const EncodeOptions(
      encode: false,
      listFormat: ListFormat.comma,
    ),
  ),
  equals('a=b,c'),
);
```

**Note:** When using [EncodeOptions.listFormat] set to [ListFormat.comma], you can also pass the [EncodeOptions.commaRoundTrip]
option set to `true` or `false`, to append `[]` on single-item [List]s, so that they can round trip through a parse.
Set [EncodeOptions.commaCompactNulls] to `true` with the same format when you'd like to drop `null` entries instead of keeping empty slots (for example, `[true, false, null, true]` becomes `true,false,true`).

When [Map]s are encoded, by default they use bracket notation:

```dart
expect(
  QS.encode(
    {
      'a': {
        'b': {'c': 'd', 'e': 'f'}
      }
    },
    const EncodeOptions(encode: false),
  ),
  equals('a[b][c]=d&a[b][e]=f'),
);
```

You may override this to use dot notation by setting the [EncodeOptions.allowDots] option to `true`:

```dart
expect(
  QS.encode(
    {
      'a': {
        'b': {'c': 'd', 'e': 'f'}
      }
    },
    const EncodeOptions(
      encode: false,
      allowDots: true,
    ),
  ),
  equals('a.b.c=d&a.b.e=f'),
);
```

Encode literal dots in keys with [EncodeOptions.encodeDotInKeys] (use with [EncodeOptions.allowDots]):

```dart
expect(
  QS.encode(
    {
      'name.obj': {'first': 'John', 'last': 'Doe'}
    },
    const EncodeOptions(
      allowDots: true,
      encodeDotInKeys: true,
    ),
  ),
  equals('name%252Eobj.first=John&name%252Eobj.last=Doe'),
);
```

**Caveat:** when both [EncodeOptions.encodeValuesOnly] and [EncodeOptions.encodeDotInKeys] are `true`, only dots in keys are encoded; values remain unchanged.

You may allow empty [List] values by setting the [EncodeOptions.allowEmptyLists] option to `true`:

```dart
expect(
  QS.encode(
    {
      'foo': [],
      'bar': 'baz',
    },
    const EncodeOptions(
      encode: false,
      allowEmptyLists: true,
    ),
  ),
  equals('foo[]&bar=baz'),
);
```

Empty strings and null values will omit the value, but the equals sign (`=`) remains in place:

```dart
expect(
  QS.encode(
    {
      'a': '',
    },
  ),
  equals('a='),
);
```

Keys with no values (e.g., empty [Map]s or [List]s) produce no output:

```dart
expect(
  QS.encode(
    {
      'a': [],
    },
  ),
  equals(''),
);

expect(
  QS.encode(
    {
      'a': {},
    },
  ),
  equals(''),
);

expect(
  QS.encode(
    {
      'a': [{}],
    },
  ),
  equals('')
);

expect(
  QS.encode(
    {
      'a': {'b': []},
    },
  ),
  equals('')
);

expect(
  QS.encode(
    {
      'a': {'b': {}},
    },
  ),
  equals('')
);
```

Properties set to [Undefined] are omitted entirely:

```dart
expect(
  QS.encode(
    {
      'a': null,
      'b': const Undefined(),
    },
  ),
  equals('a='),
);
```

The query string may optionally be prepended with a question mark:

```dart
expect(
  QS.encode(
    {
      'a': 'b',
      'c': 'd',
    },
    const EncodeOptions(addQueryPrefix: true),
  ),
  equals('?a=b&c=d'),
);
```

The delimiter may be overridden as well:

```dart
expect(
  QS.encode(
    {
      'a': 'b',
      'c': 'd',
    },
    const EncodeOptions(delimiter: ';'),
  ),
  equals('a=b;c=d'),
);
```

If you only want to override the serialization of [DateTime] objects, you can provide a custom [DateSerializer] in the
[EncodeOptions.serializeDate] option:

```dart
expect(
  QS.encode(
    {
      'a': DateTime.fromMillisecondsSinceEpoch(7).toUtc(),
    },
    const EncodeOptions(encode: false),
  ),
  equals('a=1970-01-01T00:00:00.007Z'),
);
expect(
  QS.encode(
    {
      'a': DateTime.fromMillisecondsSinceEpoch(7).toUtc(),
    },
    EncodeOptions(
      encode: false,
      serializeDate: (DateTime date) =>
          date.millisecondsSinceEpoch.toString(),
    ),
  ),
  equals('a=7'),
);
```

You may use the [EncodeOptions.sort] option to affect the order of parameter keys:

```dart
expect(
  QS.encode(
    {
      'a': 'c',
      'z': 'y',
      'b': 'f',
    },
    EncodeOptions(
      encode: false,
      sort: (a, b) => a.compareTo(b),
    ),
  ),
  equals('a=c&b=f&z=y'),
);
```

Finally, you can use the [EncodeOptions.filter] option to restrict which keys will be included in the encoded output.
If you pass a [Function], it will be called for each key to obtain the replacement value.
Otherwise, if you pass a [List], it will be used to select properties and [List] indices to be encoded:

```dart
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
  QS.encode(
    {
      'a': 'b',
      'c': 'd',
      'e': 'f',
    },
    const EncodeOptions(
      encode: false,
      filter: ['a', 'e'],
    ),
  ),
  equals('a=b&e=f'),
);

expect(
  QS.encode(
    {
      'a': ['b', 'c', 'd'],
      'e': 'f',
    },
    const EncodeOptions(
      encode: false,
      filter: ['a', 0, 2],
    ),
  ),
  equals('a[0]=b&a[2]=d'),
);
```

### Handling of `null` values

By default, `null` values are treated like empty strings:

```dart
expect(
  QS.encode(
    {
      'a': null,
      'b': '',
    },
  ),
  equals('a=&b='),
);
```

Decoding does not distinguish between parameters with and without equal signs.
Both are converted to empty strings.

```dart
expect(
  QS.decode('a&b='),
  equals({
    'a': '',
    'b': '',
  }),
);
```

To distinguish between `null` values and empty [String]s use the [EncodeOptions.strictNullHandling] flag. 
In the result string the `null` values have no `=` sign:

```dart
expect(
  QS.encode(
    {
      'a': null,
      'b': '',
    },
    const EncodeOptions(strictNullHandling: true),
  ),
  equals('a&b='),
);
```

To decode values without `=` back to `null` use the [DecodeOptions.strictNullHandling] flag:

```dart
expect(
  QS.decode(
    'a&b=',
    const DecodeOptions(strictNullHandling: true),
  ),
  equals({
    'a': null,
    'b': '',
  }),
);
```

To completely skip rendering keys with `null` values, use the [EncodeOptions.skipNulls] flag:

```dart
expect(
  QS.encode(
    {
      'a': 'b',
      'c': null,
    },
    const EncodeOptions(skipNulls: true),
  ),
  equals('a=b'),
);
```

If you're communicating with legacy systems, you can switch to [latin1] using the [EncodeOptions.charset] option:

```dart
expect(
  QS.encode(
    {
      'æ': 'æ',
    },
    const EncodeOptions(charset: latin1),
  ),
  equals('%E6=%E6'),
);
```

Characters that don't exist in [latin1] will be converted to numeric entities, similar to what browsers do:

```dart
expect(
  QS.encode(
    {
      'a': '☺',
    },
    const EncodeOptions(charset: latin1),
  ),
  equals('a=%26%239786%3B'),
);
```

You can use the [EncodeOptions.charsetSentinel] option to announce the character by including an `utf8=✓` parameter with
the proper encoding of the checkmark, similar to what Ruby on Rails and others do when submitting forms.

```dart
expect(
  QS.encode(
    {
      'a': '☺',
    },
    const EncodeOptions(charsetSentinel: true),
  ),
  equals('utf8=%E2%9C%93&a=%E2%98%BA'),
);
expect(
  QS.encode(
    {
      'a': 'æ',
    },
    const EncodeOptions(
      charset: latin1,
      charsetSentinel: true,
    ),
  ),
  equals('utf8=%26%2310003%3B&a=%E6'),
);
```

### Dealing with special character sets

By default, the encoding and decoding of characters is done in [utf8], and [latin1] support is also built in via 
the [EncodeOptions.charset] and [DecodeOptions.charset] parameter, respectively.

If you wish to encode query strings to a different character set (i.e.
[Shift JIS](https://en.wikipedia.org/wiki/Shift_JIS)) you can use the [euc](https://pub.dev/packages/euc) package

```dart
expect(
  QS.encode(
    {
      'a': 'こんにちは！',
    },
    EncodeOptions(
      encoder: (str, {Encoding? charset, Format? format}) {
        if ((str as String?)?.isNotEmpty ?? false) {
          final Uint8List buf = Uint8List.fromList(
            ShiftJIS().encode(str!),
          );
          final List<String> result = [
            for (int i = 0; i < buf.length; ++i) buf[i].toRadixString(16)
          ];
          return '%${result.join('%')}';
        }
        return '';
      },
    ),
  ),
  equals('%61=%82%b1%82%f1%82%c9%82%bf%82%cd%81%49'),
);
```

This also works for decoding of query strings:

```dart
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
        return ShiftJIS().decode(
          Uint8List.fromList(result),
        );
      },
    ),
  ),
  equals({
    'a': 'こんにちは！',
  }),
);
```

### RFC 3986 and RFC 1738 space encoding

The default [EncodeOptions.format] is [Format.rfc3986] which encodes `' '` to `%20` which is backward compatible.
You can also set the [EncodeOptions.format] to [Format.rfc1738] which encodes `' '` to `+`.

```dart
expect(
  QS.encode(
    {
      'a': 'b c',
    },
  ),
  equals('a=b%20c'),
);

expect(
  QS.encode(
    {
      'a': 'b c',
    },
    const EncodeOptions(format: Format.rfc3986),
  ),
  equals('a=b%20c'),
);

expect(
  QS.encode(
    {
      'a': 'b c',
    },
    const EncodeOptions(format: Format.rfc1738),
  ),
  equals('a=b+c'),
);
```

---

## Other ports

| Port                       | Repository                                                  | Package                                                                                                                                                                                       |
|----------------------------|-------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Python                     | [techouse/qs_codec](https://github.com/techouse/qs_codec)   | [![PyPI](https://img.shields.io/pypi/v/qs-codec?logo=python&label=PyPI)](https://pypi.org/project/qs-codec/)                                                                                  |
| Kotlin / JVM + Android AAR | [techouse/qs-kotlin](https://github.com/techouse/qs-kotlin) | [![Maven Central](https://img.shields.io/maven-central/v/io.github.techouse/qs-kotlin?logo=kotlin&label=Maven%20Central)](https://central.sonatype.com/artifact/io.github.techouse/qs-kotlin) |
| Swift / Objective-C        | [techouse/qs-swift](https://github.com/techouse/qs-swift)   | [![SPM](https://img.shields.io/github/v/release/techouse/qs-swift?logo=swift&label=SwiftPM)](https://swiftpackageindex.com/techouse/qs-swift)                                                 |
| .NET / C#                  | [techouse/qs-net](https://github.com/techouse/qs-net)       | [![NuGet](https://img.shields.io/nuget/v/QsNet?logo=dotnet&label=NuGet)](https://www.nuget.org/packages/QsNet)                                                                                |
| Node.js (original)         | [ljharb/qs](https://github.com/ljharb/qs)                   | [![npm](https://img.shields.io/npm/v/qs?logo=javascript&label=npm)](https://www.npmjs.com/package/qs)                                                                                         |

---

Special thanks to the authors of [qs](https://www.npmjs.com/package/qs) for JavaScript:
- [Jordan Harband](https://github.com/ljharb)
- [TJ Holowaychuk](https://github.com/visionmedia/node-querystring)
