## 1.5.0

- [FEAT] add key-aware decoding capability to the query string decoder via `DecodeKind`

## 1.4.3

- [FIX] optimize map merging and percent-encoding logic in `Utils`
- [FIX] improve percent-decoding performance and refactor merge logic in `Utils`
- [FIX] optimize slice logic for lists and strings to improve bounds handling and performance
- [FIX] optimize iterable handling in encoder for improved performance and consistency
- [FIX] optimize parameter splitting and iterable joining in decoder for improved performance and clarity
- [FIX] refine charset detection and array parsing logic in decoder for improved accuracy and consistency
- [FIX] add utility to create index-keyed map from iterable for improved mapping flexibility
- [FIX] optimize encoder map normalization and key handling for improved type safety and clarity
- [FIX] prevent splitting UTF-16 surrogate pairs across segment boundaries in encoder for improved correctness
- [FIX] refine UTF-16 surrogate handling in encoder for improved correctness and Unicode compliance
- [FIX] optimize list limit enforcement, key handling, and iterable indexing for improved correctness and clarity

## 1.4.2

- [CHORE] improve documentation

## 1.4.1

- [CHORE] enhance type safety and improve readability in `Utils.compact` method

## 1.4.0

- [CHORE] improve `decode` performance

## 1.3.9

- [FIX] make `encode.objKeys` late final to ensure immutability

## 1.3.8

- [FIX] enforce non-nullable `serializeDate` in `EncodeOptions`
- [CHORE] update `serializeDate` related tests

## 1.3.7+1

- [CHORE] re-release 1.3.7 due to a Github Actions issue

## 1.3.7

- [CHORE] update dev_dependencies

## 1.3.6

- [FIX] fix Lists with indices always getting parsed into a Map

## 1.3.5+1

- [FIX] respect `Uri.toStringQs` encode options

## 1.3.5

- [FIX] fix `UriExtension.toStringQs` method to use `queryParametersAll`

## 1.3.4

- [FEAT] make `QS.encode` parameter for `EncodeOptions` optional
- [FEAT] make `QS.decode` parameter for `DecodeOptions` optional

## 1.3.3+1

- [CHORE] fix URL-formatting in readme

## 1.3.3

- [CHORE] refactor `QS.encode` logic for improved readability and efficiency

## 1.3.2

- [FIX] fix `Utils.unescape` for `%` characters ([#28](https://github.com/techouse/qs/pull/28))

## 1.3.1

- [FEAT] use `Utils.combine` more in `QS.decode`
- [CHORE] add more tests
- [CHORE] fix linter warnings

## 1.3.0

- [FEAT] add `DecodeOptions.throwOnLimitExceeded` option ([#26](https://github.com/techouse/qs/pull/26))
- [CHORE] remove dead code in `Utils`
- [CHORE] add more tests
- [CHORE] update dependencies

## 1.2.4

- [CHORE] update [lints](https://pub.dev/packages/lints) to 5.0.0 (was 4.0.0)

## 1.2.3

- [FIX] `QS.decode`: avoid a crash with `interpretNumericEntities: true`, `comma: true`, and `charset: latin1`
- [CHORE] add more tests

## 1.2.2

- [FEAT] add `DecodeOptions.strictDepth` option to throw when input is beyond depth ([#22](https://github.com/techouse/qs/pull/22))

## 1.2.1

- [FIX] fix `QS.decode` output when both `strictNullHandling` and `allowEmptyLists` are set to `true` ([#21](https://github.com/techouse/qs/pull/21))

## 1.2.0

- [FEAT] `QS.decode` returns `Map<String, dynamic>` instead of `Map<dynamic, dynamic>` ([#17](https://github.com/techouse/qs/pull/17))
- [FEAT] add `Uri` extension ([#18](https://github.com/techouse/qs/pull/18)) 
- [FIX] fix decoding encoded square brackets in key names

## 1.1.0

- [FEAT] `DateSerializer` now returns `String` or `null`
- [CHORE] add more tests

## 1.0.10

- [CHORE] add [documentation](https://techouse.github.io/qs/)

## 1.0.9

- [FIX] incorrect parsing of nested params with closing square bracket `]` in the property name ([#12](https://github.com/techouse/qs/pull/12))

## 1.0.8+1

- [CHORE] update readme / documentation

## 1.0.8

- [FEAT] port `String.prototype.slice()` from JavaScript and use that instead of Dart's `String.substring()`
- [CHORE] add comparison test between output of qs_dart and [qs](https://www.npmjs.com/package/qs)
- [CHORE] update test to 1.25.3 (was 1.25.2)
- [CHORE] update path to 1.9.0 (was 1.8.0)

## 1.0.7+1

- [FIX] fix optimization regressions introduced in v1.0.7

## 1.0.7

- [FIX] disable `DecodeOptions.decodeDotInKeys` by default to restore previous behavior
- [FIX] optimize encoding performance under large data volumes, reduce memory usage

## 1.0.6

- [FEAT] add support for `Set`s
- [CHORE] rename `_encode.allowEmptyArrays` to `_encode.allowEmptyLists`
- [CHORE] optimize `Utils.removeUndefinedFromList` method
- [CHORE] delete dead code in `Utils.merge` method
- [CHORE] fix typos in documentation
- [CHORE] add more tests

## 1.0.5

- [CHORE] get rid of unused `filter` variable in `QS.encode` method

## 1.0.4

- [FIX] prevent `Utils.encode` method from encoding `Iterable`, `Map`, `Symbol`, `Record`, `Future` and `Undefined`

## 1.0.3

- [FIX] fix `Utils.isNonNullishPrimitive` method to enable encoding Enums

## 1.0.2

- [FEAT] add equatability to Undefined
- [CHORE] add more tests to raise coverage

## 1.0.1+2

- [CHORE] update documentation

## 1.0.1+1

- [CHORE] lower meta dependency from ^1.11.0 to ^1.9.1
- [CHORE] update documentation
- [CHORE] update example
- [CHORE] update readme

## 1.0.1

- [CHORE] add documentation

## 1.0.0+1

- [FIX] fix repository url in pubspec.yaml

## 1.0.0

- Initial release.
