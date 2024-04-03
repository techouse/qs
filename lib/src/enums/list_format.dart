typedef ListFormatGenerator = String Function(String prefix, [String? key]);

/// An enum of all available list format options.
enum ListFormat {
  /// Use brackets to represent list items, for example
  /// `foo[]=123&foo[]=456&foo[]=789`
  brackets(_brackets),

  /// Use commas to represent list items, for example
  /// `foo=123,456,789`
  comma(_comma),

  /// Repeat the same key to represent list items, for example
  /// `foo=123&foo=456&foo=789`
  repeat(_repeat),

  /// Use indices in brackets to represent list items, for example
  /// `foo[0]=123&foo[1]=456&foo[2]=789`
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
