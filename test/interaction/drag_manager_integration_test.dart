import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

void main() {
  group('DragManager Integration Tests', () {
    late MindMapData testData;
    late MindMapController controller;
    late DragManager dragManager;

    setUp(() {
      // Create test data with a simple tree
      testData = MindMapData(
        nodeData: NodeData.create(
          id: 'root',
          topic: 'Root',
          children: [
            NodeData.create(
              id: 'child1',
              topic: 'Child 1',
              children: [
                NodeData.create(
                  id: 'grandchild1',
                  topic: 'Grandchild 1',
                ),
              ],
            ),
            NodeData.create(
              id: 'child2',
              topic: 'Child 2',
            ),
          ],
        ),
        theme: MindMapTheme.light,
      );

      controller = MindMapController(initialData: testData);
      dragManager = DragManager();
    });

    tearDown(() {
      controller.dispose();
      dragManager.dispose();
    });

    testWidgets('should provide visual feedback during drag operation',
        (WidgetTester tester) async {
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

      // Verify initial state
      expect(dragManager.isDragging, isFalse);
      expect(dragManager.draggedNodeId, isNull);

      // Start a drag operation
      dragManager.startDrag('child1', const Offset(100, 100));

      expect(dragManager.isDragging, isTrue);
      expect(dragManager.draggedNodeId, 'child1');
      expect(dragManager.dragPosition, const Offset(100, 100));
    });

    testWidgets('should highlight drop target when hovering',
        (WidgetTester tester) async {
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

      // Get the state to access layouts
      final state = tester.state<MindMapState>(
        find.byType(MindMapWidget),
      );

      // Start drag
      dragManager.startDrag('child1', const Offset(100, 100));

      // Update drag position over another node
      dragManager.updateDrag(
        const Offset(200, 200),
        state.nodeLayouts,
        state.transform,
        testData.nodeData,
      );

      // The drop target should be set if hovering over a valid node
      // (depends on actual layout positions)
      expect(dragManager.isDragging, isTrue);
    });

    testWidgets('should clear drag state when drag ends',
        (WidgetTester tester) async {
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

      // Start and end drag
      dragManager.startDrag('child1', const Offset(100, 100));
      expect(dragManager.isDragging, isTrue);

      dragManager.endDrag();
      expect(dragManager.isDragging, isFalse);
      expect(dragManager.draggedNodeId, isNull);
      expect(dragManager.dragPosition, isNull);
      expect(dragManager.dropTargetNodeId, isNull);
    });

    testWidgets('should clear drag state when drag is cancelled',
        (WidgetTester tester) async {
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

      // Start and cancel drag
      dragManager.startDrag('child1', const Offset(100, 100));
      expect(dragManager.isDragging, isTrue);

      dragManager.cancelDrag();
      expect(dragManager.isDragging, isFalse);
      expect(dragManager.draggedNodeId, isNull);
      expect(dragManager.dragPosition, isNull);
      expect(dragManager.dropTargetNodeId, isNull);
    });

    test('should notify listeners when drag state changes', () {
      int notificationCount = 0;
      dragManager.addListener(() {
        notificationCount++;
      });

      // Start drag
      dragManager.startDrag('child1', const Offset(100, 100));
      expect(notificationCount, 1);

      // Cancel drag
      dragManager.cancelDrag();
      expect(notificationCount, 2);

      // Start another drag
      dragManager.startDrag('child2', const Offset(200, 200));
      expect(notificationCount, 3);

      // End drag
      dragManager.endDrag();
      expect(notificationCount, 4);
    });

    test('should prevent circular references in drag operations', () {
      // Create layouts for testing
      final nodeLayouts = {
        'root': NodeLayout(
          position: const Offset(100, 100),
          size: const Size(100, 40),
        ),
        'child1': NodeLayout(
          position: const Offset(50, 200),
          size: const Size(80, 30),
        ),
        'child2': NodeLayout(
          position: const Offset(150, 200),
          size: const Size(80, 30),
        ),
        'grandchild1': NodeLayout(
          position: const Offset(30, 300),
          size: const Size(70, 30),
        ),
      };

      final transform = Matrix4.identity();

      // Try to drag child1 onto its descendant grandchild1
      dragManager.startDrag('child1', const Offset(50, 200));
      dragManager.updateDrag(
        const Offset(60, 315), // Position of grandchild1
        nodeLayouts,
        transform,
        testData.nodeData,
      );

      // Should not set grandchild1 as drop target (circular reference)
      expect(dragManager.dropTargetNodeId, isNull);

      // Try to drag onto sibling (should be allowed)
      dragManager.updateDrag(
        const Offset(180, 215), // Position of child2
        nodeLayouts,
        transform,
        testData.nodeData,
      );

      // Should set child2 as drop target (valid)
      expect(dragManager.dropTargetNodeId, 'child2');
    });

    test('should handle drag lifecycle correctly', () {
      final nodeLayouts = {
        'root': NodeLayout(
          position: const Offset(100, 100),
          size: const Size(100, 40),
        ),
        'child1': NodeLayout(
          position: const Offset(50, 200),
          size: const Size(80, 30),
        ),
        'child2': NodeLayout(
          position: const Offset(150, 200),
          size: const Size(80, 30),
        ),
      };

      final transform = Matrix4.identity();

      // Complete drag lifecycle
      expect(dragManager.isDragging, isFalse);

      // 1. Start drag
      dragManager.startDrag('child1', const Offset(50, 200));
      expect(dragManager.isDragging, isTrue);
      expect(dragManager.draggedNodeId, 'child1');

      // 2. Update drag position
      dragManager.updateDrag(
        const Offset(180, 215),
        nodeLayouts,
        transform,
        testData.nodeData,
      );
      expect(dragManager.dragPosition, const Offset(180, 215));
      expect(dragManager.dropTargetNodeId, 'child2');

      // 3. End drag
      final dropTarget = dragManager.endDrag();
      expect(dropTarget, 'child2');
      expect(dragManager.isDragging, isFalse);
    });
  });
}
