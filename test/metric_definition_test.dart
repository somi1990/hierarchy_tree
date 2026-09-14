import 'package:flutter_test/flutter_test.dart';
import 'package:hierarchy_tree/hierarchy_tree.dart';

void main() {
  group('MetricDefinition.resolve', () {
    test('reads raw value by key when there is no formula', () {
      const def = MetricDefinition(key: 'total', label: 'Total');
      expect(def.resolve({'total': 42}), 42);
    });

    test('missing raw key resolves to 0', () {
      const def = MetricDefinition(key: 'total', label: 'Total');
      expect(def.resolve({}), 0);
    });

    test('formula is computed from the full metrics map', () {
      final def = MetricDefinition(
        key: 'utilization',
        label: 'Utilization',
        kind: MetricKind.percent,
        formula: (m) => (m['used'] ?? 0) / (m['total'] ?? 1) * 100,
      );

      expect(def.resolve({'used': 40, 'total': 80}), 50.0);
    });
  });

  group('MetricDefinition.format', () {
    test('count metrics get thousands separators by default', () {
      const def = MetricDefinition(key: 'total', label: 'Total');
      expect(def.format(1234567), '1,234,567');
    });

    test('percent metrics get one decimal and a % sign by default', () {
      const def = MetricDefinition(
        key: 'rate',
        label: 'Rate',
        kind: MetricKind.percent,
      );
      expect(def.format(42.567), '42.6%');
    });

    test('custom formatter overrides default formatting', () {
      final def = MetricDefinition(
        key: 'cost',
        label: 'Cost',
        formatter: (v) => '\$${v.round()}',
      );
      expect(def.format(999.9), '\$1000');
    });
  });
}
