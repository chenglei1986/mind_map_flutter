import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/mind_map_data.dart';
import '../models/node_data.dart';
import '../models/node_style.dart';
import '../models/tag_data.dart';
import '../models/arrow_data.dart';
import '../models/arrow_style.dart';
import '../models/summary_data.dart';
import '../models/summary_style.dart';
import '../models/image_data.dart';
import '../models/mind_map_theme.dart';
import '../models/layout_direction.dart';
import '../interaction/selection_manager.dart';
import '../interaction/zoom_pan_manager.dart';
import '../history/history_manager.dart';
import '../history/operations.dart';
import '../history/operation.dart';
import '../layout/layout_engine.dart';
import '../layout/node_layout.dart';
import '../rendering/mind_map_painter.dart';
import '../rendering/node_renderer.dart';
import '../rendering/arrow_renderer.dart';
import '../rendering/summary_renderer.dart';
import '../utils/arrow_utils.dart';
import '../utils/tree_utils.dart';
import '../i18n/mind_map_strings.dart';
import 'mind_map_config.dart';
import 'mind_map_widget.dart';

/// Exception thrown when attempting to delete the root node
class RootNodeDeletionException implements Exception {
  final String message;

  RootNodeDeletionException([this.message = 'Cannot delete root node']);

  @override
  String toString() => 'RootNodeDeletionException: $message';
}

/// Exception thrown when a node ID is not found
class InvalidNodeIdException implements Exception {
  final String message;

  InvalidNodeIdException(this.message);

  @override
  String toString() => 'InvalidNodeIdException: $message';
}

/// Controller for programmatic control of the mind map
class MindMapController extends ChangeNotifier {
  MindMapData _data;
  MindMapConfig _config;
  MindMapEvent? _lastEvent;
  late final SelectionManager _selectionManager;
  late final HistoryManager _historyManager;
  late final ZoomPanManager _zoomPanManager;

  // Stream controller for event broadcasting
  final StreamController<MindMapEvent> _eventStreamController =
      StreamController<MindMapEvent>.broadcast();

  // Reference to widget state for PNG export
  GlobalKey? _repaintBoundaryKey;

  // Viewport size for view control operations
  Size? _viewportSize;
  bool _centerWhenReady = false;
  bool _didInitialViewportFit = false;
  Map<String, ui.Image> _exportImageCache = const <String, ui.Image>{};
  final math.Random _branchColorRandom = math.Random();

  // Arrow creation mode state
  bool _isArrowCreationMode = false;
  String? _arrowSourceNodeId;
  String? _selectedArrowId;

  // Summary creation mode state
  bool _isSummaryCreationMode = false;
  List<String> _summarySelectedNodeIds = [];
  String? _selectedSummaryId;

  // Focus mode state
  bool _isFocusMode = false;
  String? _focusedNodeId;

  /// Get the repaint boundary key for PNG export
  GlobalKey? get repaintBoundaryKey => _repaintBoundaryKey;

  /// Get the event stream for listening to mind map events
  ///
  /// This stream broadcasts all events that occur in the mind map,
  /// including node operations, selections, edits, and more.
  ///
  /// Multiple listeners can subscribe to this stream simultaneously.
  ///
  /// Example:
  /// ```dart
  /// controller.eventStream.listen((event) {
  ///   if (event is NodeOperationEvent) {
  ///     print('Node operation: ${event.operation}');
  ///   }
  /// });
  /// ```
  ///
  Stream<MindMapEvent> get eventStream => _eventStreamController.stream;

  MindMapController({
    required MindMapData initialData,
    MindMapConfig config = const MindMapConfig(),
  }) : _data = initialData,
       _config = config {
    // Initialize node directions if not set
    _data = _data.copyWith(
      nodeData: _initializeNodeDirections(_data.nodeData, _data.direction),
    );

    // Initialize selection manager with callback to emit events
    _selectionManager = SelectionManager(
      onSelectionChanged: (event) {
        emitEvent(event);
      },
    );

    // Initialize history manager with config
    _historyManager = HistoryManager(maxHistorySize: config.maxHistorySize);

    // Initialize zoom/pan manager
    _zoomPanManager = ZoomPanManager(
      minScale: config.minScale,
      maxScale: config.maxScale,
    );

    // Listen to zoom/pan changes
    _zoomPanManager.addListener(notifyListeners);
  }

  /// Check if arrow creation mode is active
  bool get isArrowCreationMode => _isArrowCreationMode;

  /// Get the source node ID for arrow creation (if in arrow creation mode)
  String? get arrowSourceNodeId => _arrowSourceNodeId;

  /// Get the currently selected arrow ID
  String? get selectedArrowId => _selectedArrowId;

  /// Check if summary creation mode is active
  bool get isSummaryCreationMode => _isSummaryCreationMode;

  /// Get the selected node IDs for summary creation
  List<String> get summarySelectedNodeIds =>
      List.unmodifiable(_summarySelectedNodeIds);

  /// Get currently selected summary ID
  String? get selectedSummaryId => _selectedSummaryId;

  /// Check if focus mode is active
  bool get isFocusMode => _isFocusMode;

  /// Get the focused node ID (if in focus mode)
  String? get focusedNodeId => _focusedNodeId;

  /// Get current localized strings resolved from config locale.
  MindMapStrings get localizedStrings => _strings;

  /// Default label for newly created nodes.
  String get defaultNewNodeTopic => _strings.defaultNewNodeTopic;

  /// Default label for newly created summaries.
  String get defaultSummaryLabel => _strings.defaultSummaryLabel;

  /// Get the current mind map data
  MindMapData getData() => _data;

  /// Get the last emitted event
  MindMapEvent? get lastEvent => _lastEvent;

  /// Get the selection manager
  SelectionManager get selectionManager => _selectionManager;

  /// Get the zoom/pan manager
  ZoomPanManager get zoomPanManager => _zoomPanManager;

  /// Set the viewport size (called by the widget)
  void setViewportSize(Size size) {
    _viewportSize = size;
    if (_centerWhenReady) {
      _centerWhenReady = false;
      if (_didInitialViewportFit) {
        centerView(duration: Duration.zero);
      } else {
        fitToView(duration: Duration.zero);
        _didInitialViewportFit = true;
      }
    }
  }

  /// Get selected node IDs
  List<String> getSelectedNodeIds() => _selectionManager.selectedNodeIds;

  MindMapStrings get _strings => MindMapStrings.resolve(
    _config.locale,
    ui.PlatformDispatcher.instance.locale,
  );

  /// Update configuration
  void updateConfig(MindMapConfig config) {
    _config = config;

    // Update history manager max size if changed
    if (config.maxHistorySize != _config.maxHistorySize) {
      // Note: HistoryManager doesn't have a setter for maxHistorySize,
      // so we'd need to recreate it or add a setter. For now, this will
      // only affect new instances.
    }

    notifyListeners();
  }

  /// Refresh with new data
  void refresh(MindMapData data) {
    _data = data;
    _lastEvent = null;
    _didInitialViewportFit = false;
    _selectionManager.clearSelection();
    _historyManager.clear(); // Clear history when refreshing data
    notifyListeners();
  }

  /// Emit an event (internal use and by gesture handler)
  ///
  /// This method emits events through both the callback mechanism (onEvent)
  /// and the event stream. This ensures backward compatibility while providing
  /// the new Stream-based API.
  ///
  void emitEvent(MindMapEvent event) {
    _lastEvent = event;

    // Emit to stream if there are listeners
    if (!_eventStreamController.isClosed) {
      _eventStreamController.add(event);
    }

    notifyListeners();
  }

  void _recordOperation(
    Operation operation, {
    List<String>? selectionBefore,
    List<String>? selectionAfter,
  }) {
    if (!_config.allowUndo) return;

    final before = selectionBefore ?? _selectionManager.selectedNodeIds;
    final after = selectionAfter ?? _selectionManager.selectedNodeIds;

    _historyManager.recordOperation(
      operation,
      selectionBefore: before,
      selectionAfter: after,
    );
  }

  void _restoreSelection(List<String> nodeIds) {
    if (nodeIds.isEmpty) {
      _selectionManager.clearSelection();
      return;
    }

    _selectionManager.selectNodes(nodeIds);
  }

  Never _throwInvalidNodeId(String nodeId) {
    throw InvalidNodeIdException(_strings.errorInvalidNodeId(nodeId));
  }

  Color _generateRandomRootBranchColor() {
    final usedHues = <int>{};
    for (final child in _data.nodeData.children) {
      final color = _resolveBranchColor(child);
      if (color != null) {
        usedHues.add(HSLColor.fromColor(color).hue.round() % 360);
      }
    }

    for (int i = 0; i < 48; i++) {
      final candidateHue = _branchColorRandom.nextInt(360);
      bool isDistinct = true;
      for (final usedHue in usedHues) {
        final distance = (candidateHue - usedHue).abs();
        final circularDistance = distance > 180 ? 360 - distance : distance;
        if (circularDistance < 16) {
          isDistinct = false;
          break;
        }
      }
      if (isDistinct) {
        return HSLColor.fromAHSL(
          1.0,
          candidateHue.toDouble(),
          0.72,
          0.46,
        ).toColor();
      }
    }

    final fallbackHue = _branchColorRandom.nextInt(360);
    return HSLColor.fromAHSL(1.0, fallbackHue.toDouble(), 0.72, 0.46).toColor();
  }

  Color? _resolveBranchColor(NodeData node) {
    if (node.branchColor != null) {
      return node.branchColor;
    }

    NodeData? current = node;
    while (current != null) {
      final parent = _findParent(_data.nodeData, current.id);
      if (parent == null) break;
      if (parent.branchColor != null) {
        return parent.branchColor;
      }
      current = parent;
    }

    return null;
  }

