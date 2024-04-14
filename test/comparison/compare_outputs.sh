#!/usr/bin/env bash

# Get the directory of the script
script_dir=$(dirname "$0")

# Run the JavaScript and Dart scripts and save their outputs
node_output=$(node "$script_dir/qs.js")
dart_output=$(dart run "$script_dir/qs.dart")

# Compare the outputs
if [ "$node_output" == "$dart_output" ]; then
    echo "The outputs are identical."
    exit 0
else
    echo "The outputs are different."
    exit 1
fi
