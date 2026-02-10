import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_controller.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_config.dart';

void main() {
  test('Adding child to collapsed node should restore collapsed state on undo', () {
    // Create a collapsed root node
    final rootNode = NodeData.create(
      topic: 'Root',
      expanded: false,
    );
    
    final initialData = MindMapData(
      nodeData: rootNode,
      theme: MindMapTheme.light,
    );
    
    final controller = MindMapController(
      initialData: initialData,
      config: const MindMapConfig(allowUndo: true),
    );
    
    // Verify initial state
    expect(controller.getData().nodeData.expanded, false);
    expect(controller.getData().nodeData.children.length, 0);
    
    // Add a child node (should auto-expand parent)
    controller.addChildNode(rootNode.id, topic: 'Child');
    
    // Verify parent was expanded and child was added
    expect(controller.getData().nodeData.expanded, true);
    expect(controller.getData().nodeData.children.length, 1);
    
    // Undo the operation
    controller.undo();
    
    // Verify parent is collapsed again and child is removed
    expect(controller.getData().nodeData.expanded, false,
        reason: 'Parent should be collapsed after undo');
    expect(controller.getData().nodeData.children.length, 0,
        reason: 'Child should be removed after undo');
  });
  
  test('Adding child to expanded node should keep expanded state on undo', () {
    // Create an expanded root node
    final rootNode = NodeData.create(
      topic: 'Root',
      expanded: true,
    );
    
    final initialData = MindMapData(
      nodeData: rootNode,
      theme: MindMapTheme.light,
    );
    
    final controller = MindMapController(
      initialData: initialData,
      config: const MindMapConfig(allowUndo: true),
    );
    
    // Verify initial state
    expect(controller.getData().nodeData.expanded, true);
    expect(controller.getData().nodeData.children.length, 0);
    
    // Add a child node
    controller.addChildNode(rootNode.id, topic: 'Child');
    
    // Verify parent is still expanded and child was added
    expect(controller.getData().nodeData.expanded, true);
    expect(controller.getData().nodeData.children.length, 1);
    
    // Undo the operation
    controller.undo();
    
    // Verify parent is still expanded and child is removed
    expect(controller.getData().nodeData.expanded, true,
        reason: 'Parent should still be expanded after undo');
    expect(controller.getData().nodeData.children.length, 0,
        reason: 'Child should be removed after undo');
  });

  test('Moving node to collapsed parent should restore collapsed state on undo', () {
    // Create a tree structure:
    // Root (expanded)
    //   ├─ Parent1 (collapsed)
    //   │   └─ Child1
    //   └─ Parent2 (expanded)
    //       └─ NodeToMove
    
    final child1 = NodeData.create(topic: 'Child1');
    final parent1 = NodeData.create(
      topic: 'Parent1',
      expanded: false,
      children: [child1],
    );
    
    final nodeToMove = NodeData.create(topic: 'NodeToMove');
    final parent2 = NodeData.create(
      topic: 'Parent2',
      expanded: true,
      children: [nodeToMove],
    );
    
    final rootNode = NodeData.create(
      topic: 'Root',
      expanded: true,
      children: [parent1, parent2],
    );
    
    final initialData = MindMapData(
      nodeData: rootNode,
      theme: MindMapTheme.light,
    );
    
    final controller = MindMapController(
      initialData: initialData,
      config: const MindMapConfig(allowUndo: true),
    );
    
    // Verify initial state
    final initialParent1 = controller.getData().nodeData.children[0];
    expect(initialParent1.expanded, false);
    expect(initialParent1.children.length, 1);
    
    final initialParent2 = controller.getData().nodeData.children[1];
    expect(initialParent2.expanded, true);
    expect(initialParent2.children.length, 1);
    
    // Move NodeToMove from Parent2 to Parent1 (which is collapsed)
    controller.moveNode(nodeToMove.id, parent1.id);
    
    // Verify Parent1 was auto-expanded
    final afterMoveParent1 = controller.getData().nodeData.children[0];
    expect(afterMoveParent1.expanded, true, reason: 'Parent1 should be auto-expanded');
    expect(afterMoveParent1.children.length, 2, reason: 'Parent1 should have 2 children');
    
    final afterMoveParent2 = controller.getData().nodeData.children[1];
    expect(afterMoveParent2.children.length, 0, reason: 'Parent2 should have 0 children');
    
    // Undo the move
    controller.undo();
    
    // Verify Parent1 is back to collapsed state
    final afterUndoParent1 = controller.getData().nodeData.children[0];
    expect(afterUndoParent1.expanded, false, reason: 'Parent1 should be collapsed again');
    expect(afterUndoParent1.children.length, 1, reason: 'Parent1 should have 1 child');
    
    final afterUndoParent2 = controller.getData().nodeData.children[1];
    expect(afterUndoParent2.children.length, 1, reason: 'Parent2 should have 1 child');
    
    // Redo the move
    controller.redo();
    
    // Verify Parent1 is expanded again
    final afterRedoParent1 = controller.getData().nodeData.children[0];
    expect(afterRedoParent1.expanded, true, reason: 'Parent1 should be expanded again');
    expect(afterRedoParent1.children.length, 2, reason: 'Parent1 should have 2 children');
    
    controller.dispose();
  });

  test('Toggle expand operation should be undoable', () {
    // Create a root with children
    final child1 = NodeData.create(topic: 'Child 1');
    final child2 = NodeData.create(topic: 'Child 2');
    final rootNode = NodeData.create(
      topic: 'Root',
      expanded: true,
      children: [child1, child2],
    );
    final initialData = MindMapData(
      nodeData: rootNode,
      theme: MindMapTheme.light,
    );
    
    final controller = MindMapController(
      initialData: initialData,
      config: const MindMapConfig(allowUndo: true),
    );
    
    // Verify initial state
    expect(controller.getData().nodeData.expanded, true);
    
    // Collapse the node
    controller.toggleNodeExpanded(rootNode.id);
    expect(controller.getData().nodeData.expanded, false);
    
    // Undo the collapse
    controller.undo();
    expect(controller.getData().nodeData.expanded, true);
    
    // Redo the collapse
    controller.redo();
    expect(controller.getData().nodeData.expanded, false);
    
    controller.dispose();
  });
}