  /// Add a child node to the specified parent
  ///
  /// If [topic] is not provided, creates a node with default text and
  /// automatically enters edit mode (similar to mind-elixir-core behavior).
  ///
  /// If the parent node is collapsed, it will be automatically expanded.
  void addChildNode(String parentId, {String? topic}) {
    // Determine the direction for the new child
    final parent = _findNode(_data.nodeData, parentId);
    if (parent == null) {
      _throwInvalidNodeId(parentId);
    }

    // Determine direction based on parent and siblings
    LayoutDirection? childDirection;

    // If parent is root and layout is side, determine which side to add to
    if (parentId == _data.nodeData.id &&
        _data.direction == LayoutDirection.side) {
      // Count existing children on each side
      int leftCount = 0;
      int rightCount = 0;

      for (final child in parent.children) {
        if (child.direction == LayoutDirection.left) {
          leftCount++;
        } else if (child.direction == LayoutDirection.right) {
          rightCount++;
        } else {
          // If child has no explicit direction, count it based on current distribution
          if (rightCount <= leftCount) {
            rightCount++;
          } else {
            leftCount++;
          }
        }
      }

      // Add to the side with fewer children
      childDirection = rightCount <= leftCount
          ? LayoutDirection.right
          : LayoutDirection.left;
    } else if (parent.direction != null) {
      // Inherit parent's direction
      childDirection = parent.direction;
    }

    final newChild = NodeData.create(
      topic: topic ?? _strings.defaultNewNodeTopic,
      direction: childDirection,
      branchColor: parentId == _data.nodeData.id
          ? _generateRandomRootBranchColor()
          : _resolveBranchColor(parent),
    );

    final selectionBefore = List<String>.from(
      _selectionManager.selectedNodeIds,
    );

    final parentWasCollapsed = !parent.expanded;

    final updatedRoot = _addChildToNode(_data.nodeData, parentId, newChild);
    if (updatedRoot != null) {
      // Record create operation if undo is enabled
      final operation = CreateNodeOperation(
        parentId: parentId,
        newNode: newChild,
        parentWasCollapsed: parentWasCollapsed,
      );
      final selectionAfter = topic == null ? [newChild.id] : selectionBefore;
      _recordOperation(
        operation,
        selectionBefore: selectionBefore,
        selectionAfter: selectionAfter,
      );

      _data = _data.copyWith(nodeData: updatedRoot);
      emitEvent(NodeOperationEvent('addChild', newChild.id));

      // Auto-edit if no topic was provided (user-initiated add)
      // Similar to mind-elixir-core's behavior
      if (topic == null) {
        // Auto-select the new node
        selectionManager.selectNode(newChild.id);
        emitEvent(BeginEditEvent(newChild.id));
      }
    } else {
      _throwInvalidNodeId(parentId);
    }
  }

