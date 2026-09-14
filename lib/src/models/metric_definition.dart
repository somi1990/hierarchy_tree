import 'package:flutter/material.dart';

enum MetricKind { count, percent }

typedef MetricFormula = num Function(Map<String, num> metrics);

typedef MetricFormatter = String Function(num value);

/// Describes one numeric metric that can be shown on a node card and/or in
/// the details panel.
///
/// A metric with no [formula] is read directly from a node's raw `metrics`
/// map (e.g. a value summed up from source rows, like "total units"). A
/// metric with a [formula] is derived from other metrics at read time (e.g.
/// "utilization % = inUse / available * 100") and is recomputed automatically
/// as parent nodes aggregate their children.
class MetricDefinition {
  const MetricDefinition({
    required this.key,
    required this.label,
    this.kind = MetricKind.count,
    this.icon,
    this.color = const Color(0xff2563eb),
    this.formula,
    this.showOnCard = false,
    this.showAsProgress = false,
    this.formatter,
  });

  /// Unique key. For raw metrics this must match the key used in the node's
  /// `metrics` map; for derived metrics it's just an identifier.
  final String key;

  final String label;

  final MetricKind kind;

  final IconData? icon;

  final Color color;

  /// If set, the value is computed from other metrics rather than read
  /// directly. Formulas always receive the *fully aggregated* metrics map
  /// for that node (i.e. summed over all descendants for non-leaf nodes).
  final MetricFormula? formula;

  /// Show as one of the up-to-two headline numbers on the compact node card.
  final bool showOnCard;

  /// Show as one of the up-to-two progress bars on the compact node card.
  /// Only meaningful for [MetricKind.percent] metrics.
  final bool showAsProgress;

  /// Custom display formatting. Defaults to a thousands-separated integer
  /// for [MetricKind.count] and `NN.N%` for [MetricKind.percent].
  final MetricFormatter? formatter;

  num resolve(Map<String, num> metrics) {
    if (formula != null) return formula!(metrics);
    return metrics[key] ?? 0;
  }

  String format(num value) {
    if (formatter != null) return formatter!(value);
    if (kind == MetricKind.percent) return '${value.toStringAsFixed(1)}%';
    return value
        .round()
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m.group(1)},',
        );
  }
}
