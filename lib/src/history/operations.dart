import '../models/mind_map_data.dart';
import '../models/node_data.dart';
import '../models/node_style.dart';
import 'operation.dart';

/// Operation for creating a new node
///
/// This operation adds a new node to the mind map tree. It can create:
/// - Child nodes (added as children of a parent)
/// - Sibling nodes (added as siblings of an existing node)
/// - Parent nodes (inserted as parent of an existing node)
///
/// If the parent was collapsed before adding the child, it will be expanded
/// and the old state will be restored on undo.
class CreateNodeOperation implements Operation {
  final String parentId;
  final NodeData newNode;
  final int? insertIndex;
  final bool parentWasCollapsed;

  CreateNodeOperation({
    required this.parentId,
    required this.newNode,
    this.insertIndex,
    this.parentWasCollapsed = false,
  });

  @override
  MindMapData execute(MindMapData currentData) {
    final updatedRoot = _addNodeToParent(
      currentData.nodeData,
      parentId,
      newNode,
      insertIndex,
    );
    return currentData.copyWith(nodeData: updatedRoot);
  }

  @override
  MindMapData undo(MindMapData currentData) {
    var updatedRoot = _removeNodeFromTree(currentData.nodeData, newNode.id);
    // If parent was collapsed before, restore it to collapsed state
    if (parentWasCollapsed) {
      updatedRoot = _setNodeExpanded(updatedRoot, parentId, false);
    }
    return currentData.copyWith(nodeData: updatedRoot);
  }

  NodeData _addNodeToParent(
    NodeData node,
    String targetParentId,
    NodeData nodeToAdd,
    int? index,
  ) {
    if (node.id == targetParentId) {
      // Auto-expand parent if needed
      final nodeToUpdate = node.expanded ? node : node.copyWith(expanded: true);

      // Found the parent, add the child
      if (index != null &&
          index >= 0 &&
          index <= nodeToUpdate.children.length) {
        final newChildren = List<NodeData>.from(nodeToUpdate.children);
        newChildren.insert(index, nodeToAdd);
        return nodeToUpdate.copyWith(children: newChildren);
      } else {
        return nodeToUpdate.addChild(nodeToAdd);
      }
    }

    // Recursively search in children
    final updatedChildren = node.children.map((child) {
      return _addNodeToParent(child, targetParentId, nodeToAdd, index);
    }).toList();

    return node.copyWith(children: updatedChildren);
  }

  NodeData _removeNodeFromTree(NodeData node, String nodeIdToRemove) {
    // Remove from direct children
    final filteredChildren = node.children
        .where((c) => c.id != nodeIdToRemove)
        .toList();

    // Recursively remove from descendants
    final updatedChildren = filteredChildren.map((child) {
      return _removeNodeFromTree(child, nodeIdToRemove);
    }).toList();

    return node.copyWith(children: updatedChildren);
  }

  NodeData _setNodeExpanded(NodeData node, String targetNodeId, bool expanded) {
    if (node.id == targetNodeId) {
      return node.copyWith(expanded: expanded);
    }

    // Recursively search in children
    final updatedChildren = node.children.map((child) {
      return _setNodeExpanded(child, targetNodeId, expanded);
    }).toList();

    return node.copyWith(children: updatedChildren);
  }

  @override
  String get description =>
      'Create node "${newNode.topic}" under parent $parentId';
}

/// Operation for inserting a new parent above an existing node
///
/// This operation replaces a node in its parent's children list with a new
/// parent node that contains the original node as its only child.
///
class InsertParentOperation implements Operation {
  final String nodeId;
  final String oldParentId;
  final int oldIndex;
  final NodeData newParent;

  InsertParentOperation({
    required this.nodeId,
    required this.oldParentId,
    required this.oldIndex,
    required this.newParent,
  });

  @override
  MindMapData execute(MindMapData currentData) {
    final updatedRoot = _replaceChildAtIndex(
      currentData.nodeData,
      oldParentId,
      oldIndex,
      newParent,
    );
    return currentData.copyWith(nodeData: updatedRoot);
  }

  @override
  MindMapData undo(MindMapData currentData) {
    // Restore the original node (the only child of the new parent)
    final originalNode = newParent.children.first;
    final updatedRoot = _replaceChildAtIndex(
      currentData.nodeData,
      oldParentId,
      oldIndex,
      originalNode,
    );
    return currentData.copyWith(nodeData: updatedRoot);
  }

  NodeData _replaceChildAtIndex(
    NodeData node,
    String targetParentId,
    int index,
    NodeData replacement,
  ) {
    if (node.id == targetParentId) {
      final newChildren = List<NodeData>.from(node.children);
      if (index >= 0 && index < newChildren.length) {
        newChildren[index] = replacement;
      }
      return node.copyWith(children: newChildren);
    }

    final updatedChildren = node.children.map((child) {
      return _replaceChildAtIndex(child, targetParentId, index, replacement);
    }).toList();

    return node.copyWith(children: updatedChildren);
  }

  @override
  String get description => 'Insert parent above node $nodeId';
}

