/// An enum of all available duplicate key handling strategies.
enum Duplicates {
  /// Combine duplicate keys into a single key with an array of values.
  combine,

  /// Use the first value for duplicate keys.
  first,

  /// Use the last value for duplicate keys.
  last;

  @override
  String toString() => name;
}
