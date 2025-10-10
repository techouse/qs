## qs_dart – AI Coding Agent Guide

Purpose: Provide just enough project context so an AI assistant can make correct, idiomatic edits fast. Keep responses concrete, reflect existing patterns, and avoid generic advice.

### 1. Architecture & Core Concepts
* Library type: Pure Dart package (query string codec) ported from Node.js `qs` with near‑parity semantics.
* Public surface (`lib/qs_dart.dart`) re‑exports:
  - Top‑level `decode` / `encode` (wrappers around `QS.decode` / `QS.encode`).
  - Option models: `DecodeOptions`, `EncodeOptions`, enums (`Duplicates`, `ListFormat`, `Format`, `Sentinel`, `DecodeKind`).
  - `Undefined` sentinel (marks intentionally omitted values during encoding/merging).
  - `Uri` extensions (`src/uri.dart`) for ergonomic integration.
* Implementation split:
  - `src/qs.dart` orchestrates encode/decode; heavy lifting delegated to private `part` files `extensions/decode.dart` & `extensions/encode.dart` and utility helpers in `utils.dart`.
  - `utils.dart` centralizes low‑level merging (`Utils.merge`), compaction (`Utils.compact`), scalar detection, percent encoding, HTML entity handling.
  - Option classes encode guard‑rails: depth, parameterLimit, listLimit, charsetSentinel, etc.
* Design principle: mirror Node `qs` behavior while remaining Dart‑idiomatic (ordered `Map<String, dynamic>`, explicit options objects, strong enums instead of magic strings).

### 2. Key Behavioral Nuances (Don’t Break These)
* Decode limits: default `depth=5`, `parameterLimit=1000`, `listLimit=20`; exceeding may coerce indices into object keys or (with strict flags) throw.
* List vs Map merging mimics Node: duplicate keys accumulate to lists unless `duplicates` option changes strategy.
* `Undefined` entries are placeholders stripped by `Utils.compact` post‑decode / during encode pruning; never serialize `Undefined` itself.
* Charset sentinel: when `charsetSentinel=true`, `utf8=✓` token (encoded differently per charset) overrides provided `charset` and is omitted from output.
* `allowDots` & `decodeDotInKeys`: invalid combination (`decodeDotInKeys: true` with `allowDots: false`) must throw (constructor asserts). Preserve that invariant.
* Negative `listLimit` disables numeric indexing; with `throwOnLimitExceeded` certain pushes must throw `RangeError` (match existing patterns in decode logic—consult decode part file before altering behavior).
* Encoding pipeline can inject custom encoder/decoder hooks; preserve argument order and named params (`charset`, `format`, `kind`).

### 3. Source Conventions
* Public APIs: lowerCamelCase; files: snake_case; enums: PascalCase members.
* Avoid printing (`avoid_print` lint); no side‑effects outside encode/decode.
* Keep option constructors const & validating invariants via `assert`.
* Prefer extension methods & small helpers over large monolithic functions.
* Maintain iteration order: when converting iterables to maps use string indices (`Utils.createIndexMap`); merging may temporarily use `SplayTreeMap` for deterministic ordering.

### 4. Testing Strategy
* Unit tests in `test/unit/` mirror README examples & edge cases (list formats, depth, duplicates, charsets, null handling, custom hooks).
* E2E tests in `test/e2e/` exercise higher‑level URI extensions.
* Comparison tests (`test/comparison/`) ensure parity with the JS implementation via fixture JSON & a Node script; run `test/comparison/compare_outputs.sh` after semantic changes to core encode/decode logic.
* When adding behavior, first add/modify a unit test replicating the JS `qs` behavior (consult upstream if uncertain), then adjust implementation.

### 5. Dev Workflow / Commands
* Install deps: `make install` (wraps `dart pub get`).
* Quality gate before commits/PR: `make sure` (analyze + format check + tests). Always keep CI green.
* Run tests: `make test` (VM platform). Add coverage: `make show_test_coverage` → opens HTML at `coverage/html/index.html`.
* Formatting: `make format` (or `dart format .`); never commit unformatted code.
* Dependency upgrades: `make upgrade`; check outdated: `make check_outdated`.

### 6. Adding / Modifying Features (Checklist)
1. Write or update a focused test under `test/unit/` (mirroring file/module naming).
2. If changing cross‑language semantics, update comparison fixtures & run the comparison script.
3. Implement minimal changes: prefer editing encode/decode parts or localized helpers in `utils.dart` rather than inflating public API.
4. Update README only if user‑visible behavior changes (options, defaults, new enum values). Keep examples minimal and consistent with test expectations.
5. Run `make sure`; fix lint warnings as errors.

### 7. Common Pitfalls for Agents
* DO NOT expose new symbols via `qs_dart.dart` unless intentionally part of the public contract.
* Avoid broad refactors of `utils.dart`; many subtle invariants (Undefined pruning, ordering, surrogate pair handling) are covered by tests—modify surgically.
* Keep percent‑encoding logic streaming & segment‑aware (`_segmentLimit=1024`) to preserve performance.
* When adding an option: ensure const constructor, add to `copyWith` (if present in file—verify before editing), equality via `EquatableMixin`, and README table/example.
* Ensure new enums get exported in `qs_dart.dart` only if needed by library consumers (options signatures, return types).

### 8. Performance Considerations
* Encoding avoids splitting surrogate pairs when chunking strings; preserve that loop structure.
* Merge uses structural checks to decide list append vs map merge; naive rebuilding can degrade performance & ordering.
* Avoid recursive deep traversal for compaction—current iterative approach prevents stack overflows on adversarial inputs.

### 9. Error Handling Expectations
* Input type validation: non‑String/non‑Map to `QS.decode` must throw `ArgumentError.value` (message currently: 'The input must be a String or a Map<String, dynamic>'). Keep wording for stable tests.
* Depth/list/parameter overflows toggle between soft limiting or throwing depending on `strictDepth` / `throwOnLimitExceeded` flags; never silently ignore an explicit strict flag.

### 10. Documentation & Examples
* README examples double as test patterns—when you change semantics, sync both.
* Keep code comments concise; prefer section banners only where logic is subtle (merging, encoding loops).

### 11. Commit / PR Style
* Commit subject prefix emoji (e.g., `:sparkles: Add X`, `:bug:` etc.) aligned with existing history.
* PRs: link issues, state behavior changes, mention any parity deviations from Node `qs`.

### 12. Safe Extension Ideas (Low Risk)
* Additional list formats or duplicate strategies: introduce enum value + guarded branch + tests.
* Extra utility for selective key removal during encode (implemented via `filter` lambda) — prefer documenting patterns rather than expanding API unless necessary.

If anything above is unclear or you need deeper decode/encode part internals, request those specific files before editing them.

---
Feedback welcome: highlight unclear invariants or missing edge cases so we can refine this guide.