/// Operation for deleting a node
///
/// This operation removes a node and all its descendants from the mind map tree.
/// The root node cannot be deleted.
///
class DeleteNodeOperation implements Operation {
  final String nodeId;
  final String parentId;
  final NodeData deletedNode;
  final int originalIndex;

  DeleteNodeOperation({
    required this.nodeId,
    required this.parentId,
    required this.deletedNode,
    required this.originalIndex,
  });

  @override
  MindMapData execute(MindMapData currentData) {
    final updatedRoot = _removeNodeFromTree(currentData.nodeData, nodeId);
    return currentData.copyWith(nodeData: updatedRoot);
  }

  @override
  MindMapData undo(MindMapData currentData) {
    final updatedRoot = _addNodeToParent(
      currentData.nodeData,
      parentId,
      deletedNode,
      originalIndex,
    );
    return currentData.copyWith(nodeData: updatedRoot);
  }

  NodeData _removeNodeFromTree(NodeData node, String nodeIdToRemove) {
    // Remove from direct children
    final filteredChildren = node.children
        .where((c) => c.id != nodeIdToRemove)
        .toList();

    // Recursively remove from descendants
    final updatedChildren = filteredChildren.map((child) {
      return _removeNodeFromTree(child, nodeIdToRemove);
    }).toList();

    return node.copyWith(children: updatedChildren);
  }

  NodeData _addNodeToParent(
    NodeData node,
    String targetParentId,
    NodeData nodeToAdd,
    int index,
  ) {
    if (node.id == targetParentId) {
      // Found the parent, add the child at the original index
      final newChildren = List<NodeData>.from(node.children);
      if (index >= 0 && index <= newChildren.length) {
        newChildren.insert(index, nodeToAdd);
      } else {
        newChildren.add(nodeToAdd);
      }
      return node.copyWith(children: newChildren);
    }

    // Recursively search in children
    final updatedChildren = node.children.map((child) {
      return _addNodeToParent(child, targetParentId, nodeToAdd, index);
    }).toList();

    return node.copyWith(children: updatedChildren);
  }

  @override
  String get description => 'Delete node "${deletedNode.topic}" (ID: $nodeId)';
}

/// Operation for editing a node's content
///
/// This operation updates a node's topic text and potentially other properties.
///
class EditNodeOperation implements Operation {
  final String nodeId;
  final String oldTopic;
  final String newTopic;

  EditNodeOperation({
    required this.nodeId,
    required this.oldTopic,
    required this.newTopic,
  });

  @override
  MindMapData execute(MindMapData currentData) {
    final updatedRoot = _updateNodeTopic(
      currentData.nodeData,
      nodeId,
      newTopic,
    );
    return currentData.copyWith(nodeData: updatedRoot);
  }

  @override
  MindMapData undo(MindMapData currentData) {
    final updatedRoot = _updateNodeTopic(
      currentData.nodeData,
      nodeId,
      oldTopic,
    );
    return currentData.copyWith(nodeData: updatedRoot);
  }

  NodeData _updateNodeTopic(
    NodeData node,
    String targetNodeId,
    String newTopicText,
  ) {
    if (node.id == targetNodeId) {
      return node.copyWith(topic: newTopicText);
    }

    // Recursively search in children
    final updatedChildren = node.children.map((child) {
      return _updateNodeTopic(child, targetNodeId, newTopicText);
    }).toList();

    return node.copyWith(children: updatedChildren);
  }

  @override
  String get description => 'Edit node $nodeId: "$oldTopic" → "$newTopic"';
}

/// Operation for moving a node to a new parent or position
///
/// This operation moves a node from one location in the tree to another.
/// It can move nodes to different parents or reorder siblings.
///
/// If the target parent was collapsed before moving, it will be expanded
/// and the old state will be restored on undo.
class MoveNodeOperation implements Operation {
  final String nodeId;
  final String oldParentId;
  final String newParentId;
  final int oldIndex;
  final int newIndex;
  final NodeData movedNode;
  final bool targetWasCollapsed;

  MoveNodeOperation({
    required this.nodeId,
    required this.oldParentId,
    required this.newParentId,
    required this.oldIndex,
    required this.newIndex,
    required this.movedNode,
    this.targetWasCollapsed = false,
  });

  @override
  MindMapData execute(MindMapData currentData) {
    // First remove the node from its old location
    var updatedRoot = _removeNodeFromTree(currentData.nodeData, nodeId);
    // Auto-expand target if it was collapsed
    if (targetWasCollapsed) {
      updatedRoot = _setNodeExpanded(updatedRoot, newParentId, true);
    }
    // Then add it to the new location
    updatedRoot = _addNodeToParent(
      updatedRoot,
      newParentId,
      movedNode,
      newIndex,
    );
    return currentData.copyWith(nodeData: updatedRoot);
  }

