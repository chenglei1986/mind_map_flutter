import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../layout/node_layout.dart';
import '../models/node_data.dart';
import '../models/arrow_data.dart';
import '../rendering/node_renderer.dart';
import '../rendering/summary_renderer.dart';
import '../widgets/mind_map_controller.dart';
import '../widgets/mind_map_widget.dart';
import 'drag_manager.dart';
import '../utils/arrow_utils.dart';
import '../utils/url_opener.dart';

/// Handles all user interaction gestures
class GestureHandler {
  final MindMapController controller;
  Map<String, NodeLayout> nodeLayouts;
  Matrix4 transform;
  bool isReadOnly;
  final void Function(String nodeId)? onBeginEdit;
  final void Function(String summaryId)? onBeginEditSummary;
  final void Function(String arrowId)? onBeginEditArrow;
  final void Function(Rect? rect)? onSelectionRectChanged;
  final void Function(String nodeId, Offset position)? onShowContextMenu;
  final void Function()? onTapEmptySpace;
  final DragManager? dragManager;

  String? _lastTappedNodeId;
  int _lastTapTime = 0;
  String? _lastTappedSummaryId;
  int _lastSummaryTapTime = 0;
  String? _lastTappedArrowId;
  int _lastArrowTapTime = 0;
  static const int _doubleTapThreshold = 300; // milliseconds

  // Drag selection state
  Offset? _dragStartPosition;
  Offset? _dragCurrentPosition;
  bool _isDraggingSelection = false;
  bool _isPanningCanvas = false;
  bool _isScalingGesture = false;
  int _lastSelectionScanMicros = 0;
  static const int _selectionScanIntervalMicros = 16000; // ~60fps

  // Node drag state
  bool _isDraggingNode = false;

  // Arrow control point drag state
  bool _isDraggingControlPoint = false;
  String? _draggedArrowId;
  int? _draggedControlPointIndex;
  Offset? _controlPointDragStart;

  /// Get the current selection rectangle (for rendering)
  Rect? get selectionRect => _getSelectionRect();

  GestureHandler({
    required this.controller,
    required this.nodeLayouts,
    required this.transform,
    this.isReadOnly = false,
    this.onBeginEdit,
    this.onBeginEditSummary,
    this.onBeginEditArrow,
    this.onSelectionRectChanged,
    this.onShowContextMenu,
    this.onTapEmptySpace,
    this.dragManager,
  });

  void updateContext({
    required Map<String, NodeLayout> nodeLayouts,
    required Matrix4 transform,
    bool? isReadOnly,
  }) {
    this.nodeLayouts = nodeLayouts;
    this.transform = transform;
    if (isReadOnly != null) {
      this.isReadOnly = isReadOnly;
    }
  }

  /// Handle tap down event
  void handleTapDown(TapDownDetails details) {
    // Store tap position for later processing
  }

  /// Handle tap up event with optional modifier keys
  void handleTapUp(
    TapUpDetails details, {
    bool isCtrlPressed = false,
    bool isEditMode = false,
  }) {
    // Skip handling if in edit mode - let the edit overlay handle it
    // This prevents exiting edit mode when clicking on node padding areas
    if (isEditMode) {
      return;
    }

    if (isReadOnly) {
      final hyperlinkHit = hitTestHyperlinkIndicator(details.localPosition);
      if (hyperlinkHit != null) {
        _handleHyperlinkClick(hyperlinkHit);
        return;
      }

      final expandIndicatorHit = hitTestExpandIndicator(details.localPosition);
      if (expandIndicatorHit != null) {
        controller.toggleNodeExpanded(expandIndicatorHit);
      }
      return;
    }

    // Check if we're in arrow creation mode
    if (controller.isArrowCreationMode) {
      _handleArrowCreationTap(details.localPosition);
      return;
    }

    // Check if we're in summary creation mode
    if (controller.isSummaryCreationMode) {
      _handleSummaryCreationTap(details.localPosition);
      return;
    }

    // First check if we hit a hyperlink indicator
    final hyperlinkHit = hitTestHyperlinkIndicator(details.localPosition);
    if (hyperlinkHit != null) {
      // Open the hyperlink
      _handleHyperlinkClick(hyperlinkHit);
      return;
    }

    // Check if we hit a summary bracket/label.
    // Double-tap on summary enters summary label edit mode.
    final summaryId = hitTestSummary(details.localPosition);
    if (summaryId != null) {
      controller.selectSummary(summaryId);
      controller.selectionManager.clearSelection();
      controller.deselectArrow();

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      if (_lastTappedSummaryId == summaryId &&
          currentTime - _lastSummaryTapTime < _doubleTapThreshold) {
        _handleSummaryDoubleTap(summaryId);
        _lastTappedSummaryId = null;
        _lastSummaryTapTime = 0;
      } else {
        _lastTappedSummaryId = summaryId;
        _lastSummaryTapTime = currentTime;
      }
      return;
    }

    // Then check if we hit an expand indicator
    final expandIndicatorHit = hitTestExpandIndicator(details.localPosition);
    if (expandIndicatorHit != null) {
      // Toggle expand/collapse state
      controller.toggleNodeExpanded(expandIndicatorHit);
      return;
    }

    final nodeId = hitTestNode(details.localPosition);

    if (nodeId != null) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // Check for double tap
      if (_lastTappedNodeId == nodeId &&
          currentTime - _lastTapTime < _doubleTapThreshold) {
        // Double tap detected - enter edit mode
        controller.deselectSummary();
        _handleDoubleTap(nodeId);
        _lastTappedNodeId = null;
        _lastTapTime = 0;
      } else {
        // Single tap - select node
        _handleSingleTap(nodeId, isCtrlPressed: isCtrlPressed);
        controller.deselectArrow();
        controller.deselectSummary();
        _lastTappedNodeId = nodeId;
        _lastTapTime = currentTime;
      }
      return;
    }

