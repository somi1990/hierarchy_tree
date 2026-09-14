import 'package:flutter/material.dart';

import '../models/hierarchy_level.dart';
import '../models/hierarchy_node.dart';
import '../models/hierarchy_theme.dart';
import '../models/metric_definition.dart';

/// Default details panel shown for the selected node. Lists every metric
/// definition (count metrics as rows, percent metrics as progress bars).
/// Fully replaceable via `HierarchyTreeView.detailsBuilder`; restyled via
/// `HierarchyTreeView.theme` without needing a custom builder.
class HierarchyDetailsPanel<T> extends StatelessWidget {
  const HierarchyDetailsPanel({
    super.key,
    required this.node,
    required this.level,
    required this.metrics,
    required this.showCloseButton,
    this.onClose,
    this.theme = const HierarchyTheme(),
  });

  final HierarchyNode<T> node;
  final HierarchyLevel level;
  final List<MetricDefinition> metrics;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final HierarchyTheme theme;

  @override
  Widget build(BuildContext context) {
    final Color color = level.color;

    final List<MetricDefinition> counts =
        metrics.where((m) => m.kind == MetricKind.count).toList();

    final List<MetricDefinition> percents =
        metrics.where((m) => m.kind == MetricKind.percent).toList();

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(theme.cardBorderRadius + 1),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(level.icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.nameTextStyle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 3),
                    Text(level.label, style: theme.levelLabelTextStyle.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              if (showCloseButton)
                IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 15),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final def in counts) _countRow(def),
                  if (percents.isNotEmpty) const SizedBox(height: 14),
                  for (int i = 0; i < percents.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    _progressRow(percents[i]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countRow(MetricDefinition def) {
    final num value = node.metric(def);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: def.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (def.icon != null) ...[
            Icon(def.icon, size: 19, color: def.color),
            const SizedBox(width: 10),
          ],
          Expanded(child: Text(def.label, style: const TextStyle(fontSize: 12))),
          Text(
            def.format(value),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: def.color),
          ),
        ],
      ),
    );
  }

  Widget _progressRow(MetricDefinition def) {
    final num value = node.metric(def);

    final double progressValue = (value / 100.0).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(def.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              def.format(value),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: def.color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 9,
            color: def.color,
            backgroundColor: theme.progressBarBackground,
          ),
        ),
      ],
    );
  }
}
