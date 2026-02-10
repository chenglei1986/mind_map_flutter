import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';
import '../helpers/generators.dart';

// Feature: mind-map-flutter, Property 10: 节点创建树结构完整性
// Feature: mind-map-flutter, Property 11: 节点删除级联

void main() {
  group('Controller Property Tests', () {
    // Property 10: 节点创建树结构完整性
    // For any node, adding a child, sibling, or parent should correctly update
    // the tree structure, new nodes should have unique IDs and default topics,
    // and operation events should be emitted
    test('Property 10: Node creation maintains tree structure integrity', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 3,
        );
        
        final controller = MindMapController(
          initialData: initialData,
        );
        
        // Collect all initial node IDs
        final initialIds = collectAllNodeIds(initialData.nodeData);
        
        // Test adding child node
        final parentId = initialIds.elementAt(i % initialIds.length);
        controller.addChildNode(parentId, topic: 'Node $i');
        
        // Verify tree structure updated
        final afterChildAdd = controller.getData();
        final afterChildIds = collectAllNodeIds(afterChildAdd.nodeData);
        
        // Should have one more node
        expect(afterChildIds.length, initialIds.length + 1);
        
        // New node should have unique ID
        final newChildIds = afterChildIds.difference(initialIds);
        expect(newChildIds.length, 1);
        
        // Event should be emitted
        expect(controller.lastEvent, isA<NodeOperationEvent>());
        expect((controller.lastEvent as NodeOperationEvent).operation, 'addChild');
        
        // Test adding sibling node (if not root)
        if (parentId != initialData.nodeData.id) {
          final beforeSiblingIds = collectAllNodeIds(controller.getData().nodeData);
          controller.addSiblingNode(parentId, topic: 'Sibling $i');
          
          final afterSiblingAdd = controller.getData();
          final afterSiblingIds = collectAllNodeIds(afterSiblingAdd.nodeData);
          
          // Should have one more node
          expect(afterSiblingIds.length, beforeSiblingIds.length + 1);
          
          // New node should have unique ID
          final newSiblingIds = afterSiblingIds.difference(beforeSiblingIds);
          expect(newSiblingIds.length, 1);
          
          // Event should be emitted
          expect(controller.lastEvent, isA<NodeOperationEvent>());
          expect((controller.lastEvent as NodeOperationEvent).operation, 'addSibling');
        }
      }
    });
    
    // Property 11: 节点删除级联
    // For any non-root node, deleting that node should also delete all its
    // descendants, and an operation event should be emitted
    test('Property 11: Node deletion cascades to descendants', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data with guaranteed depth
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
        if (initialIds.length <= 1) continue;
        
        // Find a non-root node to delete
        final nonRootIds = initialIds.where((id) => id != initialData.nodeData.id).toList();
        if (nonRootIds.isEmpty) continue;
        
        final nodeToDelete = nonRootIds[i % nonRootIds.length];
        
        // Find the node and count its descendants
        NodeData? findNode(NodeData node, String targetId) {
          if (node.id == targetId) return node;
          for (final child in node.children) {
            final found = findNode(child, targetId);
            if (found != null) return found;
          }
          return null;
        }
        
        final targetNode = findNode(initialData.nodeData, nodeToDelete);
        if (targetNode == null) continue;
        
        final descendantIds = collectAllNodeIds(targetNode);
        
        // Delete the node
        controller.removeNode(nodeToDelete);
        
        // Verify all descendants were removed
        final afterDelete = controller.getData();
        final afterDeleteIds = collectAllNodeIds(afterDelete.nodeData);
        
        // All descendants should be removed
        for (final descendantId in descendantIds) {
          expect(afterDeleteIds.contains(descendantId), false,
              reason: 'Descendant $descendantId should be removed');
        }
        
        // Total count should decrease by number of descendants
        expect(afterDeleteIds.length, initialIds.length - descendantIds.length);
        
        // Event should be emitted
        expect(controller.lastEvent, isA<NodeOperationEvent>());
        expect((controller.lastEvent as NodeOperationEvent).operation, 'removeNode');
        expect((controller.lastEvent as NodeOperationEvent).nodeId, nodeToDelete);
      }
    });
  });
}
