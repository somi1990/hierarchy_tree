import 'package:flutter/material.dart';

import 'models/hierarchy_node.dart';

/// A node's computed position within the laid-out tree canvas.
class NodePosition<T> {
  const NodePosition({
    required this.node,
    required this.position,
    required this.level,
  });

  final HierarchyNode<T> node;
  final Offset position;
  final int level;
}

class TreeLayoutResult<T> {
  const TreeLayoutResult({
    required this.nodes,
    required this.width,
    required this.height,
  });

  final List<NodePosition<T>> nodes;
  final double width;
  final double height;
}
