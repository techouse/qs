import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart' show internal;

@internal
final class StructuredKeyScan with EquatableMixin {
  const StructuredKeyScan({
    required this.hasAnyStructuredSyntax,
    required this.structuredRoots,
    required this.structuredKeys,
  });

  const StructuredKeyScan.empty()
      : hasAnyStructuredSyntax = false,
        structuredRoots = const <String>{},
        structuredKeys = const <String>{};

  final bool hasAnyStructuredSyntax;
  final Set<String> structuredRoots;
  final Set<String> structuredKeys;

  @override
  List<Object?> get props => [
        hasAnyStructuredSyntax,
        structuredRoots,
        structuredKeys,
      ];
}
