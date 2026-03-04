import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

// Internal marker used for synthetic "value" entries (for example comma-list
// joins) so traversal can distinguish sentinel payloads from normal keys.
@internal
final class ValueSentinel with EquatableMixin {
  const ValueSentinel(this.value);

  final dynamic value;

  @override
  List<Object?> get props => [value];
}
