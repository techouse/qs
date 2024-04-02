typedef ListFormatGenerator = String Function(String prefix, [String? key]);

/// An enum of all available list format options.
enum ListFormat {
  brackets(_brackets),
  comma(_comma),
  repeat(_repeat),
  indices(_indices);

  const ListFormat(this.generator);

  final ListFormatGenerator generator;

  @override
  String toString() => name;

  static String _brackets(String prefix, [String? key]) => '$prefix[]';

  static String _comma(String prefix, [String? key]) => prefix;

  static String _indices(String prefix, [String? key]) => '$prefix[$key]';

  static String _repeat(String prefix, [String? key]) => prefix;
}
