/// An enum of all available duplicate handling strategies.
enum Duplicates {
  combine,
  first,
  last;

  @override
  String toString() => name;
}
