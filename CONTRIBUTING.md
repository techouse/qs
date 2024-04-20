# Contributing

Thank you for your interest in contributing to this project. This project relies on the help of volunteer developers for
its development and maintenance.

Before making any changes to this repository, please first discuss the proposed changes with the repository owners
through an issue, email, or any other appropriate method of communication.

Please note that a [code of conduct](CODE-OF-CONDUCT.md) is in place and should be adhered to during all interactions
related to the project.

## Dart version support

Currently, the package supports Dart versions 3.0 and above. Once a new Dart version is released, we will aim to support
it as soon as possible. If you encounter any issues with a new Dart version, please create an issue in the repository.

## Flutter support

This package is designed to work with Flutter 3.10 and above. We prioritize and are dedicated to maintaining
compatibility with these versions for a smooth user experience.

## Testing

Given the critical nature of correctly encoded HTTP query strings and the potential for security vulnerabilities if
encoding is not done correctly or consistently across platforms and versions of Dart and Flutter, thorough testing is
of utmost importance. Please remember to write tests for any new code you create, using
the [test](https://pub.dev/packages/test) package for all test cases.

### Running the test suite

To run the test suite, follow these commands:

```bash
git clone https://github.com/techouse/qs
cd qs
dart pub get
dart test
```

### Running the test suite with coverage

```bash
dart pub global activate coverage
dart pub global run coverage:test_with_coverage
genhtml coverage/lcov.info -o coverage/html
source ./scripts/makefile_scripts.sh && open_link "coverage/html/index.html"
```

## qs JavaScript package compatibility

As this package is a port of the [qs](https://www.npmjs.com/package/qs) package for JavaScript. We aim to provide a
similar experience for Dart and Flutter developers, ensuring that the two packages are as similar as possible. If you
encounter any discrepancies between the two packages, please create an issue in the repository.

### Ensuring compatibility

To ensure compatibility with the Node.js package, please run the following command:

```bash
# cd into the test/comparison directory
pushd test/comparison || exit 1

# Install the Node.js dependencies
npm install

# Run the JavaScript and Dart scripts and save their outputs
node_output=$(node qs.js)
dart_output=$(dart run qs.dart)

# Compare the outputs
if [ "$node_output" == "$dart_output" ]; then
  echo "The outputs are identical."
else
  echo "The outputs are different."
  exit 1
fi

popd || exit 1
```

For convenience, the same bash script exists
in [test/comparison/compare_outputs.sh](test/comparison/compare_outputs.sh).

## Submitting changes

To contribute to this project, please submit a new pull request and provide a clear list of your changes. For guidance
on creating pull requests, you can refer to this resource. When sending a pull request, we highly appreciate the
inclusion of tests, as we strive to enhance our test coverage.
Following our coding conventions is essential, and it would be ideal if you ensure that each commit focuses on a single
feature. For commits, please write clear log messages. While concise one-line messages are suitable for small changes,
more substantial modifications should follow a format similar to the example below:

```bash
git commit -m "A brief summary of the commit
> 
> A paragraph describing what changed and its impact."
```

## Coding standards

Prioritizing code readability and conciseness is essential. To achieve this, we recommend using `dart format` for code
formatting. Once your work is deemed complete, it is advisable to run the following command:

```bash
dart format lib test --output=none --set-exit-if-changed .
dart analyze lib test --fatal-infos
```

This command runs the Dart analyzer to identify any potential issues or inconsistencies in your code. By following these
guidelines, you can ensure a high-quality codebase.

Thanks, Klemen Tusar
