import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

/// Unit tests for undo/redo functionality when disabled
/// 
/// These tests verify the edge case where undo functionality is disabled
/// through the allowUndo configuration option.
void main() {
  group('Undo Disabled Edge Cases', () {
    late MindMapData testData;
    
    setUp(() {
      // Create test data with a simple tree structure
      final rootNode = NodeData.create(topic: 'Root');
      testData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
    });
    
    test('should not record operations when allowUndo is false', () {
      // Create controller with undo disabled
      final controller = MindMapController(
        initialData: testData,
        config: const MindMapConfig(allowUndo: false),
      );
      
      // Verify initial state
      expect(controller.canUndo(), false,
          reason: 'Initially there should be no operations to undo');
      expect(controller.canRedo(), false,
          reason: 'Initially there should be no operations to redo');
      
      // Perform a create operation
      controller.addChildNode(testData.nodeData.id, topic: 'Child 1');
      
      // Verify operation was NOT recorded
      expect(controller.canUndo(), false,
          reason: 'Operations should not be recorded when allowUndo is false');
      expect(controller.canRedo(), false,
          reason: 'Redo should not be available when allowUndo is false');
      
      // Verify the operation was still executed (data changed)
      final currentData = controller.getData();
      expect(currentData.nodeData.children.length, 1,
          reason: 'Operation should still be executed even when undo is disabled');
      expect(currentData.nodeData.children.first.topic, 'Child 1',
          reason: 'Created node should have correct topic');
      
      controller.dispose();
    });
    
    test('should not record edit operations when allowUndo is false', () {
      // Create controller with undo disabled
      final controller = MindMapController(
        initialData: testData,
        config: const MindMapConfig(allowUndo: false),
      );
      
      // Add a child node (without recording)
      controller.addChildNode(testData.nodeData.id, topic: 'Original Topic');
      final childId = controller.getData().nodeData.children.first.id;
      
      // Edit the node
      controller.updateNodeTopic(childId, 'Edited Topic');
      
      // Verify edit operation was NOT recorded
      expect(controller.canUndo(), false,
          reason: 'Edit operations should not be recorded when allowUndo is false');
      
      // Verify the edit was still applied
      final currentData = controller.getData();
      expect(currentData.nodeData.children.first.topic, 'Edited Topic',
          reason: 'Edit should still be applied even when undo is disabled');
      
      controller.dispose();
    });
    
    test('should not record delete operations when allowUndo is false', () {
      // Create controller with undo disabled
      final controller = MindMapController(
        initialData: testData,
        config: const MindMapConfig(allowUndo: false),
      );
      
      // Add two child nodes
      controller.addChildNode(testData.nodeData.id, topic: 'Child 1');
      controller.addChildNode(testData.nodeData.id, topic: 'Child 2');
      
      final childId = controller.getData().nodeData.children.first.id;
      
      // Delete one child
      controller.removeNode(childId);
      
      // Verify delete operation was NOT recorded
      expect(controller.canUndo(), false,
          reason: 'Delete operations should not be recorded when allowUndo is false');
      
      // Verify the deletion was still applied
      final currentData = controller.getData();
      expect(currentData.nodeData.children.length, 1,
          reason: 'Deletion should still be applied even when undo is disabled');
      
      controller.dispose();
    });
    
    test('should not record move operations when allowUndo is false', () {
      // Create a more complex tree structure
      final rootNode = NodeData.create(topic: 'Root');
      final child1 = NodeData.create(topic: 'Child 1');
      final child2 = NodeData.create(topic: 'Child 2');
      final grandchild = NodeData.create(topic: 'Grandchild');
      
      final rootWithChildren = rootNode.copyWith(children: [
        child1.copyWith(children: [grandchild]),
        child2,
      ]);
      
      final complexData = MindMapData(
        nodeData: rootWithChildren,
        theme: MindMapTheme.light,
      );
      
      // Create controller with undo disabled
      final controller = MindMapController(
        initialData: complexData,
        config: const MindMapConfig(allowUndo: false),
      );
      
      // Move grandchild from child1 to child2
      controller.moveNode(grandchild.id, child2.id);
      
      // Verify move operation was NOT recorded
      expect(controller.canUndo(), false,
          reason: 'Move operations should not be recorded when allowUndo is false');
      
      // Verify the move was still applied
      final currentData = controller.getData();
      final updatedChild1 = currentData.nodeData.children.firstWhere((c) => c.id == child1.id);
      final updatedChild2 = currentData.nodeData.children.firstWhere((c) => c.id == child2.id);
      
      expect(updatedChild1.children.length, 0,
          reason: 'Grandchild should be removed from child1');
      expect(updatedChild2.children.length, 1,
          reason: 'Grandchild should be added to child2');
      expect(updatedChild2.children.first.id, grandchild.id,
          reason: 'Moved node should be the grandchild');
      
      controller.dispose();
    });
    
    test('undo() should return false when allowUndo is false', () {
      // Create controller with undo disabled
      final controller = MindMapController(
        initialData: testData,
        config: const MindMapConfig(allowUndo: false),
      );
      
      // Perform an operation
      controller.addChildNode(testData.nodeData.id, topic: 'Child');
      
      // Try to undo
      final undoResult = controller.undo();
      
      // Verify undo returns false
      expect(undoResult, false,
          reason: 'undo() should return false when allowUndo is false');
      
      // Verify data is unchanged (operation was not undone)
      final currentData = controller.getData();
      expect(currentData.nodeData.children.length, 1,
          reason: 'Data should remain unchanged when undo is disabled');
      
      controller.dispose();
    });
    
    test('redo() should return false when allowUndo is false', () {
      // Create controller with undo disabled
      final controller = MindMapController(
        initialData: testData,
        config: const MindMapConfig(allowUndo: false),
      );
      
      // Try to redo (without any prior operations)
      final redoResult = controller.redo();
      
      // Verify redo returns false
      expect(redoResult, false,
          reason: 'redo() should return false when allowUndo is false');
      
      controller.dispose();
    });
    
    test('canUndo() should always return false when allowUndo is false', () {
      // Create controller with undo disabled
      final controller = MindMapController(
        initialData: testData,
        config: const MindMapConfig(allowUndo: false),
      );
      
      // Verify canUndo is false initially
      expect(controller.canUndo(), false,
          reason: 'canUndo() should return false when allowUndo is false');
      
      // Perform multiple operations
      controller.addChildNode(testData.nodeData.id, topic: 'Child 1');
      controller.addChildNode(testData.nodeData.id, topic: 'Child 2');
      controller.addChildNode(testData.nodeData.id, topic: 'Child 3');
      
      // Verify canUndo is still false
      expect(controller.canUndo(), false,
          reason: 'canUndo() should remain false after operations when allowUndo is false');
      
      controller.dispose();
    });
    
    test('canRedo() should always return false when allowUndo is false', () {
      // Create controller with undo disabled
      final controller = MindMapController(
        initialData: testData,
        config: const MindMapConfig(allowUndo: false),
      );
      
      // Verify canRedo is false initially
      expect(controller.canRedo(), false,
          reason: 'canRedo() should return false when allowUndo is false');
      
      // Perform operations
      controller.addChildNode(testData.nodeData.id, topic: 'Child');
      
      // Verify canRedo is still false
      expect(controller.canRedo(), false,
          reason: 'canRedo() should remain false after operations when allowUndo is false');
      
      controller.dispose();
    });
    
    test('should handle multiple operation types when allowUndo is false', () {
      // Create controller with undo disabled
      final controller = MindMapController(
        initialData: testData,
        config: const MindMapConfig(allowUndo: false),
      );
      
      // Perform a sequence of different operations
      controller.addChildNode(testData.nodeData.id, topic: 'Child 1');
      final child1Id = controller.getData().nodeData.children.first.id;
      
      controller.addSiblingNode(child1Id, topic: 'Child 2');
      
      controller.updateNodeTopic(child1Id, 'Modified Child 1');
      
      controller.addChildNode(child1Id, topic: 'Grandchild');
      
      // Verify no operations were recorded
      expect(controller.canUndo(), false,
          reason: 'No operations should be recorded when allowUndo is false');
      expect(controller.canRedo(), false,
          reason: 'No redo should be available when allowUndo is false');
      
      // Verify all operations were executed
      final currentData = controller.getData();
      expect(currentData.nodeData.children.length, 2,
          reason: 'Both children should be created');
      
      final modifiedChild = currentData.nodeData.children.firstWhere((c) => c.id == child1Id);
      expect(modifiedChild.topic, 'Modified Child 1',
          reason: 'Child topic should be modified');
      expect(modifiedChild.children.length, 1,
          reason: 'Grandchild should be created');
      
      controller.dispose();
    });
    
    test('should not affect history manager when allowUndo is false', () {
      // Create controller with undo disabled
      final controller = MindMapController(
        initialData: testData,
        config: const MindMapConfig(allowUndo: false),
      );
      
      // Perform operations
      for (int i = 0; i < 10; i++) {
        controller.addChildNode(testData.nodeData.id, topic: 'Child $i');
      }
      
      // Verify no operations were recorded (history manager should be empty)
      expect(controller.canUndo(), false,
          reason: 'History manager should remain empty when allowUndo is false');
      
      // Verify all operations were executed
      final currentData = controller.getData();
      expect(currentData.nodeData.children.length, 10,
          reason: 'All operations should be executed');
      
      controller.dispose();
    });
    
    test('should work correctly when switching from enabled to disabled', () {
      // Create controller with undo enabled
      final controller = MindMapController(
        initialData: testData,
        config: const MindMapConfig(allowUndo: true),
      );
      
      // Perform operation with undo enabled
      controller.addChildNode(testData.nodeData.id, topic: 'Child 1');
      
      // Verify operation was recorded
      expect(controller.canUndo(), true,
          reason: 'Operation should be recorded when allowUndo is true');
      
      // Update config to disable undo
      controller.updateConfig(const MindMapConfig(allowUndo: false));
      
      // Verify canUndo now returns false (even though history exists)
      expect(controller.canUndo(), false,
          reason: 'canUndo() should return false after disabling undo');
      
      // Perform another operation
      controller.addChildNode(testData.nodeData.id, topic: 'Child 2');
      
      // Verify still cannot undo
      expect(controller.canUndo(), false,
          reason: 'Should not be able to undo when allowUndo is false');
      
      // Verify both operations were executed
      final currentData = controller.getData();
      expect(currentData.nodeData.children.length, 2,
          reason: 'Both operations should be executed');
      
      controller.dispose();
    });
    
    test('should work correctly when switching from disabled to enabled', () {
      // Create controller with undo disabled
      final controller = MindMapController(
        initialData: testData,
        config: const MindMapConfig(allowUndo: false),
      );
      
      // Perform operation with undo disabled
      controller.addChildNode(testData.nodeData.id, topic: 'Child 1');
      
      // Verify operation was NOT recorded
      expect(controller.canUndo(), false,
          reason: 'Operation should not be recorded when allowUndo is false');
      
      // Update config to enable undo
      controller.updateConfig(const MindMapConfig(allowUndo: true));
      
      // Perform another operation
      controller.addChildNode(testData.nodeData.id, topic: 'Child 2');
      
      // Verify new operation IS recorded
      expect(controller.canUndo(), true,
          reason: 'New operation should be recorded after enabling undo');
      
      // Undo the second operation
      controller.undo();
      
      // Verify only the second operation was undone
      final currentData = controller.getData();
      expect(currentData.nodeData.children.length, 1,
          reason: 'Only the second operation should be undone');
      expect(currentData.nodeData.children.first.topic, 'Child 1',
          reason: 'First child (created when undo was disabled) should remain');
      
      controller.dispose();
    });
  });
}
