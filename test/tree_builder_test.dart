import 'package:flutter_test/flutter_test.dart';
import 'package:hierarchy_tree/hierarchy_tree.dart';

class _Row {
  const _Row(this.a, this.b, this.value);
  final String a;
  final String b;
  final int value;
}

void main() {
  final levels = HierarchyLevels([
    const HierarchyLevel(key: 'root', label: 'Root'),
    const HierarchyLevel(key: 'a', label: 'A'),
    const HierarchyLevel(key: 'b', label: 'B'),
  ]);

  group('buildHierarchyTree', () {
    test('groups rows into the right levels', () {
      final rows = [
        const _Row('X', 'X1', 10),
        const _Row('X', 'X2', 5),
        const _Row('Y', 'Y1', 7),
      ];

      final tree = buildHierarchyTree<_Row, _Row>(
        rows: rows,
        levels: levels,
        rootName: 'All',
        pathOf: (r) => [r.a, r.b],
        metricsOf: (r) => {'value': r.value},
      );

      expect(tree.name, 'All');
      expect(tree.levelIndex, 0);
      expect(tree.children.map((c) => c.name).toSet(), {'X', 'Y'});

      final x = tree.children.firstWhere((c) => c.name == 'X');
      expect(x.children.map((c) => c.name).toSet(), {'X1', 'X2'});
      expect(x.levelIndex, 1);

      final x1 = x.children.firstWhere((c) => c.name == 'X1');
      expect(x1.levelIndex, 2);
      expect(x1.metrics['value'], 10);
      expect(x1.isLeaf, isTrue);
    });

    test('aggregates metrics up the tree', () {
      final rows = [
        const _Row('X', 'X1', 10),
        const _Row('X', 'X2', 5),
        const _Row('Y', 'Y1', 7),
      ];

      final tree = buildHierarchyTree<_Row, _Row>(
        rows: rows,
        levels: levels,
        rootName: 'All',
        pathOf: (r) => [r.a, r.b],
        metricsOf: (r) => {'value': r.value},
      );

      final x = tree.children.firstWhere((c) => c.name == 'X');
      expect(x.metrics['value'], 15); // 10 + 5
      expect(tree.metrics['value'], 22); // 10 + 5 + 7
    });

    test('root starts expanded, leaves start collapsed', () {
      final rows = [const _Row('X', 'X1', 10)];

      final tree = buildHierarchyTree<_Row, _Row>(
        rows: rows,
        levels: levels,
        rootName: 'All',
        pathOf: (r) => [r.a, r.b],
        metricsOf: (r) => {'value': r.value},
      );

      expect(tree.expanded, isTrue);
      final leaf = tree.children.first.children.first;
      expect(leaf.expanded, isFalse);
    });

    test('throws when pathOf returns the wrong number of segments', () {
      final rows = [const _Row('X', 'X1', 10)];

      expect(
        () => buildHierarchyTree<_Row, _Row>(
          rows: rows,
          levels: levels,
          rootName: 'All',
          pathOf: (r) => [r.a], // should be 2 segments, not 1
          metricsOf: (r) => {'value': r.value},
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
