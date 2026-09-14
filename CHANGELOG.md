# Changelog

## 0.1.1

- Fixed a `for`-loop lint (`curly_braces_in_flow_control_structures`) flagged by pub.dev's static analysis check — this was the only issue keeping "Pass static analysis" below full marks.
- README: replaced the stale pre-publish checklist with a "Releasing a new version" checklist, added an "Installing" section with the `pubspec.yaml` snippet, and added the pub.dev version badge.

## 0.1.0

Initial release.

**Core**
- `HierarchyLevels` / `HierarchyLevel` — configurable 2–12 level hierarchy definitions, each with its own color, icon, and label.
- `MetricDefinition` — raw or formula-derived numeric metrics, shown as headline numbers or progress bars.
- `HierarchyNode<T>` — generic tree node with automatic metric aggregation up the tree and an optional custom payload type.
- `buildHierarchyTree` — build a tree from flat rows of any shape, for any level depth.
- `applyAccessScope` / `HierarchyAccessScope` — generic branch-locking access control for any tree depth: a scoped user's own branch stays open, sibling branches stay visible but locked, everything past the end of their path is fully open.

**The widget — `HierarchyTreeView<T>`**
- Zoomable, pannable tree canvas with click-to-center navigation on tap or on expand/collapse.
- Expand/collapse per node, with optional "exclusive expansion" per level (`exclusiveExpansionLevels`) for nav-style "only one branch open at a time" behavior.
- Desktop side-panel / mobile dialog details view.
- Fully overridable node card (`cardBuilder`) and details panel (`detailsBuilder`) for complete custom visuals.

**Theming**
- `HierarchyTheme` — restyle the default card and details panel (colors, border radius, shadows, text styles, progress bar sizing, search-match highlight color) without writing a custom builder.
- `HierarchyTheme.dense()` — a tighter built-in preset for trees with many siblings on screen at once.

**Auto-sizing cards & metric defaults**
- `cardWidth` (fixed) + `cardHeight` (nullable — auto-computed when unset). When left unset, card height is derived from `HierarchyTheme`'s row-height constants (`headerRowHeight`, `headlineRowHeight`, `progressRowHeight`, `rowSpacing`, `cardPaddingVertical`) and which metric rows are actually present, so a 1-metric or 0-progress-bar card shrinks to fit instead of leaving blank space.
- `autoSelectMetrics` (default `true`) — when no metric is explicitly flagged `showOnCard`/`showAsProgress`, up to two `count` metrics and up to two `percent` metrics are auto-picked for the headline/progress rows respectively. Explicit flags always take priority; set `autoSelectMetrics: false` to disable the fallback and show only what's flagged.
- `resolveHeadlineMetrics` / `resolveProgressMetrics` / `resolveCardSize` / `resolveCardMetrics` exported from `card_metrics.dart` for anyone building a fully custom `cardBuilder` that wants the same sizing logic.

**Orientation**
- `TreeOrientation.leftToRight` (default) or `TreeOrientation.topToBottom` — layout algorithm, connector curves, and click-to-center all adapt automatically.

**Search**
- `searchQuery` / `searchMatcher` / `onSearchResults` on `HierarchyTreeView`. Matching nodes are highlighted, every ancestor of a match is auto-expanded so it's actually visible, and the view centers on the first match automatically.
- A built-in "N of M" toolbar indicator with prev/next arrows appears automatically whenever a search query is active. The widget renders no search box of its own — wire up your own `TextField`.

**Programmatic control**
- `HierarchyTreeController<T>` — `centerNode`/`expandNode`/`collapseNode`/`selectNode` by id, plus `nextMatch()`/`previousMatch()` for stepping through search results, all callable from outside the widget. Safely no-ops when not attached to a mounted tree.