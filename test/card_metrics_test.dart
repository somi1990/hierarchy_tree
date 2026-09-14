import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hierarchy_tree/hierarchy_tree.dart';

void main() {
  const count1 = MetricDefinition(key: 'a', label: 'A');
  const count2 = MetricDefinition(key: 'b', label: 'B');
  const count3 = MetricDefinition(key: 'c', label: 'C');
  const percent1 = MetricDefinition(key: 'p1', label: 'P1', kind: MetricKind.percent);
  const percent2 = MetricDefinition(key: 'p2', label: 'P2', kind: MetricKind.percent);

  group('resolveHeadlineMetrics', () {
    test('respects explicit showOnCard flags exactly, even just one', () {
      const explicitOne = MetricDefinition(key: 'x', label: 'X', showOnCard: true);
      final result = resolveHeadlineMetrics([explicitOne, count1, count2]);
      expect(result, [explicitOne]);
    });

    test('caps explicit flags at two even if three are flagged', () {
      const a = MetricDefinition(key: 'a', label: 'A', showOnCard: true);
      const b = MetricDefinition(key: 'b', label: 'B', showOnCard: true);
      const c = MetricDefinition(key: 'c', label: 'C', showOnCard: true);
      final result = resolveHeadlineMetrics([a, b, c]);
      expect(result.length, 2);
      expect(result, [a, b]);
    });

    test('auto-picks up to two count metrics when nothing is flagged', () {
      final result = resolveHeadlineMetrics([count1, count2, count3, percent1]);
      expect(result, [count1, count2]);
    });

    test('auto-picking ignores percent metrics', () {
      final result = resolveHeadlineMetrics([percent1, percent2]);
      expect(result, isEmpty);
    });

    test('autoSelect: false shows nothing when nothing is flagged', () {
      final result = resolveHeadlineMetrics([count1, count2], autoSelect: false);
      expect(result, isEmpty);
    });

    test('a single unflagged count metric auto-resolves to one headline', () {
      final result = resolveHeadlineMetrics([count1]);
      expect(result, [count1]);
    });
  });

  group('resolveProgressMetrics', () {
    test('respects explicit showAsProgress flags', () {
      final result = resolveProgressMetrics([percent1, percent2, count1]);
      // Neither percent1 nor percent2 is explicitly flagged here, so this
      // exercises the auto-fallback instead — see next test for explicit.
      expect(result, [percent1, percent2]);
    });

    test('explicit flag wins even over other percent metrics', () {
      const flagged = MetricDefinition(
        key: 'p3',
        label: 'P3',
        kind: MetricKind.percent,
        showAsProgress: true,
      );
      final result = resolveProgressMetrics([percent1, percent2, flagged]);
      expect(result, [flagged]);
    });

    test('auto-picking ignores count metrics', () {
      final result = resolveProgressMetrics([count1, count2]);
      expect(result, isEmpty);
    });
  });

  group('resolveCardSize', () {
    const theme = HierarchyTheme();

    test('explicit cardHeight always wins, ignoring row presence', () {
      final size = resolveCardSize(
        theme: theme,
        cardWidth: 180,
        cardHeight: 60,
        hasHeadline: true,
        hasProgress: true,
      );
      expect(size, const Size(180, 60));
    });

    test('header-only card is the shortest', () {
      final size = resolveCardSize(
        theme: theme,
        cardWidth: 200,
        hasHeadline: false,
        hasProgress: false,
      );
      expect(size.height, theme.cardPaddingVertical + theme.headerRowHeight);
    });

    test('adding a headline row grows the height by rowSpacing + headlineRowHeight', () {
      final withoutHeadline = resolveCardSize(
        theme: theme,
        cardWidth: 200,
        hasHeadline: false,
        hasProgress: false,
      );
      final withHeadline = resolveCardSize(
        theme: theme,
        cardWidth: 200,
        hasHeadline: true,
        hasProgress: false,
      );
      expect(
        withHeadline.height - withoutHeadline.height,
        theme.rowSpacing + theme.headlineRowHeight,
      );
    });

    test('both rows present matches the original fixed default of 126', () {
      final size = resolveCardSize(
        theme: theme,
        cardWidth: 200,
        hasHeadline: true,
        hasProgress: true,
      );
      expect(size.height, 126.0);
    });
  });

  group('resolveCardMetrics', () {
    test('bundles headline, progress, and a matching auto-computed size', () {
      const theme = HierarchyTheme();
      final resolved = resolveCardMetrics(
        metrics: [count1],
        theme: theme,
        cardWidth: 200,
      );

      expect(resolved.headline, [count1]);
      expect(resolved.progress, isEmpty);
      expect(resolved.size.height, theme.cardPaddingVertical + theme.headerRowHeight + theme.rowSpacing + theme.headlineRowHeight);
    });

    test('empty metrics list shrinks to header-only height', () {
      const theme = HierarchyTheme();
      final resolved = resolveCardMetrics(metrics: const [], theme: theme, cardWidth: 200);

      expect(resolved.headline, isEmpty);
      expect(resolved.progress, isEmpty);
      expect(resolved.size.height, theme.cardPaddingVertical + theme.headerRowHeight);
    });
  });
}