    // Check if we hit an arrow.
    // Node hit has higher priority when the two overlap.
    final arrowId = hitTestArrow(details.localPosition);
    if (arrowId != null) {
      controller.selectArrow(arrowId);
      controller.selectionManager.clearSelection();
      controller.deselectSummary();

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      if (_lastTappedArrowId == arrowId &&
          currentTime - _lastArrowTapTime < _doubleTapThreshold) {
        _handleArrowDoubleTap(arrowId);
        _lastTappedArrowId = null;
        _lastArrowTapTime = 0;
      } else {
        _lastTappedArrowId = arrowId;
        _lastArrowTapTime = currentTime;
      }
      return;
    }

    // Clicked on empty space - clear selection if not holding Ctrl
    if (!isCtrlPressed) {
      controller.selectionManager.clearSelection();
      // Also deselect any selected arrow
      controller.deselectArrow();
      controller.deselectSummary();
    }
    // Notify that empty space was tapped (to finish editing)
    onTapEmptySpace?.call();
  }

  /// Handle tap during arrow creation mode
  void _handleArrowCreationTap(Offset position) {
    final nodeId = hitTestNode(position);

    if (nodeId == null) {
      // Clicked on empty space - exit arrow creation mode
      controller.exitArrowCreationMode();
      return;
    }

    if (controller.arrowSourceNodeId == null) {
      // First click - select source node
      controller.selectArrowSourceNode(nodeId);
    } else {
      // Second click - select target node and create arrow
      if (nodeId == controller.arrowSourceNodeId) {
        // Clicked on the same node - cancel
        controller.exitArrowCreationMode();
      } else {
        // Create arrow between source and target
        controller.selectArrowTargetNode(nodeId);
      }
    }
  }

  /// Handle tap during summary creation mode
  void _handleSummaryCreationTap(Offset position) {
    final nodeId = hitTestNode(position);

    if (nodeId == null) {
      // Clicked on empty space - try to create summary if nodes are selected
      if (controller.summarySelectedNodeIds.isNotEmpty) {
        try {
          controller.createSummaryFromSelection();
        } catch (e) {
          debugPrint('Failed to create summary: $e');
        }
      }
      // Exit summary creation mode
      controller.exitSummaryCreationMode();
      return;
    }

    // Toggle node selection
    controller.toggleSummaryNodeSelection(nodeId);
  }

  /// Handle single tap (node selection)
  void _handleSingleTap(String nodeId, {bool isCtrlPressed = false}) {
    if (isCtrlPressed) {
      // Multi-select mode: toggle selection
      controller.selectionManager.toggleSelection(nodeId);
    } else {
      // Single select mode: select only this node
      controller.selectionManager.selectNode(nodeId);
    }
  }

  /// Handle double tap (enter edit mode)
  void _handleDoubleTap(String nodeId) {
    // Emit begin edit event
    controller.emitEvent(BeginEditEvent(nodeId));

    // Call the edit callback if provided
    onBeginEdit?.call(nodeId);
  }

  void _handleSummaryDoubleTap(String summaryId) {
    controller.selectSummary(summaryId);
    onBeginEditSummary?.call(summaryId);
  }

  void _handleArrowDoubleTap(String arrowId) {
    controller.selectArrow(arrowId);
    onBeginEditArrow?.call(arrowId);
  }

  /// Handle hyperlink click
  void _handleHyperlinkClick(String nodeId) {
    // Find the node
    final rootNode = controller.getData().nodeData;
    final node = _findNodeById(rootNode, nodeId);

    if (node != null && node.hyperLink != null && node.hyperLink!.isNotEmpty) {
      final normalizedUrl = _normalizeHyperlink(node.hyperLink!);
      if (normalizedUrl != null) {
        unawaited(_openHyperlink(normalizedUrl));
      }

      // Emit hyperlink click event
      controller.emitEvent(HyperlinkClickEvent(nodeId, node.hyperLink!));

      debugPrint('Hyperlink clicked: ${node.hyperLink}');
    }
  }

  String? _normalizeHyperlink(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      return parsed.toString();
    }

    final withHttps = Uri.tryParse('https://$trimmed');
    return withHttps?.toString();
  }

  Future<void> _openHyperlink(String normalizedUrl) async {
    try {
      await openExternalUrl(normalizedUrl);
    } catch (e) {
      debugPrint('Failed to open hyperlink: $e');
    }
  }

  /// Handle long press event
  ///
  void handleLongPress(Offset position, {bool isEditMode = false}) {
    // Skip handling if in edit mode
    if (isEditMode || isReadOnly) {
      return;
    }

    final nodeId = hitTestNode(position);
    if (nodeId != null) {
      // Show context menu for the node
      onShowContextMenu?.call(nodeId, position);
    }
  }

  /// Handle secondary tap (right-click) event
  ///
  void handleSecondaryTapUp(TapUpDetails details, {bool isEditMode = false}) {
    // Skip handling if in edit mode
    if (isEditMode || isReadOnly) {
      return;
    }

    final nodeId = hitTestNode(details.localPosition);
    if (nodeId != null) {
      // Show context menu for the node
      onShowContextMenu?.call(nodeId, details.localPosition);
    }
  }

  /// Handle pan start (for dragging)
  void handlePanStart(DragStartDetails details) {
    if (isReadOnly) {
      _isDraggingSelection = false;
      _isDraggingNode = false;
      _isDraggingControlPoint = false;
      _isPanningCanvas = true;
      controller.zoomPanManager.handlePanStart(details.localPosition);
      return;
    }

    _isPanningCanvas = false;

    // First check if we're dragging an arrow control point
    final controlPointHit = hitTestArrowControlPoint(details.localPosition);
    if (controlPointHit != null) {
      _isDraggingControlPoint = true;
      _draggedArrowId = controlPointHit.$1;
      _draggedControlPointIndex = controlPointHit.$2;
      _controlPointDragStart = details.localPosition;
      _isDraggingSelection = false;
      _isDraggingNode = false;
      return;
    }

    final nodeId = hitTestNode(details.localPosition);

    if (nodeId == null) {
      // On touch devices, pan the canvas instead of drag selection
      if (details.kind == PointerDeviceKind.touch ||
          details.kind == PointerDeviceKind.stylus) {
        _isDraggingSelection = false;
        _isDraggingNode = false;
        _isDraggingControlPoint = false;
        _isPanningCanvas = true;
        controller.zoomPanManager.handlePanStart(details.localPosition);
      } else {
        // Start drag selection on empty space (mouse/trackpad)
        _dragStartPosition = details.localPosition;
        _dragCurrentPosition = details.localPosition;
        _isDraggingSelection = true;
        _isDraggingNode = false;
        _isDraggingControlPoint = false;
        onSelectionRectChanged?.call(_getSelectionRect());
      }
    } else {
      // Start node dragging
      _isDraggingSelection = false;
      _isDraggingNode = true;
      _isDraggingControlPoint = false;

      // Start drag operation in DragManager
      dragManager?.startDrag(nodeId, details.localPosition);
    }
  }

  /// Handle scale start (for pinch-to-zoom and single-finger drag)
  void handleScaleStart(
    ScaleStartDetails details, {
    bool isRightMouseButton = false,
    bool isSpacePressed = false,
    bool isEditMode = false,
  }) {
    // Skip handling if in edit mode - let the edit overlay handle it
    if (isEditMode) {
      return;
    }

    _isPanningCanvas = false;
    _isScalingGesture = false;

    if (isReadOnly) {
      _isDraggingSelection = false;
      _isDraggingNode = false;
      _isDraggingControlPoint = false;

      if (isRightMouseButton) {
        return;
      }

      if (details.pointerCount > 1) {
        _isScalingGesture = true;
        controller.zoomPanManager.handleScaleStart(details);
      } else {
        _isPanningCanvas = true;
        controller.zoomPanManager.handlePanStart(details.localFocalPoint);
      }
      return;
    }

    // Skip drag selection if right mouse button is pressed
    if (isRightMouseButton) {
      return;
    }

    // Support space + left mouse button drag (like mind-elixir-core)
    if (isSpacePressed) {
      _isDraggingSelection = false;
      _isDraggingNode = false;
      _isDraggingControlPoint = false;
      _isPanningCanvas = true;
      controller.zoomPanManager.handlePanStart(details.localFocalPoint);
      return;
    }

    if (details.pointerCount > 1) {
      _isDraggingSelection = false;
      _isDraggingNode = false;
      _isDraggingControlPoint = false;
      _isScalingGesture = true;
      controller.zoomPanManager.handleScaleStart(details);
      return;
    }

    final position = details.localFocalPoint;

    // First check if we're dragging an arrow control point
    final controlPointHit = hitTestArrowControlPoint(position);
    if (controlPointHit != null) {
      _isDraggingControlPoint = true;
      _draggedArrowId = controlPointHit.$1;
      _draggedControlPointIndex = controlPointHit.$2;
      _controlPointDragStart = position;
      _isDraggingSelection = false;
      _isDraggingNode = false;
      return;
    }

    // Check if we hit an expand indicator - don't start drag selection
    final expandIndicatorHit = hitTestExpandIndicator(position);
    if (expandIndicatorHit != null) {
      return;
    }

    final nodeId = hitTestNode(position);
    if (nodeId == null) {
      // On mobile platforms, pan the canvas instead of drag selection
      if (_preferPanOnEmptySpace()) {
        _isDraggingSelection = false;
        _isDraggingNode = false;
        _isDraggingControlPoint = false;
        _isPanningCanvas = true;
        controller.zoomPanManager.handlePanStart(position);
      } else {
        // Start drag selection on empty space (desktop)
        _dragStartPosition = position;
        _dragCurrentPosition = position;
        _isDraggingSelection = true;
        _isDraggingNode = false;
        _isDraggingControlPoint = false;
        onSelectionRectChanged?.call(_getSelectionRect());
      }
    } else {
      // Start node dragging
      _isDraggingSelection = false;
      _isDraggingNode = true;
      _isDraggingControlPoint = false;
      dragManager?.startDrag(nodeId, position);
    }
  }

  /// Handle pan update (for dragging)
  void handlePanUpdate(DragUpdateDetails details) {
    if (_isDraggingControlPoint &&
        _draggedArrowId != null &&
        _draggedControlPointIndex != null &&
        _controlPointDragStart != null) {
      // Update arrow control point position
      _updateArrowControlPoint(details.localPosition);
    } else if (_isPanningCanvas) {
      controller.zoomPanManager.handlePanUpdate(details.delta);
    } else if (_isDraggingSelection && _dragStartPosition != null) {
      // Update drag selection rectangle
      _dragCurrentPosition = details.localPosition;
      onSelectionRectChanged?.call(_getSelectionRect());

      _scanSelectionIfDue();
    } else if (_isDraggingNode && dragManager != null) {
      // Update node drag position and detect drop targets
      dragManager!.updateDrag(
        details.localPosition,
        nodeLayouts,
        transform,
        controller.getData().nodeData,
      );
    }
  }

  /// Update arrow control point during drag
  void _updateArrowControlPoint(Offset currentPosition) {
    if (_draggedArrowId == null ||
        _draggedControlPointIndex == null ||
        _controlPointDragStart == null) {
      return;
    }

    final arrow = controller.getArrow(_draggedArrowId!);
    if (arrow == null) return;

    // Transform positions to canvas coordinates
    final inverseTransform = Matrix4.inverted(transform);
    final transformedStart = MatrixUtils.transformPoint(
      inverseTransform,
      _controlPointDragStart!,
    );
    final transformedCurrent = MatrixUtils.transformPoint(
      inverseTransform,
      currentPosition,
    );

    // Calculate the delta from the drag
    final dragDelta = transformedCurrent - transformedStart;

    final fromLayout = nodeLayouts[arrow.fromNodeId];
    final toLayout = nodeLayouts[arrow.toNodeId];
    if (fromLayout == null || toLayout == null) return;
    final (baseDelta1, baseDelta2) = _resolveArrowDeltas(
      arrow,
      fromLayout,
      toLayout,
    );

    // Update the appropriate control point.
    // Use effective deltas as the base so first drag of "auto" arrows (zero delta)
    // doesn't jump from rendered handle position.
    Offset newDelta1 = baseDelta1;
    Offset newDelta2 = baseDelta2;

    if (_draggedControlPointIndex == 0) {
      newDelta1 = baseDelta1 + dragDelta;
    } else {
      newDelta2 = baseDelta2 + dragDelta;
    }

    // Update the arrow
    controller.updateArrowControlPoints(_draggedArrowId!, newDelta1, newDelta2);

    // Update drag start for next update
    _controlPointDragStart = currentPosition;
  }

  /// Handle scale update (for pinch-to-zoom and single-finger drag)
  void handleScaleUpdate(
    ScaleUpdateDetails details, {
    bool isRightMouseButton = false,
    bool isSpacePressed = false,
  }) {
    // Skip if right mouse button is pressed (handled by Listener)
    if (isRightMouseButton) {
      return;
    }

    if (_isScalingGesture && details.pointerCount > 1) {
      controller.zoomPanManager.handleScaleUpdate(details);
      return;
    }

    final position = details.localFocalPoint;

    if (_isDraggingControlPoint &&
        _draggedArrowId != null &&
        _draggedControlPointIndex != null &&
        _controlPointDragStart != null) {
      _updateArrowControlPoint(position);
    } else if (_isPanningCanvas || isSpacePressed) {
      controller.zoomPanManager.handlePanUpdate(details.focalPointDelta);
    } else if (_isDraggingSelection && _dragStartPosition != null) {
      _dragCurrentPosition = position;
      onSelectionRectChanged?.call(_getSelectionRect());
      _scanSelectionIfDue();
    } else if (_isDraggingNode && dragManager != null) {
      dragManager!.updateDrag(
        position,
        nodeLayouts,
        transform,
        controller.getData().nodeData,
      );
    }
  }

  void _scanSelectionIfDue() {
    final now = DateTime.now().microsecondsSinceEpoch;
    if (now - _lastSelectionScanMicros < _selectionScanIntervalMicros) {
      return;
    }
    _lastSelectionScanMicros = now;
    _selectNodesInRect();
  }

  /// Handle pan end (for dragging)
  void handlePanEnd(DragEndDetails details) {
    if (_isDraggingControlPoint) {
      // Finalize control point drag
      _isDraggingControlPoint = false;
      _draggedArrowId = null;
      _draggedControlPointIndex = null;
      _controlPointDragStart = null;
    } else if (_isPanningCanvas) {
      controller.zoomPanManager.handlePanEnd();
      _isPanningCanvas = false;
    } else if (_isDraggingSelection) {
      // Finalize drag selection
      _selectNodesInRect();

      // Clear drag state
      _dragStartPosition = null;
      _dragCurrentPosition = null;
      _isDraggingSelection = false;
      onSelectionRectChanged?.call(null);
    } else if (_isDraggingNode && dragManager != null) {
      _completeNodeDrag();
      _isDraggingNode = false;
    }
  }

  /// Handle scale end (for pinch-to-zoom and single-finger drag)
  void handleScaleEnd(ScaleEndDetails details) {
    if (_isScalingGesture) {
      controller.zoomPanManager.handleScaleEnd(details);
      _isScalingGesture = false;
      return;
    }

    if (_isDraggingControlPoint) {
      _isDraggingControlPoint = false;
      _draggedArrowId = null;
      _draggedControlPointIndex = null;
      _controlPointDragStart = null;
    } else if (_isPanningCanvas) {
      controller.zoomPanManager.handlePanEnd();
      _isPanningCanvas = false;
    } else if (_isDraggingSelection) {
      _selectNodesInRect();
      _dragStartPosition = null;
      _dragCurrentPosition = null;
      _isDraggingSelection = false;
      onSelectionRectChanged?.call(null);
    } else if (_isDraggingNode && dragManager != null) {
      _completeNodeDrag();
      _isDraggingNode = false;
    }
  }

  void _completeNodeDrag() {
    if (dragManager == null) return;

    dragManager!.resolveDropTargetNow(
      nodeLayouts,
      transform,
      controller.getData().nodeData,
    );

    final draggedNodeId = dragManager!.draggedNodeId;
    final dropTargetId = dragManager!.dropTargetNodeId;
    final dropInsertType = dragManager!.dropInsertType;

    if (draggedNodeId != null && dropTargetId != null) {
      try {
        _applyDropOperation(draggedNodeId, dropTargetId, dropInsertType);
      } catch (e) {
        debugPrint('Failed to move node: $e');
      }
    }

    dragManager!.endDrag();
  }

  void _applyDropOperation(
    String draggedNodeId,
    String targetNodeId,
    String? insertType,
  ) {
    // Default behavior and explicit "in": move as child of target node.
    if (insertType == null || insertType == 'in') {
      controller.moveNode(draggedNodeId, targetNodeId);
      return;
    }

    final rootNode = controller.getData().nodeData;
    final targetParent = _findParentById(rootNode, targetNodeId);
    if (targetParent == null) {
      // Fallback for robustness when parent resolution fails.
      controller.moveNode(draggedNodeId, targetNodeId);
      return;
    }

    final targetIndex = targetParent.children.indexWhere(
      (child) => child.id == targetNodeId,
    );
    if (targetIndex < 0) {
      controller.moveNode(draggedNodeId, targetNodeId);
      return;
    }

    final insertIndex = insertType == 'before' ? targetIndex : targetIndex + 1;
    controller.moveNode(draggedNodeId, targetParent.id, index: insertIndex);
  }

  bool _preferPanOnEmptySpace() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return false;
    }
  }

  /// Get the current selection rectangle
  Rect? _getSelectionRect() {
    if (_dragStartPosition == null || _dragCurrentPosition == null) {
      return null;
    }

    return Rect.fromPoints(_dragStartPosition!, _dragCurrentPosition!);
  }

  /// Select all nodes within the current drag selection rectangle
  void _selectNodesInRect() {
    final selectionRect = _getSelectionRect();
    if (selectionRect == null) return;

    // Transform the selection rectangle to canvas coordinates
    final inverseTransform = Matrix4.inverted(transform);
    final topLeft = MatrixUtils.transformPoint(
      inverseTransform,
      selectionRect.topLeft,
    );
    final bottomRight = MatrixUtils.transformPoint(
      inverseTransform,
      selectionRect.bottomRight,
    );
    final transformedRect = Rect.fromPoints(topLeft, bottomRight);

    // Find all nodes that intersect with the selection rectangle
    final selectedNodeIds = <String>[];
    for (final entry in nodeLayouts.entries) {
      final nodeId = entry.key;
      final layout = entry.value;

      // Check if node bounds intersect with selection rectangle
      if (layout.bounds.overlaps(transformedRect)) {
        selectedNodeIds.add(nodeId);
      }
    }

    // Update selection
    if (selectedNodeIds.isNotEmpty) {
      controller.selectionManager.selectNodes(selectedNodeIds);
    }
  }

  /// Perform hit test to find which node was tapped
  String? hitTestNode(Offset position) {
    // Transform the position by the inverse of the current transform
    final inverseTransform = Matrix4.inverted(transform);
    final transformedPosition = MatrixUtils.transformPoint(
      inverseTransform,
      position,
    );

    // Check each node's bounds
    for (final entry in nodeLayouts.entries) {
      final nodeId = entry.key;
      final layout = entry.value;

      if (layout.bounds.contains(transformedPosition)) {
        return nodeId;
      }
    }

    return null;
  }

  /// Perform hit test to find if an expand indicator was tapped
  /// Returns the node ID if an indicator was hit, null otherwise
  String? hitTestExpandIndicator(Offset position) {
    // Transform the position by the inverse of the current transform
    final inverseTransform = Matrix4.inverted(transform);
    final transformedPosition = MatrixUtils.transformPoint(
      inverseTransform,
      position,
    );

    // Get the node data to check which nodes have children
    final data = controller.getData();
    final rootNode = data.nodeData;
    final rootCenterX = _resolveRenderRootCenterX(rootNode);

    // Check each node's expand indicator bounds
    for (final entry in nodeLayouts.entries) {
      final nodeId = entry.key;
      final layout = entry.value;

      // Find the node data
      final node = _findNodeById(rootNode, nodeId);
      if (node == null) continue;

      // Get the indicator bounds
      final depth = _findNodeDepth(rootNode, nodeId);
      final indicatorBounds = NodeRenderer.getExpandIndicatorBounds(
        node,
        layout,
        data.theme,
        depth < 0 ? 0 : depth,
        rootCenterX != null ? layout.bounds.center.dx < rootCenterX : null,
      );
      if (indicatorBounds == null) continue;

      // Check if the position is within the indicator bounds
      if (indicatorBounds.contains(transformedPosition)) {
        return nodeId;
      }
    }

    return null;
  }

  double? _resolveRenderRootCenterX(NodeData dataRoot) {
    final dataRootLayout = nodeLayouts[dataRoot.id];
    if (dataRootLayout != null) {
      return dataRootLayout.bounds.center.dx;
    }

    int minDepth = 1 << 30;
    double? centerX;
    for (final entry in nodeLayouts.entries) {
      final depth = _findNodeDepth(dataRoot, entry.key);
      if (depth >= 0 && depth < minDepth) {
        minDepth = depth;
        centerX = entry.value.bounds.center.dx;
      }
    }
    return centerX;
  }

  /// Perform hit test to find if a hyperlink indicator was tapped
  /// Returns the node ID if an indicator was hit, null otherwise
  String? hitTestHyperlinkIndicator(Offset position) {
    // Transform the position by the inverse of the current transform
    final inverseTransform = Matrix4.inverted(transform);
    final transformedPosition = MatrixUtils.transformPoint(
      inverseTransform,
      position,
    );

    // Get the node data to check which nodes have hyperlinks
    final data = controller.getData();
    final rootNode = data.nodeData;
    final rootCenterX = _resolveRenderRootCenterX(rootNode);

    // Check each node's hyperlink indicator bounds
    for (final entry in nodeLayouts.entries) {
      final nodeId = entry.key;
      final layout = entry.value;

      // Find the node data
      final node = _findNodeById(rootNode, nodeId);
      if (node == null) continue;

      // Get the indicator bounds
      final depth = _findNodeDepth(rootNode, nodeId);
      final indicatorBounds = NodeRenderer.getHyperlinkIndicatorBounds(
        node,
        layout,
        data.theme,
        depth < 0 ? 0 : depth,
        rootCenterX != null ? layout.bounds.center.dx < rootCenterX : null,
      );
      if (indicatorBounds == null) continue;

      // Check if the position is within the indicator bounds
      if (indicatorBounds.contains(transformedPosition)) {
        return nodeId;
      }
    }

    return null;
  }

  /// Perform hit test to find if a summary was tapped.
  /// Returns the summary ID if a summary bounds was hit, null otherwise.
  String? hitTestSummary(Offset position) {
    final inverseTransform = Matrix4.inverted(transform);
    final transformedPosition = MatrixUtils.transformPoint(
      inverseTransform,
      position,
    );

    final data = controller.getData();
    final rootNode = data.nodeData;

    for (final summary in data.summaries.reversed) {
      final parentNode = _findNodeById(rootNode, summary.parentNodeId);
      if (parentNode == null) continue;
      final depth = _findNodeDepth(rootNode, summary.parentNodeId);
      if (depth < 0) continue;

      final bounds = SummaryRenderer.getSummaryBounds(
        summary,
        parentNode,
        nodeLayouts,
        parentHasParent: depth > 0,
        parentDepth: depth,
        theme: data.theme,
      );
      if (bounds != null && bounds.contains(transformedPosition)) {
        return summary.id;
      }
    }

    return null;
  }

  /// Helper method to find a node by ID in the tree
  NodeData? _findNodeById(NodeData node, String nodeId) {
    if (node.id == nodeId) return node;

    for (final child in node.children) {
      final found = _findNodeById(child, nodeId);
      if (found != null) return found;
    }

    return null;
  }

  NodeData? _findParentById(NodeData node, String childId) {
    for (final child in node.children) {
      if (child.id == childId) return node;
    }
    for (final child in node.children) {
      final found = _findParentById(child, childId);
      if (found != null) return found;
    }
    return null;
  }

  int _findNodeDepth(NodeData node, String targetId, [int depth = 0]) {
    if (node.id == targetId) return depth;
    for (final child in node.children) {
      final result = _findNodeDepth(child, targetId, depth + 1);
      if (result != -1) return result;
    }
    return -1;
  }

  /// Perform hit test to find which arrow was tapped
  /// Returns the arrow ID if an arrow was hit, null otherwise
  String? hitTestArrow(Offset position) {
    // Transform the position by the inverse of the current transform
    final inverseTransform = Matrix4.inverted(transform);
    final transformedPosition = MatrixUtils.transformPoint(
      inverseTransform,
      position,
    );

    // Get all arrows
    final arrows = controller.getData().arrows;

    String? bestArrowId;
    double bestDistance = double.infinity;

    // Check each arrow and pick the nearest hit
    for (final arrow in arrows) {
      final hitResult = _distanceToArrow(arrow, transformedPosition);
      if (hitResult == null) continue;
      final (distance, threshold) = hitResult;
      if (distance <= threshold && distance < bestDistance) {
        bestDistance = distance;
        bestArrowId = arrow.id;
      }
    }

    return bestArrowId;
  }

  /// Calculate distance from point to arrow curve with a scale-aware threshold.
  /// Returns (distance, threshold) in canvas coordinates, or null when layout missing.
  (double, double)? _distanceToArrow(ArrowData arrow, Offset point) {
    // Get source and target node layouts
    final fromLayout = nodeLayouts[arrow.fromNodeId];
    final toLayout = nodeLayouts[arrow.toNodeId];

    if (fromLayout == null || toLayout == null) return null;

    final (delta1, delta2) = _resolveArrowDeltas(arrow, fromLayout, toLayout);
    final startPoint = fromLayout.bounds.center;
    final endPoint = toLayout.bounds.center;
    final controlPoint1 = startPoint + delta1;
    final controlPoint2 = endPoint + delta2;

    final curveLengthEstimate =
        (controlPoint1 - startPoint).distance +
        (controlPoint2 - controlPoint1).distance +
        (endPoint - controlPoint2).distance;
    final samples = (curveLengthEstimate / 10.0).round().clamp(32, 180);

    final scale = _currentScale();
    final strokeWidth = arrow.style?.strokeWidth ?? 2.0;
    final screenThreshold = (strokeWidth * 1.8 + 8.0).clamp(10.0, 20.0);
    final hitThreshold = scale > 0 ? screenThreshold / scale : screenThreshold;

    var minDistance = double.infinity;
    for (int i = 0; i <= samples; i++) {
      final t = i / samples;
      final curvePoint = ArrowUtils.calculateBezierPoint(
        startPoint,
        controlPoint1,
        controlPoint2,
        endPoint,
        t,
      );
      final distance = (curvePoint - point).distance;
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return (minDistance, hitThreshold);
  }

  static (Offset, Offset) _resolveArrowDeltas(
    ArrowData arrow,
    NodeLayout fromLayout,
    NodeLayout toLayout,
  ) {
    if (arrow.delta1 == Offset.zero && arrow.delta2 == Offset.zero) {
      return ArrowUtils.calculateDefaultDeltas(fromLayout, toLayout);
    }
    return (arrow.delta1, arrow.delta2);
  }

  double _currentScale() {
    final scaleX = transform.storage[0].abs();
    final scaleY = transform.storage[5].abs();
    final scale = (scaleX + scaleY) * 0.5;
    if (scale.isFinite && scale > 0) {
      return scale;
    }
    return 1.0;
  }

  /// Perform hit test to find which arrow control point was tapped
  /// Returns a tuple of (arrowId, controlPointIndex) if a control point was hit
  /// controlPointIndex: 0 for first control point, 1 for second control point
  (String, int)? hitTestArrowControlPoint(Offset position) {
    // Only check if an arrow is selected
    if (controller.selectedArrowId == null) return null;

    // Transform the position by the inverse of the current transform
    final inverseTransform = Matrix4.inverted(transform);
    final transformedPosition = MatrixUtils.transformPoint(
      inverseTransform,
      position,
    );

    final arrow = controller.getArrow(controller.selectedArrowId!);
    if (arrow == null) return null;

    // Get source and target node layouts
    final fromLayout = nodeLayouts[arrow.fromNodeId];
    final toLayout = nodeLayouts[arrow.toNodeId];

    if (fromLayout == null || toLayout == null) return null;

    final (effectiveDelta1, effectiveDelta2) = _resolveArrowDeltas(
      arrow,
      fromLayout,
      toLayout,
    );

    // Calculate control points
    final startPoint = fromLayout.bounds.center;
    final endPoint = toLayout.bounds.center;
    final controlPoint1 = startPoint + effectiveDelta1;
    final controlPoint2 = endPoint + effectiveDelta2;

    const handleRadius = 6.0;
    final scale = _currentScale();
    final hitThreshold = scale > 0
        ? (handleRadius + 4.0) / scale
        : (handleRadius + 4.0); // Keep screen hit size stable

    // Check control point 1
    if ((controlPoint1 - transformedPosition).distance < hitThreshold) {
      return (arrow.id, 0);
    }

    // Check control point 2
    if ((controlPoint2 - transformedPosition).distance < hitThreshold) {
      return (arrow.id, 1);
    }

    return null;
  }
}
