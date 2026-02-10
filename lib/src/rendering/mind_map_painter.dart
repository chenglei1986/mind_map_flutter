import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import '../models/mind_map_data.dart';
import '../models/node_data.dart';
import '../layout/node_layout.dart';
import '../i18n/mind_map_strings.dart';
import 'node_renderer.dart';
import 'branch_renderer.dart';
import 'arrow_renderer.dart';
import 'summary_renderer.dart';

/// Custom painter for rendering the mind map
class MindMapPainter extends CustomPainter {
  final MindMapData data;
  final Map<String, NodeLayout> nodeLayouts;
  final Set<String> selectedNodeIds;
  final Matrix4 transform;
  final Rect? selectionRect;
  final String? draggedNodeId;
  final Offset? dragPosition;
  final String? dropTargetNodeId;
  final String? dropInsertType;
  final String? selectedArrowId;
  final String? selectedSummaryId;
  final String? arrowSourceNodeId;
  final bool isFocusMode;
  final String? focusedNodeId;
  final String? hoveredExpandNodeId;
  final MindMapStrings strings;
  final Map<String, ui.Image> imageCache;

  MindMapPainter({
    required this.data,
    required this.nodeLayouts,
    this.selectedNodeIds = const {},
    Matrix4? transform,
    this.selectionRect,
    this.draggedNodeId,
    this.dragPosition,
    this.dropTargetNodeId,
    this.dropInsertType,
    this.selectedArrowId,
    this.selectedSummaryId,
    this.arrowSourceNodeId,
    this.isFocusMode = false,
    this.focusedNodeId,
    this.hoveredExpandNodeId,
    this.strings = MindMapStrings.en,
    this.imageCache = const {},
  }) : transform = transform ?? Matrix4.identity();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Apply transformation matrix for zoom and pan
    canvas.transform(transform.storage);

    // Draw in order: branches -> nodes -> arrows -> summaries.
    // mind-elixir-core places arrows/summaries on overlay layers above topics.
    _drawBranches(canvas);
    _drawNodes(canvas);
    _drawArrows(canvas);
    _drawSummaries(canvas);

    // Draw drop target highlight (in canvas coordinates)
    if (dropTargetNodeId != null) {
      _drawDropTargetHighlight(canvas);
    }

    canvas.restore();

    // Draw focus mode indicator (without transform, in screen coordinates)
    if (isFocusMode && focusedNodeId != null) {
      _drawFocusModeIndicator(canvas, size);
    }

    // Draw selection rectangle on top (without transform)
    // This is drawn in screen coordinates, not canvas coordinates
    if (selectionRect != null) {
      _drawSelectionRect(canvas);
    }

