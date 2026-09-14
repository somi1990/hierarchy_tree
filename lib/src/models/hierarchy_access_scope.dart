/// Describes how much of a hierarchy tree a given user may see and interact
/// with, independent of how many levels the tree has.
///
/// [selectedPath] gives the chosen node *name* at each level below the root,
/// in order. Levels beyond the path are shown but locked (visible for
/// context, not expandable); levels along the path are open; levels past
/// the end of the path are fully open.
///
/// For a tree with levels `[Region, Department, Team, Role]`:
///   - Full access:            `HierarchyAccessScope()`
///   - Scoped to a Region:     `HierarchyAccessScope(selectedPath: ['EMEA'])`
///   - Scoped to a Department: `HierarchyAccessScope(selectedPath: ['EMEA', 'Sales'])`
///   - Scoped to a Team:       `HierarchyAccessScope(selectedPath: ['EMEA', 'Sales', 'Enterprise'])`
class HierarchyAccessScope {
  const HierarchyAccessScope({this.selectedPath = const <String>[]});

  final List<String> selectedPath;

  bool get isFullAccess => selectedPath.isEmpty;

  /// The deepest level index (1 = first level below root) this scope pins.
  int get scopedLevelIndex => selectedPath.length;
}
