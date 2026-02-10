import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_controller.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';

void main() {
  group('Focus Mode Tests', () {
    late MindMapController controller;
    late MindMapData testData;

    setUp(() {
      // Create test data with a tree structure
      final child1 = NodeData.create(topic: 'Child 1');
      final child2 = NodeData.create(topic: 'Child 2');
      final grandchild1 = NodeData.create(topic: 'Grandchild 1');
      final grandchild2 = NodeData.create(topic: 'Grandchild 2');
      
      final child1WithGrandchildren = child1.copyWith(
        children: [grandchild1, grandchild2],
      );
      
      final rootNode = NodeData.create(
        topic: 'Root',
        children: [child1WithGrandchildren, child2],
      );

      testData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );

      controller = MindMapController(initialData: testData);
    });

    test('focusNode should activate focus mode', () {
      final child1 = testData.nodeData.children.first;
      
      expect(controller.isFocusMode, false);
      expect(controller.focusedNodeId, null);
      
      controller.focusNode(child1.id);
      
      expect(controller.isFocusMode, true);
      expect(controller.focusedNodeId, child1.id);
    });

    test('focusNode should clear selection', () {
      final child1 = testData.nodeData.children.first;
      final child2 = testData.nodeData.children[1];
      
      // Select a node first
      controller.selectionManager.selectNode(child2.id);
      expect(controller.getSelectedNodeIds(), [child2.id]);
      
      // Enter focus mode
      controller.focusNode(child1.id);
      
      // Selection should be cleared
      expect(controller.getSelectedNodeIds(), isEmpty);
    });

    test('exitFocusMode should restore full view', () {
      final child1 = testData.nodeData.children.first;
      
      // Enter focus mode
      controller.focusNode(child1.id);
      expect(controller.isFocusMode, true);
      
      // Exit focus mode
      controller.exitFocusMode();
      
      expect(controller.isFocusMode, false);
      expect(controller.focusedNodeId, null);
    });

    test('focusNode should throw InvalidNodeIdException for non-existent node', () {
      expect(
        () => controller.focusNode('non-existent-id'),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('focus mode should notify listeners', () {
      final child1 = testData.nodeData.children.first;
      int notificationCount = 0;
      
      controller.addListener(() {
        notificationCount++;
      });
      
      // Enter focus mode
      controller.focusNode(child1.id);
      expect(notificationCount, 1);
      
      // Exit focus mode
      controller.exitFocusMode();
      expect(notificationCount, 2);
    });

    test('can enter focus mode on root node', () {
      // Should be able to focus on root node
      controller.focusNode(testData.nodeData.id);
      
      expect(controller.isFocusMode, true);
      expect(controller.focusedNodeId, testData.nodeData.id);
    });

    test('can enter focus mode on leaf node', () {
      // Should be able to focus on a leaf node (node with no children)
      final child2 = testData.nodeData.children[1];
      
      controller.focusNode(child2.id);
      
      expect(controller.isFocusMode, true);
      expect(controller.focusedNodeId, child2.id);
    });

    test('can switch focus from one node to another', () {
      final child1 = testData.nodeData.children.first;
      final child2 = testData.nodeData.children[1];
      
      // Focus on first child
      controller.focusNode(child1.id);
      expect(controller.focusedNodeId, child1.id);
      
      // Switch focus to second child
      controller.focusNode(child2.id);
      expect(controller.focusedNodeId, child2.id);
      expect(controller.isFocusMode, true);
    });
  });
}
