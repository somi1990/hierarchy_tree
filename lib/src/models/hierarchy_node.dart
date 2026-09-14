import 'metric_definition.dart';

/// A single node anywhere in a hierarchy tree.
///
/// [T] is an optional payload type for any extra per-node data the host app
/// wants to carry (a database row, an API object, ...) — the tree widget
/// itself never reads [data]; it's purely for the host app's own use inside
/// custom node/details builders.
class HierarchyNode<T> {
  HierarchyNode({
    required this.id,
    required this.name,
    required this.levelIndex,
    this.metrics = const <String, num>{},
    this.data,
    List<HierarchyNode<T>>? children,
    this.expanded = true,
    this.locked = false,
  }) : children = children ?? <HierarchyNode<T>>[];

  final String id;

  final String name;

  /// Index into the [HierarchyLevels] this tree was built with. 0 = root.
  final int levelIndex;

  /// Raw numeric metrics carried by this node (e.g. {'total': 100}).
  /// [buildHierarchyTree] sums these automatically up from leaves to root.
  final Map<String, num> metrics;

  /// Optional custom payload, ignored by the widget itself.
  final T? data;

  final List<HierarchyNode<T>> children;

  bool expanded;

  bool locked;

  bool get isLeaf => children.isEmpty;

  num metric(MetricDefinition def) => def.resolve(metrics);

  HierarchyNode<T> copyWith({
    List<HierarchyNode<T>>? children,
    bool? expanded,
    bool? locked,
  }) {
    return HierarchyNode<T>(
      id: id,
      name: name,
      levelIndex: levelIndex,
      metrics: metrics,
      data: data,
      children: children ?? this.children,
      expanded: expanded ?? this.expanded,
      locked: locked ?? this.locked,
    );
  }
}
