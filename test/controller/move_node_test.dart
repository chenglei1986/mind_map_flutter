import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_controller.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_widget.dart';

void main() {
  group('MindMapController - moveNode', () {
    late MindMapController controller;
    late MindMapData testData;

    setUp(() {
      // Create a test tree structure:
      //       root
      //      /    \
      //    node1  node2
      //    /  \
      // node3 node4
      
      final node3 = NodeData.create(topic: 'Node 3');
      final node4 = NodeData.create(topic: 'Node 4');
      final node1 = NodeData.create(
        topic: 'Node 1',
        children: [node3, node4],
      );
      final node2 = NodeData.create(topic: 'Node 2');
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

    test('should move node to a different parent', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node2 = root.children[1];
      final node3 = node1.children[0];

      // Act - Move node3 from node1 to node2
      controller.moveNode(node3.id, node2.id);

      // Assert
      final updatedRoot = controller.getData().nodeData;
      final updatedNode1 = updatedRoot.children[0];
      final updatedNode2 = updatedRoot.children[1];

      // node3 should no longer be a child of node1
      expect(updatedNode1.children.length, 1);
      expect(updatedNode1.children.any((c) => c.id == node3.id), false);

      // node3 should now be a child of node2
      expect(updatedNode2.children.length, 1);
      expect(updatedNode2.children[0].id, node3.id);
      expect(updatedNode2.children[0].topic, 'Node 3');
    });

    test('should emit moveNode event when moving to different parent', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node2 = root.children[1];
      final node3 = node1.children[0];

      // Act
      controller.moveNode(node3.id, node2.id);

      // Assert
      expect(controller.lastEvent, isA<MoveNodeEvent>());
      final event = controller.lastEvent as MoveNodeEvent;
      expect(event.nodeId, node3.id);
      expect(event.oldParentId, node1.id);
      expect(event.newParentId, node2.id);
      expect(event.isReorder, false);
    });

    test('should reorder node among siblings', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node3 = node1.children[0];
      final node4 = node1.children[1];

      // Act - Move node4 to position 0 (before node3)
      controller.moveNode(node4.id, node1.id, index: 0);

      // Assert
      final updatedRoot = controller.getData().nodeData;
      final updatedNode1 = updatedRoot.children[0];

      // node4 should now be first
      expect(updatedNode1.children.length, 2);
      expect(updatedNode1.children[0].id, node4.id);
      expect(updatedNode1.children[1].id, node3.id);
    });

    test('should emit moveNode event with isReorder=true when reordering', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node4 = node1.children[1];

      // Act
      controller.moveNode(node4.id, node1.id, index: 0);

      // Assert
      expect(controller.lastEvent, isA<MoveNodeEvent>());
      final event = controller.lastEvent as MoveNodeEvent;
      expect(event.nodeId, node4.id);
      expect(event.oldParentId, node1.id);
      expect(event.newParentId, node1.id);
      expect(event.isReorder, true);
    });

    test('should add node at end if index is null', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node2 = root.children[1];
      final node3 = node1.children[0];

      // Act - Move node3 to node2 without specifying index
      controller.moveNode(node3.id, node2.id);

      // Assert
      final updatedRoot = controller.getData().nodeData;
      final updatedNode2 = updatedRoot.children[1];

      // node3 should be at the end (position 0 since node2 had no children)
      expect(updatedNode2.children.length, 1);
      expect(updatedNode2.children[0].id, node3.id);
    });

    test('should add node at end if index is out of bounds', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node2 = root.children[1];
      final node3 = node1.children[0];

      // Act - Move node3 to node2 with index beyond bounds
      controller.moveNode(node3.id, node2.id, index: 999);

      // Assert
      final updatedRoot = controller.getData().nodeData;
      final updatedNode2 = updatedRoot.children[1];

      // node3 should be at the end
      expect(updatedNode2.children.length, 1);
      expect(updatedNode2.children[0].id, node3.id);
    });

    test('should throw exception when moving root node', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];

      // Act & Assert
      expect(
        () => controller.moveNode(root.id, node1.id),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should throw exception when moving node to itself', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];

      // Act & Assert
      expect(
        () => controller.moveNode(node1.id, node1.id),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should throw exception when moving node to its descendant (circular reference)', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node3 = node1.children[0];

      // Act & Assert - Try to move node1 to node3 (its own child)
      expect(
        () => controller.moveNode(node1.id, node3.id),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should throw exception when node ID does not exist', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];

      // Act & Assert
      expect(
        () => controller.moveNode('non-existent-id', node1.id),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should throw exception when target parent ID does not exist', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node3 = node1.children[0];

      // Act & Assert
      expect(
        () => controller.moveNode(node3.id, 'non-existent-id'),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should preserve node data when moving', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node2 = root.children[1];
      final node3 = node1.children[0];
      // Act - Move node3 (which has a sibling node4)
      controller.moveNode(node3.id, node2.id);

      // Assert
      final updatedRoot = controller.getData().nodeData;
      final updatedNode2 = updatedRoot.children[1];
      final movedNode = updatedNode2.children[0];

      // All node data should be preserved
      expect(movedNode.id, node3.id);
      expect(movedNode.topic, 'Node 3');
      expect(movedNode.children, isEmpty);
    });

    test('should move node with its entire subtree', () {
      // Arrange
      final root = controller.getData().nodeData;
      final node1 = root.children[0];
      final node2 = root.children[1];

      // Act - Move node1 (which has children node3 and node4) to node2
      controller.moveNode(node1.id, node2.id);

      // Assert
      final updatedRoot = controller.getData().nodeData;
      
      // Root should now only have node2 as a child
      expect(updatedRoot.children.length, 1);
      
      final updatedNode2 = updatedRoot.children[0];
      expect(updatedNode2.id, node2.id);
      
      // node2 should now have node1 as a child
      expect(updatedNode2.children.length, 1);
      final movedNode = updatedNode2.children[0];

      // node1 should be moved with all its children
      expect(movedNode.id, node1.id);
      expect(movedNode.topic, 'Node 1');
      expect(movedNode.children.length, 2);
      expect(movedNode.children[0].topic, 'Node 3');
      expect(movedNode.children[1].topic, 'Node 4');
    });

    test('should handle moving to specific index in middle of siblings', () {
      // Arrange - Create node2 with multiple children
      final child1 = NodeData.create(topic: 'Child 1');
      final child2 = NodeData.create(topic: 'Child 2');
      final child3 = NodeData.create(topic: 'Child 3');
      final node2 = NodeData.create(
        topic: 'Node 2',
        children: [child1, child2, child3],
      );
      final node1 = NodeData.create(topic: 'Node 1');
      final root = NodeData.create(
        topic: 'Root',
        children: [node1, node2],
      );

      final data = MindMapData(
        nodeData: root,
        theme: MindMapTheme.light,
      );
      final ctrl = MindMapController(initialData: data);

      // Act - Move node1 to position 1 in node2's children (between child1 and child2)
      ctrl.moveNode(node1.id, node2.id, index: 1);

      // Assert
      final updatedRoot = ctrl.getData().nodeData;
      final updatedNode2 = updatedRoot.children[0]; // node2 is now the only child of root

      expect(updatedNode2.children.length, 4);
      expect(updatedNode2.children[0].topic, 'Child 1');
      expect(updatedNode2.children[1].topic, 'Node 1'); // Inserted at index 1
      expect(updatedNode2.children[2].topic, 'Child 2');
      expect(updatedNode2.children[3].topic, 'Child 3');

      ctrl.dispose();
    });
  });
}
