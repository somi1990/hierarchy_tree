import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'access_scope.dart';
import 'card_metrics.dart';
import 'models/hierarchy_access_scope.dart';
import 'models/hierarchy_level.dart';
import 'models/hierarchy_node.dart';
import 'models/hierarchy_theme.dart';
import 'models/metric_definition.dart';
import 'node_position.dart';
import 'tree_orientation.dart';
import 'widgets/details_panel.dart';
import 'widgets/edges_painter.dart';
import 'widgets/node_card.dart';

/// Signature for replacing the default node card entirely.
typedef HierarchyCardBuilder<T> = Widget Function(
  BuildContext context,
  HierarchyNode<T> node,
  HierarchyLevel level,
  bool selected,
  bool canExpand,
  VoidCallback onTap,
  VoidCallback onToggle,
);

/// Signature for replacing the default details panel entirely.
typedef HierarchyDetailsBuilder<T> = Widget Function(
  BuildContext context,
  HierarchyNode<T> node,
  HierarchyLevel level,
);

/// Signature for a custom search matcher. Defaults to a case-insensitive
/// substring match on `node.name`.
typedef HierarchySearchMatcher<T> = bool Function(HierarchyNode<T> node, String query);

/// Programmatic handle to a [HierarchyTreeView] — center/expand/collapse/
/// select nodes by id, and step through search matches, from outside the
/// widget (e.g. from an external search box or a "jump to" button).
///
/// Create one, pass it to `HierarchyTreeView.controller`, and call its
/// methods any time after the first frame. A controller not currently
/// attached to a mounted [HierarchyTreeView] silently no-ops.
class HierarchyTreeController<T> extends ChangeNotifier {
  _HierarchyTreeViewState<T>? _state;

  void _attach(_HierarchyTreeViewState<T> state) => _state = state;

  void _detach(_HierarchyTreeViewState<T> state) {
    if (identical(_state, state)) _state = null;
  }

  bool get isAttached => _state != null;

  void centerNode(String id) => _state?._centerNodeById(id);

  void expandNode(String id) => _state?._expandNodeById(id);

  void collapseNode(String id) => _state?._collapseNodeById(id);

  void selectNode(String id) => _state?._selectNodeById(id);

  /// Jumps to the next search match, wrapping around. No-ops if there is
  /// no active search or no matches.
  void nextMatch() {
    _state?._nextMatch();
    notifyListeners();
  }

  /// Jumps to the previous search match, wrapping around.
  void previousMatch() {
    _state?._previousMatch();
    notifyListeners();
  }

  /// Current search matches, in tree order. Empty if there is no active
  /// search query.
  List<HierarchyNode<T>> get matches => _state?.searchMatches ?? const [];

  /// Index of the currently-focused match within [matches], or -1 if none.
  int get currentMatchIndex => _state?.currentMatchIndex ?? -1;

  HierarchyNode<T>? get selectedNode => _state?.selectedNode;

  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
}

/// A generic, publishable, zoomable/pannable hierarchy tree widget.
///
/// Works with any domain (org charts, asset trees, category trees, file
/// systems, ...) by taking a fully generic [HierarchyNode] tree, a
/// [HierarchyLevels] config (2 to 12 levels, each with its own color/icon),
/// and a list of [MetricDefinition]s describing what numbers to show.
///
/// Access control (which branches are locked/visible) is expressed via
/// [access] and applied automatically; "one branch open at a time" UX
/// (like a top nav that only ever has one open section) is opted into per
/// level via [exclusiveExpansionLevels]. Restyle via [theme], lay the tree
/// out top-down instead of left-right via [orientation], and drive an
/// external search box via [searchQuery] / [controller].
class HierarchyTreeView<T> extends StatefulWidget {
  const HierarchyTreeView({
    super.key,
    required this.data,
    required this.levels,
    required this.metrics,
    this.access = const HierarchyAccessScope(),
    this.exclusiveExpansionLevels = const <int>{},
    this.cardWidth = 200.0,
    this.cardHeight,
    this.autoSelectMetrics = true,
    this.horizontalGap = 80.0,
    this.verticalGap = 20.0,
    this.orientation = TreeOrientation.leftToRight,
    this.theme = const HierarchyTheme(),
    this.title,
    this.cardBuilder,
    this.detailsBuilder,
    this.showDetailsPanel = true,
    this.onNodeSelected,
    this.lineColor = const Color(0xff94a3b8),
    this.highlightColor = const Color(0xff2563eb),
    this.controller,
    this.searchQuery,
    this.searchMatcher,
    this.onSearchResults,
  });

