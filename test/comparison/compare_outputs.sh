#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

compare_outputs() {
  local expected="$1"
  local actual="$2"
  local description="$3"

  if ! diff -u "$expected" "$actual"; then
    echo "$description outputs are different." >&2
    exit 1
  fi
}

node "$script_dir/qs.js" > "$tmp_dir/node.out"
dart run "$script_dir/qs.dart" > "$tmp_dir/dart_vm.out"

test_cases_base64=$(base64 < "$script_dir/test_cases.json" | tr -d '\r\n')
dart compile js -O2 \
  -DQS_COMPARISON_TEST_CASES_BASE64="$test_cases_base64" \
  "$script_dir/qs_dart2js.dart" \
  -o "$tmp_dir/qs_dart2js.js"
node "$tmp_dir/qs_dart2js.js" > "$tmp_dir/dart2js.out"

compare_outputs "$tmp_dir/node.out" "$tmp_dir/dart_vm.out" "Node and Dart VM"
compare_outputs "$tmp_dir/node.out" "$tmp_dir/dart2js.out" "Node and dart2js"

echo "The Node, Dart VM, and dart2js outputs are identical."
