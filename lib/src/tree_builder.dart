import 'models/hierarchy_level.dart';
import 'models/hierarchy_node.dart';

/// Builds a [HierarchyNode] tree from a flat list of rows of any shape [R].
///
/// [pathOf] must return exactly `levels.depth - 1` names for [row] — one per
/// level below the root (the root itself is implicit and singular). For a
/// 5-level config `[Company, Zone, Division, Shed, CoachType]`, `pathOf`
/// returns 4 strings: `[zone, division, shed, coachType]`.
///
/// [metricsOf] returns the raw numeric contribution of [row] at its leaf;
/// these are summed automatically at every ancestor level.
HierarchyNode<T> buildHierarchyTree<T, R>({
  required List<R> rows,
  required HierarchyLevels levels,
  required List<String> Function(R row) pathOf,
  required Map<String, num> Function(R row) metricsOf,
  String rootId = 'root',
  required String rootName,
}) {
  final _GroupNode<R> root = _GroupNode<R>(rootId, rootName);

  for (final R row in rows) {
    final List<String> path = pathOf(row);

    assert(
      path.length == levels.depth - 1,
      'pathOf must return exactly ${levels.depth - 1} segments '
      '(one per level below the root), got ${path.length}.',
    );

    _GroupNode<R> current = root;

    for (final String segment in path) {
      current = current.child(segment);
    }

    current.rows.add(row);
  }

  return _toHierarchyNode<T, R>(root, 0, metricsOf);
}

class _GroupNode<R> {
  _GroupNode(this.id, this.name);

  final String id;

  final String name;

  final List<R> rows = <R>[];

  final Map<String, _GroupNode<R>> _children = <String, _GroupNode<R>>{};

  _GroupNode<R> child(String name) {
    return _children.putIfAbsent(
      name,
      () => _GroupNode<R>('$id-$name', name),
    );
  }

  Iterable<_GroupNode<R>> get children => _children.values;
}

HierarchyNode<T> _toHierarchyNode<T, R>(
  _GroupNode<R> group,
  int levelIndex,
  Map<String, num> Function(R row) metricsOf,
) {
  // Leaf: sum the rows collected directly under this group.
  if (group.children.isEmpty) {
    final Map<String, num> metrics = <String, num>{};

    for (final R row in group.rows) {
      metricsOf(row).forEach((String k, num v) {
        metrics[k] = (metrics[k] ?? 0) + v;
      });
    }

    return HierarchyNode<T>(
      id: group.id,
      name: group.name,
      levelIndex: levelIndex,
      metrics: metrics,
      expanded: false,
    );
  }

  final List<HierarchyNode<T>> children = group.children
      .map((c) => _toHierarchyNode<T, R>(c, levelIndex + 1, metricsOf))
      .toList();

  final Map<String, num> metrics = <String, num>{};

  for (final HierarchyNode<T> child in children) {
    child.metrics.forEach((String k, num v) {
      metrics[k] = (metrics[k] ?? 0) + v;
    });
  }

  return HierarchyNode<T>(
    id: group.id,
    name: group.name,
    levelIndex: levelIndex,
    metrics: metrics,
    children: children,
    expanded: levelIndex == 0,
  );
}
