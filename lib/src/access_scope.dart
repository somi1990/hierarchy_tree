import 'models/hierarchy_access_scope.dart';
import 'models/hierarchy_node.dart';

/// Applies a [HierarchyAccessScope] to [root], producing a new tree where:
///
/// - Nodes along the scope's path are unlocked and expanded.
/// - Sibling branches off the path are visible (for context) but locked,
///   with their children hidden.
/// - Everything below the end of the path is fully unlocked and expanded.
/// - Full access (`scope.isFullAccess`) returns the whole tree unlocked.
///
/// This single function replaces what would otherwise be one hand-written
/// branch per level (Zone-restricted, Division-restricted, Shed-restricted,
/// ...) — it works for any tree depth from 2 to 12 levels.
HierarchyNode<T> applyAccessScope<T>(
  HierarchyNode<T> root,
  HierarchyAccessScope scope,
) {
  if (scope.isFullAccess) {
    return _openSubtree<T>(root);
  }

  return _restrict<T>(root, scope, pathIndex: 0);
}

/// Fully expands and unlocks an entire subtree.
HierarchyNode<T> _openSubtree<T>(HierarchyNode<T> node) {
  return node.copyWith(
    expanded: true,
    locked: false,
    children: node.children.map((child) => _openSubtree<T>(child)).toList(),
  );
}

/// Rebuilds [node]'s children, matching each against
/// `scope.selectedPath[pathIndex]`.
HierarchyNode<T> _restrict<T>(
  HierarchyNode<T> node,
  HierarchyAccessScope scope,
  {required int pathIndex}
) {
  if (pathIndex >= scope.selectedPath.length) {
    // Past the end of the restricted path: everything here is open.
    return _openSubtree<T>(node);
  }

  final String wanted = scope.selectedPath[pathIndex];

  final List<HierarchyNode<T>> newChildren = node.children.map((child) {
    final bool matches = _sameName(child.name, wanted);

    if (!matches) {
      return child.copyWith(
        expanded: false,
        locked: true,
        children: const [],
      );
    }

    return _restrict<T>(
      child,
      scope,
      pathIndex: pathIndex + 1,
    ).copyWith(expanded: true, locked: false);
  }).toList();

  return node.copyWith(expanded: true, locked: false, children: newChildren);
}

bool _sameName(String a, String b) {
  return a.toLowerCase().trim() == b.toLowerCase().trim();
}

/// True if [node] can be expanded/collapsed by the user.
bool canToggleHierarchyNode<T>(HierarchyNode<T> node) {
  return !node.locked && node.children.isNotEmpty;
}

/// Recursively expands every unlocked node in [node].
void expandAllUnlocked<T>(HierarchyNode<T> node) {
  if (!node.locked) node.expanded = true;
  for (final child in node.children) {
    expandAllUnlocked(child);
  }
}

/// Recursively collapses every unlocked node in [node] (root stays open).
void collapseAllUnlocked<T>(HierarchyNode<T> node, {bool isRoot = true}) {
  if (!node.locked) node.expanded = isRoot;
  for (final child in node.children) {
    collapseAllUnlocked(child, isRoot: false);
  }
}

/// Recursively collapses [node] and everything beneath it, ignoring lock
/// state. Used to implement "only one branch open at a time" behavior for
/// exclusive-expansion levels.
void collapseEntireSubtree<T>(HierarchyNode<T> node) {
  node.expanded = false;
  for (final child in node.children) {
    collapseEntireSubtree(child);
  }
}

/// Builds a child-id -> parent-node lookup for the whole tree. Used to find
/// siblings when implementing exclusive expansion (see
/// [HierarchyTreeView.exclusiveExpansionLevels]).
Map<String, HierarchyNode<T>> buildParentMap<T>(HierarchyNode<T> root) {
  final Map<String, HierarchyNode<T>> map = <String, HierarchyNode<T>>{};

  void walk(HierarchyNode<T> node) {
    for (final child in node.children) {
      map[child.id] = node;
      walk(child);
    }
  }

  walk(root);

  return map;
}
