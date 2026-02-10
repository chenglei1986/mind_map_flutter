import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

void main() {
  group('SelectionManager Integration Tests', () {
    late MindMapData testData;
    late MindMapController controller;

    setUp(() {
      testData = MindMapData.empty(rootTopic: '测试根节点');
      controller = MindMapController(initialData: testData);
      
      // Add some child nodes for testing
      controller.addChildNode(testData.nodeData.id, topic: 'Child 1');
      controller.addChildNode(testData.nodeData.id, topic: 'Child 2');
      controller.addChildNode(testData.nodeData.id, topic: 'Child 3');
    });

    tearDown(() {
      controller.dispose();
    });

    test('should access selection manager through controller', () {
      expect(controller.selectionManager, isNotNull);
      expect(controller.getSelectedNodeIds(), isEmpty);
    });

    test('should select node through selection manager', () {
      final rootNode = controller.getData().nodeData;
      final childId = rootNode.children.first.id;

      controller.selectionManager.selectNode(childId);
      expect(controller.getSelectedNodeIds(), [childId]);
      expect(controller.selectionManager.isSelected(childId), isTrue);
    });

    test('should emit selectNodes event when selection changes', () {
      final rootNode = controller.getData().nodeData;
      final childId = rootNode.children.first.id;

      controller.selectionManager.selectNode(childId);
      
      expect(controller.lastEvent, isA<SelectNodesEvent>());
      final event = controller.lastEvent as SelectNodesEvent;
      expect(event.nodeIds, [childId]);
    });

    test('should support multi-selection', () {
      final rootNode = controller.getData().nodeData;
      final child1Id = rootNode.children[0].id;
      final child2Id = rootNode.children[1].id;
      final child3Id = rootNode.children[2].id;

      controller.selectionManager.selectNode(child1Id);
      controller.selectionManager.addToSelection(child2Id);
      controller.selectionManager.addToSelection(child3Id);

      expect(controller.getSelectedNodeIds(), [child1Id, child2Id, child3Id]);
    });

    test('should clear selection when refreshing data', () {
      final rootNode = controller.getData().nodeData;
      final childId = rootNode.children.first.id;

      controller.selectionManager.selectNode(childId);
      expect(controller.getSelectedNodeIds(), [childId]);

      // Refresh data
      final newData = MindMapData.empty(rootTopic: '新根节点');
      controller.refresh(newData);

      expect(controller.getSelectedNodeIds(), isEmpty);
    });

    test('should remove node from selection when node is deleted', () {
      final rootNode = controller.getData().nodeData;
      final childId = rootNode.children.first.id;

      controller.selectionManager.selectNode(childId);
      expect(controller.getSelectedNodeIds(), [childId]);

      // Delete the selected node
      controller.removeNode(childId);

      expect(controller.getSelectedNodeIds(), isEmpty);
    });

    test('should maintain selection of other nodes when one is deleted', () {
      final rootNode = controller.getData().nodeData;
      final child1Id = rootNode.children[0].id;
      final child2Id = rootNode.children[1].id;
      final child3Id = rootNode.children[2].id;

      // Select all three children
      controller.selectionManager.selectNodes([child1Id, child2Id, child3Id]);
      expect(controller.getSelectedNodeIds().length, 3);

      // Delete child2
      controller.removeNode(child2Id);

      // child1 and child3 should still be selected
      expect(controller.getSelectedNodeIds(), [child1Id, child3Id]);
    });

    test('should toggle selection correctly', () {
      final rootNode = controller.getData().nodeData;
      final childId = rootNode.children.first.id;

      // Toggle on
      controller.selectionManager.toggleSelection(childId);
      expect(controller.getSelectedNodeIds(), [childId]);

      // Toggle off
      controller.selectionManager.toggleSelection(childId);
      expect(controller.getSelectedNodeIds(), isEmpty);
    });

    test('should handle batch selection', () {
      final rootNode = controller.getData().nodeData;
      final child1Id = rootNode.children[0].id;
      final child2Id = rootNode.children[1].id;

      controller.selectionManager.selectNodes([child1Id, child2Id]);
      expect(controller.getSelectedNodeIds(), [child1Id, child2Id]);
    });

    test('should provide visual feedback through selectedNodeIds', () {
      final rootNode = controller.getData().nodeData;
      final childId = rootNode.children.first.id;

      // Initially no selection
      expect(controller.getSelectedNodeIds(), isEmpty);

      // Select a node
      controller.selectionManager.selectNode(childId);
      
      // Should be reflected in getSelectedNodeIds for rendering
      expect(controller.getSelectedNodeIds(), [childId]);
    });

    test('should handle selection state across multiple operations', () {
      final rootNode = controller.getData().nodeData;
      final child1Id = rootNode.children[0].id;
      final child2Id = rootNode.children[1].id;

      // Select first child
      controller.selectionManager.selectNode(child1Id);
      expect(controller.getSelectedNodeIds(), [child1Id]);

      // Add second child to selection
      controller.selectionManager.addToSelection(child2Id);
      expect(controller.getSelectedNodeIds(), [child1Id, child2Id]);

      // Remove first child from selection
      controller.selectionManager.removeFromSelection(child1Id);
      expect(controller.getSelectedNodeIds(), [child2Id]);

      // Clear all selection
      controller.selectionManager.clearSelection();
      expect(controller.getSelectedNodeIds(), isEmpty);
    });
  });
}
