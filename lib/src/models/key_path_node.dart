import 'package:meta/meta.dart' show internal;

/// Logically immutable linked node representation of an encoder key path.
///
/// Structure is fixed at construction time via [KeyPathNode._] (`_parent`,
/// `_segment`, `_depth`). `_dotEncoded` and `_materialized` are lazily-populated
/// mutable caches that do not change a node's structural identity.
///
/// Paths are rendered lazily so deep traversals only materialize key strings
/// at leaf emission points.
@internal
final class KeyPathNode {
  KeyPathNode._(this._parent, this._segment)
      : _depth = (_parent?._depth ?? 0) + 1;

  final KeyPathNode? _parent;
  final String _segment;
  final int _depth;

  KeyPathNode? _dotEncoded;
  String? _materialized;

  static KeyPathNode fromMaterialized(String value) =>
      KeyPathNode._(null, value);

  KeyPathNode append(String segment) =>
      segment.isEmpty ? this : KeyPathNode._(this, segment);

  /// Returns a cached view with every literal dot replaced by `%2E`.
  KeyPathNode asDotEncoded() {
    final KeyPathNode? cached = _dotEncoded;
    if (cached != null) {
      return cached;
    }

    final List<KeyPathNode> uncached = [];
    KeyPathNode? cursor = this;
    while (cursor != null && cursor._dotEncoded == null) {
      uncached.add(cursor);
      cursor = cursor._parent;
    }

    KeyPathNode? encodedParent = cursor?._dotEncoded;
    for (int i = uncached.length - 1; i >= 0; i--) {
      final KeyPathNode node = uncached[i];
      final String encodedSegment = _replaceDots(node._segment);
      final KeyPathNode? nodeParent = node._parent;
      final KeyPathNode encodedNode = switch (nodeParent) {
        null => identical(encodedSegment, node._segment)
            ? node
            : KeyPathNode._(null, encodedSegment),
        final KeyPathNode parent => identical(encodedParent, parent) &&
                identical(encodedSegment, node._segment)
            ? node
            : KeyPathNode._(encodedParent, encodedSegment),
      };

      node._dotEncoded = encodedNode;
      encodedParent = encodedNode;
    }

    // Safe: when this method starts uncached, `this` is included in `uncached`,
    // and the rebuild loop always assigns `node._dotEncoded`.
    return _dotEncoded!;
  }

  /// Materializes the full path once and caches it.
  String materialize() {
    final String? cached = _materialized;
    if (cached != null) return cached;

    final KeyPathNode? parent = _parent;
    if (parent == null) {
      _materialized = _segment;
      // Safe: root branch assigns `_materialized` immediately above.
      return _materialized!;
    }

    if (_depth == 2) {
      final String parentSegment = parent._materialized ?? parent._segment;
      _materialized = '$parentSegment$_segment';
      // Safe: depth-2 fast path assigns `_materialized` immediately above.
      return _materialized!;
    }

    final List<KeyPathNode> suffixNodes = [];
    KeyPathNode? current = this;
    String base = '';
    while (current != null) {
      final String? cachedCurrent = current._materialized;
      if (cachedCurrent != null) {
        base = cachedCurrent;
        break;
      }
      suffixNodes.add(current);
      current = current._parent;
    }

    final StringBuffer out = StringBuffer(base);
    for (int i = suffixNodes.length - 1; i >= 0; i--) {
      final KeyPathNode node = suffixNodes[i];
      out.write(node._segment);
      node._materialized ??= out.toString();
    }

    // Safe: this node is part of suffixNodes when uncached, so the loop above
    // always initializes `_materialized` before this return.
    return _materialized!;
  }

  static String _replaceDots(String value) =>
      value.contains('.') ? value.replaceAll('.', '%2E') : value;
}
