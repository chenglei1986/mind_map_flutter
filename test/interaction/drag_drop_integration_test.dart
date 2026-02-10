import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_widget.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_controller.dart';

void main() {
  group('Drag and Drop Integration Tests', () {
    late MindMapData testData;
    late MindMapController controller;

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

    testWidgets('should have drag manager initialized', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              initialData: testData,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<MindMapState>(find.byType(MindMapWidget));
      final dragManager = state.dragManager;

      // Assert
      expect(dragManager, isNotNull);
      expect(dragManager.isDragging, false);
    });

    testWidgets('should move node when moveNode is called', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              initialData: testData,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final node3 = testData.nodeData.children[0].children[0];
      final node2 = testData.nodeData.children[1];

      // Act - Move node3 to node2
      controller.moveNode(node3.id, node2.id);
      await tester.pumpAndSettle();

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
    });

    testWidgets('should emit moveNode event when node is moved', (tester) async {
      // Arrange
      MindMapEvent? lastEvent;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              initialData: testData,
              controller: controller,
              onEvent: (event) {
                lastEvent = event;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final node3 = testData.nodeData.children[0].children[0];
      final node2 = testData.nodeData.children[1];
      final node1 = testData.nodeData.children[0];

      // Act - Move node3 to node2
      controller.moveNode(node3.id, node2.id);
      await tester.pumpAndSettle();

      // Assert
      expect(lastEvent, isA<MoveNodeEvent>());
      final event = lastEvent as MoveNodeEvent;
      expect(event.nodeId, node3.id);
      expect(event.oldParentId, node1.id);
      expect(event.newParentId, node2.id);
      expect(event.isReorder, false);
    });

    testWidgets('should reorder siblings when moving within same parent', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              initialData: testData,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final node1 = testData.nodeData.children[0];
      final node3 = node1.children[0];
      final node4 = node1.children[1];

      // Act - Move node4 to position 0 (before node3)
      controller.moveNode(node4.id, node1.id, index: 0);
      await tester.pumpAndSettle();

      // Assert
      final updatedRoot = controller.getData().nodeData;
      final updatedNode1 = updatedRoot.children[0];

      // node4 should now be first
      expect(updatedNode1.children.length, 2);
      expect(updatedNode1.children[0].id, node4.id);
      expect(updatedNode1.children[1].id, node3.id);
    });

    testWidgets('should emit moveNode event with isReorder=true when reordering', (tester) async {
      // Arrange
      MindMapEvent? lastEvent;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              initialData: testData,
              controller: controller,
              onEvent: (event) {
                lastEvent = event;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final node1 = testData.nodeData.children[0];
      final node4 = node1.children[1];

      // Act - Reorder node4 within node1
      controller.moveNode(node4.id, node1.id, index: 0);
      await tester.pumpAndSettle();

      // Assert
      expect(lastEvent, isA<MoveNodeEvent>());
      final event = lastEvent as MoveNodeEvent;
      expect(event.nodeId, node4.id);
      expect(event.oldParentId, node1.id);
      expect(event.newParentId, node1.id);
      expect(event.isReorder, true);
    });

    testWidgets('should preserve node data when moving', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              initialData: testData,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final node3 = testData.nodeData.children[0].children[0];
      final node2 = testData.nodeData.children[1];

      // Act - Move node3 to node2
      controller.moveNode(node3.id, node2.id);
      await tester.pumpAndSettle();

      // Assert
      final updatedRoot = controller.getData().nodeData;
      final updatedNode2 = updatedRoot.children[1];
      final movedNode = updatedNode2.children[0];

      // All node data should be preserved
      expect(movedNode.id, node3.id);
      expect(movedNode.topic, 'Node 3');
      expect(movedNode.children, isEmpty);
    });

    testWidgets('should move node with its entire subtree', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              initialData: testData,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final node1 = testData.nodeData.children[0];
      final node2 = testData.nodeData.children[1];

      // Act - Move node1 (which has children) to node2
      controller.moveNode(node1.id, node2.id);
      await tester.pumpAndSettle();

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

    testWidgets('should render drag preview when dragging', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              initialData: testData,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<MindMapState>(find.byType(MindMapWidget));
      final dragManager = state.dragManager;
      final node3 = testData.nodeData.children[0].children[0];

      // Act - Manually trigger drag (simulating what GestureHandler would do)
      dragManager.startDrag(node3.id, const Offset(100, 100));
      await tester.pump();

      // Assert
      expect(dragManager.isDragging, true);
      expect(dragManager.draggedNodeId, node3.id);
      expect(dragManager.dragPosition, const Offset(100, 100));

      // Clean up
      dragManager.endDrag();
    });

    testWidgets('should highlight drop target when dragging over valid node', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              initialData: testData,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<MindMapState>(find.byType(MindMapWidget));
      final dragManager = state.dragManager;
      final nodeLayouts = state.nodeLayouts;
      final transform = state.transform;

      final node3 = testData.nodeData.children[0].children[0];
      final node2 = testData.nodeData.children[1];
      final node2Layout = nodeLayouts[node2.id]!;

      // Act - Start drag and move over node2
      dragManager.startDrag(node3.id, const Offset(100, 100));
      dragManager.updateDrag(
        node2Layout.bounds.center,
        nodeLayouts,
        transform,
        testData.nodeData,
      );
      await tester.pump();

      // Assert
      expect(dragManager.dropTargetNodeId, node2.id);

      // Clean up
      dragManager.endDrag();
    });

    testWidgets('should not highlight invalid drop target (circular reference)', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              initialData: testData,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state<MindMapState>(find.byType(MindMapWidget));
      final dragManager = state.dragManager;
      final nodeLayouts = state.nodeLayouts;
      final transform = state.transform;

      final node1 = testData.nodeData.children[0];
      final node3 = node1.children[0];
      final node3Layout = nodeLayouts[node3.id]!;

      // Act - Try to drag node1 over node3 (its own child)
      dragManager.startDrag(node1.id, const Offset(100, 100));
      dragManager.updateDrag(
        node3Layout.bounds.center,
        nodeLayouts,
        transform,
        testData.nodeData,
      );
      await tester.pump();

      // Assert - Should not highlight node3 as drop target
      expect(dragManager.dropTargetNodeId, isNull);

      // Clean up
      dragManager.endDrag();
    });
  });
}
