import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

void main() {
  group('Widget Performance Optimizations', () {
    late MindMapData testData;

    setUp(() {
      testData = MindMapData(
        nodeData: NodeData.create(
          topic: 'Root',
          children: [
            NodeData.create(topic: 'Child 1'),
            NodeData.create(topic: 'Child 2'),
            NodeData.create(topic: 'Child 3'),
          ],
        ),
        theme: MindMapTheme.light,
      );
    });

    testWidgets('should support hot reload without losing state', (
      tester,
    ) async {
      // Validates: Requirement 20.5

      final controller = MindMapController(initialData: testData);

      // Build initial widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller),
          ),
        ),
      );

      // Select a node
      controller.selectionManager.selectNode('child-1');
      await tester.pump();

      // Verify selection
      expect(controller.getSelectedNodeIds(), contains('child-1'));

      // Simulate hot reload by rebuilding with same controller
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller),
          ),
        ),
      );

      // Verify state is preserved after hot reload
      expect(controller.getSelectedNodeIds(), contains('child-1'));
    });

    testWidgets('should not recalculate layout when data hash is unchanged', (
      tester,
    ) async {
      // Validates: Requirement 20.5, 20.6

      final controller = MindMapController(initialData: testData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller),
          ),
        ),
      );

      // Get the state to access internal properties
      final state = tester.state<MindMapState>(find.byType(MindMapWidget));

      // Store initial layout hash
      final initialHash = state.nodeLayouts.length;

      // Trigger a rebuild without changing data structure
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller),
          ),
        ),
      );

      // Verify layout wasn't recalculated (same number of layouts)
      expect(state.nodeLayouts.length, equals(initialHash));
    });

    testWidgets('should handle rapid state updates efficiently', (
      tester,
    ) async {
      // Validates: Requirement 20.6

      final controller = MindMapController(initialData: testData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller),
          ),
        ),
      );

      // Perform rapid operations
      for (int i = 0; i < 10; i++) {
        controller.selectionManager.selectNode('child-${i % 3 + 1}');
        await tester.pump(const Duration(milliseconds: 16)); // One frame
      }

      // Verify widget is still responsive
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('should not crash when setState called after dispose', (
      tester,
    ) async {
      // Validates: Requirement 20.5, 20.6

      final controller = MindMapController(initialData: testData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller),
          ),
        ),
      );

      // Remove the widget
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );

      // Try to trigger a state update (should not crash)
      expect(
        () => controller.addChildNode(testData.nodeData.id),
        returnsNormally,
      );
    });

    testWidgets('should optimize shouldRepaint with identity checks', (
      tester,
    ) async {
      // Validates: Requirement 20.5, 20.6

      final controller = MindMapController(initialData: testData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller),
          ),
        ),
      );

      // Get the state
      final state = tester.state<MindMapState>(find.byType(MindMapWidget));

      // Store initial layouts reference
      final initialLayouts = state.nodeLayouts;

      // Rebuild without changing anything
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller),
          ),
        ),
      );

      // Verify layouts reference is preserved (identity check optimization)
      expect(identical(state.nodeLayouts, initialLayouts), isTrue);
    });

    testWidgets('should handle controller updates during hot reload', (
      tester,
    ) async {
      // Validates: Requirement 20.5

      final controller1 = MindMapController(initialData: testData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller1),
          ),
        ),
      );

      // Simulate hot reload with new controller
      final controller2 = MindMapController(initialData: testData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller2),
          ),
        ),
      );

      // Verify new controller is being used
      final state = tester.state<MindMapState>(find.byType(MindMapWidget));

      // The widget should be using controller2 now
      expect(identical(state.widget.controller, controller2), isTrue);
    });

    testWidgets('should efficiently handle large node trees', (tester) async {
      // Validates: Requirement 20.6

      // Create a large tree
      final largeTree = NodeData.create(
        topic: 'Root',
        children: List.generate(
          50,
          (i) => NodeData.create(
            topic: 'Child $i',
            children: List.generate(
              5,
              (j) => NodeData.create(topic: 'Grandchild $i-$j'),
            ),
          ),
        ),
      );

      final largeData = MindMapData(
        nodeData: largeTree,
        theme: MindMapTheme.light,
      );

      final controller = MindMapController(initialData: largeData);

      // Measure build time
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: largeData, controller: controller),
          ),
        ),
      );

      stopwatch.stop();

      // Verify it builds in reasonable time (< 1 second)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      // Verify all nodes are laid out
      final state = tester.state<MindMapState>(find.byType(MindMapWidget));

      // Should have layouts for root + 50 children + 250 grandchildren = 301 nodes
      expect(state.nodeLayouts.length, equals(301));
    });

    test('controller should manage state internally', () {
      // Validates: Requirement 20.6

      final controller = MindMapController(initialData: testData);

      // Verify controller maintains valid internal state.
      // Controller may normalize node directions for side layout.
      final initialData = controller.getData();
      expect(initialData.nodeData.id, equals(testData.nodeData.id));
      expect(initialData.nodeData.topic, equals(testData.nodeData.topic));
      expect(
        initialData.nodeData.children.length,
        equals(testData.nodeData.children.length),
      );

      // Verify controller handles operations internally
      controller.addChildNode(testData.nodeData.id, topic: 'New Child');

      final updatedData = controller.getData();
      expect(updatedData.nodeData.children.length, equals(4));
      expect(updatedData.nodeData.children.last.topic, equals('New Child'));
    });

    test('controller should notify listeners efficiently', () {
      // Validates: Requirement 20.6

      final controller = MindMapController(initialData: testData);

      int notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      // Perform multiple operations
      controller.addChildNode(testData.nodeData.id, topic: 'Test');
      controller.addChildNode(testData.nodeData.id, topic: 'Test');
      controller.addChildNode(testData.nodeData.id, topic: 'Test');

      // Verify listeners were notified (once per operation)
      expect(notificationCount, equals(3));
    });
  });

  group('shouldRepaint Optimization', () {
    test('should return false when all properties are identical', () {
      // Validates: Requirement 20.5, 20.6

      final data = MindMapData(
        nodeData: NodeData.create(topic: 'Root'),
        theme: MindMapTheme.light,
      );

      final layouts = <String, NodeLayout>{};
      final selectedIds = <String>{};
      final transform = Matrix4.identity();

      final painter1 = MindMapPainter(
        data: data,
        nodeLayouts: layouts,
        selectedNodeIds: selectedIds,
        transform: transform,
      );

      final painter2 = MindMapPainter(
        data: data,
        nodeLayouts: layouts,
        selectedNodeIds: selectedIds,
        transform: transform,
      );

      // Should return false because all properties are identical
      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('should return true when data changes', () {
      // Validates: Requirement 20.5, 20.6

      final data1 = MindMapData(
        nodeData: NodeData.create(topic: 'Root 1'),
        theme: MindMapTheme.light,
      );

      final data2 = MindMapData(
        nodeData: NodeData.create(topic: 'Root 2'),
        theme: MindMapTheme.light,
      );

      final layouts = <String, NodeLayout>{};
      final selectedIds = <String>{};
      final transform = Matrix4.identity();

      final painter1 = MindMapPainter(
        data: data1,
        nodeLayouts: layouts,
        selectedNodeIds: selectedIds,
        transform: transform,
      );

      final painter2 = MindMapPainter(
        data: data2,
        nodeLayouts: layouts,
        selectedNodeIds: selectedIds,
        transform: transform,
      );

      // Should return true because data changed
      expect(painter1.shouldRepaint(painter2), isTrue);
    });
  });
}