  /// Add a sibling node to the specified node
  ///
  /// If [topic] is not provided, creates a node with default text and
  /// automatically enters edit mode (similar to mind-elixir-core behavior).
  void addSiblingNode(String nodeId, {String? topic}) {
    // Find the node to get its direction
    final node = _findNode(_data.nodeData, nodeId);
    if (node == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Find parent of the node to record operation
    final parent = _findParent(_data.nodeData, nodeId);
    if (parent == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Inherit the direction from the sibling node
    final newSibling = NodeData.create(
      topic: topic ?? _strings.defaultNewNodeTopic,
      direction: node.direction,
      branchColor: parent.id == _data.nodeData.id
          ? _generateRandomRootBranchColor()
          : _resolveBranchColor(node),
    );

    final selectionBefore = List<String>.from(
      _selectionManager.selectedNodeIds,
    );

    // Find the index where sibling will be inserted (after the current node)
    final siblingIndex = parent.children.indexWhere((c) => c.id == nodeId) + 1;

    // Add sibling to the tree
    final updatedRoot = _addSiblingToNode(_data.nodeData, nodeId, newSibling);
    if (updatedRoot != null) {
      // Record operation if undo is enabled
      final operation = CreateNodeOperation(
        parentId: parent.id,
        newNode: newSibling,
        insertIndex: siblingIndex,
      );
      final selectionAfter = topic == null ? [newSibling.id] : selectionBefore;
      _recordOperation(
        operation,
        selectionBefore: selectionBefore,
        selectionAfter: selectionAfter,
      );

      _data = _data.copyWith(nodeData: updatedRoot);
      emitEvent(NodeOperationEvent('addSibling', newSibling.id));

      // Auto-edit if no topic was provided (user-initiated add)
      // Similar to mind-elixir-core's behavior
      if (topic == null) {
        // Auto-select the new node
        selectionManager.selectNode(newSibling.id);
        emitEvent(BeginEditEvent(newSibling.id));
      }
    } else {
      _throwInvalidNodeId(nodeId);
    }
  }

  /// Remove a node and all its descendants
  void removeNode(String nodeId) {
    // Prevent deletion of root node
    if (nodeId == _data.nodeData.id) {
      throw RootNodeDeletionException(_strings.errorCannotDeleteRootNode);
    }

    // Find the node and its parent before deletion
    final nodeToDelete = _findNode(_data.nodeData, nodeId);
    final parent = _findParent(_data.nodeData, nodeId);

    if (nodeToDelete == null || parent == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Find the original index for undo
    final originalIndex = parent.children.indexWhere((c) => c.id == nodeId);

    final updatedRoot = _removeNodeFromTree(_data.nodeData, nodeId);
    if (updatedRoot != null) {
      // Record operation if undo is enabled
      final operation = DeleteNodeOperation(
        nodeId: nodeId,
        parentId: parent.id,
        deletedNode: nodeToDelete,
        originalIndex: originalIndex,
      );
      final selectionBefore = List<String>.from(
        _selectionManager.selectedNodeIds,
      );
      final selectionAfter = selectionBefore
          .where((id) => id != nodeId)
          .toList();
      _recordOperation(
        operation,
        selectionBefore: selectionBefore,
        selectionAfter: selectionAfter,
      );

      _data = _data.copyWith(nodeData: updatedRoot);

      // Remove from selection if selected
      _selectionManager.removeFromSelection(nodeId);

      emitEvent(NodeOperationEvent('removeNode', nodeId));
    } else {
      _throwInvalidNodeId(nodeId);
    }
  }

  /// Update a node's data
  void updateNode(String nodeId, NodeData updates) {
    final updatedRoot = _updateNodeInTree(_data.nodeData, nodeId, updates);
    if (updatedRoot != null) {
      _data = _data.copyWith(nodeData: updatedRoot);
      notifyListeners();
    } else {
      _throwInvalidNodeId(nodeId);
    }
  }

  /// Update node topic (convenience method for editing)
  void updateNodeTopic(String nodeId, String newTopic) {
    final node = _findNode(_data.nodeData, nodeId);
    if (node != null) {
      // Record operation if undo is enabled
      final operation = EditNodeOperation(
        nodeId: nodeId,
        oldTopic: node.topic,
        newTopic: newTopic,
      );
      _recordOperation(operation);

      updateNode(nodeId, node.copyWith(topic: newTopic));
    } else {
      _throwInvalidNodeId(nodeId);
    }
  }

  /// Commit a node topic edit with a provided original topic
  /// This is used to avoid recording history on every keystroke during edit preview.
  void commitNodeTopicEdit(String nodeId, String oldTopic, String newTopic) {
    final node = _findNode(_data.nodeData, nodeId);
    if (node != null) {
      if (oldTopic == newTopic) return;
      final operation = EditNodeOperation(
        nodeId: nodeId,
        oldTopic: oldTopic,
        newTopic: newTopic,
      );
      _recordOperation(operation);
      updateNode(nodeId, node.copyWith(topic: newTopic));
    } else {
      _throwInvalidNodeId(nodeId);
    }
  }

  /// Toggle the expanded state of a node
  ///
  /// This method includes view drift compensation to maintain the user's focus
  /// on the node being expanded/collapsed, similar to mind-elixir-core's behavior.
  void toggleNodeExpanded(String nodeId) {
    final node = _findNode(_data.nodeData, nodeId);
    if (node == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Store the old state for undo/redo
    final oldExpanded = node.expanded;

    // Store the current node position before expansion
    final beforePosition = _getNodeScreenPosition(nodeId);

    // Toggle the expanded state
    final newExpandedState = !oldExpanded;
    final updatedNode = node.copyWith(expanded: newExpandedState);

    // Update the node in the tree
    updateNode(nodeId, updatedNode);

    // Record operation if undo is enabled
    final operation = ToggleExpandOperation(
      nodeId: nodeId,
      oldExpanded: oldExpanded,
      newExpanded: newExpandedState,
    );
    _recordOperation(operation);

    // Emit expandNode event
    emitEvent(ExpandNodeEvent(nodeId, newExpandedState));

    // Schedule view compensation after layout recalculation
    // This ensures the node stays in the same visual position
    _scheduleViewCompensation(nodeId, beforePosition);
  }

  /// Get the current screen position of a node
  /// Returns null if the node position cannot be determined
  Offset? _getNodeScreenPosition(String nodeId) {
    // This will be called by the widget to get the position
    // We'll store it in a callback mechanism
    return _nodePositionCallback?.call(nodeId);
  }

  /// Callback to get node screen position (set by widget)
  Offset? Function(String nodeId)? _nodePositionCallback;

  /// Set the callback for getting node screen positions
  void setNodePositionCallback(Offset? Function(String nodeId) callback) {
    _nodePositionCallback = callback;
  }

  /// Callback to compensate view drift (set by widget)
  void Function(String nodeId, Offset beforePosition)?
  _viewCompensationCallback;

  /// Set the callback for view compensation
  void setViewCompensationCallback(
    void Function(String nodeId, Offset beforePosition) callback,
  ) {
    _viewCompensationCallback = callback;
  }

  /// Schedule view compensation after layout recalculation
  void _scheduleViewCompensation(String nodeId, Offset? beforePosition) {
    if (beforePosition != null && _viewCompensationCallback != null) {
      _viewCompensationCallback!(nodeId, beforePosition);
    }
  }

  /// Expand a node (show its children)
  void expandNode(String nodeId) {
    final node = _findNode(_data.nodeData, nodeId);
    if (node == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Only update if currently collapsed
    if (!node.expanded) {
      final oldExpanded = false;
      final newExpanded = true;

      final updatedNode = node.copyWith(expanded: newExpanded);
      updateNode(nodeId, updatedNode);

      // Record operation if undo is enabled
      final operation = ToggleExpandOperation(
        nodeId: nodeId,
        oldExpanded: oldExpanded,
        newExpanded: newExpanded,
      );
      _recordOperation(operation);

      emitEvent(ExpandNodeEvent(nodeId, newExpanded));
    }
  }

  /// Collapse a node (hide its children)
  void collapseNode(String nodeId) {
    final node = _findNode(_data.nodeData, nodeId);
    if (node == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Only update if currently expanded
    if (node.expanded) {
      final oldExpanded = true;
      final newExpanded = false;

      final updatedNode = node.copyWith(expanded: newExpanded);
      updateNode(nodeId, updatedNode);

      // Record operation if undo is enabled
      final operation = ToggleExpandOperation(
        nodeId: nodeId,
        oldExpanded: oldExpanded,
        newExpanded: newExpanded,
      );
      _recordOperation(operation);

      emitEvent(ExpandNodeEvent(nodeId, newExpanded));
    }
  }

  /// Move multiple nodes to a new parent or reorder within siblings
  ///
  /// This method moves multiple selected nodes to a new parent.
  /// The nodes will maintain their relative order.
  ///
  /// [nodeIds] - List of node IDs to move
  /// [newParentId] - ID of the new parent node
  /// [index] - Optional position in the new parent's children list
  ///
  void moveNodes(List<String> nodeIds, String newParentId, {int? index}) {
    if (nodeIds.isEmpty) return;

    // Remove duplicates (preserve order) and filter out root node
    final validNodeIds = _dedupePreserveOrder(
      nodeIds,
    ).where((id) => id != _data.nodeData.id).toList();

    if (validNodeIds.isEmpty) return;

    // Prevent moving to any of the nodes being moved
    if (validNodeIds.contains(newParentId)) {
      throw InvalidNodeIdException(_strings.errorCannotMoveNodesToMovedSet);
    }

    // Verify new parent exists
    final newParent = _findNode(_data.nodeData, newParentId);
    if (newParent == null) {
      _throwInvalidNodeId(newParentId);
    }

    // Track if target was collapsed (for undo/redo)
    final targetWasCollapsed =
        !newParent.expanded && newParent.children.isNotEmpty;

    // Preserve visual order by sorting by current tree order (preorder)
    final orderMap = _buildNodeOrderMap(_data.nodeData);
    validNodeIds.sort((a, b) {
      final aIndex = orderMap[a] ?? 0;
      final bIndex = orderMap[b] ?? 0;
      return aIndex.compareTo(bIndex);
    });

    // Collect nodes and verify they exist
    final nodesToMove = <NodeData>[];
    final moveInfos = <_MoveNodeInfo>[];
    for (final nodeId in validNodeIds) {
      final node = _findNode(_data.nodeData, nodeId);
      if (node == null) {
        _throwInvalidNodeId(nodeId);
      }

      // Prevent circular reference
      if (_isDescendant(node, newParentId)) {
        throw InvalidNodeIdException(
          _strings.errorCannotMoveNodeToOwnDescendant,
        );
      }

      final currentParent = _findParent(_data.nodeData, nodeId);
      if (currentParent == null) {
        throw InvalidNodeIdException(
          _strings.errorCannotFindParentOfNode(nodeId),
        );
      }

      final oldIndex = currentParent.children.indexWhere((c) => c.id == nodeId);
      nodesToMove.add(node);
      moveInfos.add(
        _MoveNodeInfo(
          nodeId: nodeId,
          node: node,
          oldParentId: currentParent.id,
          oldIndex: oldIndex,
        ),
      );
    }

    // Adjust index for removals if moving within the same parent
    int? adjustedIndex = index;
    if (index != null) {
      int removedBefore = 0;
      for (final info in moveInfos) {
        if (info.oldParentId == newParentId && info.oldIndex < index) {
          removedBefore++;
        }
      }
      adjustedIndex = index - removedBefore;
      if (adjustedIndex < 0) {
        adjustedIndex = 0;
      }
    }

    // Record operations if undo is enabled
    final operations = <MoveNodeOperation>[];

    // Remove all nodes from their current positions
    var updatedRoot = _data.nodeData;
    for (final info in moveInfos) {
      // Remove from current position
      updatedRoot = _removeNodeFromTree(updatedRoot, info.nodeId)!;
    }

    // Auto-expand target node if collapsed (without recording separate operation)
    if (targetWasCollapsed) {
      updatedRoot = _setNodeExpandedInTree(updatedRoot, newParentId, true);
    }

    // Determine insertion index after removals
    int insertIndex;
    if (adjustedIndex == null) {
      final updatedNewParent = _findNode(updatedRoot, newParentId);
      final currentLength = updatedNewParent?.children.length ?? 0;
      insertIndex = currentLength;
    } else {
      insertIndex = adjustedIndex;
    }

    // Add all nodes to new parent
    for (int i = 0; i < nodesToMove.length; i++) {
      final node = nodesToMove[i];
      updatedRoot = _addChildToNodeAtIndex(
        updatedRoot,
        newParentId,
        node,
        insertIndex,
      );
      // Record operation per node using the actual insertion index
      if (_config.allowUndo) {
        final info = moveInfos[i];
        operations.add(
          MoveNodeOperation(
            nodeId: info.nodeId,
            oldParentId: info.oldParentId,
            newParentId: newParentId,
            oldIndex: info.oldIndex,
            newIndex: insertIndex,
            movedNode: info.node,
            targetWasCollapsed: targetWasCollapsed,
          ),
        );
      }
      insertIndex++;
    }

    // Record all operations
    if (_config.allowUndo) {
      final selectionSnapshot = List<String>.from(
        _selectionManager.selectedNodeIds,
      );
      for (final operation in operations) {
        _recordOperation(
          operation,
          selectionBefore: selectionSnapshot,
          selectionAfter: selectionSnapshot,
        );
      }
    }

    _data = _data.copyWith(nodeData: updatedRoot);

    // Emit move event
    emitEvent(
      MoveNodeEvent(
        nodeId: validNodeIds.first,
        oldParentId: operations.isNotEmpty ? operations.first.oldParentId : '',
        newParentId: newParentId,
        isReorder: false,
      ),
    );
  }

  ///
  /// If [newParentId] is the current parent, the node will be reordered among siblings.
  /// If [newParentId] is a different node, the node will be moved to be a child of that node.
  ///
  /// If the target node is collapsed, it will be automatically expanded.
  ///
  /// [index] specifies the position in the new parent's children list.
  /// If null, the node will be added at the end.
  ///
  void moveNode(String nodeId, String newParentId, {int? index}) {
    // Prevent moving root node
    if (nodeId == _data.nodeData.id) {
      throw InvalidNodeIdException(_strings.errorCannotMoveRootNode);
    }

    // Prevent moving to itself
    if (nodeId == newParentId) {
      throw InvalidNodeIdException(_strings.errorCannotMoveNodeToItself);
    }

    // Find the node to move
    final nodeToMove = _findNode(_data.nodeData, nodeId);
    if (nodeToMove == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Verify new parent exists
    final newParent = _findNode(_data.nodeData, newParentId);
    if (newParent == null) {
      _throwInvalidNodeId(newParentId);
    }

    // Track if target was collapsed (for undo)
    final targetWasCollapsed =
        !newParent.expanded && newParent.children.isNotEmpty;

    // Prevent circular reference (moving to own descendant)
    if (_isDescendant(nodeToMove, newParentId)) {
      throw InvalidNodeIdException(_strings.errorCannotMoveNodeToOwnDescendant);
    }

    // Find current parent
    final currentParent = _findParent(_data.nodeData, nodeId);
    if (currentParent == null) {
      throw InvalidNodeIdException(
        _strings.errorCannotFindParentOfNode(nodeId),
      );
    }

    // Find the original index
    final oldIndex = currentParent.children.indexWhere((c) => c.id == nodeId);

    // Check if this is a reorder operation (same parent)
    final isReorder = currentParent.id == newParentId;

    // Determine the actual new index (default to end if not specified)
    int actualNewIndex;
    if (index == null) {
      // If reordering within same parent, end should be last index after removal
      actualNewIndex = isReorder
          ? newParent.children.length - 1
          : newParent.children.length;
    } else {
      actualNewIndex = index;
      if (isReorder && index > oldIndex) {
        actualNewIndex = index - 1;
      }
    }

    // Record operation if undo is enabled
    final operation = MoveNodeOperation(
      nodeId: nodeId,
      oldParentId: currentParent.id,
      newParentId: newParentId,
      oldIndex: oldIndex,
      newIndex: actualNewIndex,
      movedNode: nodeToMove,
      targetWasCollapsed: targetWasCollapsed,
    );
    _recordOperation(operation);

    // Remove node from current parent
    NodeData updatedRoot = _removeNodeFromTree(_data.nodeData, nodeId)!;

    // Auto-expand target node if collapsed (without recording separate operation)
    if (targetWasCollapsed) {
      updatedRoot = _setNodeExpandedInTree(updatedRoot, newParentId, true);
    }

    // Add node to new parent at specified index
    updatedRoot = _addChildToNodeAtIndex(
      updatedRoot,
      newParentId,
      nodeToMove,
      actualNewIndex,
    );

    _data = _data.copyWith(nodeData: updatedRoot);

    // Emit moveNode event with source and target information
    emitEvent(
      MoveNodeEvent(
        nodeId: nodeId,
        oldParentId: currentParent.id,
        newParentId: newParentId,
        isReorder: isReorder,
      ),
    );
  }

  /// Add a parent node above the specified node
  ///
  /// This inserts a new parent between the node and its current parent,
  /// similar to mind-elixir-core's insertParent behavior.
  ///
  void addParentNode(String nodeId, {String? topic}) {
    // Prevent inserting parent above root
    if (nodeId == _data.nodeData.id) {
      throw InvalidNodeIdException(_strings.errorCannotInsertParentForRootNode);
    }

    final nodeToReparent = _findNode(_data.nodeData, nodeId);
    if (nodeToReparent == null) {
      _throwInvalidNodeId(nodeId);
    }

    final currentParent = _findParent(_data.nodeData, nodeId);
    if (currentParent == null) {
      throw InvalidNodeIdException(
        _strings.errorCannotFindParentOfNode(nodeId),
      );
    }

    final oldIndex = currentParent.children.indexWhere((c) => c.id == nodeId);

    // Create new parent node with the target node as its only child
    final newParent = NodeData.create(
      topic: topic ?? _strings.defaultNewNodeTopic,
      children: [nodeToReparent],
      branchColor: _resolveBranchColor(nodeToReparent),
    );

    // Insert the new parent into the tree
    final updatedRoot = _insertParentNode(_data.nodeData, nodeId, newParent);

    // Record operation if undo is enabled
    final operation = InsertParentOperation(
      nodeId: nodeId,
      oldParentId: currentParent.id,
      oldIndex: oldIndex,
      newParent: newParent,
    );
    final selectionBefore = List<String>.from(
      _selectionManager.selectedNodeIds,
    );
    final selectionAfter = topic == null ? [newParent.id] : selectionBefore;
    _recordOperation(
      operation,
      selectionBefore: selectionBefore,
      selectionAfter: selectionAfter,
    );

    _data = _data.copyWith(nodeData: updatedRoot);

    emitEvent(NodeOperationEvent('addParent', newParent.id));

    // Auto-edit if no topic was provided (user-initiated add)
    if (topic == null) {
      selectionManager.selectNode(newParent.id);
      emitEvent(BeginEditEvent(newParent.id));
    }
  }

  /// Undo the last operation
  ///
  /// Returns true if an operation was undone, false if there's nothing to undo.
  ///
  bool undo() {
    if (!_config.allowUndo || !_historyManager.canUndo) {
      return false;
    }

    final entry = _historyManager.undo();
    if (entry != null) {
      _data = entry.operation.undo(_data);
      _restoreSelection(entry.selectionBefore);
      notifyListeners();
      return true;
    }

    return false;
  }

  /// Redo the last undone operation
  ///
  /// Returns true if an operation was redone, false if there's nothing to redo.
  ///
  bool redo() {
    if (!_config.allowUndo || !_historyManager.canRedo) {
      return false;
    }

    final entry = _historyManager.redo();
    if (entry != null) {
      _data = entry.operation.execute(_data);
      _restoreSelection(entry.selectionAfter);
      notifyListeners();
      return true;
    }

    return false;
  }

  /// Check if there are operations that can be undone
  ///
  bool canUndo() {
    return _config.allowUndo && _historyManager.canUndo;
  }

  /// Check if there are operations that can be redone
  ///
  bool canRedo() {
    return _config.allowUndo && _historyManager.canRedo;
  }

  /// Helper: Add child to a node in the tree
  ///
  /// If the parent node is collapsed, it will be automatically expanded
  /// (similar to mind-elixir-core behavior).
  NodeData? _addChildToNode(NodeData node, String parentId, NodeData newChild) {
    if (node.id == parentId) {
      // Auto-expand parent if it's collapsed (mind-elixir-core behavior)
      final nodeToUpdate = node.expanded ? node : node.copyWith(expanded: true);
      return nodeToUpdate.addChild(newChild);
    }

    // Recursively search in children
    for (int i = 0; i < node.children.length; i++) {
      final updatedChild = _addChildToNode(
        node.children[i],
        parentId,
        newChild,
      );
      if (updatedChild != null) {
        return node.updateChild(node.children[i].id, updatedChild);
      }
    }

    return null;
  }

  /// Helper: Add sibling to a node in the tree
  NodeData? _addSiblingToNode(
    NodeData node,
    String nodeId,
    NodeData newSibling,
  ) {
    // Check if any child matches the nodeId
    for (int i = 0; i < node.children.length; i++) {
      if (node.children[i].id == nodeId) {
        // Found the node, add sibling after it
        final newChildren = List<NodeData>.from(node.children);
        newChildren.insert(i + 1, newSibling);
        return node.copyWith(children: newChildren);
      }
    }

    // Recursively search in children
    for (int i = 0; i < node.children.length; i++) {
      final updatedChild = _addSiblingToNode(
        node.children[i],
        nodeId,
        newSibling,
      );
      if (updatedChild != null) {
        return node.updateChild(node.children[i].id, updatedChild);
      }
    }

    return null;
  }

  /// Helper: Remove a node from the tree
  NodeData? _removeNodeFromTree(NodeData node, String nodeId) {
    // Check if any child matches the nodeId
    final childIndex = node.children.indexWhere((c) => c.id == nodeId);
    if (childIndex != -1) {
      // Found the node, remove it
      return node.removeChild(nodeId);
    }

    // Recursively search in children
    for (int i = 0; i < node.children.length; i++) {
      final updatedChild = _removeNodeFromTree(node.children[i], nodeId);
      if (updatedChild != null) {
        return node.updateChild(node.children[i].id, updatedChild);
      }
    }

    return null;
  }

  /// Helper: Update a node in the tree
  NodeData? _updateNodeInTree(NodeData node, String nodeId, NodeData updates) {
    if (node.id == nodeId) {
      return updates;
    }

    // Recursively search in children
    for (int i = 0; i < node.children.length; i++) {
      final updatedChild = _updateNodeInTree(node.children[i], nodeId, updates);
      if (updatedChild != null) {
        return node.updateChild(node.children[i].id, updatedChild);
      }
    }

    return null;
  }

  /// Helper: Initialize node directions for all nodes in the tree
  /// This ensures that all nodes have explicit direction set, preventing
  /// position jumping when nodes are deleted
  NodeData _initializeNodeDirections(
    NodeData node,
    LayoutDirection layoutDirection, {
    bool isRoot = true,
  }) {
    // Root node doesn't need direction
    if (isRoot) {
      if (node.children.isEmpty) {
        return node;
      }

      // Initialize children directions based on layout direction
      final updatedChildren = <NodeData>[];

      if (layoutDirection == LayoutDirection.side) {
        // For side layout, distribute children evenly
        int leftCount = 0;
        int rightCount = 0;

        for (final child in node.children) {
          LayoutDirection childDirection;

          if (child.direction != null) {
            // Keep existing direction
            childDirection = child.direction!;
            if (childDirection == LayoutDirection.left) {
              leftCount++;
            } else {
              rightCount++;
            }
          } else {
            // Assign direction based on balance
            if (leftCount <= rightCount) {
              childDirection = LayoutDirection.left;
              leftCount++;
            } else {
              childDirection = LayoutDirection.right;
              rightCount++;
            }
          }

          // Recursively initialize child's descendants
          final updatedChild = _initializeNodeDirections(
            child.copyWith(direction: childDirection),
            childDirection,
            isRoot: false,
          );
          updatedChildren.add(updatedChild);
        }
      } else {
        // For left or right layout, keep explicit direction if present.
        for (final child in node.children) {
          final childDirection = child.direction ?? layoutDirection;
          final updatedChild = _initializeNodeDirections(
            child.copyWith(direction: childDirection),
            childDirection,
            isRoot: false,
          );
          updatedChildren.add(updatedChild);
        }
      }

      return node.copyWith(children: updatedChildren);
    } else {
      // Non-root node: keep explicit direction when available.
      final currentDirection = node.direction ?? layoutDirection;

      if (node.children.isEmpty) {
        return node.copyWith(direction: currentDirection);
      }

      // Recursively initialize children
      final updatedChildren = <NodeData>[];
      for (final child in node.children) {
        final childDirection = child.direction ?? currentDirection;
        final updatedChild = _initializeNodeDirections(
          child.copyWith(direction: childDirection),
          childDirection,
          isRoot: false,
        );
        updatedChildren.add(updatedChild);
      }

      return node.copyWith(
        direction: currentDirection,
        children: updatedChildren,
      );
    }
  }

  /// Helper: Find a node in the tree
  NodeData? _findNode(NodeData node, String nodeId) {
    if (node.id == nodeId) {
      return node;
    }

    for (final child in node.children) {
      final found = _findNode(child, nodeId);
      if (found != null) return found;
    }

    return null;
  }

  /// Helper: Find the parent of a node in the tree
  NodeData? _findParent(NodeData node, String childId) {
    // Check if any direct child matches
    for (final child in node.children) {
      if (child.id == childId) {
        return node;
      }
    }

    // Recursively search in children
    for (final child in node.children) {
      final parent = _findParent(child, childId);
      if (parent != null) return parent;
    }

    return null;
  }

  /// Helper: Check if a node is a descendant of another node
  bool _isDescendant(NodeData ancestor, String nodeId) {
    if (ancestor.id == nodeId) return true;

    for (final child in ancestor.children) {
      if (_isDescendant(child, nodeId)) return true;
    }

    return false;
  }

  /// Helper: Set expanded state of a node in the tree
  /// This is used internally to change expand state without recording a separate operation
  NodeData _setNodeExpandedInTree(NodeData node, String nodeId, bool expanded) {
    if (node.id == nodeId) {
      return node.copyWith(expanded: expanded);
    }

    // Recursively search in children
    final updatedChildren = node.children.map((child) {
      return _setNodeExpandedInTree(child, nodeId, expanded);
    }).toList();

    return node.copyWith(children: updatedChildren);
  }

  /// Helper: Add child to a node at a specific index
  NodeData _addChildToNodeAtIndex(
    NodeData node,
    String parentId,
    NodeData newChild,
    int? index,
  ) {
    if (node.id == parentId) {
      final newChildren = List<NodeData>.from(node.children);
      if (index != null && index >= 0 && index <= newChildren.length) {
        newChildren.insert(index, newChild);
      } else {
        newChildren.add(newChild);
      }
      return node.copyWith(children: newChildren);
    }

    // Recursively search in children
    for (int i = 0; i < node.children.length; i++) {
      final updatedChild = _addChildToNodeAtIndex(
        node.children[i],
        parentId,
        newChild,
        index,
      );
      if (updatedChild != node.children[i]) {
        return node.updateChild(node.children[i].id, updatedChild);
      }
    }

    return node;
  }

  /// Helper: Build a preorder index map for current node order
  Map<String, int> _buildNodeOrderMap(NodeData node) {
    final orderMap = <String, int>{};
    int counter = 0;

    void traverse(NodeData current) {
      orderMap[current.id] = counter++;
      for (final child in current.children) {
        traverse(child);
      }
    }

    traverse(node);
    return orderMap;
  }

  /// Helper: Remove duplicates while preserving order
  List<String> _dedupePreserveOrder(List<String> ids) {
    final seen = <String>{};
    final result = <String>[];
    for (final id in ids) {
      if (seen.add(id)) {
        result.add(id);
      }
    }
    return result;
  }

  /// Helper: Insert a new parent above a node
  NodeData _insertParentNode(NodeData node, String nodeId, NodeData newParent) {
    for (int i = 0; i < node.children.length; i++) {
      final child = node.children[i];
      if (child.id == nodeId) {
        final newChildren = List<NodeData>.from(node.children);
        newChildren[i] = newParent;
        return node.copyWith(children: newChildren);
      }

      final updatedChild = _insertParentNode(child, nodeId, newParent);
      if (updatedChild != child) {
        return node.updateChild(child.id, updatedChild);
      }
    }

    return node;
  }

  // ========== Arrow Management Methods ==========

  /// Start arrow creation mode
  ///
  void startArrowCreationMode() {
    _isArrowCreationMode = true;
    _arrowSourceNodeId = null;
    _selectedArrowId = null;
    _selectedSummaryId = null;
    notifyListeners();
  }

  /// Exit arrow creation mode
  void exitArrowCreationMode() {
    _isArrowCreationMode = false;
    _arrowSourceNodeId = null;
    notifyListeners();
  }

  /// Select source node for arrow creation
  ///
  /// This should be called when in arrow creation mode and a node is clicked.
  ///
  void selectArrowSourceNode(String nodeId) {
    if (!_isArrowCreationMode) {
      throw StateError(_strings.errorNotInArrowCreationMode);
    }

    _arrowSourceNodeId = nodeId;
    notifyListeners();
  }

  /// Select target node and create arrow
  ///
  /// This should be called when in arrow creation mode, a source node is selected,
  /// and a target node is clicked.
  ///
  void selectArrowTargetNode(
    String targetNodeId, {
    String? label,
    bool bidirectional = false,
  }) {
    if (!_isArrowCreationMode) {
      throw StateError(_strings.errorNotInArrowCreationMode);
    }

    if (_arrowSourceNodeId == null) {
      throw StateError(_strings.errorNoSourceNodeSelected);
    }

    // Calculate intelligent control points
    final (delta1, delta2) = _calculateArrowDeltas(
      _arrowSourceNodeId!,
      targetNodeId,
    );

    // Create the arrow with calculated deltas
    final arrow = ArrowData.create(
      fromNodeId: _arrowSourceNodeId!,
      toNodeId: targetNodeId,
      label: label,
      bidirectional: bidirectional,
      delta1: delta1,
      delta2: delta2,
    );

    // Add arrow to data
    final newArrows = List<ArrowData>.from(_data.arrows)..add(arrow);
    _data = _data.copyWith(arrows: newArrows);

    // Exit arrow creation mode
    _isArrowCreationMode = false;
    _arrowSourceNodeId = null;

    // Emit event
    emitEvent(ArrowCreatedEvent(arrow.id, arrow.fromNodeId, arrow.toNodeId));

    notifyListeners();
  }

  /// Add an arrow between two nodes
  ///
  /// If delta1 and delta2 are not provided (or are Offset.zero), they will be
  /// calculated automatically based on the node positions for optimal visual appearance.
  ///
  void addArrow({
    required String fromNodeId,
    required String toNodeId,
    String? label,
    bool bidirectional = false,
    Offset? delta1,
    Offset? delta2,
    ArrowStyle? style,
  }) {
    // Verify both nodes exist
    final fromNode = _findNode(_data.nodeData, fromNodeId);
    final toNode = _findNode(_data.nodeData, toNodeId);

    if (fromNode == null) {
      _throwInvalidNodeId(fromNodeId);
    }
    if (toNode == null) {
      _throwInvalidNodeId(toNodeId);
    }

    // Calculate intelligent control points if not provided
    Offset finalDelta1;
    Offset finalDelta2;

    if (delta1 == null ||
        delta2 == null ||
        (delta1 == Offset.zero && delta2 == Offset.zero)) {
      final (calculatedDelta1, calculatedDelta2) = _calculateArrowDeltas(
        fromNodeId,
        toNodeId,
      );
      finalDelta1 = delta1 ?? calculatedDelta1;
      finalDelta2 = delta2 ?? calculatedDelta2;
    } else {
      finalDelta1 = delta1;
      finalDelta2 = delta2;
    }

    // Create the arrow
    final arrow = ArrowData.create(
      fromNodeId: fromNodeId,
      toNodeId: toNodeId,
      label: label,
      bidirectional: bidirectional,
      delta1: finalDelta1,
      delta2: finalDelta2,
      style: style,
    );

    // Add arrow to data
    final newArrows = List<ArrowData>.from(_data.arrows)..add(arrow);
    _data = _data.copyWith(arrows: newArrows);

    // Emit event
    emitEvent(ArrowCreatedEvent(arrow.id, arrow.fromNodeId, arrow.toNodeId));

    notifyListeners();
  }

  /// Calculate intelligent arrow control point deltas based on node positions
  ///
  /// This method uses the current layout to determine optimal control points
  /// for a bezier curve connecting two nodes.
  ///
  /// Returns (delta1, delta2) or (Offset.zero, Offset.zero) if layouts are not available.
  (Offset, Offset) _calculateArrowDeltas(String fromNodeId, String toNodeId) {
    // We need the current layout to calculate deltas
    // This requires access to the layout engine and current node positions
    // For now, we'll calculate a basic layout on-demand

    final layoutEngine = LayoutEngine();
    final layouts = layoutEngine.calculateLayout(
      _data.nodeData,
      _data.theme,
      _data.direction,
    );

    final fromLayout = layouts[fromNodeId];
    final toLayout = layouts[toNodeId];

    if (fromLayout == null || toLayout == null) {
      // Fallback to zero if layouts are not available
      return (Offset.zero, Offset.zero);
    }

    // Use the intelligent calculation from ArrowUtils
    return ArrowUtils.calculateDefaultDeltas(fromLayout, toLayout);
  }

  /// Remove an arrow
  void removeArrow(String arrowId) {
    final arrowIndex = _data.arrows.indexWhere((a) => a.id == arrowId);
    if (arrowIndex == -1) {
      throw InvalidNodeIdException(_strings.errorArrowNotFound(arrowId));
    }

    // Remove arrow from data
    final newArrows = List<ArrowData>.from(_data.arrows)..removeAt(arrowIndex);
    _data = _data.copyWith(arrows: newArrows);

    // Clear selection if this arrow was selected
    if (_selectedArrowId == arrowId) {
      _selectedArrowId = null;
    }

    notifyListeners();
  }

  /// Update an arrow's properties
  ///
  void updateArrow(String arrowId, ArrowData updatedArrow) {
    final arrowIndex = _data.arrows.indexWhere((a) => a.id == arrowId);
    if (arrowIndex == -1) {
      throw InvalidNodeIdException(_strings.errorArrowNotFound(arrowId));
    }

    // Update arrow in data
    final newArrows = List<ArrowData>.from(_data.arrows);
    newArrows[arrowIndex] = updatedArrow;
    _data = _data.copyWith(arrows: newArrows);

    notifyListeners();
  }

  /// Update arrow control points
  ///
  /// This is used when dragging control points to adjust the arrow curve.
  ///
  void updateArrowControlPoints(String arrowId, Offset delta1, Offset delta2) {
    final arrowIndex = _data.arrows.indexWhere((a) => a.id == arrowId);
    if (arrowIndex == -1) {
      throw InvalidNodeIdException(_strings.errorArrowNotFound(arrowId));
    }

    // Update arrow control points
    final arrow = _data.arrows[arrowIndex];
    final updatedArrow = arrow.copyWith(delta1: delta1, delta2: delta2);

    updateArrow(arrowId, updatedArrow);
  }

  /// Select an arrow for editing
  ///
  /// When an arrow is selected, its control points should be displayed.
  ///
  void selectArrow(String arrowId) {
    // Verify the arrow exists
    _data.arrows.firstWhere(
      (a) => a.id == arrowId,
      orElse: () =>
          throw InvalidNodeIdException(_strings.errorArrowNotFound(arrowId)),
    );

    _selectedArrowId = arrowId;
    _selectedSummaryId = null;
    notifyListeners();
  }

  /// Deselect the currently selected arrow
  void deselectArrow() {
    _selectedArrowId = null;
    notifyListeners();
  }

  /// Get an arrow by ID
  ArrowData? getArrow(String arrowId) {
    try {
      return _data.arrows.firstWhere((a) => a.id == arrowId);
    } catch (e) {
      return null;
    }
  }

  // ========== Summary Management Methods ==========

  /// Start summary creation mode
  ///
  /// In this mode, users can select multiple nodes to create a summary.
  /// The system will automatically find the minimum common parent and
  /// calculate the appropriate range.
  ///
  void startSummaryCreationMode() {
    _isSummaryCreationMode = true;
    _summarySelectedNodeIds = [];
    _selectedSummaryId = null;
    notifyListeners();
  }

  /// Exit summary creation mode
  void exitSummaryCreationMode() {
    _isSummaryCreationMode = false;
    _summarySelectedNodeIds = [];
    notifyListeners();
  }

  /// Toggle node selection for summary creation
  ///
  /// In summary creation mode, clicking nodes will add/remove them from
  /// the selection. When at least one node is selected, a summary can be created.
  ///
  void toggleSummaryNodeSelection(String nodeId) {
    if (!_isSummaryCreationMode) {
      throw StateError(_strings.errorNotInSummaryCreationMode);
    }

    // Verify the node exists
    final node = _findNode(_data.nodeData, nodeId);
    if (node == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Toggle selection
    if (_summarySelectedNodeIds.contains(nodeId)) {
      _summarySelectedNodeIds.remove(nodeId);
    } else {
      _summarySelectedNodeIds.add(nodeId);
    }

    notifyListeners();
  }

  /// Create summary from selected nodes
  ///
  /// This uses the intelligent minimum common parent algorithm to automatically
  /// determine the parent node and child range from the selected nodes.
  ///
  void createSummaryFromSelection({String? label}) {
    if (!_isSummaryCreationMode) {
      throw StateError(_strings.errorNotInSummaryCreationMode);
    }

    if (_summarySelectedNodeIds.isEmpty) {
      throw StateError(_strings.errorNoNodesSelectedForSummary);
    }

    try {
      // Use the intelligent algorithm to find the minimum common parent
      final (
        parentId,
        startIndex,
        endIndex,
      ) = TreeUtils.findMinimumCommonParent(
        _data.nodeData,
        _summarySelectedNodeIds,
        strings: _strings,
      );

      // Create the summary
      final summary = SummaryData.create(
        parentNodeId: parentId,
        startIndex: startIndex,
        endIndex: endIndex,
        label: label ?? _strings.defaultSummaryLabel,
      );

      // Add summary to data
      final newSummaries = List<SummaryData>.from(_data.summaries)
        ..add(summary);
      _data = _data.copyWith(summaries: newSummaries);

      // Exit summary creation mode
      _isSummaryCreationMode = false;
      _summarySelectedNodeIds = [];

      // Emit event
      emitEvent(SummaryCreatedEvent(summary.id, summary.parentNodeId));

      notifyListeners();
    } catch (e) {
      // Re-throw with more context
      throw StateError(_strings.errorFailedToCreateSummary(e));
    }
  }

  /// Add a summary directly
  ///
  void addSummary({
    required String parentNodeId,
    required int startIndex,
    required int endIndex,
    String? label,
    SummaryStyle? style,
  }) {
    // Verify parent node exists
    final parentNode = _findNode(_data.nodeData, parentNodeId);
    if (parentNode == null) {
      _throwInvalidNodeId(parentNodeId);
    }

    // Verify indices are valid
    if (startIndex < 0 ||
        endIndex >= parentNode.children.length ||
        startIndex > endIndex) {
      throw StateError(_strings.errorInvalidChildRange(startIndex, endIndex));
    }

    // Create the summary
    final summary = SummaryData.create(
      parentNodeId: parentNodeId,
      startIndex: startIndex,
      endIndex: endIndex,
      label: label,
      style: style,
    );

    // Add summary to data
    final newSummaries = List<SummaryData>.from(_data.summaries)..add(summary);
    _data = _data.copyWith(summaries: newSummaries);

    // Emit event
    emitEvent(SummaryCreatedEvent(summary.id, summary.parentNodeId));

    notifyListeners();
  }

  /// Remove a summary
  void removeSummary(String summaryId) {
    final summaryIndex = _data.summaries.indexWhere((s) => s.id == summaryId);
    if (summaryIndex == -1) {
      throw InvalidNodeIdException(_strings.errorSummaryNotFound(summaryId));
    }

    // Remove summary from data
    final newSummaries = List<SummaryData>.from(_data.summaries)
      ..removeAt(summaryIndex);
    _data = _data.copyWith(summaries: newSummaries);
    if (_selectedSummaryId == summaryId) {
      _selectedSummaryId = null;
    }

    notifyListeners();
  }

  /// Update a summary's properties
  ///
  void updateSummary(String summaryId, SummaryData updatedSummary) {
    final summaryIndex = _data.summaries.indexWhere((s) => s.id == summaryId);
    if (summaryIndex == -1) {
      throw InvalidNodeIdException(_strings.errorSummaryNotFound(summaryId));
    }

    // Update summary in data
    final newSummaries = List<SummaryData>.from(_data.summaries);
    newSummaries[summaryIndex] = updatedSummary;
    _data = _data.copyWith(summaries: newSummaries);

    notifyListeners();
  }

  /// Get a summary by ID
  SummaryData? getSummary(String summaryId) {
    try {
      return _data.summaries.firstWhere((s) => s.id == summaryId);
    } catch (e) {
      return null;
    }
  }

  /// Select a summary for visual highlighting / keyboard operations.
  void selectSummary(String summaryId) {
    _data.summaries.firstWhere(
      (s) => s.id == summaryId,
      orElse: () => throw InvalidNodeIdException(
        _strings.errorSummaryNotFound(summaryId),
      ),
    );

    _selectedSummaryId = summaryId;
    notifyListeners();
  }

  /// Deselect current summary.
  void deselectSummary() {
    if (_selectedSummaryId == null) return;
    _selectedSummaryId = null;
    notifyListeners();
  }

  // ========== Theme Management Methods ==========

  /// Set the theme for the mind map
  ///
  /// This allows runtime theme switching without requiring widget re-initialization.
  /// All visual elements will be updated to use the new theme colors and styles.
  ///
  void setTheme(MindMapTheme theme) {
    _data = _data.copyWith(theme: theme);
    notifyListeners();
  }

  /// Get the current theme
  MindMapTheme getTheme() {
    return _data.theme;
  }

  // ========== View Control Methods ==========

  /// Center the view on the whole mind map.
  ///
  /// This method centers the viewport on the full mind map bounding box with
  /// smooth animation (not only the root node).
  ///
  void centerView({Duration duration = const Duration(milliseconds: 300)}) {
    if (_viewportSize == null) {
      // If viewport size is not set, just reset to origin
      _zoomPanManager.reset();
      return;
    }

    // Center on full mind map visual bounds.
    final mapCenter = _getMindMapCenterInCanvas();

    if (duration.inMilliseconds > 0) {
      // Animate to center position
      _animateViewTransition(
        targetPosition: mapCenter,
        targetScale: _zoomPanManager.scale,
        duration: duration,
      );
    } else {
      // Immediate center without animation
      _zoomPanManager.centerOn(mapCenter, _viewportSize!);
    }
  }

  /// Fit the full mind map into the viewport and center it.
  void fitToView({Duration duration = const Duration(milliseconds: 300)}) {
    if (_viewportSize == null) {
      _zoomPanManager.reset();
      return;
    }

    final layouts = LayoutEngine().calculateLayout(
      _data.nodeData,
      _data.theme,
      _data.direction,
    );
    final bounds = _calculateBoundingBox(layouts);
    final viewport = _viewportSize!;

    const fitPadding = 16.0;
    final availableWidth = math.max(1.0, viewport.width - fitPadding * 2);
    final availableHeight = math.max(1.0, viewport.height - fitPadding * 2);

    double targetScale = _zoomPanManager.scale;
    if (bounds.width > 0.0 && bounds.height > 0.0) {
      targetScale = math.min(
        availableWidth / bounds.width,
        availableHeight / bounds.height,
      );
      if (!targetScale.isFinite || targetScale <= 0.0) {
        targetScale = 1.0;
      }
    }

    targetScale = targetScale.clamp(
      _zoomPanManager.minScale,
      _zoomPanManager.maxScale,
    );

    if (duration.inMilliseconds > 0) {
      _animateViewTransition(
        targetPosition: bounds.center,
        targetScale: targetScale,
        duration: duration,
      );
    } else {
      _zoomPanManager.setZoom(targetScale);
      _zoomPanManager.centerOn(bounds.center, viewport);
    }
  }

  Offset _getMindMapCenterInCanvas() {
    final layouts = LayoutEngine().calculateLayout(
      _data.nodeData,
      _data.theme,
      _data.direction,
    );
    final bounds = _calculateBoundingBox(layouts);
    return bounds.center;
  }

  /// Center view when the viewport size is available.
  /// If called before the widget reports its size, the request is deferred.
  void centerViewWhenReady() {
    if (_viewportSize == null) {
      _centerWhenReady = true;
      return;
    }
    if (_didInitialViewportFit) {
      centerView(duration: Duration.zero);
    } else {
      fitToView(duration: Duration.zero);
      _didInitialViewportFit = true;
    }
  }

  /// Set the zoom level programmatically
  ///
  /// [scale] - The new zoom scale (will be clamped to min/max limits)
  /// [focalPoint] - Optional point to zoom around (defaults to viewport center)
  /// [duration] - Animation duration (default 300ms, set to Duration.zero for immediate)
  ///
  void setZoom(
    double scale, {
    Offset? focalPoint,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    if (duration.inMilliseconds > 0) {
      // Animate zoom transition
      _animateViewTransition(
        targetPosition: _zoomPanManager.translation,
        targetScale: scale,
        duration: duration,
        focalPoint: focalPoint,
      );
    } else {
      // Immediate zoom without animation
      _zoomPanManager.setZoom(scale, focalPoint: focalPoint);
    }
  }

  /// Get the current zoom level
  ///
  /// Returns the current scale factor of the view.
  double getZoom() {
    return _zoomPanManager.scale;
  }

  /// Set the layout direction
  ///
  /// Changes the layout direction and reinitializes all node directions.
  /// This allows switching between:
  /// - LayoutDirection.side: Nodes distributed on both sides (default)
  /// - LayoutDirection.left: All nodes on the left side
  /// - LayoutDirection.right: All nodes on the right side
  ///
  /// [direction] - The new layout direction
  /// [duration] - Optional animation duration for view transition
  void setLayoutDirection(
    LayoutDirection direction, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final isSameDirection = _data.direction == direction;
    if (isSameDirection && direction != LayoutDirection.side) {
      // Already in this direction, no change needed for left/right.
      return;
    }

    // Update the layout direction
    _data = _data.copyWith(direction: direction);

    // Reinitialize all node directions based on the new layout direction
    // For SIDE layout, rebalance root children directions to match
    // mind-elixir "average distribution" behavior from the UI action.
    _data = _data.copyWith(
      nodeData: _initializeNodeDirections(_data.nodeData, direction),
    );

    // Notify listeners to trigger layout recalculation
    notifyListeners();

    // Optionally center the view after layout change
    if (duration.inMilliseconds > 0) {
      Future.delayed(const Duration(milliseconds: 50), () {
        centerView(duration: duration);
      });
    }
  }

  /// Get the current layout direction
  ///
  /// Returns the current layout direction setting.
  LayoutDirection getLayoutDirection() {
    return _data.direction;
  }

  /// Copy a node to the clipboard
  ///
  /// This copies the node and all its descendants to an internal clipboard.
  /// The copied node can then be pasted as a child of another node.
  ///
  void copyNode(String nodeId) {
    final node = _findNode(_data.nodeData, nodeId);
    if (node == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Store the copied node in the selection manager's clipboard
    _selectionManager.copyToClipboard(node);
  }

  /// Paste the copied node as a child of the specified parent
  ///
  /// This pastes the previously copied node (and all its descendants)
  /// as a child of the specified parent node.
  ///
  void pasteNode(String parentId) {
    final copiedNode = _selectionManager.getFromClipboard();
    if (copiedNode == null) {
      throw Exception(_strings.errorNoNodeInClipboard);
    }

    // Create a deep copy with new IDs
    final pastedNode = _createNodeCopyWithNewIds(copiedNode);

    // Add as child
    final updatedRoot = _addChildToNode(_data.nodeData, parentId, pastedNode);
    if (updatedRoot != null) {
      _data = _data.copyWith(nodeData: updatedRoot);
      emitEvent(NodeOperationEvent('paste', pastedNode.id));
      notifyListeners();
    } else {
      _throwInvalidNodeId(parentId);
    }
  }

  /// Create a deep copy of a node with new IDs for all nodes
  NodeData _createNodeCopyWithNewIds(NodeData node) {
    final newChildren = node.children
        .map((child) => _createNodeCopyWithNewIds(child))
        .toList();

    return NodeData(
      id: NodeData.generateId(),
      topic: node.topic,
      style: node.style,
      children: newChildren,
      tags: node.tags,
      icons: node.icons,
      hyperLink: node.hyperLink,
      expanded: node.expanded,
      direction: node.direction,
      image: node.image,
      images: node.images,
      branchColor: node.branchColor,
      note: node.note,
    );
  }

  /// Center the view on a specific node
  ///
  /// [nodeId] - The ID of the node to center on
  /// [nodePosition] - The position of the node in canvas coordinates
  /// [duration] - Animation duration (default 300ms)
  ///
  /// Note: This requires the node position to be provided by the widget
  void centerOnNode(
    String nodeId,
    Offset nodePosition, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    if (_viewportSize == null) {
      return;
    }

    if (duration.inMilliseconds > 0) {
      _animateViewTransition(
        targetPosition: nodePosition,
        targetScale: _zoomPanManager.scale,
        duration: duration,
      );
    } else {
      _zoomPanManager.centerOn(nodePosition, _viewportSize!);
    }
  }

  /// Animate view transition with smooth animation
  ///
  /// This provides smooth animations for pan and zoom operations.
  ///
  void _animateViewTransition({
    required Offset targetPosition,
    required double targetScale,
    required Duration duration,
    Offset? focalPoint,
  }) {
    if (_viewportSize == null) {
      return;
    }

    // Get current state
    final startScale = _zoomPanManager.scale;
    final startTranslation = _zoomPanManager.translation;

    // Clamp target scale to limits
    final clampedScale = targetScale.clamp(
      _zoomPanManager.minScale,
      _zoomPanManager.maxScale,
    );

    // Calculate target translation
    Offset targetTranslation;
    if (focalPoint != null) {
      // Zoom around focal point
      final focalPointInCanvasBefore = _screenToCanvas(
        focalPoint,
        startScale,
        startTranslation,
      );

      // Calculate what translation would be needed at target scale
      // to keep focal point fixed
      final scaledFocalPoint = focalPointInCanvasBefore * clampedScale;
      targetTranslation = focalPoint - scaledFocalPoint;
    } else {
      // Center on target position
      final viewportCenter = Offset(
        _viewportSize!.width / 2,
        _viewportSize!.height / 2,
      );
      final scaledTargetPosition = targetPosition * clampedScale;
      targetTranslation = viewportCenter - scaledTargetPosition;
    }

    // Create animation controller (simplified - in real implementation,
    // this would use AnimationController with TickerProvider)
    // For now, we'll do a simple linear interpolation over time
    final startTime = DateTime.now();

    void animate() {
      final elapsed = DateTime.now().difference(startTime);
      final t = (elapsed.inMilliseconds / duration.inMilliseconds).clamp(
        0.0,
        1.0,
      );

      if (t >= 1.0) {
        // Animation complete
        _zoomPanManager.setZoom(clampedScale, focalPoint: focalPoint);
        if (focalPoint == null) {
          _zoomPanManager.setTranslation(targetTranslation);
        }
        return;
      }

      // Apply easing function (ease-in-out)
      final easedT = _easeInOutCubic(t);

      // Interpolate scale
      final currentScale = startScale + (clampedScale - startScale) * easedT;

      // Interpolate translation
      final currentTranslation = Offset(
        startTranslation.dx +
            (targetTranslation.dx - startTranslation.dx) * easedT,
        startTranslation.dy +
            (targetTranslation.dy - startTranslation.dy) * easedT,
      );

      // Update zoom/pan manager
      _zoomPanManager.setZoom(currentScale);
      _zoomPanManager.setTranslation(currentTranslation);

      // Schedule next frame
      Future.delayed(const Duration(milliseconds: 16), animate);
    }

    // Start animation
    animate();
  }

  /// Ease-in-out cubic easing function
  double _easeInOutCubic(double t) {
    if (t < 0.5) {
      return 4 * t * t * t;
    } else {
      final f = 2 * t - 2;
      return 0.5 * f * f * f + 1;
    }
  }

  /// Convert screen coordinates to canvas coordinates
  Offset _screenToCanvas(Offset screenPoint, double scale, Offset translation) {
    return (screenPoint - translation) / scale;
  }

  // ========== Focus Mode Methods ==========

  /// Enter focus mode on a specific node
  ///
  /// When focus mode is active, only the focused node and its descendants are visible.
  /// The focused node is displayed as the root node.
  ///
  void focusNode(String nodeId) {
    // Verify the node exists
    final node = _findNode(_data.nodeData, nodeId);
    if (node == null) {
      _throwInvalidNodeId(nodeId);
    }

    _isFocusMode = true;
    _focusedNodeId = nodeId;

    // Clear selection when entering focus mode
    _selectionManager.clearSelection();

    notifyListeners();
  }

  /// Exit focus mode and restore the full mind map view
  ///
  void exitFocusMode() {
    _isFocusMode = false;
    _focusedNodeId = null;

    notifyListeners();
  }

  // ========== Node Style Methods ==========

  /// Set the font size of a node
  ///
  /// [nodeId] - The ID of the node to update
  /// [fontSize] - The new font size in logical pixels
  ///
  void setNodeFontSize(String nodeId, double fontSize) {
    final node = _findNode(_data.nodeData, nodeId);
    if (node == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Get existing style or create new one
    final currentStyle = node.style ?? NodeStyle();
    final updatedStyle = currentStyle.copyWith(fontSize: fontSize);

    // Record operation if undo is enabled
    final operation = StyleNodeOperation(
      nodeId: nodeId,
      oldStyle: node.style,
      newStyle: updatedStyle,
    );
    _recordOperation(operation);

    // Update node with new style
    updateNode(nodeId, node.copyWith(style: updatedStyle));
  }

  /// Set the text color of a node
  ///
  /// [nodeId] - The ID of the node to update
  /// [color] - The new text color
  ///
  void setNodeColor(String nodeId, Color color) {
    final node = _findNode(_data.nodeData, nodeId);
    if (node == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Get existing style or create new one
    final currentStyle = node.style ?? NodeStyle();
    final updatedStyle = currentStyle.copyWith(color: color);

    // Record operation if undo is enabled
    final operation = StyleNodeOperation(
      nodeId: nodeId,
      oldStyle: node.style,
      newStyle: updatedStyle,
    );
    _recordOperation(operation);

    // Update node with new style
    updateNode(nodeId, node.copyWith(style: updatedStyle));
  }

  /// Set the background color of a node
  ///
  /// [nodeId] - The ID of the node to update
  /// [background] - The new background color
  ///
  void setNodeBackground(String nodeId, Color background) {
    final node = _findNode(_data.nodeData, nodeId);
    if (node == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Get existing style or create new one
    final currentStyle = node.style ?? NodeStyle();
    final updatedStyle = currentStyle.copyWith(background: background);

    // Record operation if undo is enabled
    final operation = StyleNodeOperation(
      nodeId: nodeId,
      oldStyle: node.style,
      newStyle: updatedStyle,
    );
    _recordOperation(operation);

    // Update node with new style
    updateNode(nodeId, node.copyWith(style: updatedStyle));
  }

  /// Set the font weight of a node (e.g., bold)
  ///
  /// [nodeId] - The ID of the node to update
  /// [fontWeight] - The new font weight (e.g., FontWeight.bold, FontWeight.normal)
  ///
  void setNodeFontWeight(String nodeId, FontWeight fontWeight) {
    final node = _findNode(_data.nodeData, nodeId);
    if (node == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Get existing style or create new one
    final currentStyle = node.style ?? NodeStyle();
    final updatedStyle = currentStyle.copyWith(fontWeight: fontWeight);

    // Record operation if undo is enabled
    final operation = StyleNodeOperation(
      nodeId: nodeId,
      oldStyle: node.style,
      newStyle: updatedStyle,
    );
    _recordOperation(operation);

    // Update node with new style
    updateNode(nodeId, node.copyWith(style: updatedStyle));
  }

  /// Add a tag to a node
  ///
  /// [nodeId] - The ID of the node to update
  /// [tag] - The tag to add
  ///
  /// If the tag already exists (same text), it will not be added again.
  ///
  void addNodeTag(String nodeId, TagData tag) {
    final node = _findNode(_data.nodeData, nodeId);
    if (node == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Check if tag already exists
    if (node.tags.any((t) => t.text == tag.text)) {
      // Tag already exists, don't add duplicate
      return;
    }

    // Add tag to node
    final updatedTags = [...node.tags, tag];
    updateNode(nodeId, node.copyWith(tags: updatedTags));
  }

  /// Remove a tag from a node
  ///
  /// [nodeId] - The ID of the node to update
  /// [tagText] - The text of the tag to remove
  ///
  void removeNodeTag(String nodeId, String tagText) {
    final node = _findNode(_data.nodeData, nodeId);
    if (node == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Remove tag from node
    final updatedTags = node.tags.where((t) => t.text != tagText).toList();
    updateNode(nodeId, node.copyWith(tags: updatedTags));
  }

  /// Add an icon to a node
  ///
  /// [nodeId] - The ID of the node to update
  /// [icon] - The icon string (emoji or icon character)
  ///
  /// If the icon already exists, it will not be added again.
  ///
  void addNodeIcon(String nodeId, String icon) {
    final node = _findNode(_data.nodeData, nodeId);
    if (node == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Check if icon already exists
    if (node.icons.contains(icon)) {
      // Icon already exists, don't add duplicate
      return;
    }

    // Add icon to node
    final updatedIcons = [...node.icons, icon];
    updateNode(nodeId, node.copyWith(icons: updatedIcons));
  }

  /// Remove an icon from a node
  ///
  /// [nodeId] - The ID of the node to update
  /// [icon] - The icon string to remove
  ///
  void removeNodeIcon(String nodeId, String icon) {
    final node = _findNode(_data.nodeData, nodeId);
    if (node == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Remove icon from node
    final updatedIcons = node.icons.where((i) => i != icon).toList();
    updateNode(nodeId, node.copyWith(icons: updatedIcons));
  }

  /// Set a hyperlink on a node
  ///
  /// [nodeId] - The ID of the node to update
  /// [hyperLink] - The URL to set (or null to remove the hyperlink)
  ///
  /// When a node has a hyperlink, it should be rendered with a visual indicator
  /// and allow the user to open the link.
  ///
  void setNodeHyperLink(String nodeId, String? hyperLink) {
    final node = _findNode(_data.nodeData, nodeId);
    if (node == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Create new node with updated hyperlink
    // We need to create a new NodeData directly because copyWith doesn't support setting to null
    final updatedNode = NodeData(
      id: node.id,
      topic: node.topic,
      style: node.style,
      children: node.children,
      tags: node.tags,
      icons: node.icons,
      hyperLink: hyperLink,
      expanded: node.expanded,
      direction: node.direction,
      image: node.image,
      images: node.images,
      branchColor: node.branchColor,
      note: node.note,
    );

    updateNode(nodeId, updatedNode);
  }

  /// Set image on a node
  ///
  /// [nodeId] - The ID of the node to update
  /// [image] - Image data to set, or null to remove image
  void setNodeImage(String nodeId, ImageData? image) {
    final node = _findNode(_data.nodeData, nodeId);
    if (node == null) {
      _throwInvalidNodeId(nodeId);
    }

    // Build a full node instance so image can be set to null explicitly.
    final updatedNode = NodeData(
      id: node.id,
      topic: node.topic,
      style: node.style,
      children: node.children,
      tags: node.tags,
      icons: node.icons,
      hyperLink: node.hyperLink,
      expanded: node.expanded,
      direction: node.direction,
      image: image,
      images: image == null ? const [] : [image],
      branchColor: node.branchColor,
      note: node.note,
    );

    updateNode(nodeId, updatedNode);
  }

  /// Append an image to a node (supports multiple images per node).
  void addNodeImage(String nodeId, ImageData image) {
    final node = _findNode(_data.nodeData, nodeId);
    if (node == null) {
      _throwInvalidNodeId(nodeId);
    }

    final merged = [...node.effectiveImages, image];
    final updatedNode = NodeData(
      id: node.id,
      topic: node.topic,
      style: node.style,
      children: node.children,
      tags: node.tags,
      icons: node.icons,
      hyperLink: node.hyperLink,
      expanded: node.expanded,
      direction: node.direction,
      image: merged.isEmpty ? null : merged.first,
      images: merged,
      branchColor: node.branchColor,
      note: node.note,
    );
    updateNode(nodeId, updatedNode);
  }

  /// Remove all images from a node.
  void clearNodeImages(String nodeId) {
    setNodeImage(nodeId, null);
  }

  // ========== Export Methods ==========

  /// Export the mind map to JSON string
  ///
  /// Returns a JSON string representation of the complete mind map data,
  /// including all nodes, arrows, summaries, direction, and theme.
  ///
  /// The returned JSON string can be saved to a file or transmitted over
  /// a network, and later imported using MindMapData.fromJson().
  ///
  String exportToJson() {
    // Get the JSON representation of the mind map data
    final jsonMap = _data.toJson();

    // Convert to JSON string with pretty printing for readability
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonMap);

    return jsonString;
  }

  /// Set the repaint boundary key for PNG export
  ///
  /// This method is called internally by MindMapWidget to provide
  /// access to the RepaintBoundary for image capture.
  void setRepaintBoundaryKey(GlobalKey key) {
    _repaintBoundaryKey = key;
  }

  /// Set decoded node image cache used by offscreen PNG export.
  void setExportImageCache(Map<String, ui.Image> imageCache) {
    _exportImageCache = imageCache;
  }

  /// Export the mind map to PNG image
  ///
  /// Renders the mind map offscreen and returns the image data as PNG.
  /// Export output is auto fit-and-centered and does not depend on current
  /// interactive zoom/pan state.
  ///
  /// Parameters:
  /// - [size]: Optional size for the exported image. If not provided,
  ///   uses the current widget size. If provided, the mind map will be
  ///   rendered at the specified size.
  /// - [pixelRatio]: The pixel ratio for the image. Defaults to 1.0.
  ///   Higher values produce higher resolution images.
  ///
  /// Returns a Future that completes with the PNG image data as Uint8List.
  ///
  /// Throws an exception if the RepaintBoundary is not available or if
  /// image capture fails.
  ///
  /// Example:
  /// ```dart
  /// final pngBytes = await controller.exportToPng();
  /// // Save to file or display
  /// ```
  ///
  Future<Uint8List> exportToPng({Size? size, double pixelRatio = 1.0}) async {
    if (_repaintBoundaryKey == null) {
      throw Exception(_strings.errorRepaintBoundaryKeyNotSet);
    }

    // Get the RenderRepaintBoundary from the key
    final boundary =
        _repaintBoundaryKey!.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;

    if (boundary == null) {
      throw Exception(_strings.errorFailedToGetRenderRepaintBoundary);
    }

    final layoutEngine = LayoutEngine();
    final layouts = layoutEngine.calculateLayout(
      _data.nodeData,
      _data.theme,
      _data.direction,
    );
    final bounds = _calculateBoundingBox(layouts);
    final exportSize = size ?? boundary.size;
    final effectivePixelRatio = pixelRatio <= 0.0 ? 1.0 : pixelRatio;
    final renderWidth = math.max(
      1,
      (exportSize.width * effectivePixelRatio).round(),
    );
    final renderHeight = math.max(
      1,
      (exportSize.height * effectivePixelRatio).round(),
    );
    final renderSize = Size(renderWidth.toDouble(), renderHeight.toDouble());
    const exportPadding = 8.0;
    final availableWidth = math.max(1.0, renderSize.width - exportPadding * 2);
    final availableHeight = math.max(
      1.0,
      renderSize.height - exportPadding * 2,
    );

    double fitScale = 1.0;
    if (bounds.width > 0.0 && bounds.height > 0.0) {
      fitScale = math.min(
        availableWidth / bounds.width,
        availableHeight / bounds.height,
      );
      if (!fitScale.isFinite || fitScale <= 0.0) {
        fitScale = 1.0;
      }
    }

    final fitTranslation = Offset(
      (renderSize.width - bounds.width * fitScale) / 2 - bounds.left * fitScale,
      (renderSize.height - bounds.height * fitScale) / 2 -
          bounds.top * fitScale,
    );
    final exportTransform = Matrix4.identity()
      ..translateByDouble(fitTranslation.dx, fitTranslation.dy, 0.0, 1.0)
      ..scaleByDouble(fitScale, fitScale, 1.0, 1.0);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0.0, 0.0, renderSize.width, renderSize.height),
    );
    final painter = MindMapPainter(
      data: _data,
      nodeLayouts: layouts,
      transform: exportTransform,
      strings: _strings,
      imageCache: _exportImageCache,
    );
    painter.paint(canvas, renderSize);
    final picture = recorder.endRecording();
    final image = await picture.toImage(renderWidth, renderHeight);

    // Convert to PNG bytes
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception(_strings.errorFailedToConvertImageToPng);
    }

    // Return the PNG bytes
    return byteData.buffer.asUint8List();
  }

  /// Calculate the visual bounding box of the mind map.
  ///
  /// Includes nodes and overlay visuals that can extend outside node bounds:
  /// expand/collapse indicators, hyperlink indicators, arrows and summaries.
  Rect _calculateBoundingBox(Map<String, NodeLayout> layouts) {
    if (layouts.isEmpty) {
      return Rect.zero;
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final layout in layouts.values) {
      minX = minX < layout.bounds.left ? minX : layout.bounds.left;
      minY = minY < layout.bounds.top ? minY : layout.bounds.top;
      maxX = maxX > layout.bounds.right ? maxX : layout.bounds.right;
      maxY = maxY > layout.bounds.bottom ? maxY : layout.bounds.bottom;
    }

    Rect totalBounds = Rect.fromLTRB(minX, minY, maxX, maxY);

    final rootLayout = layouts[_data.nodeData.id];
    final rootCenterX = rootLayout?.bounds.center.dx;

    for (final entry in layouts.entries) {
      final nodeId = entry.key;
      final layout = entry.value;
      final node = _findNode(_data.nodeData, nodeId);
      if (node == null) continue;
      final depth = _findNodeDepthById(_data.nodeData, nodeId);
      final resolvedDepth = depth < 0 ? 0 : depth;
      final isLeftSide = rootCenterX != null
          ? layout.bounds.center.dx < rootCenterX
          : (node.direction == LayoutDirection.left);

      final expandBounds = NodeRenderer.getExpandIndicatorBounds(
        node,
        layout,
        _data.theme,
        resolvedDepth,
        isLeftSide,
      );
      if (expandBounds != null) {
        totalBounds = totalBounds.expandToInclude(expandBounds.inflate(2.0));
      }

      final hyperlinkBounds = NodeRenderer.getHyperlinkIndicatorBounds(
        node,
        layout,
        _data.theme,
        resolvedDepth,
        isLeftSide,
      );
      if (hyperlinkBounds != null) {
        totalBounds = totalBounds.expandToInclude(hyperlinkBounds.inflate(2.0));
      }
    }

    for (final arrow in _data.arrows) {
      final arrowBounds = ArrowRenderer.getArrowBounds(
        arrow,
        layouts,
        _data.theme,
      );
      if (arrowBounds != null) {
        totalBounds = totalBounds.expandToInclude(arrowBounds.inflate(2.0));
      }
    }

    for (final summary in _data.summaries) {
      final parentNode = _findNode(_data.nodeData, summary.parentNodeId);
      if (parentNode == null) continue;
      final parentDepth = _findNodeDepthById(_data.nodeData, summary.parentNodeId);
      if (parentDepth < 0) continue;
      final summaryBounds = SummaryRenderer.getSummaryBounds(
        summary,
        parentNode,
        layouts,
        parentHasParent: parentDepth > 0,
        parentDepth: parentDepth,
        theme: _data.theme,
      );
      if (summaryBounds != null) {
        totalBounds = totalBounds.expandToInclude(summaryBounds.inflate(2.0));
      }
    }

    // Keep a tiny guard for anti-aliasing/stroke caps.
    return totalBounds.inflate(2.0);
  }

  int _findNodeDepthById(NodeData node, String targetId, [int depth = 0]) {
    if (node.id == targetId) {
      return depth;
    }
    for (final child in node.children) {
      final childDepth = _findNodeDepthById(child, targetId, depth + 1);
      if (childDepth >= 0) {
        return childDepth;
      }
    }
    return -1;
  }

  @override
  void dispose() {
    _selectionManager.dispose();
    _zoomPanManager.dispose();
    _eventStreamController.close();
    super.dispose();
  }
}

class _MoveNodeInfo {
  final String nodeId;
  final NodeData node;
  final String oldParentId;
  final int oldIndex;

  _MoveNodeInfo({
    required this.nodeId,
    required this.node,
    required this.oldParentId,
    required this.oldIndex,
  });
}
