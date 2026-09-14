/// A generic, configurable, zoomable/pannable hierarchy tree widget for
/// Flutter — org charts, asset trees, category trees, file systems, or any
/// other parent/child data, with 2 to 12 user-defined levels, fully custom
/// colors/icons/metrics, and pluggable access control.
library hierarchy_tree;

export 'src/access_scope.dart'
    show
        applyAccessScope,
        canToggleHierarchyNode,
        expandAllUnlocked,
        collapseAllUnlocked,
        collapseEntireSubtree,
        buildParentMap;
export 'src/card_metrics.dart';
export 'src/hierarchy_tree_view.dart';
export 'src/models/hierarchy_access_scope.dart';
export 'src/models/hierarchy_level.dart';
export 'src/models/hierarchy_node.dart';
export 'src/models/hierarchy_theme.dart';
export 'src/models/metric_definition.dart';
export 'src/node_position.dart';
export 'src/tree_builder.dart';
export 'src/tree_orientation.dart';
export 'src/widgets/details_panel.dart';
export 'src/widgets/edges_painter.dart';
export 'src/widgets/node_card.dart';
