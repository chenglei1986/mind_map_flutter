import 'package:flutter/material.dart';
import '../layout/node_layout.dart';
import '../models/layout_direction.dart';
import '../models/mind_map_theme.dart';
import '../models/node_data.dart';
import '../models/summary_data.dart';
import '../models/summary_style.dart';

/// Renderer for summary brackets that group sibling nodes.
///
/// Geometry follows mind-elixir-core `summary.ts`:
/// - wrapper bounds use subtree extents
/// - top/bottom offsets use `single ? 10 : 20`
/// - non-root parent adds extra vertical offset `+10`
/// - bracket path uses curved side hooks, not square caps
class SummaryRenderer {
  /// Matches mind-elixir-core stroke width.
  static const double bracketWidth = 2.0;

  /// Horizontal distance from summary side to the short middle connector.
  static const double bracketCapLength = 10.0;

  /// Kept for API/test compatibility.
  static const double bracketPadding = 10.0;

  /// Kept for API/test compatibility (mind-elixir uses topic padding for label).
  static const EdgeInsets labelPadding = EdgeInsets.all(3.0);

  static const double _singleRangeInset = 10.0;
  static const double _multiRangeInset = 20.0;
  static const double _nonRootVerticalOffset = 10.0;
  static const double _labelAnchorDistance = 20.0;
  static const double _labelMaxWidth = 200.0;
  static const double _selectedHighlightOpacity = 0.45;
  static const double _selectedHighlightStrokeWidth = 6.0;

  /// Draw a summary bracket around a group of sibling nodes.
  static void drawSummary(
    Canvas canvas,
    SummaryData summary,
    NodeData parentNode,
    Map<String, NodeLayout> nodeLayouts,
    MindMapTheme theme, {
    bool parentHasParent = false,
    int parentDepth = 0,
    bool isSelected = false,
  }) {
    final parentLayout = nodeLayouts[summary.parentNodeId];
    if (parentLayout == null) return;

    final geometry = _resolveGeometry(
      summary: summary,
      parentNode: parentNode,
      parentLayout: parentLayout,
      nodeLayouts: nodeLayouts,
      parentHasParent: parentHasParent,
      parentDepth: parentDepth,
      theme: theme,
    );
    if (geometry == null) return;

    if (isSelected) {
      _drawSelectedBracketHighlight(canvas, geometry, theme);
    }
    _drawBracket(canvas, geometry, theme, summary.style);
    final label = summary.label;
    if (label != null && label.isNotEmpty) {
      _drawLabel(
        canvas,
        label,
        geometry,
        theme,
        summary.style,
        isSelected: isSelected,
      );
    }
  }

  static void _drawSelectedBracketHighlight(
    Canvas canvas,
    _SummaryGeometry geometry,
    MindMapTheme theme,
  ) {
    final paint = Paint()
      ..color = theme.variables.selectedColor.withValues(alpha: 
        _selectedHighlightOpacity,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = _selectedHighlightStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    if (geometry.isOnRight) {
      final right = geometry.right;
      path.moveTo(right - 10, geometry.top);
      path.cubicTo(
        right - 5,
        geometry.top,
        right,
        geometry.top + 5,
        right,
        geometry.top + 10,
      );
      path.lineTo(right, geometry.bottom - 10);
      path.cubicTo(
        right,
        geometry.bottom - 5,
        right - 5,
        geometry.bottom,
        right - 10,
        geometry.bottom,
      );
      path.moveTo(right, geometry.midY);
      path.lineTo(right + bracketCapLength, geometry.midY);
    } else {
      final left = geometry.left;
      path.moveTo(left + 10, geometry.top);
      path.cubicTo(
        left + 5,
        geometry.top,
        left,
        geometry.top + 5,
        left,
        geometry.top + 10,
      );
      path.lineTo(left, geometry.bottom - 10);
      path.cubicTo(
        left,
        geometry.bottom - 5,
        left + 5,
        geometry.bottom,
        left + 10,
        geometry.bottom,
      );
      path.moveTo(left, geometry.midY);
      path.lineTo(left - bracketCapLength, geometry.midY);
    }

    canvas.drawPath(path, paint);
  }

  static void _drawBracket(
    Canvas canvas,
    _SummaryGeometry geometry,
    MindMapTheme theme,
    SummaryStyle? style,
  ) {
    final color = style?.stroke ?? style?.labelColor ?? theme.variables.color;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = bracketWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    if (geometry.isOnRight) {
      final right = geometry.right;
      path.moveTo(right - 10, geometry.top);
      path.cubicTo(
        right - 5,
        geometry.top,
        right,
        geometry.top + 5,
        right,
        geometry.top + 10,
      );
      path.lineTo(right, geometry.bottom - 10);
      path.cubicTo(
        right,
        geometry.bottom - 5,
        right - 5,
        geometry.bottom,
        right - 10,
        geometry.bottom,
      );
      path.moveTo(right, geometry.midY);
      path.lineTo(right + bracketCapLength, geometry.midY);
    } else {
      final left = geometry.left;
      path.moveTo(left + 10, geometry.top);
      path.cubicTo(
        left + 5,
        geometry.top,
        left,
        geometry.top + 5,
        left,
        geometry.top + 10,
      );
      path.lineTo(left, geometry.bottom - 10);
      path.cubicTo(
        left,
        geometry.bottom - 5,
        left + 5,
        geometry.bottom,
        left + 10,
        geometry.bottom,
      );
      path.moveTo(left, geometry.midY);
      path.lineTo(left - bracketCapLength, geometry.midY);
    }

    canvas.drawPath(path, paint);
  }

  static void _drawLabel(
    Canvas canvas,
    String label,
    _SummaryGeometry geometry,
    MindMapTheme theme,
    SummaryStyle? style, {
    bool isSelected = false,
  }) {
    final color = style?.labelColor ?? style?.stroke ?? theme.variables.color;
    final padding = theme.variables.topicPadding;
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: _labelMaxWidth - padding.horizontal);

    final boxWidth = textPainter.width + padding.horizontal;
    final boxHeight = textPainter.height + padding.vertical;
    final boxLeft = geometry.isOnRight
        ? geometry.right + _labelAnchorDistance
        : geometry.left - _labelAnchorDistance - boxWidth;
    final boxTop = geometry.midY - boxHeight / 2;
    final boxRect = Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight);

