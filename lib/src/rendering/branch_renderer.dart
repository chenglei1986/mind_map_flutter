import 'package:flutter/material.dart';
import '../models/node_data.dart';
import '../models/mind_map_theme.dart';
import '../layout/node_layout.dart';

/// Renderer for branch connections between nodes
class BranchRenderer {
  // mind-elixir-core me-parent has vertical padding: 6px.
  static const double _subParentPaddingY = 6.0;

  /// Draw a branch connection from parent to child
  /// Uses mind-elixir-core-equivalent formulas:
  /// - main(): M ... Q ...
  /// - sub():  M ... C ... H ...
  static void drawBranch(
    Canvas canvas,
    NodeLayout parentLayout,
    NodeLayout childLayout,
    MindMapTheme theme,
    int branchIndex, {
    Color? customColor,
    bool isMainNode = false,
    bool isFirstChild = false,
    required double containerHeight,
  }) {
    final color =
        customColor ?? theme.palette[branchIndex % theme.palette.length];
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final parentBounds = parentLayout.bounds;
    final childBounds = childLayout.bounds;
    final isChildOnRight = childBounds.center.dx > parentBounds.center.dx;
    final gap = theme.variables.nodeGapX;

    if (isMainNode) {
      _drawMainBranchCore(
        canvas,
        paint,
        parentBounds,
        childBounds,
        isChildOnRight,
        containerHeight,
      );
      return;
    }

    _drawSubBranchCore(
      canvas,
      paint,
      isFirstChild
          ? _toVirtualMainParentBounds(parentBounds)
          : _toVirtualSubParentBounds(parentBounds, gap),
      _toVirtualSubParentBounds(childBounds, gap),
      isChildOnRight,
      gap,
      isFirstChild,
    );
  }

  static void _drawMainBranchCore(
    Canvas canvas,
    Paint paint,
    Rect parentBounds,
    Rect childBounds,
    bool isChildOnRight,
    double containerHeight,
  ) {
    // Matches mind-elixir-core generateBranch.main()
    double x1 = parentBounds.left + parentBounds.width / 2;
    final y1 = parentBounds.top + parentBounds.height / 2;
    final x2 = isChildOnRight ? childBounds.left : childBounds.right;
    final y2 = childBounds.top + childBounds.height / 2;

    final safeContainerHeight = containerHeight <= 0 ? 1.0 : containerHeight;
    final pct = (y2 - y1).abs() / safeContainerHeight;
    final offset = (1 - pct) * 0.25 * (parentBounds.width / 2);
    if (isChildOnRight) {
      x1 = x1 + parentBounds.width / 10 + offset;
    } else {
      x1 = x1 - parentBounds.width / 10 - offset;
    }

    final path = Path()
      ..moveTo(x1, y1)
      ..quadraticBezierTo(x1, y2, x2, y2);
    canvas.drawPath(path, paint);
  }

  static void _drawSubBranchCore(
    Canvas canvas,
    Paint paint,
    Rect parentBounds,
    Rect childBounds,
    bool isChildOnRight,
    double gap,
    bool isFirstChild,
  ) {
    // Matches mind-elixir-core generateBranch.sub()
    final y1 = isFirstChild
        ? parentBounds.top + parentBounds.height / 2
        : parentBounds.top + parentBounds.height;
    final y2 = childBounds.top + childBounds.height;
    final offset = ((y1 - y2).abs() / 300.0) * gap;

    final path = Path();
    if (isChildOnRight) {
      final xMid = parentBounds.left + parentBounds.width;
      final x1 = xMid - gap;
      final x2 = xMid + gap;
      final end = childBounds.left + childBounds.width - gap;
      path
        ..moveTo(x1, y1)
        ..cubicTo(xMid, y1, xMid - offset, y2, x2, y2)
        ..lineTo(end, y2);
    } else {
      final xMid = parentBounds.left;
      final x1 = xMid + gap;
      final x2 = xMid - gap;
      final end = childBounds.left + gap;
      path
        ..moveTo(x1, y1)
        ..cubicTo(xMid, y1, xMid + offset, y2, x2, y2)
        ..lineTo(end, y2);
    }

    canvas.drawPath(path, paint);
  }

  static Rect _toVirtualSubParentBounds(Rect topicBounds, double gap) {
    // Convert topic bounds to me-parent-like bounds used by mind-elixir-core
    // for sub-line generation.
    return Rect.fromLTWH(
      topicBounds.left - gap,
      topicBounds.top - _subParentPaddingY,
      topicBounds.width + gap * 2,
      topicBounds.height + _subParentPaddingY * 2,
    );
  }

