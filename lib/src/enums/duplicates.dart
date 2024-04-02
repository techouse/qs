/// An enum of all available duplicate key handling strategies.
enum Duplicates {
  combine,
  first,
  last;

  @override
  String toString() => name;
}
