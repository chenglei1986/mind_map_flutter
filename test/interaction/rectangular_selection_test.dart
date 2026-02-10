import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

void main() {
  group('Rectangular Selection Tests', () {
    late MindMapData testData;
    late MindMapController controller;
    late Map<String, NodeLayout> nodeLayouts;
    late GestureHandler gestureHandler;
    
    setUp(() {
      // Create test data with multiple nodes
      testData = MindMapData.empty(rootTopic: 'Root');
      controller = MindMapController(initialData: testData);
      
      // Add child nodes
      controller.addChildNode(testData.nodeData.id, topic: 'Child 1');
      controller.addChildNode(testData.nodeData.id, topic: 'Child 2');
      controller.addChildNode(testData.nodeData.id, topic: 'Child 3');
      
      // Create mock node layouts
      final rootNode = controller.getData().nodeData;
      nodeLayouts = {
        rootNode.id: NodeLayout(
          position: const Offset(200, 200),
          size: const Size(100, 40),
        ),
        rootNode.children[0].id: NodeLayout(
          position: const Offset(50, 100),
          size: const Size(80, 30),
        ),
        rootNode.children[1].id: NodeLayout(
          position: const Offset(50, 150),
          size: const Size(80, 30),
        ),
        rootNode.children[2].id: NodeLayout(
          position: const Offset(50, 200),
          size: const Size(80, 30),
        ),
      };
      
      // Create gesture handler
      gestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: nodeLayouts,
        transform: Matrix4.identity(),
      );
    });
    
    tearDown(() {
      controller.dispose();
    });
    
    // Test drag selection gesture handling
    // Validates: Requirement 6.3
    test('should start drag selection on empty space', () {
      // Start drag on empty space (not on a node)
      gestureHandler.handlePanStart(
        DragStartDetails(
          localPosition: const Offset(400, 400),
        ),
      );
      
      // Selection rectangle should be initialized
      expect(gestureHandler.selectionRect, isNotNull);
    });
    
    test('should not start drag selection when starting on a node', () {
      final rootNode = controller.getData().nodeData;
      final nodePosition = nodeLayouts[rootNode.id]!.position;
      
      // Start drag on a node
      gestureHandler.handlePanStart(
        DragStartDetails(
          localPosition: nodePosition + const Offset(10, 10),
        ),
      );
      
      // Selection rectangle should not be initialized (node drag instead)
      expect(gestureHandler.selectionRect, isNull);
    });
    
    test('should update selection rectangle during drag', () {
      Rect? capturedRect;
      
      // Create gesture handler with callback
      gestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: nodeLayouts,
        transform: Matrix4.identity(),
        onSelectionRectChanged: (rect) {
          capturedRect = rect;
        },
      );
      
      // Start drag
      gestureHandler.handlePanStart(
        DragStartDetails(
          localPosition: const Offset(30, 80),
        ),
      );
      
      expect(capturedRect, isNotNull);
      
      // Update drag
      gestureHandler.handlePanUpdate(
        DragUpdateDetails(
          localPosition: const Offset(150, 220),
          globalPosition: const Offset(150, 220),
          delta: const Offset(120, 140),
        ),
      );
      
      // Rectangle should be updated
      expect(capturedRect, isNotNull);
      expect(capturedRect!.left, 30);
      expect(capturedRect!.top, 80);
      expect(capturedRect!.right, 150);
      expect(capturedRect!.bottom, 220);
    });
    
    test('should select nodes within rectangle', () {
      // Start drag that will encompass child nodes 1 and 2
      gestureHandler.handlePanStart(
        DragStartDetails(
          localPosition: const Offset(30, 80),
        ),
      );
      
      // Drag to encompass nodes
      gestureHandler.handlePanUpdate(
        DragUpdateDetails(
          localPosition: const Offset(150, 190),
          globalPosition: const Offset(150, 190),
          delta: const Offset(120, 110),
        ),
      );
      
      // Check that nodes are selected
      final selectedIds = controller.getSelectedNodeIds();
      expect(selectedIds.length, greaterThan(0));
      
      // Should include child 1 and child 2
      final rootNode = controller.getData().nodeData;
      expect(selectedIds, contains(rootNode.children[0].id));
      expect(selectedIds, contains(rootNode.children[1].id));
    });
    
    test('should clear selection rectangle on drag end', () {
      Rect? capturedRect;
      
      // Create gesture handler with callback
      gestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: nodeLayouts,
        transform: Matrix4.identity(),
        onSelectionRectChanged: (rect) {
          capturedRect = rect;
        },
      );
      
      // Start and update drag
      gestureHandler.handlePanStart(
        DragStartDetails(
          localPosition: const Offset(30, 80),
        ),
      );
      
      gestureHandler.handlePanUpdate(
        DragUpdateDetails(
          localPosition: const Offset(150, 220),
          globalPosition: const Offset(150, 220),
          delta: const Offset(120, 140),
        ),
      );
      
      expect(capturedRect, isNotNull);
      
      // End drag
      gestureHandler.handlePanEnd(
        DragEndDetails(),
      );
      
      // Rectangle should be cleared
      expect(capturedRect, isNull);
      expect(gestureHandler.selectionRect, isNull);
    });
    
    test('should finalize selection on drag end', () {
      final rootNode = controller.getData().nodeData;
      
      // Start drag
      gestureHandler.handlePanStart(
        DragStartDetails(
          localPosition: const Offset(30, 80),
        ),
      );
      
      // Drag to encompass all child nodes
      gestureHandler.handlePanUpdate(
        DragUpdateDetails(
          localPosition: const Offset(150, 240),
          globalPosition: const Offset(150, 240),
          delta: const Offset(120, 160),
        ),
      );
      
      // End drag
      gestureHandler.handlePanEnd(
        DragEndDetails(),
      );
      
      // All child nodes should be selected
      final selectedIds = controller.getSelectedNodeIds();
      expect(selectedIds.length, 3);
      expect(selectedIds, contains(rootNode.children[0].id));
      expect(selectedIds, contains(rootNode.children[1].id));
      expect(selectedIds, contains(rootNode.children[2].id));
    });
    
    test('should handle empty selection rectangle', () {
      // Start drag in empty area
      gestureHandler.handlePanStart(
        DragStartDetails(
          localPosition: const Offset(400, 400),
        ),
      );
      
      // Drag in empty area (no nodes)
      gestureHandler.handlePanUpdate(
        DragUpdateDetails(
          localPosition: const Offset(500, 500),
          globalPosition: const Offset(500, 500),
          delta: const Offset(100, 100),
        ),
      );
      
      // End drag
      gestureHandler.handlePanEnd(
        DragEndDetails(),
      );
      
      // No nodes should be selected
      final selectedIds = controller.getSelectedNodeIds();
      expect(selectedIds, isEmpty);
    });
    
    test('should emit selectNodes event during drag selection', () {
      // Start drag
      gestureHandler.handlePanStart(
        DragStartDetails(
          localPosition: const Offset(30, 80),
        ),
      );
      
      // Drag to encompass nodes
      gestureHandler.handlePanUpdate(
        DragUpdateDetails(
          localPosition: const Offset(150, 190),
          globalPosition: const Offset(150, 190),
          delta: const Offset(120, 110),
        ),
      );
      
      // Check that event was emitted
      expect(controller.lastEvent, isA<SelectNodesEvent>());
      final event = controller.lastEvent as SelectNodesEvent;
      expect(event.nodeIds.length, greaterThan(0));
    });
    
    test('should handle selection rectangle with negative dimensions', () {
      // Start drag
      gestureHandler.handlePanStart(
        DragStartDetails(
          localPosition: const Offset(150, 220),
        ),
      );
      
      // Drag backwards (creating negative dimensions)
      gestureHandler.handlePanUpdate(
        DragUpdateDetails(
          localPosition: const Offset(30, 80),
          globalPosition: const Offset(30, 80),
          delta: const Offset(-120, -140),
        ),
      );
      
      // Should still select nodes correctly
      final selectedIds = controller.getSelectedNodeIds();
      expect(selectedIds.length, greaterThan(0));
    });
    
    test('should work with transformed canvas', () {
      // Create gesture handler with zoom transform
      final zoomTransform = Matrix4.identity()
        ..scaleByDouble(2.0, 2.0, 1.0, 1.0);
      gestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: nodeLayouts,
        transform: zoomTransform,
      );
      
      // Start drag (coordinates will be transformed)
      gestureHandler.handlePanStart(
        DragStartDetails(
          localPosition: const Offset(60, 160), // 2x scaled
        ),
      );
      
      // Drag
      gestureHandler.handlePanUpdate(
        DragUpdateDetails(
          localPosition: const Offset(300, 380), // 2x scaled
          globalPosition: const Offset(300, 380),
          delta: const Offset(240, 220),
        ),
      );
      
      // End drag
      gestureHandler.handlePanEnd(
        DragEndDetails(),
      );
      
      // Should still select nodes correctly after transform
      final selectedIds = controller.getSelectedNodeIds();
      expect(selectedIds.length, greaterThan(0));
    });
  });
}
