# hierarchy_tree

A generic, zoomable, pannable hierarchy tree widget for Flutter — for org
charts, asset trees, category trees, file systems, or any other parent/child
data.

**Features:**
- **2 to 12 user-defined levels**, each with its own color, icon, and label
- Fully custom, formula-derived **metrics**, shown as headline numbers and/or progress bars
- **Auto-sizing cards** — height adapts to whichever metrics you actually show, with full manual override available
- **Theming** via `HierarchyTheme`, including a built-in dense preset
- **Left-to-right or top-to-bottom** orientation
- **Search** — highlight matches, auto-expand their ancestors, jump between results
- **Programmatic control** via `HierarchyTreeController` — center/expand/collapse/select by id from outside the widget
- **Pluggable access-scope locking** — restrict a user to their own branch while keeping siblings visible-but-locked
- Click-to-center navigation, fully overridable card and details-panel builders

Nothing about a specific domain (railways, companies, folders, ...) is
hardcoded — the whole tree is configured through plain data:

- `HierarchyLevels` — the ordered list of levels (2 to 12), each with its
  own `label`, `color`, and `icon`.
- `MetricDefinition` — the numeric metrics shown per node, either read
  straight from source data or computed with a `formula` from other metrics
  (e.g. a derived "utilization %").
- `HierarchyNode<T>` — the tree itself, generic over an optional payload
  type `T` for any extra data your app wants to carry per node.

## Quick start

```dart
final levels = HierarchyLevels([
  HierarchyLevel(key: 'company', label: 'Company', color: Colors.indigo, icon: Icons.business),
  HierarchyLevel(key: 'department', label: 'Department', color: Colors.teal, icon: Icons.apartment),
  HierarchyLevel(key: 'team', label: 'Team', color: Colors.orange, icon: Icons.groups),
]);

final metrics = [
  MetricDefinition(key: 'headcount', label: 'Headcount', showOnCard: true),
  MetricDefinition(
    key: 'utilization',
    label: 'Utilization',
    kind: MetricKind.percent,
    showAsProgress: true,
    formula: (m) => (m['billable'] ?? 0) / (m['headcount'] ?? 1) * 100,
  ),
];

final tree = buildHierarchyTree<Team, Team>(
  rows: teams,
  levels: levels,
  rootName: 'Acme Inc.',
  pathOf: (t) => [t.department, t.name],
  metricsOf: (t) => {'headcount': t.headcount, 'billable': t.billable},
);

HierarchyTreeView<Team>(
  data: tree,
  levels: levels,
  metrics: metrics,
);
```

See `example/lib/main.dart` for a full working example: a 4-level company
org chart (Company → Department → Team → Role) with headcount, open-roles,
budget, and two derived progress metrics.

## Customization

| What | How |
|---|---|
| Number of levels | `HierarchyLevels([...])`, 2 to 12 entries |
| Per-level color/icon/label | `HierarchyLevel(color: ..., icon: ..., label: ...)` |
| What numbers show, and how | `MetricDefinition` list — raw or `formula`-derived |
| Card layout | Default `HierarchyNodeCard`, or pass `cardBuilder` to replace entirely |
| Details panel | Default `HierarchyDetailsPanel`, or pass `detailsBuilder` to replace entirely |
| Overall visual style | `HierarchyTheme` — colors, radii, text styles, `HierarchyTheme.dense()` preset |
| Layout direction | `orientation: TreeOrientation.leftToRight \| topToBottom` |
| Which branches are locked | `HierarchyAccessScope(selectedPath: [...])` |
| "Only one open at a time" sections | `exclusiveExpansionLevels: {1}` (by level index) |
| Card size | `cardWidth` (fixed), `cardHeight` (auto by default — see below), `horizontalGap`, `verticalGap` |
| Which metrics show at all | `autoSelectMetrics` (default true — see below) |
| Line/selection colors | `lineColor`, `highlightColor` |
| Search | `searchQuery` + `searchMatcher`, driven by your own search box |
| Programmatic control | `controller: HierarchyTreeController<T>()` |

## Theming

`HierarchyTheme` restyles the default card and details panel without a
custom builder — colors, border radius, shadows, text styles, progress bar
sizing, and the search-match highlight color:

```dart
HierarchyTreeView<T>(
  // ...
  theme: const HierarchyTheme(
    cardBorderRadius: 16,
    searchMatchBorderColor: Colors.pink,
  ),
);
```

Use `HierarchyTheme.dense()` as a starting point for trees with many
siblings on screen at once (smaller text, tighter progress bars).

## Auto-sizing cards & metric defaults

Cards don't hardcode "two headline numbers and two progress bars." They show
exactly what your `metrics` list gives them:

```dart
// Just one number, no progress row — the card automatically shrinks to fit.
HierarchyTreeView<T>(
  metrics: [
    MetricDefinition(key: 'headcount', label: 'Headcount'),
  ],
  // cardHeight left unset — computed automatically from theme's row-height
  // constants and which rows are actually present.
);
```