  @override
  MindMapData undo(MindMapData currentData) {
    // Remove from new location
    var updatedRoot = _removeNodeFromTree(currentData.nodeData, nodeId);
    // Add back to old location
    updatedRoot = _addNodeToParent(
      updatedRoot,
      oldParentId,
      movedNode,
      oldIndex,
    );
    // If target was collapsed before, restore it to collapsed state
    if (targetWasCollapsed) {
      updatedRoot = _setNodeExpanded(updatedRoot, newParentId, false);
    }
    return currentData.copyWith(nodeData: updatedRoot);
  }

  NodeData _removeNodeFromTree(NodeData node, String nodeIdToRemove) {
    // Remove from direct children
    final filteredChildren = node.children
        .where((c) => c.id != nodeIdToRemove)
        .toList();

    // Recursively remove from descendants
    final updatedChildren = filteredChildren.map((child) {
      return _removeNodeFromTree(child, nodeIdToRemove);
    }).toList();

    return node.copyWith(children: updatedChildren);
  }

  NodeData _addNodeToParent(
    NodeData node,
    String targetParentId,
    NodeData nodeToAdd,
    int index,
  ) {
    if (node.id == targetParentId) {
      // Found the parent, add the child at the specified index
      final newChildren = List<NodeData>.from(node.children);
      if (index >= 0 && index <= newChildren.length) {
        newChildren.insert(index, nodeToAdd);
      } else {
        newChildren.add(nodeToAdd);
      }
      return node.copyWith(children: newChildren);
    }

    // Recursively search in children
    final updatedChildren = node.children.map((child) {
      return _addNodeToParent(child, targetParentId, nodeToAdd, index);
    }).toList();

    return node.copyWith(children: updatedChildren);
  }

  NodeData _setNodeExpanded(NodeData node, String targetNodeId, bool expanded) {
    if (node.id == targetNodeId) {
      return node.copyWith(expanded: expanded);
    }

    // Recursively search in children
    final updatedChildren = node.children.map((child) {
      return _setNodeExpanded(child, targetNodeId, expanded);
    }).toList();

    return node.copyWith(children: updatedChildren);
  }

  @override
  String get description =>
      'Move node $nodeId from $oldParentId[$oldIndex] to $newParentId[$newIndex]';
}

/// Operation for changing a node's style
///
/// This operation updates a node's visual styling properties such as
/// font size, color, background, etc.
///
class StyleNodeOperation implements Operation {
  final String nodeId;
  final NodeStyle? oldStyle;
  final NodeStyle? newStyle;

  StyleNodeOperation({
    required this.nodeId,
    required this.oldStyle,
    required this.newStyle,
  });

  @override
  MindMapData execute(MindMapData currentData) {
    final updatedRoot = _updateNodeStyle(
      currentData.nodeData,
      nodeId,
      newStyle,
    );
    return currentData.copyWith(nodeData: updatedRoot);
  }

  @override
  MindMapData undo(MindMapData currentData) {
    final updatedRoot = _updateNodeStyle(
      currentData.nodeData,
      nodeId,
      oldStyle,
    );
    return currentData.copyWith(nodeData: updatedRoot);
  }

  NodeData _updateNodeStyle(
    NodeData node,
    String targetNodeId,
    NodeStyle? style,
  ) {
    if (node.id == targetNodeId) {
      // Create a new node with the updated style
      return NodeData(
        id: node.id,
        topic: node.topic,
        style: style,
        children: node.children,
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

    // Recursively search in children
    final updatedChildren = node.children.map((child) {
      return _updateNodeStyle(child, targetNodeId, style);
    }).toList();

    return node.copyWith(children: updatedChildren);
  }

  @override
  String get description => 'Style node $nodeId';
}

/// Operation for toggling a node's expanded state
///
/// This operation changes whether a node's children are visible (expanded)
/// or hidden (collapsed). This is important for undo/redo to work correctly
/// with expand/collapse operations.
class ToggleExpandOperation implements Operation {
  final String nodeId;
  final bool oldExpanded;
  final bool newExpanded;

  ToggleExpandOperation({
    required this.nodeId,
    required this.oldExpanded,
    required this.newExpanded,
  });

  @override
  MindMapData execute(MindMapData currentData) {
    final updatedRoot = _updateNodeExpanded(
      currentData.nodeData,
      nodeId,
      newExpanded,
    );
    return currentData.copyWith(nodeData: updatedRoot);
  }

  @override
  MindMapData undo(MindMapData currentData) {
    final updatedRoot = _updateNodeExpanded(
      currentData.nodeData,
      nodeId,
      oldExpanded,
    );
    return currentData.copyWith(nodeData: updatedRoot);
  }

  NodeData _updateNodeExpanded(
    NodeData node,
    String targetNodeId,
    bool expanded,
  ) {
    if (node.id == targetNodeId) {
      return node.copyWith(expanded: expanded);
    }

    // Recursively search in children
    final updatedChildren = node.children.map((child) {
      return _updateNodeExpanded(child, targetNodeId, expanded);
    }).toList();

    return node.copyWith(children: updatedChildren);
  }

  @override
  String get description =>
      'Toggle expand node $nodeId: $oldExpanded → $newExpanded';
}
