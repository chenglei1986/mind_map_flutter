import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../widgets/mind_map_controller.dart';
import '../models/node_data.dart';

/// Handles keyboard shortcuts for common mind map operations
///
class KeyboardHandler {
  final MindMapController controller;
  final VoidCallback? onCenterView;
  final VoidCallback? onBeginEdit;

  // Clipboard state for copy/paste
  String? _copiedNodeId;

  KeyboardHandler({
    required this.controller,
    this.onCenterView,
    this.onBeginEdit,
  });

  /// Handle keyboard events
  ///
  /// Returns true if the event was handled, false otherwise.
  bool handleKeyEvent(KeyEvent event) {
    // Handle key down and key repeat events; ignore key up.
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return false;
    }

    // Check for modifier keys - use a safer approach for testing
    bool isCtrlPressed = false;
    bool isMetaPressed = false;
    bool isShiftPressed = false;

    try {
      isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
      isMetaPressed = HardwareKeyboard.instance.isMetaPressed;
      isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    } catch (e) {
      // In tests, HardwareKeyboard might not be initialized
      // Fall back to checking the event's modifiers
      debugPrint('HardwareKeyboard not available, using event modifiers');
    }

    // Platform-specific modifier (Ctrl on Windows/Linux, Cmd on macOS)
    final isModifierPressed = isCtrlPressed || isMetaPressed;

    // Get selected nodes
    final selectedNodeIds = controller.getSelectedNodeIds();
    final hasSelection = selectedNodeIds.isNotEmpty;
    final selectedNodeId = hasSelection ? selectedNodeIds.first : null;

    // Handle shortcuts based on key
    final key = event.logicalKey;

    // ESC - Exit focus mode
    if (key == LogicalKeyboardKey.escape && controller.isFocusMode) {
      controller.exitFocusMode();
      return true;
    }

    // Tab - Add child node
    if (key == LogicalKeyboardKey.tab && hasSelection) {
      controller.addChildNode(
        selectedNodeId!,
        topic: controller.defaultNewNodeTopic,
      );
      // Select the newly created node
      final node = controller.getData().nodeData;
      final parent = _findNode(node, selectedNodeId);
      if (parent != null && parent.children.isNotEmpty) {
        final newChild = parent.children.last;
        controller.selectionManager.selectNode(newChild.id);
      }
      return true;
    }

    // Enter - Add sibling node
    if (key == LogicalKeyboardKey.enter && hasSelection) {
      // Don't add sibling to root node
      if (selectedNodeId != controller.getData().nodeData.id) {
        controller.addSiblingNode(
          selectedNodeId!,
          topic: controller.defaultNewNodeTopic,
        );
        // Select the newly created node
        final node = controller.getData().nodeData;
        final parent = _findParent(node, selectedNodeId);
        if (parent != null) {
          final siblingIndex = parent.children.indexWhere(
            (c) => c.id == selectedNodeId,
          );
          if (siblingIndex >= 0 && siblingIndex + 1 < parent.children.length) {
            final newSibling = parent.children[siblingIndex + 1];
            controller.selectionManager.selectNode(newSibling.id);
          }
        }
      }
      return true;
    }

    // Delete/Backspace - Delete node(s), arrow, or summary
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      // Priority 1: Delete selected arrow
      if (controller.selectedArrowId != null) {
        controller.removeArrow(controller.selectedArrowId!);
        return true;
      }

      // Priority 2: Delete selected summary
      if (controller.selectedSummaryId != null) {
        controller.removeSummary(controller.selectedSummaryId!);
        return true;
      }

