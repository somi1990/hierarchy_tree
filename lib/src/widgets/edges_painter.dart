import 'package:flutter/material.dart';

import '../models/hierarchy_node.dart';
import '../node_position.dart';
import '../tree_orientation.dart';

/// Draws curved connector lines between expanded parent nodes and their
/// visible children, oriented according to [orientation]. The edge
/// touching the selected node is highlighted.
class HierarchyEdgesPainter<T> extends CustomPainter {
  HierarchyEdgesPainter({
    required this.nodes,
    required this.selectedNode,
    required this.nodeSize,
    required this.orientation,
    this.lineColor = const Color(0xff94a3b8),
    this.highlightColor = const Color(0xff2563eb),
  });

  final List<NodePosition<T>> nodes;
  final HierarchyNode<T>? selectedNode;
  final Size nodeSize;
  final TreeOrientation orientation;
  final Color lineColor;
  final Color highlightColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Map<String, NodePosition<T>> lookup = <String, NodePosition<T>>{
      for (final item in nodes) item.node.id: item,
    };

    for (final parent in nodes) {
      if (!parent.node.expanded) continue;

      for (final child in parent.node.children) {
        final NodePosition<T>? childPosition = lookup[child.id];
        if (childPosition == null) continue;
        _drawConnection(canvas, parent, childPosition);
      }
    }
  }

  void _drawConnection(Canvas canvas, NodePosition<T> parent, NodePosition<T> child) {
    final Offset start;
    final Offset end;
    final Path path = Path();

    if (orientation == TreeOrientation.leftToRight) {
      start = Offset(
        parent.position.dx + nodeSize.width,
        parent.position.dy + nodeSize.height / 2.0,
      );
      end = Offset(child.position.dx, child.position.dy + nodeSize.height / 2.0);

      final double middleX = (start.dx + end.dx) / 2.0;
      path
        ..moveTo(start.dx, start.dy)
        ..cubicTo(middleX, start.dy, middleX, end.dy, end.dx, end.dy);
    } else {
      start = Offset(
        parent.position.dx + nodeSize.width / 2.0,
        parent.position.dy + nodeSize.height,
      );
      end = Offset(child.position.dx + nodeSize.width / 2.0, child.position.dy);

      final double middleY = (start.dy + end.dy) / 2.0;
      path
        ..moveTo(start.dx, start.dy)
        ..cubicTo(start.dx, middleY, end.dx, middleY, end.dx, end.dy);
    }

    final bool highlighted =
        selectedNode?.id == parent.node.id || selectedNode?.id == child.node.id;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = highlighted ? 3.0 : 1.8
      ..strokeCap = StrokeCap.round
      ..color = highlighted ? highlightColor : lineColor;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HierarchyEdgesPainter oldDelegate) => true;
}
