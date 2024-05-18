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
