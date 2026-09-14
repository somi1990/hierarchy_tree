import 'package:flutter/material.dart';

import '../models/hierarchy_level.dart';
import '../models/hierarchy_node.dart';
import '../models/hierarchy_theme.dart';
import '../models/metric_definition.dart';

/// Default node card. Renders the level's icon/color, the node name, and
/// whichever rows [headlineMetrics]/[progressMetrics] actually contain —
/// zero, one, or two of each. Fully replaceable via
/// `HierarchyTreeView.cardBuilder`; visually restyled via
/// `HierarchyTreeView.theme` without needing a custom builder.
///
/// [headlineMetrics] and [progressMetrics] should come from
/// `resolveCardMetrics` (see `card_metrics.dart`) so the rows actually
/// rendered here always match the height [size] was computed for.
class HierarchyNodeCard<T> extends StatelessWidget {
  const HierarchyNodeCard({
    super.key,
    required this.node,
    required this.level,
    required this.headlineMetrics,
    required this.progressMetrics,
    required this.size,
    required this.selected,
    required this.canExpand,
    required this.onTap,
    required this.onToggle,
    this.theme = const HierarchyTheme(),
    this.isSearchMatch = false,
  });

  final HierarchyNode<T> node;
  final HierarchyLevel level;

  /// Up to two metrics shown as headline numbers. Pass an empty list to
  /// omit that row entirely — the card shrinks to match (see [size]).
  final List<MetricDefinition> headlineMetrics;

  /// Up to two metrics shown as progress bars. Pass an empty list to omit
  /// that row entirely.
  final List<MetricDefinition> progressMetrics;

  final Size size;
  final bool selected;
  final bool canExpand;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final HierarchyTheme theme;

  /// True if this node currently matches an active search query — drawn
  /// with `theme.searchMatchBorderColor` regardless of selection state.
  final bool isSearchMatch;

  @override
  Widget build(BuildContext context) {
    final Color color = level.color;

    final Color cardColor = node.locked ? theme.lockedCardBackground : theme.cardBackground;

    final Color borderColor = node.locked
        ? theme.lockedBorderColor
        : isSearchMatch
            ? theme.searchMatchBorderColor
            : selected
                ? color
                : color.withValues(alpha: 0.28);

    final double borderWidth =
        selected || isSearchMatch ? theme.selectedBorderWidth : theme.unselectedBorderWidth;

    final bool hasHeadline = headlineMetrics.isNotEmpty;
    final bool hasProgress = progressMetrics.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minWidth: size.width,
          maxWidth: size.width,
          minHeight: size.height,
        ),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: theme.cardPaddingVertical / 2),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(theme.cardBorderRadius),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: theme.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: theme.headerRowHeight),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(level.icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.nameTextStyle.copyWith(
                            color: node.locked
                                ? theme.lockedNameTextColor
                                : theme.nameTextStyle.color,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          level.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.levelLabelTextStyle,
                        ),
                      ],
                    ),
                  ),
                  if (node.locked)
                    Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(Icons.lock_outline, size: 18, color: theme.lockedIconColor),
                    ),
                  if (!node.locked && canExpand)
                    InkWell(
                      onTap: onToggle,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          node.expanded ? Icons.remove_circle : Icons.add_circle,
                          color: color,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (hasHeadline) ...[
              SizedBox(height: theme.rowSpacing),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: theme.headlineRowHeight),
                child: Row(
                  children: [
                    for (int i = 0; i < headlineMetrics.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: _metric(headlineMetrics[i])),
                    ],
                  ],
                ),
              ),
            ],
            if (hasProgress) ...[
              SizedBox(height: theme.rowSpacing),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: theme.progressRowHeight),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < progressMetrics.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: _progress(progressMetrics[i])),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(MetricDefinition def) {
    final num value = node.metric(def);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          def.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.metricLabelTextStyle,
        ),
        const SizedBox(height: 3),
        Text(
          def.format(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: theme.metricValueFontSize,
            height: 1,
            fontWeight: FontWeight.w700,
            color: def.color,
          ),
        ),
      ],
    );
  }

  Widget _progress(MetricDefinition def) {
    final num value = node.metric(def);

    final double progressValue = (value / 100.0).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                def.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 8, height: 1),
              ),
            ),
            Text(
              def.format(value),
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: def.color),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: theme.progressBarHeight,
            backgroundColor: theme.progressBarBackground,
            color: def.color,
          ),
        ),
      ],
    );
  }
}