    // Draw dragged node preview (without transform, in screen coordinates)
    if (draggedNodeId != null && dragPosition != null) {
      _drawDragPreview(canvas);
    }
  }

  void _drawBranches(Canvas canvas) {
    // Draw all branches starting from root
    BranchRenderer.drawNodeBranches(
      canvas,
      data.nodeData,
      nodeLayouts,
      data.theme,
      0, // Start branch index at 0
    );
  }

  void _drawArrows(Canvas canvas) {
    // Draw all arrows
    ArrowRenderer.drawAllArrows(
      canvas,
      data.arrows,
      nodeLayouts,
      data.theme,
      selectedArrowId,
    );

    // Draw control points for selected arrow
    if (selectedArrowId != null) {
      final arrow = data.arrows.firstWhere(
        (a) => a.id == selectedArrowId,
        orElse: () => data.arrows.first, // Fallback, should not happen
      );

      if (arrow.id == selectedArrowId) {
        ArrowRenderer.drawControlPoints(canvas, arrow, nodeLayouts, data.theme);
      }
    }

    // Draw visual feedback for arrow creation mode
    if (arrowSourceNodeId != null) {
      _drawArrowCreationFeedback(canvas);
    }
  }

  /// Draw visual feedback during arrow creation
  void _drawArrowCreationFeedback(Canvas canvas) {
    if (arrowSourceNodeId == null) return;

    final sourceLayout = nodeLayouts[arrowSourceNodeId!];
    if (sourceLayout == null) return;

    // Draw a highlight around the source node
    final highlightPaint = Paint()
      ..color = data.theme.variables.accentColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final glowPaint = Paint()
      ..color = data.theme.variables.accentColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    final radius = Radius.circular(data.theme.variables.mainRadius);
    final rrect = RRect.fromRectAndRadius(sourceLayout.bounds, radius);

    // Draw glow effect
    canvas.drawRRect(rrect, glowPaint);

    // Draw solid border
    canvas.drawRRect(rrect, highlightPaint);
  }

  void _drawSummaries(Canvas canvas) {
    // Draw all summaries
    SummaryRenderer.drawAllSummaries(
      canvas,
      data.summaries,
      data.nodeData,
      nodeLayouts,
      data.theme,
      selectedSummaryId,
    );
  }

  void _drawNodes(Canvas canvas) {
    final isDesktop = _isDesktopPlatform();

    // In focus mode, only draw the focused node and its descendants
    if (isFocusMode && focusedNodeId != null) {
      final focusedNode = _findNode(data.nodeData, focusedNodeId!);
      if (focusedNode != null) {
        // Draw the focused node as if it were the root
        _drawNodeRecursive(
          canvas,
          focusedNode,
          true,
          renderRootId: focusedNode.id,
          isDesktop: isDesktop,
        );
        return;
      }
    }

    // Normal mode: draw all nodes recursively
    _drawNodeRecursive(
      canvas,
      data.nodeData,
      true,
      renderRootId: data.nodeData.id,
      isDesktop: isDesktop,
    );
  }

  void _drawNodeRecursive(
    Canvas canvas,
    NodeData node,
    bool isRoot, {
    int depth = 0,
    required String renderRootId,
    required bool isDesktop,
  }) {
    final layout = nodeLayouts[node.id];
    if (layout == null) return;

    // Draw the node
    final isSelected = selectedNodeIds.contains(node.id);

    // Root node should never show expand indicator
    // For other nodes:
    // - Expand button (+): always show on desktop and mobile
    // - Collapse button (-): only show on hover (desktop) or always show (mobile/web)
    final showExpandIndicator = !isRoot;
    final showCollapseIndicator =
        !isRoot && (hoveredExpandNodeId == node.id || !isDesktop);

    NodeRenderer.drawNode(
      canvas,
      node,
      layout,
      data.theme,
      isSelected,
      isRoot,
      showExpandIndicator: showExpandIndicator,
      showCollapseIndicator: showCollapseIndicator,
      depth: depth,
      isLeftSideOverride: _computeIsLeftSide(node.id, renderRootId),
      imageCache: imageCache,
    );

    // Recursively draw children with incremented depth
    for (final child in node.children) {
      _drawNodeRecursive(
        canvas,
        child,
        false,
        depth: depth + 1,
        renderRootId: renderRootId,
        isDesktop: isDesktop,
      );
    }
  }

  bool? _computeIsLeftSide(String nodeId, String renderRootId) {
    final nodeLayout = nodeLayouts[nodeId];
    final rootLayout = nodeLayouts[renderRootId];
    if (nodeLayout == null || rootLayout == null) {
      return null;
    }
    return nodeLayout.bounds.center.dx < rootLayout.bounds.center.dx;
  }

  /// Check if the current platform is desktop (Windows, macOS, Linux)
  bool _isDesktopPlatform() {
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
  }

  /// Draw the selection rectangle
  void _drawSelectionRect(Canvas canvas) {
    if (selectionRect == null) return;

    final paint = Paint()
      ..color = data.theme.variables.accentColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = data.theme.variables.accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw filled rectangle
    canvas.drawRect(selectionRect!, paint);

    // Draw border
    canvas.drawRect(selectionRect!, borderPaint);
  }

  /// Draw visual feedback for the node being dragged
  void _drawDragPreview(Canvas canvas) {
    if (draggedNodeId == null || dragPosition == null) return;

    final node = _findNode(data.nodeData, draggedNodeId!);
    if (node == null) return;

    final layout = nodeLayouts[draggedNodeId!];
    if (layout == null) return;

    // Create a semi-transparent preview at the drag position
    canvas.save();

    // Draw a ghost/preview of the node at the cursor position
    final previewPaint = Paint()
      ..color = data.theme.variables.mainBgColor.withValues(alpha: 0.7);

    final borderPaint = Paint()
      ..color = data.theme.variables.accentColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Center the preview on the cursor
    final previewRect = Rect.fromCenter(
      center: dragPosition!,
      width: layout.size.width,
      height: layout.size.height,
    );

    // Draw rounded rectangle background
    final radius = Radius.circular(data.theme.variables.mainRadius);
    final rrect = RRect.fromRectAndRadius(previewRect, radius);

    canvas.drawRRect(rrect, previewPaint);
    canvas.drawRRect(rrect, borderPaint);

    // Draw the node text
    final textSpan = TextSpan(
      text: node.topic,
      style: TextStyle(
        color: data.theme.variables.mainColor.withValues(alpha: 0.8),
        fontSize: node.style?.fontSize ?? 14,
        fontWeight: node.style?.fontWeight ?? FontWeight.normal,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );

    textPainter.layout(maxWidth: layout.size.width - 16);

    final textOffset = Offset(
      previewRect.left + (previewRect.width - textPainter.width) / 2,
      previewRect.top + (previewRect.height - textPainter.height) / 2,
    );

    textPainter.paint(canvas, textOffset);

    canvas.restore();
  }

  /// Draw highlight for the drop target node
  void _drawDropTargetHighlight(Canvas canvas) {
    if (dropTargetNodeId == null) return;

    final layout = nodeLayouts[dropTargetNodeId!];
    if (layout == null) return;

    final mode = dropInsertType ?? 'in';
    final accent = data.theme.variables.accentColor;

    if (mode == 'before' || mode == 'after') {
      final y = mode == 'before' ? layout.bounds.top : layout.bounds.bottom;
      final glowPaint = Paint()
        ..color = accent.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
      final linePaint = Paint()
        ..color = accent.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      final start = Offset(layout.bounds.left, y);
      final end = Offset(layout.bounds.right, y);
      canvas.drawLine(start, end, glowPaint);
      canvas.drawLine(start, end, linePaint);
      return;
    }

    final highlightPaint = Paint()
      ..color = accent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    final glowPaint = Paint()
      ..color = accent.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    final radius = Radius.circular(data.theme.variables.mainRadius);
    final rrect = RRect.fromRectAndRadius(layout.bounds, radius);
    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, highlightPaint);
  }

  /// Find a node in the tree by ID
  NodeData? _findNode(NodeData node, String nodeId) {
    if (node.id == nodeId) return node;

    for (final child in node.children) {
      final found = _findNode(child, nodeId);
      if (found != null) return found;
    }

    return null;
  }

  /// Draw focus mode indicator
  ///
  /// Shows a visual indicator that focus mode is active.
  void _drawFocusModeIndicator(Canvas canvas, Size size) {
    // Draw a banner at the top of the screen
    const bannerHeight = 32.0;
    final bannerRect = Rect.fromLTWH(0, 0, size.width, bannerHeight);

    // Draw banner background
    final bannerPaint = Paint()
      ..color = data.theme.variables.accentColor.withValues(alpha: 0.9);

    canvas.drawRect(bannerRect, bannerPaint);

    // Draw banner text
    final focusedNode = _findNode(data.nodeData, focusedNodeId!);
    final nodeTitle = focusedNode?.topic ?? strings.focusModeUnknownNode;

    final textSpan = TextSpan(
      text: strings.focusModeTitle(nodeTitle),
      style: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );

    textPainter.layout(maxWidth: size.width - 32);

    final textOffset = Offset(16, (bannerHeight - textPainter.height) / 2);

    textPainter.paint(canvas, textOffset);

    // Draw exit hint on the right
    final hintSpan = TextSpan(
      text: strings.focusModeExitHint,
      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
    );

    final hintPainter = TextPainter(
      text: hintSpan,
      textDirection: TextDirection.ltr,
    );

    hintPainter.layout();

    final hintOffset = Offset(
      size.width - hintPainter.width - 16,
      (bannerHeight - hintPainter.height) / 2,
    );

    hintPainter.paint(canvas, hintOffset);
  }

  @override
  bool shouldRepaint(MindMapPainter oldDelegate) {
    // Check high-frequency interaction fields first to avoid expensive deep
    // equality on large mind-map structures every pointer frame.
    if (transform != oldDelegate.transform) return true;
    if (selectionRect != oldDelegate.selectionRect) return true;
    if (draggedNodeId != oldDelegate.draggedNodeId) return true;
    if (dragPosition != oldDelegate.dragPosition) return true;
    if (dropTargetNodeId != oldDelegate.dropTargetNodeId) return true;
    if (dropInsertType != oldDelegate.dropInsertType) return true;
    if (selectedArrowId != oldDelegate.selectedArrowId) return true;
    if (selectedSummaryId != oldDelegate.selectedSummaryId) return true;
    if (arrowSourceNodeId != oldDelegate.arrowSourceNodeId) return true;
    if (hoveredExpandNodeId != oldDelegate.hoveredExpandNodeId) return true;

    // Lower-frequency structural/style changes.
    if (isFocusMode != oldDelegate.isFocusMode) return true;
    if (focusedNodeId != oldDelegate.focusedNodeId) return true;
    if (strings != oldDelegate.strings) return true;
    if (imageCache != oldDelegate.imageCache) return true;
    if (selectedNodeIds != oldDelegate.selectedNodeIds) return true;
    if (nodeLayouts != oldDelegate.nodeLayouts) return true;
    if (data != oldDelegate.data) return true;

    return false;
  }

  @override
  bool shouldRebuildSemantics(MindMapPainter oldDelegate) {
    // Rebuild semantics only when data reference changes.
    return !identical(data, oldDelegate.data);
  }
}
