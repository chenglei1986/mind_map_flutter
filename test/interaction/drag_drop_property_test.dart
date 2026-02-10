import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';
import '../helpers/generators.dart';

// Feature: mind-map-flutter, Property 12: 拖放树结构更新

void main() {
  group('Drag and Drop Property Tests', () {
    const iterations = 100;

    // For any valid drag-and-drop operation (node to another node or sibling reordering),
    // the tree structure should be correctly updated, and a moveNode event should be emitted
    test('Property 12: Drag-drop tree structure update', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data with guaranteed depth
        final initialData = generateRandomMindMapData(
          maxDepth: 3,
          maxChildren: 4,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Collect all initial node IDs
        final initialIds = collectAllNodeIds(initialData.nodeData);

        // Skip if only root node exists
        if (initialIds.length <= 1) continue;

        // Find a non-root node to move
        final nonRootIds = initialIds.where((id) => id != initialData.nodeData.id).toList();
        if (nonRootIds.isEmpty) continue;

        final nodeToMove = nonRootIds[i % nonRootIds.length];

        // Find the node to move
        final targetNode = _findNode(initialData.nodeData, nodeToMove);
        if (targetNode == null) continue;

        // Find valid drop targets (not self, not descendants, not root)
        final validTargets = initialIds.where((id) {
          // Not the node itself
          if (id == nodeToMove) return false;
          // Not a descendant of the node
          if (_isDescendant(targetNode, id)) return false;
          return true;
        }).toList();

        if (validTargets.isEmpty) continue;

        // Choose a random valid target
        final targetParentId = validTargets[i % validTargets.length];

        // Find current parent before move
        final currentParent = _findParent(initialData.nodeData, nodeToMove);
        if (currentParent == null) continue;

        // Count descendants of node to move
        final descendantIds = collectAllNodeIds(targetNode);

        // Perform the move operation
        controller.moveNode(nodeToMove, targetParentId);

        // Verify tree structure updated correctly
        final afterMove = controller.getData();
        final afterMoveIds = collectAllNodeIds(afterMove.nodeData);

        // 1. Total number of nodes should remain the same (Requirement 5.6)
        expect(afterMoveIds.length, initialIds.length,
            reason: 'Total node count should remain unchanged after move');

        // 2. All original nodes should still exist
        for (final id in initialIds) {
          expect(afterMoveIds.contains(id), true,
              reason: 'Node $id should still exist after move');
        }

        // 3. The moved node should no longer be a child of its old parent
        final oldParentAfterMove = _findNode(afterMove.nodeData, currentParent.id);
        if (oldParentAfterMove != null && currentParent.id != targetParentId) {
          final oldParentChildIds = oldParentAfterMove.children.map((c) => c.id).toList();
          expect(oldParentChildIds.contains(nodeToMove), false,
              reason: 'Node should be removed from old parent');
        }

        // 4. The moved node should now be a child of the new parent (Requirement 5.3)
        final newParentAfterMove = _findNode(afterMove.nodeData, targetParentId);
        expect(newParentAfterMove, isNotNull,
            reason: 'New parent should exist');
        final newParentChildIds = newParentAfterMove!.children.map((c) => c.id).toList();
        expect(newParentChildIds.contains(nodeToMove), true,
            reason: 'Node should be added to new parent');

        // 5. All descendants should move with the node (Requirement 5.6)
        final movedNodeAfter = _findNode(afterMove.nodeData, nodeToMove);
        expect(movedNodeAfter, isNotNull,
            reason: 'Moved node should exist');
        final movedNodeDescendants = collectAllNodeIds(movedNodeAfter!);
        expect(movedNodeDescendants, descendantIds,
            reason: 'All descendants should move with the node');

        // 6. moveNode event should be emitted (Requirement 5.7)
        expect(controller.lastEvent, isA<MoveNodeEvent>(),
            reason: 'moveNode event should be emitted');
        final event = controller.lastEvent as MoveNodeEvent;
        expect(event.nodeId, nodeToMove,
            reason: 'Event should contain correct node ID');
        expect(event.oldParentId, currentParent.id,
            reason: 'Event should contain correct old parent ID');
        expect(event.newParentId, targetParentId,
            reason: 'Event should contain correct new parent ID');

        // 7. isReorder flag should be correct (Requirement 5.4)
        final isReorder = currentParent.id == targetParentId;
        expect(event.isReorder, isReorder,
            reason: 'isReorder flag should be ${isReorder}');

        controller.dispose();
      }
    });

    // Additional property test: Sibling reordering maintains tree structure
    test('Property 12 (Extended): Sibling reordering maintains structure', () {
      for (int i = 0; i < iterations; i++) {
        // Generate data with guaranteed siblings
        final child1 = NodeData.create(topic: 'Child 1');
        final child2 = NodeData.create(topic: 'Child 2');
        final child3 = NodeData.create(topic: 'Child 3');
        final root = NodeData.create(
          topic: 'Root',
          children: [child1, child2, child3],
        );

        final initialData = MindMapData(
          nodeData: root,
          theme: MindMapTheme.light,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Reorder siblings - move child3 to position 0
        controller.moveNode(child3.id, root.id, index: 0);

        // Verify tree structure
        final afterMove = controller.getData();
        final rootAfterMove = afterMove.nodeData;

        // 1. Should still have 3 children (Requirement 5.4)
        expect(rootAfterMove.children.length, 3,
            reason: 'Should maintain same number of children');

        // 2. Order should be updated
        expect(rootAfterMove.children[0].id, child3.id,
            reason: 'Child 3 should be at position 0');
        expect(rootAfterMove.children[1].id, child1.id,
            reason: 'Child 1 should be at position 1');
        expect(rootAfterMove.children[2].id, child2.id,
            reason: 'Child 2 should be at position 2');

        // 3. moveNode event should be emitted with isReorder=true (Requirement 5.7)
        expect(controller.lastEvent, isA<MoveNodeEvent>());
        final event = controller.lastEvent as MoveNodeEvent;
        expect(event.isReorder, true,
            reason: 'isReorder should be true for sibling reordering');
        expect(event.oldParentId, root.id);
        expect(event.newParentId, root.id);

        controller.dispose();
      }
    });

    // Property test: Node data is preserved during move
    test('Property 12 (Extended): Node data preserved during move', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 3,
          maxChildren: 3,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Collect all initial node IDs
        final initialIds = collectAllNodeIds(initialData.nodeData);

        // Skip if only root node exists
        if (initialIds.length <= 2) continue;

        // Find a non-root node to move
        final nonRootIds = initialIds.where((id) => id != initialData.nodeData.id).toList();
        if (nonRootIds.isEmpty) continue;

        final nodeToMove = nonRootIds[i % nonRootIds.length];

        // Find the node to move and capture its data
        final targetNode = _findNode(initialData.nodeData, nodeToMove);
        if (targetNode == null) continue;

        // Capture node properties before move
        final originalTopic = targetNode.topic;
        final originalTags = targetNode.tags;
        final originalIcons = targetNode.icons;
        final originalBranchColor = targetNode.branchColor;
        final originalExpanded = targetNode.expanded;
        final originalChildrenCount = targetNode.children.length;

        // Find valid drop targets
        final validTargets = initialIds.where((id) {
          if (id == nodeToMove) return false;
          if (_isDescendant(targetNode, id)) return false;
          return true;
        }).toList();

        if (validTargets.isEmpty) continue;

        // Choose a random valid target
        final targetParentId = validTargets[i % validTargets.length];

        // Perform the move operation
        controller.moveNode(nodeToMove, targetParentId);

        // Find the moved node
        final afterMove = controller.getData();
        final movedNode = _findNode(afterMove.nodeData, nodeToMove);
        expect(movedNode, isNotNull);

        // Verify all node properties are preserved (Requirement 5.6)
        expect(movedNode!.topic, originalTopic,
            reason: 'Topic should be preserved');
        expect(movedNode.tags, originalTags,
            reason: 'Tags should be preserved');
        expect(movedNode.icons, originalIcons,
            reason: 'Icons should be preserved');
        expect(movedNode.branchColor, originalBranchColor,
            reason: 'Branch color should be preserved');
        expect(movedNode.expanded, originalExpanded,
            reason: 'Expanded state should be preserved');
        expect(movedNode.children.length, originalChildrenCount,
            reason: 'Children count should be preserved');

        controller.dispose();
      }
    });

    // Property test: Move to specific index positions
    test('Property 12 (Extended): Move to specific index maintains order', () {
      for (int i = 0; i < iterations; i++) {
        // Create a parent with multiple children
        final children = List.generate(
          5,
          (index) => NodeData.create(topic: 'Child $index'),
        );
        final parent = NodeData.create(
          topic: 'Parent',
          children: children,
        );
        final nodeToMove = NodeData.create(topic: 'Moving Node');
        final root = NodeData.create(
          topic: 'Root',
          children: [parent, nodeToMove],
        );

        final initialData = MindMapData(
          nodeData: root,
          theme: MindMapTheme.light,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Move node to a specific index (0 to 5)
        final targetIndex = i % 6;
        controller.moveNode(nodeToMove.id, parent.id, index: targetIndex);

        // Verify the node is at the correct position (Requirement 5.4)
        final afterMove = controller.getData();
        final parentAfterMove = _findNode(afterMove.nodeData, parent.id);
        expect(parentAfterMove, isNotNull);

        // Should have 6 children now (5 original + 1 moved)
        expect(parentAfterMove!.children.length, 6,
            reason: 'Should have 6 children after move');

        // The moved node should be at the target index
        expect(parentAfterMove.children[targetIndex].id, nodeToMove.id,
            reason: 'Moved node should be at index $targetIndex');

        // moveNode event should be emitted (Requirement 5.7)
        expect(controller.lastEvent, isA<MoveNodeEvent>());

        controller.dispose();
      }
    });
  });
}

// Helper functions

NodeData? _findNode(NodeData node, String nodeId) {
  if (node.id == nodeId) return node;
  for (final child in node.children) {
    final found = _findNode(child, nodeId);
    if (found != null) return found;
  }
  return null;
}

NodeData? _findParent(NodeData node, String childId) {
  for (final child in node.children) {
    if (child.id == childId) return node;
  }
  for (final child in node.children) {
    final parent = _findParent(child, childId);
    if (parent != null) return parent;
  }
  return null;
}

bool _isDescendant(NodeData ancestor, String nodeId) {
  if (ancestor.id == nodeId) return true;
  for (final child in ancestor.children) {
    if (_isDescendant(child, nodeId)) return true;
  }
  return false;
}