  /// The full, unrestricted tree. Access restriction is applied internally.
  final HierarchyNode<T> data;

  final HierarchyLevels levels;

  final List<MetricDefinition> metrics;

  final HierarchyAccessScope access;

  /// Levels at which opening one sibling automatically closes the others
  /// under the same parent (e.g. a top-level nav where only one section is
  /// ever expanded at once).
  final Set<int> exclusiveExpansionLevels;

  /// Width of every card in the tree. Fixed — mixing card widths per node
  /// isn't supported since the grid layout assumes a uniform size.
  final double cardWidth;

  /// Height of every card. Leave unset (the default) to auto-compute from
  /// [theme]'s row-height constants and which metric rows are actually
  /// present — a card with only a headline metric and no progress bars
  /// ends up shorter than one with both, and a card with neither shrinks
  /// to just its header. Set explicitly to opt out of auto-sizing.
  final double? cardHeight;

  /// When true (the default), a metric with neither `showOnCard` nor
  /// `showAsProgress` set still gets a sensible home: up to two
  /// `MetricKind.count` metrics are auto-picked for the headline row and
  /// up to two `MetricKind.percent` metrics for the progress row, in list
  /// order. Explicitly flagged metrics always take priority over this
  /// fallback. Set to false to show only what's explicitly flagged (which
  /// may mean nothing, if nothing is flagged).
  final bool autoSelectMetrics;

  final double horizontalGap;
  final double verticalGap;

  /// Whether the tree grows left-to-right (default) or top-to-bottom.
  final TreeOrientation orientation;

  /// Visual theme for the default node card and details panel.
  final HierarchyTheme theme;

  /// Toolbar title. Defaults to the name of the root node.
  final String? title;

  final HierarchyCardBuilder<T>? cardBuilder;
  final HierarchyDetailsBuilder<T>? detailsBuilder;
  final bool showDetailsPanel;

  final ValueChanged<HierarchyNode<T>>? onNodeSelected;

  final Color lineColor;
  final Color highlightColor;

  /// Optional programmatic handle — see [HierarchyTreeController].
  final HierarchyTreeController<T>? controller;

  /// Current search query. Matching nodes are highlighted, their ancestors
  /// auto-expanded, and the tree jumps to the first match. Pass `null` or
  /// an empty string to clear search. The widget does not render its own
  /// search box — wire this up to your own `TextField`.
  final String? searchQuery;

  /// Custom match predicate. Defaults to a case-insensitive substring
  /// match on `node.name`.
  final HierarchySearchMatcher<T>? searchMatcher;

  /// Called with the full list of matches whenever [searchQuery] changes.
  final ValueChanged<List<HierarchyNode<T>>>? onSearchResults;

  @override
  State<HierarchyTreeView<T>> createState() => _HierarchyTreeViewState<T>();
}

class _HierarchyTreeViewState<T> extends State<HierarchyTreeView<T>> {
  late HierarchyNode<T> visibleRoot;

  Map<String, HierarchyNode<T>> parentOf = <String, HierarchyNode<T>>{};
  Map<String, HierarchyNode<T>> nodeById = <String, HierarchyNode<T>>{};

  final Map<String, GlobalKey> nodeKeys = <String, GlobalKey>{};

  HierarchyNode<T>? selectedNode;

  List<HierarchyNode<T>> searchMatches = <HierarchyNode<T>>[];
  int currentMatchIndex = -1;

  double zoom = 1.0;