How the defaults work:

- **Auto-height.** Leave `cardHeight` unset (the default) and the card's
  height is computed from `HierarchyTheme`'s row-height constants
  (`headerRowHeight`, `headlineRowHeight`, `progressRowHeight`,
  `rowSpacing`, `cardPaddingVertical`) and whichever rows are actually
  present — a header-only card, a header+headline card, and a
  header+headline+progress card each get a different, correctly-fitted
  height with zero configuration. Set `cardHeight` explicitly any time you
  want full manual control instead.
- **Auto-selected metrics.** If you don't flag anything with `showOnCard`
  or `showAsProgress`, the card still shows something sensible: up to two
  `MetricKind.count` metrics become the headline numbers, and up to two
  `MetricKind.percent` metrics become the progress bars, in list order.
  Flagging any metric explicitly (even just one) takes priority and
  disables auto-selection for that row — so `showOnCard: true` on a single
  metric shows exactly that one, not padded up to two.
- **Opting out entirely.** Set `autoSelectMetrics: false` to show only
  what's explicitly flagged — which may mean nothing renders in a row if
  nothing was flagged.

`cardWidth` (default `200.0`) is still one fixed value for every card in
the tree — mixing widths per node isn't supported, since the grid layout
assumes a uniform size.

## Orientation

Trees lay out left-to-right by default (root on the left). Pass
`orientation: TreeOrientation.topToBottom` for a classic top-down org-chart
layout instead — the layout algorithm, connector curves, and centering all
adapt automatically:

```dart
HierarchyTreeView<T>(
  // ...
  orientation: TreeOrientation.topToBottom,
);
```

## Search

The widget renders no search box of its own — wire your own `TextField` to
`searchQuery`, and the tree does the rest: matching nodes are highlighted,
every ancestor of a match is auto-expanded so it's actually visible, and the
view centers on the first match automatically.

```dart
final controller = HierarchyTreeController<T>();

HierarchyTreeView<T>(
  // ...
  controller: controller,
  searchQuery: myQuery, // update via setState as the user types
  searchMatcher: (node, query) => node.name.toLowerCase().contains(query.toLowerCase()),
  onSearchResults: (matches) => print('${matches.length} matches'),
);

// Step through results from your own UI:
controller.nextMatch();
controller.previousMatch();
```

A small "N of M" indicator with prev/next arrows appears in the built-in
toolbar automatically whenever `searchQuery` is non-empty.

## Programmatic control

`HierarchyTreeController<T>` lets you center, expand, collapse, or select a
node by id from outside the widget — e.g. a "jump to my team" button, or
restoring a previously-selected node:

```dart
final controller = HierarchyTreeController<T>();

HierarchyTreeView<T>(controller: controller, /* ... */);

controller.centerNode('team-42');
controller.expandNode('team-42');
controller.selectNode('team-42');
print(controller.selectedNode);
```

A controller not currently attached to a mounted `HierarchyTreeView`
silently no-ops rather than throwing — safe to call before the first frame.

## Access control

`HierarchyAccessScope` generalizes "this user can only see/edit their own
branch": pass the chain of node *names* the user is scoped to, from the top
level down. Everything along that path is unlocked and expanded; sibling
branches are shown (for context) but locked with their children hidden;
everything past the end of the path is fully open.

```dart
// Full access — everything unlocked.
const HierarchyAccessScope()

// Scoped to one branch at level 2 ("Team" in a Company/Department/Team/Role tree).
const HierarchyAccessScope(selectedPath: ['Engineering', 'Platform'])
```

## Interaction behavior

- Tapping a node selects it, opens the details panel (desktop: side panel,
  mobile: dialog), and smoothly scrolls/centers it into view.
- Tapping the expand/collapse icon toggles that node's children and
  re-centers it once the tree reflows.
- `exclusiveExpansionLevels` makes toggling a node at that level collapse
  its siblings first — useful for a top-level nav where only one section
  should ever be open.

## Publishing checklist

This package includes a `LICENSE`, `CHANGELOG.md`, and a `test/` suite
already. Before running `dart pub publish`:

- [ ] Check [pub.dev](https://pub.dev/packages?q=hierarchy_tree) for a name
      collision — package names are global and permanent
- [ ] Replace `homepage`/`repository` placeholders in `pubspec.yaml` with
      your real repo URL
- [ ] Replace the placeholder name in `LICENSE`
- [ ] `flutter pub get && flutter analyze && flutter test` — this repo
      hasn't been run through a live Flutter SDK, so this is the first
      real compile/test check it gets
- [ ] `dart pub publish --dry-run` and address anything it flags
- [ ] Optionally run `pana .` (`dart pub global activate pana` first) to
      preview your pub.dev score locally before publishing
