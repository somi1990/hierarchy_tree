import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hierarchy_tree/hierarchy_tree.dart';

void main() {
  group('HierarchyTheme', () {
    test('default constructor has comfortable density', () {
      const theme = HierarchyTheme();
      expect(theme.density, HierarchyDensity.comfortable);
      expect(theme.cardBorderRadius, 13.0);
    });

    test('dense() preset uses compact density and smaller sizing', () {
      final dense = HierarchyTheme.dense();
      final comfortable = const HierarchyTheme();

      expect(dense.density, HierarchyDensity.compact);
      expect(dense.metricValueFontSize, lessThan(comfortable.metricValueFontSize));
      expect(dense.progressBarHeight, lessThan(comfortable.progressBarHeight));
    });

    test('copyWith overrides only the given fields', () {
      const base = HierarchyTheme();
      final updated = base.copyWith(cardBorderRadius: 20, searchMatchBorderColor: Colors.red);

      expect(updated.cardBorderRadius, 20);
      expect(updated.searchMatchBorderColor, Colors.red);
      // Untouched fields fall back to the original.
      expect(updated.progressBarHeight, base.progressBarHeight);
      expect(updated.density, base.density);
    });
  });
}
