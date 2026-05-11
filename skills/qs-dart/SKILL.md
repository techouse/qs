---
name: qs-dart
description: Use this skill whenever a user wants to install, configure, generate code for, troubleshoot, or choose options for encoding and decoding nested query strings in Dart or Flutter with the qs_dart package. This skill helps produce practical QS.decode, QS.encode, and Uri extension snippets, explain option tradeoffs, and avoid qs_dart edge-case pitfalls.
---

# qs_dart Usage Assistant

Help users parse and build query strings with the Dart/Flutter `qs_dart`
package. Focus on user application code and interoperability outcomes, not
repository maintenance.

## Start With Inputs

Before producing a final snippet, collect only the missing details that change
the code:

- Runtime: Dart CLI/server, Flutter app, tests, or generated example.
- Direction: decode an incoming query string, encode Dart data, or normalize a
  `Uri`.
- The actual query string or Dart structure when available.
- Target API convention for lists: indexed brackets, empty brackets, repeated
  keys, or comma-separated values.
- Whether the query may include a leading `?`, dot notation, literal dots in
  keys, duplicate keys, custom delimiters, comma-separated lists, `null` flags,
  Latin-1/legacy charset behavior, or untrusted user input.

Do not over-ask when the desired behavior is obvious. State assumptions in the
answer and give the user a concrete snippet they can paste.

## Installation

For a Dart package or CLI:

```bash
dart pub add qs_dart
```

For Flutter:

```bash
flutter pub add qs_dart
```

Use the public import:

```dart
import 'package:qs_dart/qs_dart.dart';
```

When snippets use `latin1`, `utf8`, or `Encoding`, also include:

```dart
import 'dart:convert' show Encoding, latin1, utf8;
```

## Base Patterns

Decode a query string into nested Dart values:

```dart
final params = QS.decode('a[b][c]=d&tags[]=dart&tags[]=flutter');
// {'a': {'b': {'c': 'd'}}, 'tags': ['dart', 'flutter']}
```

Encode nested Dart values into a query string:

```dart
final query = QS.encode({
  'a': {
    'b': {'c': 'd'},
  },
  'tags': ['dart', 'flutter'],
});
// a%5Bb%5D%5Bc%5D=d&tags%5B0%5D=dart&tags%5B1%5D=flutter
```

Use the `Uri` extensions when working with Dart `Uri` objects:

```dart
final params = Uri.parse(
  'https://example.com/search?filters[status]=open',
).queryParametersQs();

final url = Uri.https('example.com', '/search', {
  'tag': ['dart', 'flutter'],
}).toStringQs();
```

`Uri.toStringQs()` defaults to `ListFormat.repeat`, so repeated query values
become `tag=dart&tag=flutter`.

## Decode Recipes

Use these options with `QS.decode(query, const DecodeOptions(...))`:

- Leading question mark: `ignoreQueryPrefix: true`.
- Dot notation such as `a.b=c`: `allowDots: true`.
- Encoded literal dots in keys such as `name%252Eobj.first=John`:
  `decodeDotInKeys: true`.
- Duplicate keys: `duplicates: Duplicates.combine` keeps all values as a list;
  use `Duplicates.first` or `Duplicates.last` to collapse.
- Bracket lists: enabled by default; set `parseLists: false` to treat numeric
  indices as map keys.
- Large or sparse list indices: default `listLimit` is `20`; indices above the
  limit become map keys.
- Comma-separated values such as `a=b,c`: `comma: true`.
- Tokens without `=` as `null`: `strictNullHandling: true`.
- Custom delimiters: `delimiter: ';'` or `delimiter: RegExp(r'[;,]')`.
- Legacy charset input: `charset: latin1`; use `charsetSentinel: true` when a
  form may include `utf8=...` to signal the real charset.
- HTML numeric entities: `interpretNumericEntities: true`, usually with
  `latin1` or charset sentinel handling.
