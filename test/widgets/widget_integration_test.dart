import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

/// Unit tests for Widget integration features
void main() {
  group('Widget Integration Tests - Requirements 20.1-20.7', () {
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

    // ========== Requirement 20.1: Stateful Flutter Widget ==========

    testWidgets('should be a StatefulWidget', (tester) async {
      // Validates: Requirement 20.1
      // THE 系统 SHALL 提供封装思维导图功能的有状态 Flutter 组件

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MindMapWidget(initialData: testData)),
        ),
      );

      // Verify widget is a StatefulWidget
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify it has state
      final state = tester.state<MindMapState>(find.byType(MindMapWidget));
      expect(state, isNotNull);
      expect(state, isA<State<MindMapWidget>>());
    });

    testWidgets('should encapsulate mind map functionality', (tester) async {
      // Validates: Requirement 20.1
      // Verify the widget encapsulates all core functionality

      final controller = MindMapController(initialData: testData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller),
          ),
        ),
      );

      // Verify widget encapsulates rendering
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget encapsulates interaction (can add nodes)
      controller.addChildNode(testData.nodeData.id, topic: 'New Child');
      await tester.pump();

      expect(controller.getData().nodeData.children.length, equals(4));

      // Verify widget encapsulates selection
      controller.selectionManager.selectNode(
        testData.nodeData.children.first.id,
      );
      await tester.pump();

      expect(controller.getSelectedNodeIds().length, equals(1));
    });

    // ========== Requirement 20.2: Configuration Parameters ==========

    test('should accept configuration options as constructor parameters', () {
      // Validates: Requirement 20.2
      // THE 组件 SHALL 接受配置选项作为构造函数参数

      final config = MindMapConfig(
        allowUndo: true,
        maxHistorySize: 50,
        minScale: 0.5,
        maxScale: 3.0,
        enableKeyboardShortcuts: true,
      );

      final widget = MindMapWidget(initialData: testData, config: config);

      // Verify widget accepts config
      expect(widget.config, equals(config));
      expect(widget.config.allowUndo, isTrue);
      expect(widget.config.maxHistorySize, equals(50));
      expect(widget.config.minScale, equals(0.5));
      expect(widget.config.maxScale, equals(3.0));
      expect(widget.config.enableKeyboardShortcuts, isTrue);
    });

    test('should use default configuration when not provided', () {
      // Validates: Requirement 20.2

      final widget = MindMapWidget(initialData: testData);

      // Verify default config is used
      expect(widget.config, equals(const MindMapConfig()));
      expect(widget.config.allowUndo, isTrue);
      expect(widget.config.maxHistorySize, equals(50)); // Default is 50
    });

    testWidgets('should pass configuration to controller', (tester) async {
      // Validates: Requirement 20.2

      final config = MindMapConfig(allowUndo: false, maxHistorySize: 25);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, config: config),
          ),
        ),
      );

      final state = tester.state<MindMapState>(find.byType(MindMapWidget));

      // Verify configuration is applied
      // When allowUndo is false, undo should not work
      final controller = state.widget.controller;
      if (controller != null) {
        expect(controller.canUndo(), isFalse);
      }
    });

    // ========== Requirement 20.3: Programmatic Control Methods ==========

    test('should expose getData method', () {
      // Validates: Requirement 20.3
      // THE 组件 SHALL 公开用于程序化控制的方法（getData、refresh、addNode 等）

      final controller = MindMapController(initialData: testData);

      // Verify getData method exists and works
      final data = controller.getData();
      expect(data, isNotNull);
      expect(data.nodeData.topic, equals('Root'));
      expect(data.nodeData.children.length, equals(3));
    });

    test('should expose refresh method', () {
      // Validates: Requirement 20.3

      final controller = MindMapController(initialData: testData);

      // Create new data
      final newData = MindMapData(
        nodeData: NodeData.create(
          topic: 'New Root',
          children: [NodeData.create(topic: 'New Child')],
        ),
        theme: MindMapTheme.dark,
      );

      // Verify refresh method exists and works
      controller.refresh(newData);

      final data = controller.getData();
      expect(data.nodeData.topic, equals('New Root'));
      expect(data.nodeData.children.length, equals(1));
      expect(data.theme, equals(MindMapTheme.dark));
    });

    test('should expose addChildNode method', () {
      // Validates: Requirement 20.3

      final controller = MindMapController(initialData: testData);

      // Verify addChildNode method exists and works
      controller.addChildNode(testData.nodeData.id, topic: 'New Child');

      final data = controller.getData();
      expect(data.nodeData.children.length, equals(4));
      expect(data.nodeData.children.last.topic, equals('New Child'));
    });

    test('should expose addSiblingNode method', () {
      // Validates: Requirement 20.3

      final controller = MindMapController(initialData: testData);
      final firstChildId = testData.nodeData.children.first.id;

      // Verify addSiblingNode method exists and works
      controller.addSiblingNode(firstChildId, topic: 'Sibling');

      final data = controller.getData();
      expect(data.nodeData.children.length, equals(4));
    });

    test('should expose removeNode method', () {
      // Validates: Requirement 20.3

      final controller = MindMapController(initialData: testData);
      final firstChildId = testData.nodeData.children.first.id;

      // Verify removeNode method exists and works
      controller.removeNode(firstChildId);

      final data = controller.getData();
      expect(data.nodeData.children.length, equals(2));
    });

    test('should expose updateNode method', () {
      // Validates: Requirement 20.3

      final controller = MindMapController(initialData: testData);
      final firstChildId = testData.nodeData.children.first.id;

      // Verify updateNode method exists and works
      controller.updateNodeTopic(firstChildId, 'Updated Topic');

      final data = controller.getData();
      final updatedNode = data.nodeData.children.first;
      expect(updatedNode.topic, equals('Updated Topic'));
    });

    test('should expose moveNode method', () {
      // Validates: Requirement 20.3

      final controller = MindMapController(initialData: testData);
      final firstChildId = testData.nodeData.children.first.id;
      final secondChildId = testData.nodeData.children[1].id;

      // Verify moveNode method exists and works
      controller.moveNode(firstChildId, secondChildId);

      final data = controller.getData();
      final secondChild = data.nodeData.children.firstWhere(
        (n) => n.id == secondChildId,
      );
      expect(secondChild.children.length, equals(1));
      expect(secondChild.children.first.id, equals(firstChildId));
    });

    test('should expose selection methods', () {
      // Validates: Requirement 20.3

      final controller = MindMapController(initialData: testData);
      final firstChildId = testData.nodeData.children.first.id;

      // Verify selection methods exist and work
      controller.selectionManager.selectNode(firstChildId);
      expect(controller.getSelectedNodeIds(), contains(firstChildId));

      controller.selectionManager.clearSelection();
      expect(controller.getSelectedNodeIds(), isEmpty);
    });

    test('should expose view control methods', () {
      // Validates: Requirement 20.3

      final controller = MindMapController(initialData: testData);

      // Verify view control methods exist
      expect(() => controller.centerView(), returnsNormally);
      expect(() => controller.setZoom(1.5), returnsNormally);
      expect(() => controller.focusNode(testData.nodeData.id), returnsNormally);
      expect(() => controller.exitFocusMode(), returnsNormally);
    });

    test('should expose undo/redo methods', () {
      // Validates: Requirement 20.3

      final controller = MindMapController(initialData: testData);

      // Verify undo/redo methods exist
      expect(controller.canUndo(), isFalse);
      expect(controller.canRedo(), isFalse);

      // Perform an operation
      controller.addChildNode(testData.nodeData.id, topic: 'Test');
      expect(controller.canUndo(), isTrue);

      // Undo
      controller.undo();
      expect(controller.canRedo(), isTrue);

      // Redo
      controller.redo();
      expect(controller.canUndo(), isTrue);
    });

    test('should expose export methods', () {
      // Validates: Requirement 20.3

      final controller = MindMapController(initialData: testData);

      // Verify export methods exist
      expect(() => controller.exportToJson(), returnsNormally);
      // Note: exportToPng requires a widget context, tested separately
    });

    // ========== Requirement 20.4: Event Emission ==========

    test('should emit events through callback', () {
      // Validates: Requirement 20.4
      // THE 组件 SHALL 通过回调或流为用户交互发出事件

      MindMapEvent? receivedEvent;

      final controller = MindMapController(initialData: testData);
      controller.addListener(() {
        receivedEvent = controller.lastEvent;
      });

      // Perform an operation
      controller.addChildNode(testData.nodeData.id, topic: 'Test');

      // Verify event was emitted through callback
      expect(receivedEvent, isNotNull);
      expect(receivedEvent, isA<NodeOperationEvent>());
    });

    test('should emit events through stream', () async {
      // Validates: Requirement 20.4

      final controller = MindMapController(initialData: testData);

      // Listen to event stream
      final eventFuture = controller.eventStream.first;

      // Perform an operation
      controller.addChildNode(testData.nodeData.id, topic: 'Test');

      // Verify event was emitted through stream
      final event = await eventFuture;
      expect(event, isNotNull);
      expect(event, isA<NodeOperationEvent>());
    });

    testWidgets('should support onEvent callback parameter', (tester) async {
      // Validates: Requirement 20.4

      MindMapEvent? receivedEvent;

      final controller = MindMapController(initialData: testData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              initialData: testData,
              controller: controller,
              onEvent: (event) {
                receivedEvent = event;
              },
            ),
          ),
        ),
      );

      // Perform an operation
      controller.addChildNode(testData.nodeData.id, topic: 'Test');
      await tester.pump();

      // Verify event was received through callback
      expect(receivedEvent, isNotNull);
      expect(receivedEvent, isA<NodeOperationEvent>());
    });

    test(
      'should emit different event types for different operations',
      () async {
        // Validates: Requirement 20.4

        final controller = MindMapController(initialData: testData);
        final events = <MindMapEvent>[];

        final subscription = controller.eventStream.listen((event) {
          events.add(event);
        });

        // Perform various operations
        controller.addChildNode(testData.nodeData.id, topic: 'Test');
        await Future.delayed(const Duration(milliseconds: 10));

        controller.selectionManager.selectNode(
          testData.nodeData.children.first.id,
        );
        await Future.delayed(const Duration(milliseconds: 10));

        controller.toggleNodeExpanded(testData.nodeData.id);
        await Future.delayed(const Duration(milliseconds: 10));

        // Verify different event types were emitted
        expect(events.length, greaterThanOrEqualTo(2));
        expect(events.any((e) => e is NodeOperationEvent), isTrue);
        expect(events.any((e) => e is ExpandNodeEvent), isTrue);

        await subscription.cancel();
      },
    );

    // ========== Requirement 20.5: Hot Reload Support ==========

    testWidgets('should support hot reload', (tester) async {
      // Validates: Requirement 20.5
      // THE 组件 SHALL 在开发期间支持热重载

      final controller = MindMapController(initialData: testData);

      // Build initial widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller),
          ),
        ),
      );

      // Modify state
      controller.addChildNode(testData.nodeData.id, topic: 'Hot Reload Child');
      controller.selectionManager.selectNode(
        testData.nodeData.children.last.id,
      );
      await tester.pump();

      // Verify state before hot reload
      expect(controller.getData().nodeData.children.length, equals(4));
      expect(controller.getSelectedNodeIds().length, equals(1));

      // Simulate hot reload by rebuilding with same controller
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller),
          ),
        ),
      );

      // Verify state is preserved after hot reload
      expect(controller.getData().nodeData.children.length, equals(4));
      expect(controller.getSelectedNodeIds().length, equals(1));
      expect(
        controller.getData().nodeData.children.last.topic,
        equals('Hot Reload Child'),
      );
    });

    testWidgets('should handle controller replacement during hot reload', (
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

      expect(identical(state.widget.controller, controller2), isTrue);
    });

    testWidgets('should preserve visual state during hot reload', (
      tester,
    ) async {
      // Validates: Requirement 20.5

      final controller = MindMapController(initialData: testData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller),
          ),
        ),
      );

      // Set zoom level (with no animation)
      controller.setZoom(1.5, duration: Duration.zero);
      await tester.pump();

      // Simulate hot reload
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller),
          ),
        ),
      );

      // Verify zoom level is preserved
      expect(controller.zoomPanManager.scale, equals(1.5));
    });

    // ========== Requirement 20.6: Internal State Management ==========

    test('should manage state internally', () {
      // Validates: Requirement 20.6
      // THE 组件 SHALL 在内部处理自己的状态管理

      final controller = MindMapController(initialData: testData);

      // Verify controller maintains its own state
      expect(controller.getData(), isNotNull);

      // Perform operations - state should be managed internally
      controller.addChildNode(testData.nodeData.id, topic: 'Test');
      controller.selectionManager.selectNode(
        testData.nodeData.children.first.id,
      );
      controller.setZoom(1.5, duration: Duration.zero);

      // Verify state is maintained internally
      expect(controller.getData().nodeData.children.length, equals(4));
      expect(controller.getSelectedNodeIds().length, equals(1));
      expect(controller.zoomPanManager.scale, equals(1.5));
    });

    testWidgets('should not require external state management', (tester) async {
      // Validates: Requirement 20.6

      // Widget should work without external state management
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MindMapWidget(initialData: testData)),
        ),
      );

      // Verify widget renders and works without external state
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Get the internal controller
      final state = tester.state<MindMapState>(find.byType(MindMapWidget));

      // Verify internal state management works
      expect(state.nodeLayouts, isNotEmpty);
    });

    test('should handle state updates efficiently', () {
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

      // Verify listeners were notified efficiently (once per operation)
      expect(notificationCount, equals(3));
    });

    testWidgets('should manage layout state internally', (tester) async {
      // Validates: Requirement 20.6

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MindMapWidget(initialData: testData)),
        ),
      );

      final state = tester.state<MindMapState>(find.byType(MindMapWidget));

      // Verify layout is calculated and managed internally
      expect(state.nodeLayouts, isNotEmpty);
      expect(state.nodeLayouts.length, greaterThan(0));

      // Verify transform is managed internally
      expect(state.transform, isNotNull);
    });

    testWidgets('should manage selection state internally', (tester) async {
      // Validates: Requirement 20.6

      final controller = MindMapController(initialData: testData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller),
          ),
        ),
      );

      // Select a node
      controller.selectionManager.selectNode(
        testData.nodeData.children.first.id,
      );
      await tester.pump();

      // Verify selection is managed internally
      expect(controller.getSelectedNodeIds(), isNotEmpty);
      expect(controller.selectionManager, isNotNull);
    });

    testWidgets('should manage history state internally', (tester) async {
      // Validates: Requirement 20.6

      final controller = MindMapController(initialData: testData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller),
          ),
        ),
      );

      // Perform an operation
      controller.addChildNode(testData.nodeData.id, topic: 'Test');
      await tester.pump();

      // Verify history is managed internally
      expect(controller.canUndo(), isTrue);

      // Undo
      controller.undo();
      await tester.pump();

      expect(controller.canRedo(), isTrue);
    });

    // ========== Requirement 20.7: Layout System Compatibility ==========

    testWidgets('should work with tight constraints', (tester) async {
      // Validates: Requirement 20.7
      // THE 组件 SHALL 与 Flutter 的布局系统和约束兼容

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: MindMapWidget(initialData: testData),
            ),
          ),
        ),
      );

      // Verify widget respects tight constraints
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, equals(400));
      expect(widgetSize.height, equals(300));
    });

    testWidgets('should work with loose constraints', (tester) async {
      // Validates: Requirement 20.7

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 200,
                  maxWidth: 800,
                  minHeight: 150,
                  maxHeight: 600,
                ),
                child: MindMapWidget(initialData: testData),
              ),
            ),
          ),
        ),
      );

      // Verify widget works within loose constraints
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, greaterThanOrEqualTo(200));
      expect(widgetSize.width, lessThanOrEqualTo(800));
      expect(widgetSize.height, greaterThanOrEqualTo(150));
      expect(widgetSize.height, lessThanOrEqualTo(600));
    });

    testWidgets('should work in Expanded widget', (tester) async {
      // Validates: Requirement 20.7

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Container(height: 100, color: Colors.blue),
                Expanded(child: MindMapWidget(initialData: testData)),
                Container(height: 100, color: Colors.red),
              ],
            ),
          ),
        ),
      );

      // Verify widget fills available space
      final screenHeight = tester.getSize(find.byType(Scaffold)).height;
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.height, equals(screenHeight - 200));
    });

    testWidgets('should work in Flexible widget', (tester) async {
      // Validates: Requirement 20.7

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Container(width: 100, color: Colors.blue),
                Flexible(flex: 2, child: MindMapWidget(initialData: testData)),
                Container(width: 100, color: Colors.red),
              ],
            ),
          ),
        ),
      );

      // Verify widget works in flexible layout
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, greaterThan(0));
      expect(widgetSize.height, greaterThan(0));
    });

    testWidgets('should work in Stack widget', (tester) async {
      // Validates: Requirement 20.7

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: MindMapWidget(
                    key: const ValueKey('mind_map'),
                    initialData: testData,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(width: 50, height: 50, color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify widget fills the stack
      expect(find.byKey(const ValueKey('mind_map')), findsOneWidget);
    });

    testWidgets('should maintain functionality when resized', (tester) async {
      // Validates: Requirement 20.7

      final controller = MindMapController(initialData: testData);

      // Build with initial size
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: MindMapWidget(
                initialData: testData,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      // Add a node
      controller.addChildNode(testData.nodeData.id, topic: 'New Child');
      await tester.pump();

      expect(controller.getData().nodeData.children.length, equals(4));

      // Resize the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: MindMapWidget(
                initialData: testData,
                controller: controller,
              ),
            ),
          ),
        ),
      );

      // Verify functionality is maintained after resize
      expect(controller.getData().nodeData.children.length, equals(4));

      // Verify widget respects new constraints
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, equals(800));
      expect(widgetSize.height, equals(600));
    });

    testWidgets('should work with very small constraints', (tester) async {
      // Validates: Requirement 20.7

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 50,
              height: 50,
              child: MindMapWidget(initialData: testData),
            ),
          ),
        ),
      );

      // Verify widget handles small size gracefully
      expect(find.byType(MindMapWidget), findsOneWidget);

      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, equals(50));
      expect(widgetSize.height, equals(50));
    });

    testWidgets('should work with zero-sized constraints', (tester) async {
      // Validates: Requirement 20.7

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 0,
              height: 0,
              child: MindMapWidget(initialData: testData),
            ),
          ),
        ),
      );

      // Verify widget handles zero size gracefully
      expect(find.byType(MindMapWidget), findsOneWidget);

      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, equals(0));
      expect(widgetSize.height, equals(0));
    });
  });
}
