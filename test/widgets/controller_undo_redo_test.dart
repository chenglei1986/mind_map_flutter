import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_controller.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_config.dart';

void main() {
  group('MindMapController Undo/Redo Integration', () {
    late MindMapController controller;
    late MindMapData testData;

    setUp(() {
      testData = MindMapData(
        nodeData: NodeData.create(
          id: 'root',
          topic: 'Root',
          children: [
            NodeData.create(id: 'child1', topic: 'Child 1'),
            NodeData.create(id: 'child2', topic: 'Child 2'),
          ],
        ),
        theme: MindMapTheme.light,
      );
      controller = MindMapController(
        initialData: testData,
        config: const MindMapConfig(allowUndo: true),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('canUndo and canRedo should return false initially', () {
      expect(controller.canUndo(), false);
      expect(controller.canRedo(), false);
    });

    test('should record and undo addChildNode operation', () {
      // Add a child node
      controller.addChildNode('root', topic: 'New Child');
      
      // Should have 3 children now
      expect(controller.getData().nodeData.children.length, 3);
      expect(controller.canUndo(), true);
      expect(controller.canRedo(), false);
      
      // Undo the operation
      final undone = controller.undo();
      expect(undone, true);
      
      // Should be back to 2 children
      expect(controller.getData().nodeData.children.length, 2);
      expect(controller.canUndo(), false);
      expect(controller.canRedo(), true);
    });

    test('should record and undo addSiblingNode operation', () {
      // Add a sibling node
      controller.addSiblingNode('child1', topic: 'Sibling');
      
      // Should have 3 children now
      expect(controller.getData().nodeData.children.length, 3);
      expect(controller.canUndo(), true);
      
      // Undo the operation
      controller.undo();
      
      // Should be back to 2 children
      expect(controller.getData().nodeData.children.length, 2);
      expect(controller.canUndo(), false);
    });

    test('should record and undo removeNode operation', () {
      // Remove a child node
      controller.removeNode('child1');
      
      // Should have 1 child now
      expect(controller.getData().nodeData.children.length, 1);
      expect(controller.getData().nodeData.children[0].id, 'child2');
      expect(controller.canUndo(), true);
      
      // Undo the operation
      controller.undo();
      
      // Should be back to 2 children
      expect(controller.getData().nodeData.children.length, 2);
      expect(controller.getData().nodeData.children[0].id, 'child1');
    });

    test('should record and undo updateNodeTopic operation', () {
      // Update node topic
      controller.updateNodeTopic('child1', 'Updated Child 1');
      
      // Topic should be updated
      expect(controller.getData().nodeData.children[0].topic, 'Updated Child 1');
      expect(controller.canUndo(), true);
      
      // Undo the operation
      controller.undo();
      
      // Topic should be reverted
      expect(controller.getData().nodeData.children[0].topic, 'Child 1');
    });

    test('should record and undo moveNode operation', () {
      // Add a third child to move
      controller.addChildNode('root', topic: 'Child 3');
      
      // Move child1 to be a child of child2
      controller.moveNode('child1', 'child2');
      
      // child1 should now be a child of child2
      final child2 = controller.getData().nodeData.children
          .firstWhere((c) => c.id == 'child2');
      expect(child2.children.length, 1);
      expect(child2.children[0].id, 'child1');
      
      // Undo the move
      controller.undo();
      
      // child1 should be back as a direct child of root
      expect(controller.getData().nodeData.children.length, 3);
      expect(controller.getData().nodeData.children[0].id, 'child1');
    });

    test('should support redo after undo', () {
      // Add a child node
      controller.addChildNode('root', topic: 'New Child');
      expect(controller.getData().nodeData.children.length, 3);
      
      // Undo
      controller.undo();
      expect(controller.getData().nodeData.children.length, 2);
      expect(controller.canRedo(), true);
      
      // Redo
      final redone = controller.redo();
      expect(redone, true);
      expect(controller.getData().nodeData.children.length, 3);
      expect(controller.canRedo(), false);
    });
    
    test('undo/redo should restore selection after addChildNode', () {
      controller.selectionManager.selectNode('child1');
      
      // Add child without topic to trigger auto-select
      controller.addChildNode('child1');
      final addedChildId = controller.getData().nodeData.children
          .firstWhere((c) => c.id == 'child1')
          .children
          .first
          .id;
      
      expect(controller.getSelectedNodeIds(), [addedChildId]);
      
      // Undo should restore previous selection
      controller.undo();
      expect(controller.getSelectedNodeIds(), ['child1']);
      
      // Redo should restore selection to new child
      controller.redo();
      expect(controller.getSelectedNodeIds(), [addedChildId]);
    });
    
    test('undo/redo should restore selection after removeNode', () {
      controller.selectionManager.selectNode('child1');
      
      controller.removeNode('child1');
      expect(controller.getSelectedNodeIds(), isEmpty);
      
      controller.undo();
      expect(controller.getSelectedNodeIds(), ['child1']);
      
      controller.redo();
      expect(controller.getSelectedNodeIds(), isEmpty);
    });

    test('should clear redo history when new operation is performed after undo', () {
      // Add a child node
      controller.addChildNode('root', topic: 'Child 3');
      
      // Undo
      controller.undo();
      expect(controller.canRedo(), true);
      
      // Perform a new operation
      controller.addChildNode('root', topic: 'Child 4');
      
      // Redo should no longer be available
      expect(controller.canRedo(), false);
    });

    test('should support multiple undo/redo operations', () {
      // Perform multiple operations
      controller.addChildNode('root', topic: 'Child 3');
      controller.addChildNode('root', topic: 'Child 4');
      controller.updateNodeTopic('child1', 'Updated Child 1');
      
      expect(controller.getData().nodeData.children.length, 4);
      
      // Undo all operations
      controller.undo(); // Undo topic update
      expect(controller.getData().nodeData.children[0].topic, 'Child 1');
      
      controller.undo(); // Undo Child 4
      expect(controller.getData().nodeData.children.length, 3);
      
      controller.undo(); // Undo Child 3
      expect(controller.getData().nodeData.children.length, 2);
      
      expect(controller.canUndo(), false);
      expect(controller.canRedo(), true);
      
      // Redo all operations
      controller.redo(); // Redo Child 3
      expect(controller.getData().nodeData.children.length, 3);
      
      controller.redo(); // Redo Child 4
      expect(controller.getData().nodeData.children.length, 4);
      
      controller.redo(); // Redo topic update
      expect(controller.getData().nodeData.children[0].topic, 'Updated Child 1');
      
      expect(controller.canRedo(), false);
    });

    test('should not record operations when allowUndo is false', () {
      final noUndoController = MindMapController(
        initialData: testData,
        config: const MindMapConfig(allowUndo: false),
      );
      
      // Add a child node
      noUndoController.addChildNode('root', topic: 'New Child');
      
      // Should not be able to undo
      expect(noUndoController.canUndo(), false);
      expect(noUndoController.undo(), false);
      
      noUndoController.dispose();
    });

    test('should clear history when refresh is called', () {
      // Add a child node
      controller.addChildNode('root', topic: 'Child 3');
      expect(controller.canUndo(), true);
      
      // Refresh with new data
      controller.refresh(testData);
      
      // History should be cleared
      expect(controller.canUndo(), false);
      expect(controller.canRedo(), false);
    });

    test('undo should return false when nothing to undo', () {
      expect(controller.undo(), false);
    });

    test('redo should return false when nothing to redo', () {
      expect(controller.redo(), false);
    });

    test('should respect maxHistorySize limit', () {
      final limitedController = MindMapController(
        initialData: testData,
        config: const MindMapConfig(allowUndo: true, maxHistorySize: 2),
      );
      
      // Perform 3 operations
      limitedController.addChildNode('root', topic: 'Child 3');
      limitedController.addChildNode('root', topic: 'Child 4');
      limitedController.addChildNode('root', topic: 'Child 5');
      
      // Should only be able to undo 2 operations (the last 2)
      limitedController.undo(); // Undo Child 5
      limitedController.undo(); // Undo Child 4
      
      // Should still have Child 3 (first operation was dropped)
      expect(limitedController.getData().nodeData.children.length, 3);
      expect(limitedController.canUndo(), false);
      
      limitedController.dispose();
    });
  });
}
