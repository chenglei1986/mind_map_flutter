import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_controller.dart';

/// Unit tests for circular reference prevention in drag-drop operations
/// 
/// These tests verify that the system prevents invalid drag-drop operations
/// that would create circular references in the tree structure.
void main() {
  group('Circular Reference Prevention - Edge Cases', () {
    late MindMapController controller;
    late MindMapData testData;

    setUp(() {
      // Create a deep tree structure for comprehensive testing:
      //           root
      //          /    \
      //       node1   node2
      //       /  \      \
      //   node3 node4  node5
      //     /            \
      //  node6          node7
      //                   \
      //                  node8
      
      final node6 = NodeData.create(topic: 'Node 6');
      final node3 = NodeData.create(
        topic: 'Node 3',
        children: [node6],
      );
      final node4 = NodeData.create(topic: 'Node 4');
      final node1 = NodeData.create(
        topic: 'Node 1',
        children: [node3, node4],
      );
      
      final node8 = NodeData.create(topic: 'Node 8');
      final node7 = NodeData.create(
        topic: 'Node 7',
        children: [node8],
      );
      final node5 = NodeData.create(
        topic: 'Node 5',
        children: [node7],
      );
      final node2 = NodeData.create(
        topic: 'Node 2',
        children: [node5],
      );
      
      final root = NodeData.create(
        topic: 'Root',
        children: [node1, node2],
      );

      testData = MindMapData(
        nodeData: root,
        theme: MindMapTheme.light,
      );

      controller = MindMapController(initialData: testData);
    });

    tearDown(() {
      controller.dispose();
    });

    test('should prevent moving node to itself', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];

      // Act & Assert
      expect(
        () => controller.moveNode(node1.id, node1.id),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should prevent moving node to its direct child', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node3 = node1.children[0];

      // Act & Assert - Try to move node1 to node3 (its direct child)
      expect(
        () => controller.moveNode(node1.id, node3.id),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should prevent moving node to its grandchild', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node3 = node1.children[0];
      final node6 = node3.children[0];

      // Act & Assert - Try to move node1 to node6 (its grandchild)
      expect(
        () => controller.moveNode(node1.id, node6.id),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should prevent moving node to its deep descendant', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node2 = root.children[1];
      final node5 = node2.children[0];
      final node7 = node5.children[0];
      final node8 = node7.children[0];

      // Act & Assert - Try to move node2 to node8 (its great-grandchild)
      expect(
        () => controller.moveNode(node2.id, node8.id),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should prevent moving parent to any of its descendants in a deep tree', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node3 = node1.children[0];
      final node4 = node1.children[1];
      final node6 = node3.children[0];

      // Act & Assert - Multiple attempts to move node1 to its descendants
      expect(
        () => controller.moveNode(node1.id, node3.id),
        throwsA(isA<InvalidNodeIdException>()),
      );
      
      expect(
        () => controller.moveNode(node1.id, node4.id),
        throwsA(isA<InvalidNodeIdException>()),
      );
      
      expect(
        () => controller.moveNode(node1.id, node6.id),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should allow moving node to sibling (not a circular reference)', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node2 = root.children[1];

      // Act - Move node1 to node2 (sibling, should be allowed)
      controller.moveNode(node1.id, node2.id);

      // Assert - Operation should succeed
      final updatedRoot = controller.getData().nodeData;
      final updatedNode2 = updatedRoot.children[0]; // node2 is now the only child of root
      
      expect(updatedNode2.id, node2.id);
      expect(updatedNode2.children.length, 2); // node5 and node1
      expect(updatedNode2.children.any((c) => c.id == node1.id), true);
    });

    test('should allow moving node to cousin (not a circular reference)', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node3 = node1.children[0];
      final node2 = root.children[1];
      final node5 = node2.children[0];

      // Act - Move node3 to node5 (cousin, should be allowed)
      controller.moveNode(node3.id, node5.id);

      // Assert - Operation should succeed
      final updatedRoot = controller.getData().nodeData;
      final updatedNode1 = updatedRoot.children[0];
      final updatedNode2 = updatedRoot.children[1];
      final updatedNode5 = updatedNode2.children[0];
      
      // node3 should no longer be a child of node1
      expect(updatedNode1.children.any((c) => c.id == node3.id), false);
      
      // node3 should now be a child of node5
      expect(updatedNode5.children.any((c) => c.id == node3.id), true);
    });

    test('should allow moving node to ancestor\'s sibling (not a circular reference)', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node2 = root.children[1];
      final node3 = node1.children[0];
      final node6 = node3.children[0];

      // Act - Move node6 to node2 (ancestor's sibling, should be allowed)
      controller.moveNode(node6.id, node2.id);

      // Assert - Operation should succeed
      final updatedRoot = controller.getData().nodeData;
      final updatedNode1 = updatedRoot.children[0];
      final updatedNode3 = updatedNode1.children[0];
      final updatedNode2 = updatedRoot.children[1];
      
      // node6 should no longer be a child of node3
      expect(updatedNode3.children.any((c) => c.id == node6.id), false);
      
      // node6 should now be a child of node2
      expect(updatedNode2.children.any((c) => c.id == node6.id), true);
    });

    test('should prevent moving root node', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];

      // Act & Assert - Try to move root node
      expect(
        () => controller.moveNode(root.id, node1.id),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should throw exception with descriptive message for circular reference', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node3 = node1.children[0];

      // Act & Assert
      try {
        controller.moveNode(node1.id, node3.id);
        fail('Expected InvalidNodeIdException to be thrown');
      } catch (e) {
        expect(e, isA<InvalidNodeIdException>());
        expect(e.toString(), contains('descendant'));
      }
    });

    test('should maintain tree integrity after failed circular reference attempt', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node3 = node1.children[0];
      final originalData = controller.getData();

      // Act - Try to create circular reference (should fail)
      try {
        controller.moveNode(node1.id, node3.id);
      } catch (e) {
        // Expected to throw
      }

      // Assert - Tree structure should remain unchanged
      final currentData = controller.getData();
      expect(currentData.nodeData.id, originalData.nodeData.id);
      expect(currentData.nodeData.children.length, originalData.nodeData.children.length);
      
      final currentNode1 = currentData.nodeData.children[0];
      final originalNode1 = originalData.nodeData.children[0];
      expect(currentNode1.id, originalNode1.id);
      expect(currentNode1.children.length, originalNode1.children.length);
    });

    test('should prevent circular reference in complex multi-level scenario', () {
      // Arrange - Create a more complex tree
      final deepChild = NodeData.create(topic: 'Deep Child');
      final midChild = NodeData.create(
        topic: 'Mid Child',
        children: [deepChild],
      );
      final topChild = NodeData.create(
        topic: 'Top Child',
        children: [midChild],
      );
      final root = NodeData.create(
        topic: 'Root',
        children: [topChild],
      );

      final data = MindMapData(
        nodeData: root,
        theme: MindMapTheme.light,
      );
      final ctrl = MindMapController(initialData: data);

      // Act & Assert - Try to move topChild to deepChild (3 levels deep)
      expect(
        () => ctrl.moveNode(topChild.id, deepChild.id),
        throwsA(isA<InvalidNodeIdException>()),
      );

      ctrl.dispose();
    });

    test('should allow reordering within same parent (not a circular reference)', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node3 = node1.children[0];
      final node4 = node1.children[1];

      // Act - Reorder node4 before node3 (same parent)
      controller.moveNode(node4.id, node1.id, index: 0);

      // Assert - Operation should succeed
      final updatedRoot = controller.getData().nodeData;
      final updatedNode1 = updatedRoot.children[0];
      
      expect(updatedNode1.children.length, 2);
      expect(updatedNode1.children[0].id, node4.id);
      expect(updatedNode1.children[1].id, node3.id);
    });

    test('should handle edge case: single child trying to move to itself', () {
      // Arrange - Create simple tree with single child
      final child = NodeData.create(topic: 'Child');
      final root = NodeData.create(
        topic: 'Root',
        children: [child],
      );

      final data = MindMapData(
        nodeData: root,
        theme: MindMapTheme.light,
      );
      final ctrl = MindMapController(initialData: data);

      // Act & Assert
      expect(
        () => ctrl.moveNode(child.id, child.id),
        throwsA(isA<InvalidNodeIdException>()),
      );

      ctrl.dispose();
    });

    test('should handle edge case: node with no children cannot have circular reference to non-existent descendants', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node4 = root.children[0].children[1]; // node4 has no children
      final node2 = root.children[1];

      // Act - Move leaf node to another branch (should succeed)
      controller.moveNode(node4.id, node2.id);

      // Assert
      final updatedRoot = controller.getData().nodeData;
      final updatedNode2 = updatedRoot.children[1];
      
      expect(updatedNode2.children.any((c) => c.id == node4.id), true);
    });

    test('should prevent moving node with large subtree to any of its descendants', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0]; // Has children: node3 (with node6), node4
      final node3 = node1.children[0];
      final node6 = node3.children[0];

      // Act & Assert - Try to move node1 (with its entire subtree) to node6
      expect(
        () => controller.moveNode(node1.id, node6.id),
        throwsA(isA<InvalidNodeIdException>()),
      );

      // Verify tree structure is unchanged
      final currentRoot = controller.getData().nodeData;
      final currentNode1 = currentRoot.children[0];
      expect(currentNode1.children.length, 2); // Still has node3 and node4
    });
  });
}
