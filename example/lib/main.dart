import 'package:flutter/material.dart';
import 'package:hierarchy_tree/hierarchy_tree.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'hierarchy_tree example — org chart',
      home: Scaffold(
        backgroundColor: const Color(0xfff1f5f9),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: OrgChartExample(),
          ),
        ),
      ),
    );
  }
}

// ===============================================================
// 1. Levels — 4 here, but anywhere from 2 to 12 works. Change the
//    labels/colors/icons to fit any domain: org charts, product
//    catalogs, file systems, regions, whatever your tree represents.
// ===============================================================

final HierarchyLevels orgLevels = HierarchyLevels([
  const HierarchyLevel(
    key: 'company',
    label: 'Company',
    color: Color(0xff4f46e5),
    icon: Icons.business,
  ),
  const HierarchyLevel(
    key: 'department',
    label: 'Department',
    color: Color(0xff0d9488),
    icon: Icons.apartment,
  ),
  const HierarchyLevel(
    key: 'team',
    label: 'Team',
    color: Color(0xfff59e0b),
    icon: Icons.groups,
  ),
  const HierarchyLevel(
    key: 'role',
    label: 'Role',
    color: Color(0xffdb2777),
    icon: Icons.badge,
  ),
]);

// ===============================================================
// 2. Metrics — raw ones summed straight from source rows, derived
//    ones computed with a formula from the aggregated metrics map.
// ===============================================================

final List<MetricDefinition> orgMetrics = [
  const MetricDefinition(
    key: 'headcount',
    label: 'Headcount',
    icon: Icons.people,
    color: Color(0xff4f46e5),
    showOnCard: true,
  ),
  const MetricDefinition(
    key: 'openRoles',
    label: 'Open Roles',
    icon: Icons.person_add_alt,
    color: Color(0xfff59e0b),
    showOnCard: true,
  ),
  const MetricDefinition(
    key: 'budgetUsd',
    label: 'Annual Budget (USD)',
    icon: Icons.attach_money,
    color: Color(0xff0d9488),
    formatter: _currency,
  ),
  MetricDefinition(
    key: 'staffed',
    label: 'Roles Staffed',
    icon: Icons.check_circle,
    color: Colors.green,
    formula: (m) => (m['headcount'] ?? 0) - (m['openRoles'] ?? 0),
  ),
  MetricDefinition(
    key: 'staffingRate',
    label: 'Staffing Rate',
    kind: MetricKind.percent,
    color: Colors.green,
    showAsProgress: true,
    formula: (m) {
      final headcount = m['headcount'] ?? 0;
      if (headcount <= 0) return 0;
      final staffed = headcount - (m['openRoles'] ?? 0);
      return staffed / headcount * 100.0;
    },
  ),
  MetricDefinition(
    key: 'budgetPerHeadRatio',
    label: 'Budget / Head (vs \$250k target)',
    kind: MetricKind.percent,
    color: Colors.blue,
    showAsProgress: true,
    formula: (m) {
      final headcount = m['headcount'] ?? 0;
      if (headcount <= 0) return 0;
      // Normalized against a $250k/head reference point — swap in
      // whatever target makes sense for your own data.
      final perHead = (m['budgetUsd'] ?? 0) / headcount;
      return (perHead / 250000 * 100).clamp(0, 100);
    },
  ),
];

// A trimmed-down metrics list — just one headline number, no progress
// bars. Demonstrates auto card sizing: since `cardHeight` is left unset,
// the card automatically shrinks to fit only what's actually shown here.
final List<MetricDefinition> headcountOnlyMetrics = [
  const MetricDefinition(
    key: 'headcount',
    label: 'Headcount',
    icon: Icons.people,
    color: Color(0xff4f46e5),
    // No showOnCard/showAsProgress flags needed — with a single count
    // metric and autoSelectMetrics left at its default (true), it's
    // auto-picked as the headline number.
  ),
];

String _currency(num value) {
  return '\$${value.round().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m.group(1)},',
      )}';
}

// ===============================================================
// 3. Source rows — one row per (department, team, role). Replace
//    with whatever flat data your backend actually returns.
// ===============================================================