- Untrusted input: keep a small `depth`, keep `parameterLimit`, and use
  `strictDepth: true` or `throwOnLimitExceeded: true` when callers need hard
  failures instead of soft limiting.

Example for a request query:

```dart
final params = QS.decode(
  '?filter.status=open&tag=dart&tag=flutter',
  const DecodeOptions(
    ignoreQueryPrefix: true,
    allowDots: true,
    duplicates: Duplicates.combine,
  ),
);
```

## Encode Recipes

Use these options with `QS.encode(data, const EncodeOptions(...))`:

- List style defaults to `ListFormat.indices`: `tags[0]=dart&tags[1]=flutter`.
- Empty brackets: `listFormat: ListFormat.brackets`.
- Repeated keys: `listFormat: ListFormat.repeat`.
- Comma-separated values: `listFormat: ListFormat.comma`.
- Single-item comma lists that must round-trip as lists: `commaRoundTrip: true`.
- Drop `null` items before comma-joining lists: `commaCompactNulls: true`.
- Dot notation for nested maps: `allowDots: true`.
- Literal dots in keys: `encodeDotInKeys: true`; this implies dot-style output.
- Add a leading `?`: `addQueryPrefix: true`.
- Custom pair delimiter: `delimiter: ';'`.
- Preserve readable bracket/dot keys while encoding values:
  `encodeValuesOnly: true`.
- Disable percent encoding entirely for debugging or documented examples:
  `encode: false`.
- Emit `null` without `=`: `strictNullHandling: true`.
- Omit `null` keys: `skipNulls: true`.
- Emit empty lists as `foo[]`: `allowEmptyLists: true`.
- Legacy form spaces as `+`: `format: Format.rfc1738`; the default is
  `Format.rfc3986`, which emits spaces as `%20`.
- Legacy charset output: `charset: latin1`; use `charsetSentinel: true` to
  prepend the `utf8=...` sentinel.
- Custom behavior: use `encoder`, `serializeDate`, `sort`, or `filter` when
  the target API needs special scalar encoding, date formatting, stable key
  order, or selected fields.

Example for an API that expects repeated keys:

```dart
final query = QS.encode(
  {
    'q': 'query strings',
    'tag': ['dart', 'flutter'],
  },
  const EncodeOptions(
    listFormat: ListFormat.repeat,
    addQueryPrefix: true,
  ),
);
// ?q=query%20strings&tag=dart&tag=flutter
```

## Combinations To Check

Warn or adjust before giving code for these cases:

- `decodeDotInKeys: true` with `allowDots: false` is invalid.
- `parameterLimit` must be positive or `double.infinity`; `double.nan` and
  non-positive values are invalid.
- Built-in charset handling supports only `utf8` and `latin1`; other encodings
  require a custom `encoder` or `decoder`.
- `EncodeOptions.encoder` is ignored when `encode: false`.
- Combining `encodeValuesOnly: true` and `encodeDotInKeys: true` encodes only
  dots in keys; values remain otherwise unchanged.
- `DecodeOptions.comma` parses simple comma-separated values, but does not
  decode nested map syntax such as `a={b:1},{c:d}`.
- Negative `listLimit` disables numeric-index list parsing; with
  `throwOnLimitExceeded: true`, list-growth paths throw.
- Native `Uri.queryParameters` flattens duplicate values. Prefer
  `queryParametersQs()` and `toStringQs()` when users need qs-style nested or
  repeated values.

## Response Shape

For code-generation requests, answer with:

1. A short statement of assumptions, especially list format, null handling,
   charset, prefix handling, and whether input is trusted.
2. One concrete Dart snippet using `QS.decode`, `QS.encode`, or the `Uri`
   extension.
3. A brief explanation of only the options used.
4. A small verification example, such as an expected map, expected query string,
   or a `package:test` `expect`.

Keep snippets application-oriented. Prefer public API imports from
`package:qs_dart/qs_dart.dart`; do not ask users to import from `lib/src/`.