      // Priority 3: Delete selected node(s)
      if (hasSelection) {
        // Delete all selected nodes (except root)
        for (final nodeId in selectedNodeIds) {
          // Don't delete root node
          if (nodeId != controller.getData().nodeData.id) {
            try {
              controller.removeNode(nodeId);
            } catch (e) {
              // Silently ignore if deletion fails
              debugPrint('Failed to delete node $nodeId: $e');
            }
          }
        }
        return true;
      }
    }

    // F1 - Center view on root
    if (key == LogicalKeyboardKey.f1) {
      if (onCenterView != null) {
        onCenterView!();
      } else {
        controller.centerView();
      }
      return true;
    }

    // F2 - Enter edit mode
    if (key == LogicalKeyboardKey.f2 && hasSelection) {
      if (onBeginEdit != null) {
        onBeginEdit!();
      }
      return true;
    }

    // Ctrl/Cmd + C - Copy node
    if (isModifierPressed && key == LogicalKeyboardKey.keyC && hasSelection) {
      _copiedNodeId = selectedNodeId;
      return true;
    }

    // Ctrl/Cmd + V - Paste node
    if (isModifierPressed &&
        key == LogicalKeyboardKey.keyV &&
        hasSelection &&
        _copiedNodeId != null) {
      // Find the copied node
      final copiedNode = _findNode(
        controller.getData().nodeData,
        _copiedNodeId!,
      );
      if (copiedNode != null) {
        // Create a deep copy of the node with new IDs
        final pastedNode = _deepCopyNode(copiedNode);

        // Add the pasted node as a child of the selected node
        _addNodeAsChild(selectedNodeId!, pastedNode);
      }
      return true;
    }

    // Ctrl/Cmd + Z - Undo
    if (isModifierPressed &&
        !isShiftPressed &&
        key == LogicalKeyboardKey.keyZ) {
      controller.undo();
      return true;
    }

    // Ctrl/Cmd + Shift + Z or Ctrl/Cmd + Y - Redo
    if ((isModifierPressed &&
            isShiftPressed &&
            key == LogicalKeyboardKey.keyZ) ||
        (isModifierPressed && key == LogicalKeyboardKey.keyY)) {
      controller.redo();
      return true;
    }

    // Ctrl/Cmd + Plus/Equals - Zoom in
    if (isModifierPressed &&
        (key == LogicalKeyboardKey.equal ||
            key == LogicalKeyboardKey.add ||
            key == LogicalKeyboardKey.numpadAdd)) {
      final currentScale = controller.zoomPanManager.scale;
      final newScale = (currentScale * 1.2).clamp(
        controller.zoomPanManager.minScale,
        controller.zoomPanManager.maxScale,
      );
      controller.setZoom(newScale, duration: const Duration(milliseconds: 200));
      return true;
    }

    // Ctrl/Cmd + Minus - Zoom out
    if (isModifierPressed &&
        (key == LogicalKeyboardKey.minus ||
            key == LogicalKeyboardKey.numpadSubtract)) {
      final currentScale = controller.zoomPanManager.scale;
      final newScale = (currentScale / 1.2).clamp(
        controller.zoomPanManager.minScale,
        controller.zoomPanManager.maxScale,
      );
      controller.setZoom(newScale, duration: const Duration(milliseconds: 200));
      return true;
    }

    return false;
  }

  /// Find a node in the tree
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

  /// Find the parent of a node in the tree
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

  /// Create a deep copy of a node with new IDs
  ///
  /// This creates a complete copy of the node and all its descendants,
  /// generating new UUIDs for each node to maintain uniqueness.
  NodeData _deepCopyNode(NodeData node) {
    // Recursively copy all children with new IDs
    final List<NodeData> copiedChildren = [];
    for (final child in node.children) {
      copiedChildren.add(_deepCopyNode(child));
    }

    // Create a new node with a new ID but same properties
    // Note: We use NodeData.create to generate a new UUID
    return NodeData.create(
      topic: node.topic,
      style: node.style,
      tags: node.tags,
      icons: node.icons,
      hyperLink: node.hyperLink,
      expanded: node.expanded,
      direction: node.direction,
      image: node.image,
      images: node.images,
      branchColor: node.branchColor,
      note: node.note,
      children: copiedChildren,
    );
  }

  /// Add a node as a child of the specified parent
  ///
  /// This is a helper method for paste functionality that adds a complete
  /// node (with all its properties and children) to the tree.
  void _addNodeAsChild(String parentId, NodeData nodeToAdd) {
    // We need to add the node through the controller's internal methods
    // Since we can't directly manipulate the tree, we'll use a workaround:
    // 1. Add a child node with the topic
    // 2. Update it with all properties
    // 3. Recursively add all children

    controller.addChildNode(parentId, topic: nodeToAdd.topic);

    // Get the newly created node
    final parent = _findNode(controller.getData().nodeData, parentId);
    if (parent != null && parent.children.isNotEmpty) {
      final newChild = parent.children.last;

      // Update with all properties from the pasted node
      final updatedChild = newChild.copyWith(
        style: nodeToAdd.style,
        tags: nodeToAdd.tags,
        icons: nodeToAdd.icons,
        hyperLink: nodeToAdd.hyperLink,
        expanded: nodeToAdd.expanded,
        direction: nodeToAdd.direction,
        image: nodeToAdd.image,
        branchColor: nodeToAdd.branchColor,
        note: nodeToAdd.note,
      );

      controller.updateNode(newChild.id, updatedChild);

      // Recursively add all children
      for (final child in nodeToAdd.children) {
        _addNodeAsChild(newChild.id, child);
      }
    }
  }

  /// Clear clipboard
  void clearClipboard() {
    _copiedNodeId = null;
  }
}