    if (isSelected) {
      final selectedFill = Paint()
        ..color = theme.variables.selectedColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      final selectedStroke = Paint()
        ..color = theme.variables.selectedColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final selectedRRect = RRect.fromRectAndRadius(
        boxRect,
        const Radius.circular(4.0),
      );
      canvas.drawRRect(selectedRRect, selectedFill);
      canvas.drawRRect(selectedRRect, selectedStroke);
    }

    final textOffset = Offset(boxLeft + padding.left, boxTop + padding.top);
    textPainter.paint(canvas, textOffset);
  }

  /// Draw all summaries in the mind map.
  static void drawAllSummaries(
    Canvas canvas,
    List<SummaryData> summaries,
    NodeData rootNode,
    Map<String, NodeLayout> nodeLayouts,
    MindMapTheme theme, [
    String? selectedSummaryId,
  ]
  ) {
    for (final summary in summaries) {
      final context = _findNodeContext(rootNode, summary.parentNodeId, 0);
      if (context == null) continue;
      drawSummary(
        canvas,
        summary,
        context.node,
        nodeLayouts,
        theme,
        parentHasParent: context.depth > 0,
        parentDepth: context.depth,
        isSelected:
            selectedSummaryId != null && summary.id == selectedSummaryId,
      );
    }
  }

  /// Get the bounds of a summary bracket for hit testing.
  static Rect? getSummaryBounds(
    SummaryData summary,
    NodeData parentNode,
    Map<String, NodeLayout> nodeLayouts, {
    bool parentHasParent = false,
    int parentDepth = 0,
    MindMapTheme? theme,
  }) {
    final parentLayout = nodeLayouts[summary.parentNodeId];
    if (parentLayout == null) return null;

    final geometry = _resolveGeometry(
      summary: summary,
      parentNode: parentNode,
      parentLayout: parentLayout,
      nodeLayouts: nodeLayouts,
      parentHasParent: parentHasParent,
      parentDepth: parentDepth,
      theme: theme ?? MindMapTheme.light,
    );
    if (geometry == null) return null;

    if (geometry.isOnRight) {
      return Rect.fromLTRB(
        geometry.right - 12,
        geometry.top,
        geometry.right + _labelAnchorDistance + _labelMaxWidth,
        geometry.bottom,
      );
    }

    return Rect.fromLTRB(
      geometry.left - (_labelAnchorDistance + _labelMaxWidth),
      geometry.top,
      geometry.left + 12,
      geometry.bottom,
    );
  }

  /// Get the bounds of a summary label box for precise text editing overlay.
  static Rect? getSummaryLabelBounds(
    SummaryData summary,
    NodeData parentNode,
    Map<String, NodeLayout> nodeLayouts,
    MindMapTheme theme, {
    bool parentHasParent = false,
    int parentDepth = 0,
    String? overrideLabel,
  }) {
    final parentLayout = nodeLayouts[summary.parentNodeId];
    if (parentLayout == null) return null;

    final geometry = _resolveGeometry(
      summary: summary,
      parentNode: parentNode,
      parentLayout: parentLayout,
      nodeLayouts: nodeLayouts,
      parentHasParent: parentHasParent,
      parentDepth: parentDepth,
      theme: theme,
    );
    if (geometry == null) return null;

    final label = overrideLabel ?? summary.label ?? '';
    final padding = theme.variables.topicPadding;
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: _labelMaxWidth - padding.horizontal);

    final textWidth = label.isEmpty ? 64.0 : textPainter.width;
    final textHeight = label.isEmpty ? 16.0 * 1.2 : textPainter.height;
    final boxWidth = textWidth + padding.horizontal;
    final boxHeight = textHeight + padding.vertical;
    final boxLeft = geometry.isOnRight
        ? geometry.right + _labelAnchorDistance
        : geometry.left - _labelAnchorDistance - boxWidth;
    final boxTop = geometry.midY - boxHeight / 2;

    return Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight);
  }

  static _SummaryGeometry? _resolveGeometry({
    required SummaryData summary,
    required NodeData parentNode,
    required NodeLayout parentLayout,
    required Map<String, NodeLayout> nodeLayouts,
    required bool parentHasParent,
    required int parentDepth,
    required MindMapTheme theme,
  }) {
    if (summary.startIndex < 0 ||
        summary.endIndex >= parentNode.children.length ||
        summary.startIndex > summary.endIndex) {
      return null;
    }

    final isSingle = summary.startIndex == summary.endIndex;
    final inset = isSingle ? _singleRangeInset : _multiRangeInset;
    double left = double.infinity;
    double right = double.negativeInfinity;
    double startTop = 0;
    double endBottom = 0;

    for (int i = summary.startIndex; i <= summary.endIndex; i++) {
      final child = parentNode.children[i];
      final wrapper = _collectVisibleSubtreeBounds(
        child,
        nodeLayouts,
        depth: parentDepth + 1,
        theme: theme,
      );
      if (wrapper == null) return null;

      if (i == summary.startIndex) {
        startTop = wrapper.top + inset;
      }
      if (i == summary.endIndex) {
        endBottom = wrapper.bottom - inset;
      }
      left = left < wrapper.left ? left : wrapper.left;
      right = right > wrapper.right ? right : wrapper.right;
    }

    if (!left.isFinite || !right.isFinite) return null;

    final extraOffset = parentHasParent ? _nonRootVerticalOffset : 0.0;
    final top = startTop + extraOffset;
    final bottom = endBottom + extraOffset;
    if (bottom <= top) return null;

    // For root-level summaries, determine side by geometry so switching
    // layout mode does not rely on persisted child.direction.
    final direction = parentHasParent ? parentNode.direction : null;
    final isOnRight = _resolveSide(
      direction,
      parentLayout: parentLayout,
      left: left,
      right: right,
    );

    return _SummaryGeometry(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      midY: (top + bottom) / 2,
      isOnRight: isOnRight,
    );
  }

  static bool _resolveSide(
    LayoutDirection? direction, {
    required NodeLayout parentLayout,
    required double left,
    required double right,
  }) {
    if (direction == LayoutDirection.left) return false;
    if (direction == LayoutDirection.right) return true;
    final centerX = (left + right) / 2;
    return centerX > parentLayout.bounds.center.dx;
  }

  static Rect? _collectVisibleSubtreeBounds(
    NodeData node,
    Map<String, NodeLayout> nodeLayouts, {
    required int depth,
    required MindMapTheme theme,
  }) {
    final layout = nodeLayouts[node.id];
    if (layout == null) return null;

    Rect bounds = _toVirtualWrapperBounds(layout.bounds, depth, theme);
    if (node.expanded) {
      for (final child in node.children) {
        final childBounds = _collectVisibleSubtreeBounds(
          child,
          nodeLayouts,
          depth: depth + 1,
          theme: theme,
        );
        if (childBounds != null) {
          bounds = bounds.expandToInclude(childBounds);
        }
      }
    }
    return bounds;
  }

  static Rect _toVirtualWrapperBounds(
    Rect topicBounds,
    int depth,
    MindMapTheme theme,
  ) {
    if (depth <= 0) {
      return topicBounds;
    }

    if (depth == 1) {
      // me-main > me-wrapper > me-parent has margin: 10px
      return Rect.fromLTWH(
        topicBounds.left - 10.0,
        topicBounds.top - 10.0,
        topicBounds.width + 20.0,
        topicBounds.height + 20.0,
      );
    }

    // me-parent has padding: 6px var(--node-gap-x)
    final gapX = theme.variables.nodeGapX;
    return Rect.fromLTWH(
      topicBounds.left - gapX,
      topicBounds.top - 6.0,
      topicBounds.width + gapX * 2,
      topicBounds.height + 12.0,
    );
  }

  static _NodeContext? _findNodeContext(
    NodeData node,
    String nodeId,
    int depth,
  ) {
    if (node.id == nodeId) {
      return _NodeContext(node: node, depth: depth);
    }
    for (final child in node.children) {
      final context = _findNodeContext(child, nodeId, depth + 1);
      if (context != null) return context;
    }
    return null;
  }
}

class _SummaryGeometry {
  final double left;
  final double right;
  final double top;
  final double bottom;
  final double midY;
  final bool isOnRight;

  const _SummaryGeometry({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.midY,
    required this.isOnRight,
  });
}

class _NodeContext {
  final NodeData node;
  final int depth;

  const _NodeContext({required this.node, required this.depth});
}