  static Rect _toVirtualMainParentBounds(Rect topicBounds) {
    // For main->sub connection, parent me-parent in mind-elixir-core has
    // no x/y padding (only margin), so topic bounds map directly.
    return topicBounds;
  }

  static double _computeContainerHeight(Map<String, NodeLayout> nodeLayouts) {
    if (nodeLayouts.isEmpty) return 1.0;
    double minTop = double.infinity;
    double maxBottom = -double.infinity;
    for (final layout in nodeLayouts.values) {
      final bounds = layout.bounds;
      if (bounds.top < minTop) minTop = bounds.top;
      if (bounds.bottom > maxBottom) maxBottom = bounds.bottom;
    }
    final h = maxBottom - minTop;
    return h <= 0 ? 1.0 : h;
  }

  /// Draw all branches for a node and its children
  static void drawNodeBranches(
    Canvas canvas,
    NodeData node,
    Map<String, NodeLayout> nodeLayouts,
    MindMapTheme theme,
    int startBranchIndex, {
    int depth = 0,
  }) {
    final parentLayout = nodeLayouts[node.id];
    if (parentLayout == null) return;
    final effectiveContainerHeight = _computeContainerHeight(nodeLayouts);

    // Draw branches to all children
    for (int i = 0; i < node.children.length; i++) {
      final child = node.children[i];
      final childLayout = nodeLayouts[child.id];

      if (childLayout != null) {
        // Use custom branch color if specified, otherwise use palette
        final branchColor = child.branchColor;
        final branchIndex = startBranchIndex + i;

        // Child nodes are at depth >= 2 (grandchildren of root and deeper)
        // Main nodes are at depth 1 (direct children of root)
        final childDepth = depth + 1;
        final isMainNode = childDepth == 1;

        // mind-elixir-core's `isFirst` means sub-line directly under a main node.
        // It is NOT "first child by index".
        final isFirstChild = depth == 1;

        drawBranch(
          canvas,
          parentLayout,
          childLayout,
          theme,
          branchIndex,
          customColor: branchColor,
          isMainNode: isMainNode,
          isFirstChild: isFirstChild,
          containerHeight: effectiveContainerHeight,
        );

        // Recursively draw branches for child's children
        drawNodeBranches(
          canvas,
          child,
          nodeLayouts,
          theme,
          branchIndex,
          depth: childDepth,
        );
      }
    }
  }

  /// Draw straight line branch (alternative style)
  /// The branch line extends into the child node boundary
  ///
  /// Connection rules (matching mind-elixir-core):
  /// - Main nodes: Connect to boundary (no inset), at CENTER
  /// - Sub nodes under main node: Start from parent CENTER, end at child BOTTOM far boundary
  /// - Deeper sub nodes: Start from parent BOTTOM, end at child BOTTOM far boundary
  static void drawStraightBranch(
    Canvas canvas,
    NodeLayout parentLayout,
    NodeLayout childLayout,
    MindMapTheme theme,
    int branchIndex, {
    Color? customColor,
    bool isMainNode = false,
    bool isFirstChild = false,
  }) {
    // Get color from theme palette
    final color =
        customColor ?? theme.palette[branchIndex % theme.palette.length];

    // Create paint for the branch line
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Calculate connection points
    final parentBounds = parentLayout.bounds;
    final childBounds = childLayout.bounds;

    // Determine if child is on left or right side of parent
    final isChildOnRight = childBounds.center.dx > parentBounds.center.dx;

    // Calculate start point (edge of parent node)
    // Main nodes or first child: use parent center
    // Other children: use parent bottom
    final startY = isMainNode || isFirstChild
        ? parentBounds.center.dy
        : parentBounds.bottom;

    final startPoint = Offset(
      isChildOnRight ? parentBounds.right : parentBounds.left,
      startY,
    );

    // Calculate end point.
    // For sub branches we end on far boundary to match core behavior.
    final double endX = isMainNode
        ? (isChildOnRight ? childBounds.left : childBounds.right)
        : (isChildOnRight ? childBounds.right : childBounds.left);

    final endPoint = Offset(
      endX,
      isMainNode ? childBounds.center.dy : childBounds.bottom,
    );

    // Draw straight line
    canvas.drawLine(startPoint, endPoint, paint);
  }
}
