#!/usr/bin/env bash

# Run the JavaScript and Dart scripts and save their outputs
node_output=$(node qs.js)
dart_output=$(dart run qs.dart)

# Compare the outputs
if [ "$node_output" == "$dart_output" ]; then
    echo "The outputs are identical."
    exit 0
else
    echo "The outputs are different."
    exit 1
fi