class RoleRow {
  const RoleRow(
    this.department,
    this.team,
    this.role,
    this.headcount,
    this.openRoles,
    this.budgetUsd,
  );

  final String department;
  final String team;
  final String role;
  final int headcount;
  final int openRoles;
  final int budgetUsd;
}

final List<RoleRow> sampleRows = [
  const RoleRow('Engineering', 'Platform', 'Backend Engineer', 12, 2, 2400000),
  const RoleRow('Engineering', 'Platform', 'SRE', 5, 1, 1100000),
  const RoleRow('Engineering', 'Mobile', 'iOS Engineer', 6, 0, 1200000),
  const RoleRow('Engineering', 'Mobile', 'Android Engineer', 6, 1, 1150000),
  const RoleRow('Sales', 'Enterprise', 'Account Executive', 9, 3, 1800000),
  const RoleRow('Sales', 'Enterprise', 'Solutions Engineer', 4, 0, 820000),
  const RoleRow('Sales', 'SMB', 'Account Executive', 14, 2, 2100000),
  const RoleRow('Marketing', 'Growth', 'Growth Marketer', 5, 1, 650000),
  const RoleRow('Marketing', 'Brand', 'Designer', 4, 0, 520000),
];

// ===============================================================
// 4. Wire it up — including search (with prev/next controls via the
//    controller), a theme override, and an orientation toggle.
// ===============================================================

class OrgChartExample extends StatefulWidget {
  const OrgChartExample({super.key});

  @override
  State<OrgChartExample> createState() => _OrgChartExampleState();
}

class _OrgChartExampleState extends State<OrgChartExample> {
  late final HierarchyNode<RoleRow> tree = buildHierarchyTree<RoleRow, RoleRow>(
    rows: sampleRows,
    levels: orgLevels,
    rootName: 'Acme Inc.',
    pathOf: (row) => [row.department, row.team, row.role],
    metricsOf: (row) => {
      'headcount': row.headcount,
      'openRoles': row.openRoles,
      'budgetUsd': row.budgetUsd,
    },
  );

  final HierarchyTreeController<RoleRow> controller = HierarchyTreeController<RoleRow>();
  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';
  TreeOrientation orientation = TreeOrientation.leftToRight;
  bool showAllMetrics = true;

  @override
  void dispose() {
    controller.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search, size: 18),
                  hintText: 'Search by name (e.g. "Engineer")',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
            ),
            const SizedBox(width: 8),
            // Demonstrates auto card sizing: switching to a metrics list
            // with just one headline number and no progress bars shrinks
            // every card automatically — no cardHeight math required.
            FilterChip(
              label: const Text('All metrics'),
              selected: showAllMetrics,
              onSelected: (value) => setState(() => showAllMetrics = value),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: orientation == TreeOrientation.leftToRight
                  ? 'Switch to top-to-bottom'
                  : 'Switch to left-to-right',
              onPressed: () => setState(() {
                orientation = orientation == TreeOrientation.leftToRight
                    ? TreeOrientation.topToBottom
                    : TreeOrientation.leftToRight;
              }),
              icon: Icon(
                orientation == TreeOrientation.leftToRight
                    ? Icons.arrow_downward
                    : Icons.arrow_forward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: HierarchyTreeView<RoleRow>(
            data: tree,
            levels: orgLevels,
            metrics: showAllMetrics ? orgMetrics : headcountOnlyMetrics,
            orientation: orientation,
            // A custom theme, restyled without writing a cardBuilder.
            theme: const HierarchyTheme(
              cardBorderRadius: 16,
              searchMatchBorderColor: Color(0xfff43f5e),
            ),
            // cardHeight intentionally left unset — the card height
            // auto-adjusts to whichever metrics list is active above.
            // Only one department open at a time, like a collapsible sidebar nav.
            exclusiveExpansionLevels: const {1},
            controller: controller,
            searchQuery: searchQuery,
            onSearchResults: (matches) {
              // e.g. update your own "N results" label here if you're not
              // using the toolbar's built-in match indicator.
            },
            // Example: scope a department head to just their own department:
            // access: const HierarchyAccessScope(selectedPath: ['Engineering']),
          ),
        ),
      ],
    );
  }
}
