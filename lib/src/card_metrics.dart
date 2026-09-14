import 'package:flutter/material.dart';

import 'models/hierarchy_theme.dart';
import 'models/metric_definition.dart';

/// Resolves which metrics to show as the up-to-two headline numbers on a
/// card.
///
/// If any metric explicitly opts in via `showOnCard`, only those are used
/// (respecting the choice exactly, even if it's just one — no padding up
/// to two). Otherwise, when [autoSelect] is true (the default), up to two
/// `MetricKind.count` metrics are auto-picked in list order so a card never
/// renders blank just because nothing was flagged. Pass `autoSelect: false`
/// to opt out and show nothing unless explicitly flagged.
List<MetricDefinition> resolveHeadlineMetrics(
  List<MetricDefinition> metrics, {
  bool autoSelect = true,
}) {
  final List<MetricDefinition> explicit =
      metrics.where((m) => m.showOnCard).take(2).toList();

  if (explicit.isNotEmpty || !autoSelect) return explicit;

  return metrics.where((m) => m.kind == MetricKind.count).take(2).toList();
}

/// Same idea as [resolveHeadlineMetrics], for the up-to-two progress bars
/// (`showAsProgress`), falling back to auto-picking up to two
/// `MetricKind.percent` metrics.
List<MetricDefinition> resolveProgressMetrics(
  List<MetricDefinition> metrics, {
  bool autoSelect = true,
}) {
  final List<MetricDefinition> explicit =
      metrics.where((m) => m.showAsProgress).take(2).toList();

  if (explicit.isNotEmpty || !autoSelect) return explicit;

  return metrics.where((m) => m.kind == MetricKind.percent).take(2).toList();
}

/// Computes the card size to use across the whole tree.
///
/// If [cardHeight] is given explicitly, it wins outright — no
/// auto-computation, full manual control. Otherwise the height is derived
/// from [theme]'s row-height constants and which rows are actually present
/// (a card with no progress metrics is shorter than one with; a card with
/// neither headline nor progress metrics shrinks to just its header row).
Size resolveCardSize({
  required HierarchyTheme theme,
  required double cardWidth,
  double? cardHeight,
  required bool hasHeadline,
  required bool hasProgress,
}) {
  if (cardHeight != null) return Size(cardWidth, cardHeight);

  double height = theme.cardPaddingVertical + theme.headerRowHeight;

  if (hasHeadline) height += theme.rowSpacing + theme.headlineRowHeight;
  if (hasProgress) height += theme.rowSpacing + theme.progressRowHeight;

  return Size(cardWidth, height);
}

/// Bundles the resolved headline metrics, progress metrics, and final card
/// size for one tree — computed once per build and reused by the layout
/// algorithm, the edge painter, and the card widget so they can never
/// disagree with each other.
class ResolvedCardMetrics {
  const ResolvedCardMetrics({
    required this.headline,
    required this.progress,
    required this.size,
  });

  final List<MetricDefinition> headline;
  final List<MetricDefinition> progress;
  final Size size;
}

ResolvedCardMetrics resolveCardMetrics({
  required List<MetricDefinition> metrics,
  required HierarchyTheme theme,
  required double cardWidth,
  double? cardHeight,
  bool autoSelect = true,
}) {
  final List<MetricDefinition> headline =
      resolveHeadlineMetrics(metrics, autoSelect: autoSelect);

  final List<MetricDefinition> progress =
      resolveProgressMetrics(metrics, autoSelect: autoSelect);

  final Size size = resolveCardSize(
    theme: theme,
    cardWidth: cardWidth,
    cardHeight: cardHeight,
    hasHeadline: headline.isNotEmpty,
    hasProgress: progress.isNotEmpty,
  );

  return ResolvedCardMetrics(headline: headline, progress: progress, size: size);
}
