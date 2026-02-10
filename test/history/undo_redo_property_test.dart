import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';
import '../helpers/generators.dart';

// Feature: mind-map-flutter, Property 16: 操作历史记录
// Feature: mind-map-flutter, Property 17: 撤销重做往返
// Feature: mind-map-flutter, Property 18: 撤销后新操作清除重做

void main() {
  group('Undo/Redo Property Tests', () {
    const iterations = 100;

    // For any user operation (create, delete, edit, move, style change),
    // the operation should be recorded in history
    test('Property 16: Operation history recording', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 3,
        );

        final controller = MindMapController(
          initialData: initialData,
          config: const MindMapConfig(allowUndo: true),
        );

        // Initially, there should be no operations to undo
        expect(controller.canUndo(), false,
            reason: 'Initially there should be no operations to undo');
        expect(controller.canRedo(), false,
            reason: 'Initially there should be no operations to redo');

        // Test 1: Create node operation should be recorded
        controller.addChildNode(initialData.nodeData.id, topic: 'Test Child');
        expect(controller.canUndo(), true,
            reason: 'Create node operation should be recorded in history');

        // Test 2: Edit node operation should be recorded
        final nodeToEdit = _findAnyNode(controller.getData().nodeData);
        if (nodeToEdit != null) {
          controller.updateNodeTopic(nodeToEdit.id, 'Edited Topic');
          expect(controller.canUndo(), true,
              reason: 'Edit node operation should be recorded in history');
        }

        // Test 3: Delete node operation should be recorded (if there are children)
        final nodeWithChildren = _findNodeWithChildren(controller.getData().nodeData);
        if (nodeWithChildren != null && nodeWithChildren.children.isNotEmpty) {
          final childToDelete = nodeWithChildren.children.first;
          controller.removeNode(childToDelete.id);
          expect(controller.canUndo(), true,
              reason: 'Delete node operation should be recorded in history');
        }

        // Test 4: Move node operation should be recorded
        final currentData = controller.getData();
        final nodeToMove = _findNodeWithParent(currentData.nodeData);
        final targetParent = _findDifferentNode(currentData.nodeData, nodeToMove?.id);
        if (nodeToMove != null && targetParent != null) {
          // Ensure we're not moving to a descendant
          if (!_isDescendant(nodeToMove, targetParent.id)) {
            controller.moveNode(nodeToMove.id, targetParent.id);
            expect(controller.canUndo(), true,
                reason: 'Move node operation should be recorded in history');
          }
        }

        controller.dispose();
      }
    });

    // For any undoable operation, executing operation -> undo -> redo
    // should restore to the state after execution
    test('Property 17: Undo-redo round-trip', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 3,
        );

        final controller = MindMapController(
          initialData: initialData,
          config: const MindMapConfig(allowUndo: true),
        );

        // Capture initial state
        final initialState = _serializeData(controller.getData());

        // Perform a random operation
        final operationType = i % 4;
        
        switch (operationType) {
          case 0: // Create node
            controller.addChildNode(initialData.nodeData.id, topic: 'New Node');
            break;
            
          case 1: // Edit node
            final nodeToEdit = _findAnyNode(controller.getData().nodeData);
            if (nodeToEdit != null) {
              controller.updateNodeTopic(nodeToEdit.id, 'Edited ${i}');
            }
            break;
            
          case 2: // Delete node
            final nodeToDelete = _findDeletableNode(controller.getData().nodeData);
            if (nodeToDelete != null) {
              controller.removeNode(nodeToDelete.id);
            }
            break;
            
          case 3: // Move node
            final currentData = controller.getData();
            final nodeToMove = _findNodeWithParent(currentData.nodeData);
            final targetParent = _findDifferentNode(currentData.nodeData, nodeToMove?.id);
            if (nodeToMove != null && targetParent != null) {
              if (!_isDescendant(nodeToMove, targetParent.id)) {
                controller.moveNode(nodeToMove.id, targetParent.id);
              }
            }
            break;
        }

        // Capture state after operation
        final afterOperationState = _serializeData(controller.getData());

        // Verify operation was recorded
        if (controller.canUndo()) {
          // Undo the operation (Requirement 8.2)
          final undoSuccess = controller.undo();
          expect(undoSuccess, true,
              reason: 'Undo should succeed when there are operations to undo');

          // Verify state is restored to initial state
          final afterUndoState = _serializeData(controller.getData());
          expect(afterUndoState, initialState,
              reason: 'Undo should restore to initial state');

          // Verify redo is now available
          expect(controller.canRedo(), true,
              reason: 'Redo should be available after undo');

          // Redo the operation (Requirement 8.3)
          final redoSuccess = controller.redo();
          expect(redoSuccess, true,
              reason: 'Redo should succeed when there are operations to redo');

          // Verify state is restored to after-operation state (Requirement 8.4)
          final afterRedoState = _serializeData(controller.getData());
          expect(afterRedoState, afterOperationState,
              reason: 'Redo should restore to state after operation');

          // Verify undo is available again
          expect(controller.canUndo(), true,
              reason: 'Undo should be available after redo');
        }

        controller.dispose();
      }
    });

    // For any undo operation followed by a new operation,
    // the redo history should be cleared
    test('Property 18: New operation after undo clears redo', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 3,
        );

        final controller = MindMapController(
          initialData: initialData,
          config: const MindMapConfig(allowUndo: true),
        );

        // Perform first operation
        controller.addChildNode(initialData.nodeData.id, topic: 'First Node');
        expect(controller.canUndo(), true,
            reason: 'First operation should be recorded');

        // Undo the first operation
        controller.undo();
        expect(controller.canRedo(), true,
            reason: 'Redo should be available after undo');

        // Perform a new operation (different type based on iteration)
        final newOperationType = i % 3;
        switch (newOperationType) {
          case 0: // Create a different node
            controller.addChildNode(initialData.nodeData.id, topic: 'Second Node');
            break;
            
          case 1: // Edit a node
            final nodeToEdit = _findAnyNode(controller.getData().nodeData);
            if (nodeToEdit != null) {
              controller.updateNodeTopic(nodeToEdit.id, 'New Edit ${i}');
            } else {
              // Fallback to create if no node to edit
              controller.addChildNode(initialData.nodeData.id, topic: 'Fallback Node');
            }
            break;
            
          case 2: // Create sibling
            final nodeForSibling = _findAnyNode(controller.getData().nodeData);
            if (nodeForSibling != null && nodeForSibling.id != initialData.nodeData.id) {
              controller.addSiblingNode(nodeForSibling.id, topic: 'Sibling Node');
            } else {
              // Fallback to create child
              controller.addChildNode(initialData.nodeData.id, topic: 'Fallback Node');
            }
            break;
        }

        // Verify redo history is cleared (Requirement 8.5)
        expect(controller.canRedo(), false,
            reason: 'Redo history should be cleared after new operation following undo');

        // Verify undo is still available for the new operation
        expect(controller.canUndo(), true,
            reason: 'Undo should be available for the new operation');

        controller.dispose();
      }
    });

    // Additional property test: Multiple undo/redo operations
    test('Property 17 (Extended): Multiple undo/redo operations', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 2,
        );

        final controller = MindMapController(
          initialData: initialData,
          config: const MindMapConfig(allowUndo: true),
        );

        // Capture initial state
        final initialState = _serializeData(controller.getData());

        // Perform multiple operations
        final operationCount = 3 + (i % 3); // 3-5 operations
        final states = <String>[initialState];

        for (int j = 0; j < operationCount; j++) {
          // Perform operation
          controller.addChildNode(
            initialData.nodeData.id,
            topic: 'Node $j',
          );
          
          // Capture state after each operation
          states.add(_serializeData(controller.getData()));
        }

        // Verify all operations can be undone
        expect(controller.canUndo(), true,
            reason: 'Should be able to undo after multiple operations');

        // Undo all operations one by one
        for (int j = operationCount - 1; j >= 0; j--) {
          controller.undo();
          final currentState = _serializeData(controller.getData());
          expect(currentState, states[j],
              reason: 'State after undo $j should match state before operation $j');
        }

        // Verify we're back to initial state
        final finalState = _serializeData(controller.getData());
        expect(finalState, initialState,
            reason: 'After undoing all operations, should be back to initial state');

        // Verify no more undo available
        expect(controller.canUndo(), false,
            reason: 'No more undo should be available after undoing all operations');

        // Verify redo is available
        expect(controller.canRedo(), true,
            reason: 'Redo should be available after undoing operations');

        // Redo all operations
        for (int j = 1; j <= operationCount; j++) {
          controller.redo();
          final currentState = _serializeData(controller.getData());
          expect(currentState, states[j],
              reason: 'State after redo $j should match state after operation $j');
        }

        // Verify no more redo available
        expect(controller.canRedo(), false,
            reason: 'No more redo should be available after redoing all operations');

        controller.dispose();
      }
    });

    // Additional property test: Undo/redo with disabled undo
    test('Property 16 (Extended): Operations not recorded when undo disabled', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 3,
        );

        final controller = MindMapController(
          initialData: initialData,
          config: const MindMapConfig(allowUndo: false), // Undo disabled
        );

        // Perform operations
        controller.addChildNode(initialData.nodeData.id, topic: 'Test Node');
        
        final nodeToEdit = _findAnyNode(controller.getData().nodeData);
        if (nodeToEdit != null) {
          controller.updateNodeTopic(nodeToEdit.id, 'Edited');
        }

        // Verify operations are NOT recorded when undo is disabled
        expect(controller.canUndo(), false,
            reason: 'Operations should not be recorded when undo is disabled');
        expect(controller.canRedo(), false,
            reason: 'Redo should not be available when undo is disabled');

        // Verify undo/redo return false
        expect(controller.undo(), false,
            reason: 'Undo should return false when disabled');
        expect(controller.redo(), false,
            reason: 'Redo should return false when disabled');

        controller.dispose();
      }
    });

    // Additional property test: Undo/redo idempotency
    test('Property 17 (Extended): Undo/redo idempotency', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 3,
        );

        final controller = MindMapController(
          initialData: initialData,
          config: const MindMapConfig(allowUndo: true),
        );

        // Perform operation
        controller.addChildNode(initialData.nodeData.id, topic: 'Test Node');

        // Undo once
        controller.undo();
        final afterFirstUndo = _serializeData(controller.getData());

        // Try to undo again (should have no effect)
        final secondUndoResult = controller.undo();
        expect(secondUndoResult, false,
            reason: 'Second undo should return false when nothing to undo');
        
        final afterSecondUndo = _serializeData(controller.getData());
        expect(afterSecondUndo, afterFirstUndo,
            reason: 'Multiple undos when nothing to undo should not change state');

        // Redo once
        controller.redo();
        final afterFirstRedo = _serializeData(controller.getData());

        // Try to redo again (should have no effect)
        final secondRedoResult = controller.redo();
        expect(secondRedoResult, false,
            reason: 'Second redo should return false when nothing to redo');
        
        final afterSecondRedo = _serializeData(controller.getData());
        expect(afterSecondRedo, afterFirstRedo,
            reason: 'Multiple redos when nothing to redo should not change state');

        controller.dispose();
      }
    });

    // Additional property test: Complex operation sequences
    test('Property 17 (Extended): Complex operation sequences', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 2,
        );

        final controller = MindMapController(
          initialData: initialData,
          config: const MindMapConfig(allowUndo: true),
        );

        // Perform a sequence: create -> edit -> undo edit -> create another -> undo all
        
        // Step 1: Create node
        controller.addChildNode(initialData.nodeData.id, topic: 'Node 1');
        final afterCreate1 = _serializeData(controller.getData());

        // Step 2: Edit the created node
        final createdNode = controller.getData().nodeData.children.last;
        controller.updateNodeTopic(createdNode.id, 'Edited Node 1');

        // Step 3: Undo the edit
        controller.undo();
        final afterUndoEdit = _serializeData(controller.getData());
        expect(afterUndoEdit, afterCreate1,
            reason: 'After undoing edit, should be back to state after create');

        // Step 4: Create another node (this should clear redo)
        controller.addChildNode(initialData.nodeData.id, topic: 'Node 2');
        expect(controller.canRedo(), false,
            reason: 'Creating new node after undo should clear redo');

        // Step 5: Undo both creates
        controller.undo(); // Undo create node 2
        controller.undo(); // Undo create node 1
        
        final finalState = _serializeData(controller.getData());
        final initialState = _serializeData(initialData);
        expect(finalState, initialState,
            reason: 'After undoing all operations, should be back to initial state');

        controller.dispose();
      }
    });
  });
}

