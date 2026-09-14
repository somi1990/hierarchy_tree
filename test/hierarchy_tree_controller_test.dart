import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hierarchy_tree/hierarchy_tree.dart';

HierarchyNode<void> _leaf(String id, int level) =>
    HierarchyNode<void>(id: id, name: id, levelIndex: level, expanded: false);

HierarchyNode<void> _buildSampleTree() {
  return HierarchyNode<void>(
    id: 'root',
    name: 'Root',
    levelIndex: 0,
    children: [
      HierarchyNode<void>(
        id: 'A',
        name: 'Alpha',
        levelIndex: 1,
        children: [_leaf('A1', 2), _leaf('A2', 2)],
      ),
      HierarchyNode<void>(
        id: 'B',
        name: 'Beta',
        levelIndex: 1,
        children: [_leaf('B1', 2)],
      ),
    ],
  );
}

final HierarchyLevels _levels = HierarchyLevels([
  const HierarchyLevel(key: 'root', label: 'Root'),
  const HierarchyLevel(key: 'group', label: 'Group'),
  const HierarchyLevel(key: 'item', label: 'Item'),
]);

/// A small host widget so tests can update `searchQuery` via [setQuery] and
/// exercise HierarchyTreeView.didUpdateWidget.
class _Harness extends StatefulWidget {
  const _Harness({required this.controller});

  final HierarchyTreeController<void> controller;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  String? query;

  /// Public wrapper so tests can update [query] without reaching into
  /// [State.setState], which is protected and only callable from within a
  /// State subclass's own instance methods.
  void setQuery(String? value) {
    setState(() => query = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1000,
          height: 800,
          child: HierarchyTreeView<void>(
            data: _buildSampleTree(),
            levels: _levels,
            metrics: const [],
            controller: widget.controller,
            searchQuery: query,
            showDetailsPanel: false,
          ),
        ),
      ),
    );
  }
}

void main() {
  group('HierarchyTreeController', () {
    testWidgets('selectNode updates controller.selectedNode', (tester) async {
      final controller = HierarchyTreeController<void>();
      await tester.pumpWidget(_Harness(controller: controller));
      await tester.pumpAndSettle();

      expect(controller.isAttached, isTrue);
      expect(controller.selectedNode, isNull);

      controller.selectNode('A1');
      await tester.pumpAndSettle();

      expect(controller.selectedNode?.id, 'A1');
    });

    testWidgets('expandNode / collapseNode reveal and hide children', (tester) async {
      final controller = HierarchyTreeController<void>();
      await tester.pumpWidget(_Harness(controller: controller));
      await tester.pumpAndSettle();

      // Force a known state via the controller regardless of the tree's
      // initial expansion (full access opens every node by default).
      controller.collapseNode('A');
      await tester.pumpAndSettle();
      expect(find.text('A1'), findsNothing);

      controller.expandNode('A');
      await tester.pumpAndSettle();
      expect(find.text('A1'), findsOneWidget);
    });

    testWidgets('detaches cleanly on dispose without throwing', (tester) async {
      final controller = HierarchyTreeController<void>();
      await tester.pumpWidget(_Harness(controller: controller));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      expect(controller.isAttached, isFalse);
      // Should no-op rather than throw once detached.
      expect(() => controller.selectNode('A1'), returnsNormally);
    });
  });

  group('search', () {
    testWidgets('finds matches, expands ancestors, and highlights them', (tester) async {
      final controller = HierarchyTreeController<void>();
      await tester.pumpWidget(_Harness(controller: controller));
      await tester.pumpAndSettle();

      final harnessState = tester.state<_HarnessState>(find.byType(_Harness));
      harnessState.setQuery('A1');
      await tester.pumpAndSettle();

      expect(controller.matches.map((n) => n.id), ['A1']);
      expect(controller.currentMatchIndex, 0);
      // Ancestor "A" must have been auto-expanded so A1 is actually visible.
      expect(find.text('A1'), findsOneWidget);
    });

    testWidgets('nextMatch/previousMatch cycle through results', (tester) async {
      final controller = HierarchyTreeController<void>();
      await tester.pumpWidget(_Harness(controller: controller));
      await tester.pumpAndSettle();

      final harnessState = tester.state<_HarnessState>(find.byType(_Harness));
      // Matches both group nodes by a shared prefix search on their ids.
      harnessState.setQuery('A');
      await tester.pumpAndSettle();

      expect(controller.matches.length, greaterThanOrEqualTo(2));
      final firstId = controller.matches[0].id;

      controller.nextMatch();
      await tester.pumpAndSettle();
      expect(controller.currentMatchIndex, 1);
      expect(controller.matches[controller.currentMatchIndex].id, isNot(firstId));

      controller.previousMatch();
      await tester.pumpAndSettle();
      expect(controller.currentMatchIndex, 0);
    });

    testWidgets('clearing the query resets matches', (tester) async {
      final controller = HierarchyTreeController<void>();
      await tester.pumpWidget(_Harness(controller: controller));
      await tester.pumpAndSettle();

      final harnessState = tester.state<_HarnessState>(find.byType(_Harness));
      harnessState.setQuery('A1');
      await tester.pumpAndSettle();
      expect(controller.matches, isNotEmpty);

      harnessState.setQuery(null);
      await tester.pumpAndSettle();
      expect(controller.matches, isEmpty);
      expect(controller.currentMatchIndex, -1);
    });
  });
}
