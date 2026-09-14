import 'package:flutter_test/flutter_test.dart';
import 'package:hierarchy_tree/hierarchy_tree.dart';

HierarchyNode<void> _leaf(String id, int level) =>
    HierarchyNode<void>(id: id, name: id, levelIndex: level, expanded: false);

HierarchyNode<void> _buildSampleTree() {
  // root
  //  ├─ A (level 1)
  //  │   ├─ A1 (level 2)
  //  │   └─ A2 (level 2)
  //  └─ B (level 1)
  //      └─ B1 (level 2)
  return HierarchyNode<void>(
    id: 'root',
    name: 'root',
    levelIndex: 0,
    children: [
      HierarchyNode<void>(
        id: 'A',
        name: 'A',
        levelIndex: 1,
        children: [_leaf('A1', 2), _leaf('A2', 2)],
      ),
      HierarchyNode<void>(
        id: 'B',
        name: 'B',
        levelIndex: 1,
        children: [_leaf('B1', 2)],
      ),
    ],
  );
}

void main() {
  group('applyAccessScope', () {
    test('full access unlocks and expands everything', () {
      final tree = _buildSampleTree();
      final result = applyAccessScope(tree, const HierarchyAccessScope());

      expect(result.locked, isFalse);
      expect(result.expanded, isTrue);
      for (final child in result.children) {
        expect(child.locked, isFalse);
        expect(child.expanded, isTrue);
        for (final grandchild in child.children) {
          expect(grandchild.locked, isFalse);
          expect(grandchild.expanded, isTrue);
        }
      }
    });

    test('scoped path unlocks the matching branch, locks siblings', () {
      final tree = _buildSampleTree();
      final result = applyAccessScope(
        tree,
        const HierarchyAccessScope(selectedPath: ['A']),
      );

      final a = result.children.firstWhere((c) => c.id == 'A');
      final b = result.children.firstWhere((c) => c.id == 'B');

      expect(a.locked, isFalse);
      expect(a.expanded, isTrue);
      expect(a.children, isNotEmpty); // full subtree preserved

      expect(b.locked, isTrue);
      expect(b.expanded, isFalse);
      expect(b.children, isEmpty); // children hidden
    });

    test('match is case-insensitive and trims whitespace', () {
      final tree = _buildSampleTree();
      final result = applyAccessScope(
        tree,
        const HierarchyAccessScope(selectedPath: [' a ']),
      );

      final a = result.children.firstWhere((c) => c.id == 'A');
      expect(a.locked, isFalse);
    });

    test('deeper scope leaves everything past it fully open', () {
      final tree = _buildSampleTree();
      final result = applyAccessScope(
        tree,
        const HierarchyAccessScope(selectedPath: ['A']),
      );

      final a = result.children.firstWhere((c) => c.id == 'A');
      for (final grandchild in a.children) {
        expect(grandchild.locked, isFalse);
        expect(grandchild.expanded, isTrue);
      }
    });
  });

  group('canToggleHierarchyNode', () {
    test('false when locked', () {
      final node = HierarchyNode<void>(
        id: 'x',
        name: 'x',
        levelIndex: 1,
        locked: true,
        children: [_leaf('y', 2)],
      );
      expect(canToggleHierarchyNode(node), isFalse);
    });

    test('false when no children', () {
      final node = _leaf('x', 1);
      expect(canToggleHierarchyNode(node), isFalse);
    });

    test('true when unlocked with children', () {
      final node = HierarchyNode<void>(
        id: 'x',
        name: 'x',
        levelIndex: 1,
        children: [_leaf('y', 2)],
      );
      expect(canToggleHierarchyNode(node), isTrue);
    });
  });

  group('expandAllUnlocked / collapseAllUnlocked', () {
    test('expand opens every unlocked node, skips locked ones', () {
      final tree = _buildSampleTree();
      tree.children.first.expanded = false; // start "A" collapsed...
      tree.children.first.locked = true; //    ...then lock it

      expandAllUnlocked(tree);

      expect(tree.expanded, isTrue);
      // Locked nodes are skipped entirely, not forced open — "A" stays
      // exactly as it was before the call.
      expect(tree.children.first.expanded, isFalse);
      expect(tree.children.last.expanded, isTrue);
    });

    test('collapse closes every unlocked node but keeps root open', () {
      final tree = _buildSampleTree();
      expandAllUnlocked(tree);

      collapseAllUnlocked(tree);

      expect(tree.expanded, isTrue); // root stays open
      expect(tree.children.first.expanded, isFalse);
      expect(tree.children.last.expanded, isFalse);
    });
  });

  group('buildParentMap', () {
    test('maps every child id to its direct parent', () {
      final tree = _buildSampleTree();
      final map = buildParentMap(tree);

      expect(map['A']!.id, 'root');
      expect(map['B']!.id, 'root');
      expect(map['A1']!.id, 'A');
      expect(map['B1']!.id, 'B');
      expect(map.containsKey('root'), isFalse);
    });
  });
}