  final ScrollController horizontalController = ScrollController();
  final ScrollController verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _rebuild();
  }

  @override
  void didUpdateWidget(covariant HierarchyTreeView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }

    if (oldWidget.data != widget.data || oldWidget.access != widget.access) {
      setState(_rebuild);
    } else if (oldWidget.searchQuery != widget.searchQuery) {
      setState(_recomputeSearch);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    horizontalController.dispose();
    verticalController.dispose();
    super.dispose();
  }

  void _rebuild() {
    visibleRoot = applyAccessScope<T>(widget.data, widget.access);
    parentOf = buildParentMap<T>(visibleRoot);
    nodeById = <String, HierarchyNode<T>>{};

    void indexWalk(HierarchyNode<T> node) {
      nodeById[node.id] = node;
      for (final child in node.children) {
        indexWalk(child);
      }
    }

    indexWalk(visibleRoot);

    nodeKeys.clear();
    selectedNode = null;
    _recomputeSearch();
  }

  GlobalKey _keyFor(String id) => nodeKeys.putIfAbsent(id, () => GlobalKey());

  // ===========================================================
  // SEARCH
  // ===========================================================

  bool _defaultMatcher(HierarchyNode<T> node, String query) {
    return node.name.toLowerCase().contains(query.toLowerCase());
  }

  void _recomputeSearch() {
    final String? query = widget.searchQuery;

    if (query == null || query.trim().isEmpty) {
      searchMatches = const [];
      currentMatchIndex = -1;
      widget.onSearchResults?.call(searchMatches);
      return;
    }

    final HierarchySearchMatcher<T> matcher = widget.searchMatcher ?? _defaultMatcher;
    final List<HierarchyNode<T>> found = <HierarchyNode<T>>[];

    void walk(HierarchyNode<T> node) {
      if (matcher(node, query)) found.add(node);
      for (final child in node.children) {
        walk(child);
      }
    }

    walk(visibleRoot);

    // Expand every ancestor of every match so matches are actually visible.
    // Ancestors of a node present in visibleRoot are never locked — a
    // locked node always has its children stripped, so a match can only
    // exist beneath unlocked ancestors.
    for (final match in found) {
      HierarchyNode<T>? ancestor = parentOf[match.id];
      while (ancestor != null) {
        ancestor.expanded = true;
        ancestor = parentOf[ancestor.id];
      }
    }

    searchMatches = found;
    currentMatchIndex = found.isEmpty ? -1 : 0;
    widget.onSearchResults?.call(found);

    if (found.isNotEmpty) _centerOn(found.first);
  }

  void _nextMatch() {
    if (searchMatches.isEmpty) return;
    setState(() {
      currentMatchIndex = (currentMatchIndex + 1) % searchMatches.length;
    });
    _centerOn(searchMatches[currentMatchIndex]);
  }

  void _previousMatch() {
    if (searchMatches.isEmpty) return;
    setState(() {
      currentMatchIndex = (currentMatchIndex - 1 + searchMatches.length) % searchMatches.length;
    });
    _centerOn(searchMatches[currentMatchIndex]);
  }

  // ===========================================================
  // CONTROLLER-DRIVEN ACTIONS
  // ===========================================================

  void _centerNodeById(String id) {
    final HierarchyNode<T>? node = nodeById[id];
    if (node != null) _centerOn(node);
  }

  void _expandNodeById(String id) {
    final HierarchyNode<T>? node = nodeById[id];
    if (node == null || node.locked || node.children.isEmpty) return;
    setState(() => node.expanded = true);
    _centerOn(node);
  }

  void _collapseNodeById(String id) {
    final HierarchyNode<T>? node = nodeById[id];
    if (node == null || node.locked) return;
    setState(() => node.expanded = false);
  }

  void _selectNodeById(String id) {
    final HierarchyNode<T>? node = nodeById[id];
    if (node != null) _select(node);
  }

  // ===========================================================
  // TOGGLE / SELECT / CENTER
  // ===========================================================

  void _toggle(HierarchyNode<T> node) {
    if (node.locked || node.children.isEmpty) return;

    setState(() {
      if (widget.exclusiveExpansionLevels.contains(node.levelIndex)) {
        final HierarchyNode<T>? parent = parentOf[node.id];

        if (!node.expanded && parent != null) {
          for (final sibling in parent.children) {
            if (sibling.id != node.id) collapseEntireSubtree<T>(sibling);
          }
          node.expanded = true;
        } else {
          node.expanded = false;
        }
      } else {
        node.expanded = !node.expanded;
      }
    });

    _centerOn(node);
  }

  void _select(HierarchyNode<T> node) {
    setState(() => selectedNode = node);
    widget.onNodeSelected?.call(node);
    _centerOn(node);
  }

  void _centerOn(HierarchyNode<T> node) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final BuildContext? ctx = nodeKeys[node.id]?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _expandAll() {
    setState(() => expandAllUnlocked<T>(visibleRoot));
  }

  void _collapseAll() {
    setState(() => collapseAllUnlocked<T>(visibleRoot));
  }

  void _zoomIn() => setState(() => zoom = math.min(2.0, zoom + 0.1));
  void _zoomOut() => setState(() => zoom = math.max(0.5, zoom - 0.1));
  void _resetZoom() => setState(() => zoom = 1.0);

  // ===========================================================
  // LAYOUT — orientation-aware. "main axis" is the axis levels grow
  // along (x for left-to-right, y for top-to-bottom); "cross axis" is
  // the axis siblings are spread along.
  // ===========================================================

  TreeLayoutResult<T> _calculateLayout(Size cardSize) {
    final bool ltr = widget.orientation == TreeOrientation.leftToRight;

    final double mainSize = ltr ? cardSize.width : cardSize.height;
    final double mainGap = ltr ? widget.horizontalGap : widget.verticalGap;
    final double crossSize = ltr ? cardSize.height : cardSize.width;
    final double crossGap = ltr ? widget.verticalGap : widget.horizontalGap;

    Offset toOffset(double main, double cross) => ltr ? Offset(main, cross) : Offset(cross, main);
    double crossOf(Offset o) => ltr ? o.dy : o.dx;

    final List<NodePosition<T>> positions = <NodePosition<T>>[];
    int leafIndex = 0;

    void walk(HierarchyNode<T> node, int level) {
      final List<HierarchyNode<T>> children =
          node.expanded ? node.children : <HierarchyNode<T>>[];

      final double main = 60.0 + level * (mainSize + mainGap);

      if (children.isEmpty) {
        final double cross = 60.0 + leafIndex * (crossSize + crossGap);
        positions.add(NodePosition<T>(node: node, position: toOffset(main, cross), level: level));
        leafIndex++;
        return;
      }

      final int start = positions.length;
      for (final child in children) {
        walk(child, level + 1);
      }

      final List<NodePosition<T>> childPositions = positions.sublist(start);
      if (childPositions.isEmpty) return;

      double sumCross = 0.0;
      for (final c in childPositions) {
        sumCross += crossOf(c.position);
      }
      final double averageCross = sumCross / childPositions.length;

      positions.add(NodePosition<T>(node: node, position: toOffset(main, averageCross), level: level));
    }

    walk(visibleRoot, 0);

    double maxX = 1200.0;
    double maxY = 700.0;

    for (final item in positions) {
      final double right = item.position.dx + cardSize.width;
      final double bottom = item.position.dy + cardSize.height;
      if (right > maxX) maxX = right;
      if (bottom > maxY) maxY = bottom;
    }

    return TreeLayoutResult<T>(nodes: positions, width: maxX, height: maxY);
  }

  // ===========================================================
  // BUILD
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 750;

        return Column(
          children: [
            _buildToolbar(),
            const SizedBox(height: 10),
            Expanded(
              child: isMobile || !widget.showDetailsPanel
                  ? _buildTreeArea(isMobile)
                  : _buildDesktopLayout(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 5,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: widget.highlightColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.levels[0].icon, size: 19, color: widget.highlightColor),
          ),
          const SizedBox(width: 4),
          Text(
            widget.title ?? visibleRoot.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          if (searchMatches.isNotEmpty || (widget.searchQuery?.isNotEmpty ?? false)) ...[
            _buildSearchIndicator(),
            const SizedBox(width: 8),
          ],
          OutlinedButton.icon(
            onPressed: _expandAll,
            icon: const Icon(Icons.unfold_more, size: 17),
            label: const Text('Expand All'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 34),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _collapseAll,
            icon: const Icon(Icons.unfold_less, size: 17),
            label: const Text('Collapse All'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 34),
            ),
          ),
          IconButton(tooltip: 'Zoom out', onPressed: _zoomOut, icon: const Icon(Icons.remove)),
          Container(
            width: 50,
            alignment: Alignment.center,
            child: Text(
              '${(zoom * 100).round()}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(tooltip: 'Zoom in', onPressed: _zoomIn, icon: const Icon(Icons.add)),
          IconButton(
            tooltip: 'Reset zoom',
            onPressed: _resetZoom,
            icon: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
    );
  }

  /// Small "N of M" indicator with prev/next controls, shown automatically
  /// once a search query is active. Only appears if you're driving
  /// [HierarchyTreeView.searchQuery] yourself — there's no built-in text
  /// field, this is just the result/navigation readout.
  Widget _buildSearchIndicator() {
    final String label =
        searchMatches.isEmpty ? 'No matches' : '${currentMatchIndex + 1} of ${searchMatches.length}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xff64748b))),
        IconButton(
          tooltip: 'Previous match',
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          onPressed: searchMatches.isEmpty ? null : _previousMatch,
          icon: const Icon(Icons.keyboard_arrow_up),
        ),
        IconButton(
          tooltip: 'Next match',
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          onPressed: searchMatches.isEmpty ? null : _nextMatch,
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildTreeArea(false)),
        const SizedBox(width: 12),
        SizedBox(
          width: 360,
          child: selectedNode == null
              ? _buildEmptyDetailsPanel()
              : _buildDetailsPanel(selectedNode!, false),
        ),
      ],
    );
  }

  Widget _buildDetailsPanel(HierarchyNode<T> node, bool asDialog) {
    final HierarchyLevel level = widget.levels[node.levelIndex];

    if (widget.detailsBuilder != null) {
      return widget.detailsBuilder!(context, node, level);
    }

    return HierarchyDetailsPanel<T>(
      node: node,
      level: level,
      metrics: widget.metrics,
      showCloseButton: asDialog,
      onClose: asDialog ? () => Navigator.of(context).pop() : null,
      theme: widget.theme,
    );
  }

  void _showMobileDetails(HierarchyNode<T> node) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: SizedBox(width: 500, height: 650, child: _buildDetailsPanel(node, true)),
        );
      },
    );
  }

  Widget _buildTreeArea(bool isMobile) {
    final ResolvedCardMetrics resolved = resolveCardMetrics(
      metrics: widget.metrics,
      theme: widget.theme,
      cardWidth: widget.cardWidth,
      cardHeight: widget.cardHeight,
      autoSelect: widget.autoSelectMetrics,
    );

    final TreeLayoutResult<T> layout = _calculateLayout(resolved.size);

    final double unscaledWidth = math.max(layout.width + 100.0, 1200.0);
    final double unscaledHeight = math.max(layout.height + 100.0, 700.0);
    final double scaledWidth = unscaledWidth * zoom;
    final double scaledHeight = unscaledHeight * zoom;

    final Set<String> matchIds = searchMatches.map((n) => n.id).toSet();

    return Container(
      width: double.infinity,
      height: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Scrollbar(
        controller: verticalController,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        scrollbarOrientation: ScrollbarOrientation.right,
        child: SingleChildScrollView(
          controller: verticalController,
          scrollDirection: Axis.vertical,
          child: Scrollbar(
            controller: horizontalController,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: horizontalController,
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                width: scaledWidth,
                height: scaledHeight,
                child: Transform.scale(
                  scale: zoom,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: unscaledWidth,
                    height: unscaledHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: HierarchyEdgesPainter<T>(
                              nodes: layout.nodes,
                              selectedNode: selectedNode,
                              nodeSize: resolved.size,
                              orientation: widget.orientation,
                              lineColor: widget.lineColor,
                              highlightColor: widget.highlightColor,
                            ),
                          ),
                        ),
                        ...layout.nodes.map((item) {
                          final HierarchyLevel level = widget.levels[item.node.levelIndex];
                          final bool selected = selectedNode?.id == item.node.id;
                          final bool canExpand = canToggleHierarchyNode<T>(item.node);
                          final bool isMatch = matchIds.contains(item.node.id);

                          void onTap() {
                            _select(item.node);
                            if (isMobile) _showMobileDetails(item.node);
                          }

                          void onToggle() => _toggle(item.node);

                          return Positioned(
                            left: item.position.dx,
                            top: item.position.dy,
                            child: KeyedSubtree(
                              key: _keyFor(item.node.id),
                              child: widget.cardBuilder != null
                                  ? widget.cardBuilder!(
                                      context,
                                      item.node,
                                      level,
                                      selected,
                                      canExpand,
                                      onTap,
                                      onToggle,
                                    )
                                  : HierarchyNodeCard<T>(
                                      node: item.node,
                                      level: level,
                                      headlineMetrics: resolved.headline,
                                      progressMetrics: resolved.progress,
                                      size: resolved.size,
                                      selected: selected,
                                      canExpand: canExpand,
                                      onTap: onTap,
                                      onToggle: onToggle,
                                      theme: widget.theme,
                                      isSearchMatch: isMatch,
                                    ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDetailsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app, size: 42, color: Color(0xff94a3b8)),
              SizedBox(height: 10),
              Text(
                'Select a node',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xff475569)),
              ),
              SizedBox(height: 5),
              Text(
                'Click a node to view its details.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xff64748b)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
