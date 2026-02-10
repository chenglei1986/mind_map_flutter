import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/history/operations.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/node_style.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';

void main() {
  group('CreateNodeOperation', () {
    late MindMapData testData;
    late NodeData rootNode;
    late NodeData childNode1;
    
    setUp(() {
      childNode1 = NodeData.create(id: 'child1', topic: 'Child 1');
      rootNode = NodeData.create(
        id: 'root',
        topic: 'Root',
        children: [childNode1],
      );
      testData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
    });
    
    test('should add child node to parent', () {
      final newNode = NodeData.create(id: 'child2', topic: 'Child 2');
      final operation = CreateNodeOperation(
        parentId: 'root',
        newNode: newNode,
      );
      
      final result = operation.execute(testData);
      
      expect(result.nodeData.children.length, 2);
      expect(result.nodeData.children.last.id, 'child2');
      expect(result.nodeData.children.last.topic, 'Child 2');
    });
    
    test('should add child node at specific index', () {
      final newNode = NodeData.create(id: 'child2', topic: 'Child 2');
      final operation = CreateNodeOperation(
        parentId: 'root',
        newNode: newNode,
        insertIndex: 0,
      );
      
      final result = operation.execute(testData);
      
      expect(result.nodeData.children.length, 2);
      expect(result.nodeData.children.first.id, 'child2');
      expect(result.nodeData.children.last.id, 'child1');
    });
    
    test('should add node to nested parent', () {
      final grandchild = NodeData.create(id: 'grandchild', topic: 'Grandchild');
      final operation = CreateNodeOperation(
        parentId: 'child1',
        newNode: grandchild,
      );
      
      final result = operation.execute(testData);
      
      expect(result.nodeData.children.first.children.length, 1);
      expect(result.nodeData.children.first.children.first.id, 'grandchild');
    });
    
    test('should undo node creation', () {
      final newNode = NodeData.create(id: 'child2', topic: 'Child 2');
      final operation = CreateNodeOperation(
        parentId: 'root',
        newNode: newNode,
      );
      
      final afterExecute = operation.execute(testData);
      expect(afterExecute.nodeData.children.length, 2);
      
      final afterUndo = operation.undo(afterExecute);
      expect(afterUndo.nodeData.children.length, 1);
      expect(afterUndo.nodeData.children.first.id, 'child1');
    });
    
    test('should have descriptive description', () {
      final newNode = NodeData.create(id: 'child2', topic: 'Child 2');
      final operation = CreateNodeOperation(
        parentId: 'root',
        newNode: newNode,
      );
      
      expect(operation.description, contains('Create node'));
      expect(operation.description, contains('Child 2'));
      expect(operation.description, contains('root'));
    });
  });
  
  group('DeleteNodeOperation', () {
    late MindMapData testData;
    late NodeData rootNode;
    late NodeData childNode1;
    late NodeData childNode2;
    
    setUp(() {
      childNode1 = NodeData.create(id: 'child1', topic: 'Child 1');
      childNode2 = NodeData.create(id: 'child2', topic: 'Child 2');
      rootNode = NodeData.create(
        id: 'root',
        topic: 'Root',
        children: [childNode1, childNode2],
      );
      testData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
    });
    
    test('should delete node from parent', () {
      final operation = DeleteNodeOperation(
        nodeId: 'child1',
        parentId: 'root',
        deletedNode: childNode1,
        originalIndex: 0,
      );
      
      final result = operation.execute(testData);
      
      expect(result.nodeData.children.length, 1);
      expect(result.nodeData.children.first.id, 'child2');
    });
    
    test('should delete node with descendants', () {
      final grandchild = NodeData.create(id: 'grandchild', topic: 'Grandchild');
      final childWithDescendants = childNode1.copyWith(children: [grandchild]);
      final rootWithGrandchild = rootNode.copyWith(
        children: [childWithDescendants, childNode2],
      );
      final dataWithGrandchild = testData.copyWith(nodeData: rootWithGrandchild);
      
      final operation = DeleteNodeOperation(
        nodeId: 'child1',
        parentId: 'root',
        deletedNode: childWithDescendants,
        originalIndex: 0,
      );
      
      final result = operation.execute(dataWithGrandchild);
      
      expect(result.nodeData.children.length, 1);
      expect(result.nodeData.children.first.id, 'child2');
    });
    
    test('should undo node deletion', () {
      final operation = DeleteNodeOperation(
        nodeId: 'child1',
        parentId: 'root',
        deletedNode: childNode1,
        originalIndex: 0,
      );
      
      final afterExecute = operation.execute(testData);
      expect(afterExecute.nodeData.children.length, 1);
      
      final afterUndo = operation.undo(afterExecute);
      expect(afterUndo.nodeData.children.length, 2);
      expect(afterUndo.nodeData.children.first.id, 'child1');
      expect(afterUndo.nodeData.children.last.id, 'child2');
    });
    
    test('should restore node at original index', () {
      final operation = DeleteNodeOperation(
        nodeId: 'child2',
        parentId: 'root',
        deletedNode: childNode2,
        originalIndex: 1,
      );
      
      final afterExecute = operation.execute(testData);
      final afterUndo = operation.undo(afterExecute);
      
      expect(afterUndo.nodeData.children[0].id, 'child1');
      expect(afterUndo.nodeData.children[1].id, 'child2');
    });
    
    test('should have descriptive description', () {
      final operation = DeleteNodeOperation(
        nodeId: 'child1',
        parentId: 'root',
        deletedNode: childNode1,
        originalIndex: 0,
      );
      
      expect(operation.description, contains('Delete node'));
      expect(operation.description, contains('Child 1'));
      expect(operation.description, contains('child1'));
    });
  });
  
  group('EditNodeOperation', () {
    late MindMapData testData;
    late NodeData rootNode;
    late NodeData childNode;
    
    setUp(() {
      childNode = NodeData.create(id: 'child1', topic: 'Original Topic');
      rootNode = NodeData.create(
        id: 'root',
        topic: 'Root',
        children: [childNode],
      );
      testData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
    });
    
    test('should edit node topic', () {
      final operation = EditNodeOperation(
        nodeId: 'child1',
        oldTopic: 'Original Topic',
        newTopic: 'New Topic',
      );
      
      final result = operation.execute(testData);
      
      expect(result.nodeData.children.first.topic, 'New Topic');
    });
    
    test('should edit root node topic', () {
      final operation = EditNodeOperation(
        nodeId: 'root',
        oldTopic: 'Root',
        newTopic: 'New Root',
      );
      
      final result = operation.execute(testData);
      
      expect(result.nodeData.topic, 'New Root');
    });
    
    test('should edit nested node topic', () {
      final grandchild = NodeData.create(id: 'grandchild', topic: 'Grandchild');
      final childWithGrandchild = childNode.copyWith(children: [grandchild]);
      final rootWithGrandchild = rootNode.copyWith(children: [childWithGrandchild]);
      final dataWithGrandchild = testData.copyWith(nodeData: rootWithGrandchild);
      
      final operation = EditNodeOperation(
        nodeId: 'grandchild',
        oldTopic: 'Grandchild',
        newTopic: 'Updated Grandchild',
      );
      
      final result = operation.execute(dataWithGrandchild);
      
      expect(result.nodeData.children.first.children.first.topic, 'Updated Grandchild');
    });
    
    test('should undo node edit', () {
      final operation = EditNodeOperation(
        nodeId: 'child1',
        oldTopic: 'Original Topic',
        newTopic: 'New Topic',
      );
      
      final afterExecute = operation.execute(testData);
      expect(afterExecute.nodeData.children.first.topic, 'New Topic');
      
      final afterUndo = operation.undo(afterExecute);
      expect(afterUndo.nodeData.children.first.topic, 'Original Topic');
    });
    
    test('should have descriptive description', () {
      final operation = EditNodeOperation(
        nodeId: 'child1',
        oldTopic: 'Original Topic',
        newTopic: 'New Topic',
      );
      
      expect(operation.description, contains('Edit node'));
      expect(operation.description, contains('child1'));
      expect(operation.description, contains('Original Topic'));
      expect(operation.description, contains('New Topic'));
    });
  });
  
  group('MoveNodeOperation', () {
    late MindMapData testData;
    late NodeData rootNode;
    late NodeData childNode1;
    late NodeData childNode2;
    late NodeData grandchild;
    
    setUp(() {
      grandchild = NodeData.create(id: 'grandchild', topic: 'Grandchild');
      childNode1 = NodeData.create(
        id: 'child1',
        topic: 'Child 1',
        children: [grandchild],
      );
      childNode2 = NodeData.create(id: 'child2', topic: 'Child 2');
      rootNode = NodeData.create(
        id: 'root',
        topic: 'Root',
        children: [childNode1, childNode2],
      );
      testData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
    });
    
    test('should move node to different parent', () {
      final operation = MoveNodeOperation(
        nodeId: 'grandchild',
        oldParentId: 'child1',
        newParentId: 'child2',
        oldIndex: 0,
        newIndex: 0,
        movedNode: grandchild,
      );
      
      final result = operation.execute(testData);
      
      // Grandchild should be removed from child1
      expect(result.nodeData.children[0].children.length, 0);
      // Grandchild should be added to child2
      expect(result.nodeData.children[1].children.length, 1);
      expect(result.nodeData.children[1].children.first.id, 'grandchild');
    });
    
    test('should reorder siblings', () {
      final operation = MoveNodeOperation(
        nodeId: 'child2',
        oldParentId: 'root',
        newParentId: 'root',
        oldIndex: 1,
        newIndex: 0,
        movedNode: childNode2,
      );
      
      final result = operation.execute(testData);
      
      expect(result.nodeData.children.length, 2);
      expect(result.nodeData.children[0].id, 'child2');
      expect(result.nodeData.children[1].id, 'child1');
    });
    
    test('should undo node move', () {
      final operation = MoveNodeOperation(
        nodeId: 'grandchild',
        oldParentId: 'child1',
        newParentId: 'child2',
        oldIndex: 0,
        newIndex: 0,
        movedNode: grandchild,
      );
      
      final afterExecute = operation.execute(testData);
      expect(afterExecute.nodeData.children[0].children.length, 0);
      expect(afterExecute.nodeData.children[1].children.length, 1);
      
      final afterUndo = operation.undo(afterExecute);
      expect(afterUndo.nodeData.children[0].children.length, 1);
      expect(afterUndo.nodeData.children[0].children.first.id, 'grandchild');
      expect(afterUndo.nodeData.children[1].children.length, 0);
    });
    
    test('should preserve node data when moving', () {
      final operation = MoveNodeOperation(
        nodeId: 'grandchild',
        oldParentId: 'child1',
        newParentId: 'child2',
        oldIndex: 0,
        newIndex: 0,
        movedNode: grandchild,
      );
      
      final result = operation.execute(testData);
      
      final movedNode = result.nodeData.children[1].children.first;
      expect(movedNode.id, grandchild.id);
      expect(movedNode.topic, grandchild.topic);
    });
    
    test('should have descriptive description', () {
      final operation = MoveNodeOperation(
        nodeId: 'grandchild',
        oldParentId: 'child1',
        newParentId: 'child2',
        oldIndex: 0,
        newIndex: 0,
        movedNode: grandchild,
      );
      
      expect(operation.description, contains('Move node'));
      expect(operation.description, contains('grandchild'));
      expect(operation.description, contains('child1'));
      expect(operation.description, contains('child2'));
    });
  });
  
  group('StyleNodeOperation', () {
    late MindMapData testData;
    late NodeData rootNode;
    late NodeData childNode;
    
    setUp(() {
      childNode = NodeData.create(id: 'child1', topic: 'Child 1');
      rootNode = NodeData.create(
        id: 'root',
        topic: 'Root',
        children: [childNode],
      );
      testData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
    });
    
    test('should apply style to node', () {
      final newStyle = NodeStyle(
        fontSize: 20,
        color: Colors.red,
        background: Colors.yellow,
      );
      
      final operation = StyleNodeOperation(
        nodeId: 'child1',
        oldStyle: null,
        newStyle: newStyle,
      );
      
      final result = operation.execute(testData);
      
      expect(result.nodeData.children.first.style, newStyle);
      expect(result.nodeData.children.first.style?.fontSize, 20);
      expect(result.nodeData.children.first.style?.color, Colors.red);
    });
    
    test('should update existing style', () {
      final oldStyle = NodeStyle(fontSize: 16, color: Colors.black);
      final childWithStyle = childNode.copyWith(style: oldStyle);
      final rootWithStyledChild = rootNode.copyWith(children: [childWithStyle]);
      final dataWithStyle = testData.copyWith(nodeData: rootWithStyledChild);
      
      final newStyle = NodeStyle(fontSize: 20, color: Colors.red);
      final operation = StyleNodeOperation(
        nodeId: 'child1',
        oldStyle: oldStyle,
        newStyle: newStyle,
      );
      
      final result = operation.execute(dataWithStyle);
      
      expect(result.nodeData.children.first.style, newStyle);
      expect(result.nodeData.children.first.style?.fontSize, 20);
    });
    
    test('should remove style when newStyle is null', () {
      final oldStyle = NodeStyle(fontSize: 16, color: Colors.black);
      final childWithStyle = childNode.copyWith(style: oldStyle);
      final rootWithStyledChild = rootNode.copyWith(children: [childWithStyle]);
      final dataWithStyle = testData.copyWith(nodeData: rootWithStyledChild);
      
      final operation = StyleNodeOperation(
        nodeId: 'child1',
        oldStyle: oldStyle,
        newStyle: null,
      );
      
      final result = operation.execute(dataWithStyle);
      
      expect(result.nodeData.children.first.style, null);
    });
    
    test('should style nested node', () {
      final grandchild = NodeData.create(id: 'grandchild', topic: 'Grandchild');
      final childWithGrandchild = childNode.copyWith(children: [grandchild]);
      final rootWithGrandchild = rootNode.copyWith(children: [childWithGrandchild]);
      final dataWithGrandchild = testData.copyWith(nodeData: rootWithGrandchild);
      
      final newStyle = NodeStyle(fontSize: 18, color: Colors.blue);
      final operation = StyleNodeOperation(
        nodeId: 'grandchild',
        oldStyle: null,
        newStyle: newStyle,
      );
      
      final result = operation.execute(dataWithGrandchild);
      
      expect(result.nodeData.children.first.children.first.style, newStyle);
    });
    
    test('should undo style change', () {
      final oldStyle = NodeStyle(fontSize: 16, color: Colors.black);
      final newStyle = NodeStyle(fontSize: 20, color: Colors.red);
      
      final operation = StyleNodeOperation(
        nodeId: 'child1',
        oldStyle: oldStyle,
        newStyle: newStyle,
      );
      
      final childWithStyle = childNode.copyWith(style: oldStyle);
      final rootWithStyledChild = rootNode.copyWith(children: [childWithStyle]);
      final dataWithStyle = testData.copyWith(nodeData: rootWithStyledChild);
      
      final afterExecute = operation.execute(dataWithStyle);
      expect(afterExecute.nodeData.children.first.style, newStyle);
      
      final afterUndo = operation.undo(afterExecute);
      expect(afterUndo.nodeData.children.first.style, oldStyle);
    });
    
    test('should have descriptive description', () {
      final operation = StyleNodeOperation(
        nodeId: 'child1',
        oldStyle: null,
        newStyle: NodeStyle(fontSize: 20),
      );
      
      expect(operation.description, contains('Style node'));
      expect(operation.description, contains('child1'));
    });
  });
  
  group('Operations Integration', () {
    late MindMapData testData;
    
    setUp(() {
      final rootNode = NodeData.create(id: 'root', topic: 'Root');
      testData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
    });
    
    test('should support chaining multiple operations', () {
      // Create a child
      final child1 = NodeData.create(id: 'child1', topic: 'Child 1');
      final createOp = CreateNodeOperation(
        parentId: 'root',
        newNode: child1,
      );
      var result = createOp.execute(testData);
      expect(result.nodeData.children.length, 1);
      
      // Edit the child
      final editOp = EditNodeOperation(
        nodeId: 'child1',
        oldTopic: 'Child 1',
        newTopic: 'Updated Child 1',
      );
      result = editOp.execute(result);
      expect(result.nodeData.children.first.topic, 'Updated Child 1');
      
      // Style the child
      final styleOp = StyleNodeOperation(
        nodeId: 'child1',
        oldStyle: null,
        newStyle: NodeStyle(fontSize: 20, color: Colors.red),
      );
      result = styleOp.execute(result);
      expect(result.nodeData.children.first.style?.fontSize, 20);
      
      // Create another child
      final child2 = NodeData.create(id: 'child2', topic: 'Child 2');
      final createOp2 = CreateNodeOperation(
        parentId: 'root',
        newNode: child2,
      );
      result = createOp2.execute(result);
      expect(result.nodeData.children.length, 2);
    });
    
    test('should support undo chain', () {
      // Create and execute operations
      final child1 = NodeData.create(id: 'child1', topic: 'Child 1');
      final createOp = CreateNodeOperation(
        parentId: 'root',
        newNode: child1,
      );
      var result = createOp.execute(testData);
      
      final editOp = EditNodeOperation(
        nodeId: 'child1',
        oldTopic: 'Child 1',
        newTopic: 'Updated Child 1',
      );
      result = editOp.execute(result);
      
      // Undo in reverse order
      result = editOp.undo(result);
      expect(result.nodeData.children.first.topic, 'Child 1');
      
      result = createOp.undo(result);
      expect(result.nodeData.children.length, 0);
    });
  });
}
