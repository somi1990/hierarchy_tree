import 'package:flutter/material.dart';

/// Describes one level of a hierarchy (e.g. "Region", "Department", "Team").
///
/// Levels are ordered root -> leaf. Level 0 is always the single implicit
/// root of the tree (e.g. "Company", "Indian Railways", "World").
class HierarchyLevel {
  const HierarchyLevel({
    required this.key,
    required this.label,
    this.pluralLabel,
    this.color = const Color(0xff64748b),
    this.icon = Icons.circle,
  });

  /// Unique, stable identifier for this level (e.g. 'region'). Used to look
  /// up levels programmatically and must not change once data is built.
  final String key;

  /// Display name for a single node at this level (e.g. 'Region').
  final String label;

  /// Optional plural form for summaries (e.g. 'Regions'). Defaults to
  /// [label] with no pluralization applied.
  final String? pluralLabel;

  final Color color;

  final IconData icon;

  String get displayPlural => pluralLabel ?? label;
}

/// The full, ordered set of levels that make up a hierarchy tree.
///
/// Must contain between 2 and 12 levels (inclusive). Level 0 is the root;
/// every tree built with these levels has exactly one root node.
class HierarchyLevels {
  HierarchyLevels(this.levels)
      : assert(
          levels.length >= 2 && levels.length <= 12,
          'HierarchyLevels supports 2 to 12 levels (got ${levels.length}).',
        );

  final List<HierarchyLevel> levels;

  int get depth => levels.length;

  HierarchyLevel operator [](int index) => levels[index];

  int indexOfKey(String key) => levels.indexWhere((l) => l.key == key);
}