// Helper functions

/// Find any non-root node in the tree
NodeData? _findAnyNode(NodeData root) {
  if (root.children.isNotEmpty) {
    return root.children.first;
  }
  for (final child in root.children) {
    final found = _findAnyNode(child);
    if (found != null) return found;
  }
  return null;
}

/// Find a node with children
NodeData? _findNodeWithChildren(NodeData node) {
  if (node.children.isNotEmpty) {
    return node;
  }
  for (final child in node.children) {
    final found = _findNodeWithChildren(child);
    if (found != null) return found;
  }
  return null;
}

/// Find a node that has a parent (not root)
NodeData? _findNodeWithParent(NodeData root) {
  for (final child in root.children) {
    return child; // Any direct child has a parent
  }
  return null;
}

/// Find a node different from the given ID
NodeData? _findDifferentNode(NodeData root, String? excludeId) {
  if (root.id != excludeId) {
    return root;
  }
  for (final child in root.children) {
    final found = _findDifferentNode(child, excludeId);
    if (found != null) return found;
  }
  return null;
}

/// Find a deletable node (not root, has parent)
NodeData? _findDeletableNode(NodeData root) {
  if (root.children.isNotEmpty) {
    return root.children.first;
  }
  for (final child in root.children) {
    final found = _findDeletableNode(child);
    if (found != null) return found;
  }
  return null;
}

/// Check if a node is a descendant of another
bool _isDescendant(NodeData ancestor, String nodeId) {
  if (ancestor.id == nodeId) return true;
  for (final child in ancestor.children) {
    if (_isDescendant(child, nodeId)) return true;
  }
  return false;
}

/// Serialize data to a comparable string representation
String _serializeData(MindMapData data) {
  return _serializeNode(data.nodeData);
}

/// Serialize a node tree to a string
String _serializeNode(NodeData node) {
  final buffer = StringBuffer();
  buffer.write('${node.id}:${node.topic}:${node.expanded}');
  if (node.children.isNotEmpty) {
    buffer.write('[');
    for (int i = 0; i < node.children.length; i++) {
      if (i > 0) buffer.write(',');
      buffer.write(_serializeNode(node.children[i]));
    }
    buffer.write(']');
  }
  return buffer.toString();
}
