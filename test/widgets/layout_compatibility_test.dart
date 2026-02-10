import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

/// Tests for layout compatibility with Flutter's layout system
///
/// Validates: Requirement 20.7
/// THE 组件 SHALL 与 Flutter 的布局系统和约束兼容
void main() {
  group('Layout Compatibility Tests', () {
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

    testWidgets('should work with tight constraints', (tester) async {
      // Validates: Requirement 20.7
      // Test that the widget works with exact size constraints

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

      // Verify widget renders without errors
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget respects the tight constraints
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, equals(400));
      expect(widgetSize.height, equals(300));
    });

    testWidgets('should work with loose constraints', (tester) async {
      // Validates: Requirement 20.7
      // Test that the widget works with flexible size constraints

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

      // Verify widget renders without errors
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget size is within constraints
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, greaterThanOrEqualTo(200));
      expect(widgetSize.width, lessThanOrEqualTo(800));
      expect(widgetSize.height, greaterThanOrEqualTo(150));
      expect(widgetSize.height, lessThanOrEqualTo(600));
    });

    testWidgets('should work with unbounded width constraints', (tester) async {
      // Validates: Requirement 20.7
      // Test that the widget works when placed in a horizontally scrollable container
      // Note: Widget needs explicit width when in unbounded horizontal constraints

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1000, // Provide explicit width for unbounded horizontal
                height: 400,
                child: MindMapWidget(initialData: testData),
              ),
            ),
          ),
        ),
      );

      // Verify widget renders without errors
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget has the specified dimensions
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, equals(1000));
      expect(widgetSize.height, equals(400));
    });

    testWidgets('should work with unbounded height constraints', (
      tester,
    ) async {
      // Validates: Requirement 20.7
      // Test that the widget works when placed in a vertically scrollable container
      // Note: Widget needs explicit height when in unbounded vertical constraints

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SizedBox(
                width: 600,
                height: 800, // Provide explicit height for unbounded vertical
                child: MindMapWidget(initialData: testData),
              ),
            ),
          ),
        ),
      );

      // Verify widget renders without errors
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget has the specified dimensions
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, equals(600));
      expect(widgetSize.height, equals(800));
    });

    testWidgets('should work in Expanded widget', (tester) async {
      // Validates: Requirement 20.7
      // Test that the widget works when placed in an Expanded widget

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

      // Verify widget renders without errors
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget fills the available space
      final screenHeight = tester.getSize(find.byType(Scaffold)).height;
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(
        widgetSize.height,
        equals(screenHeight - 200),
      ); // Screen height minus the two 100px containers
    });

    testWidgets('should work in Flexible widget', (tester) async {
      // Validates: Requirement 20.7
      // Test that the widget works when placed in a Flexible widget

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

      // Verify widget renders without errors
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget has a reasonable size
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, greaterThan(0));
      expect(widgetSize.height, greaterThan(0));
    });

    testWidgets('should work in Stack widget', (tester) async {
      // Validates: Requirement 20.7
      // Test that the widget works when placed in a Stack

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              key: const ValueKey('test_stack'),
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

      // Verify widget renders without errors
      expect(find.byKey(const ValueKey('mind_map')), findsOneWidget);

      // Verify widget fills the stack
      final stackSize = tester.getSize(
        find.byKey(const ValueKey('test_stack')),
      );
      final widgetSize = tester.getSize(find.byKey(const ValueKey('mind_map')));
      expect(widgetSize, equals(stackSize));
    });

    testWidgets('should work with AspectRatio widget', (tester) async {
      // Validates: Requirement 20.7
      // Test that the widget works when constrained by aspect ratio

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: MindMapWidget(initialData: testData),
              ),
            ),
          ),
        ),
      );

      // Verify widget renders without errors
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget respects aspect ratio
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      final aspectRatio = widgetSize.width / widgetSize.height;
      expect(aspectRatio, closeTo(16 / 9, 0.01));
    });

    testWidgets('should work with FractionallySizedBox', (tester) async {
      // Validates: Requirement 20.7
      // Test that the widget works when sized as a fraction of parent

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FractionallySizedBox(
              widthFactor: 0.8,
              heightFactor: 0.6,
              child: MindMapWidget(initialData: testData),
            ),
          ),
        ),
      );

      // Verify widget renders without errors
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget is sized correctly
      final screenSize = tester.getSize(find.byType(Scaffold));
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, closeTo(screenSize.width * 0.8, 1.0));
      expect(widgetSize.height, closeTo(screenSize.height * 0.6, 1.0));
    });

    testWidgets('should work with ConstrainedBox', (tester) async {
      // Validates: Requirement 20.7
      // Test that the widget works with explicit constraints

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 300,
                  maxWidth: 500,
                  minHeight: 200,
                  maxHeight: 400,
                ),
                child: MindMapWidget(initialData: testData),
              ),
            ),
          ),
        ),
      );

      // Verify widget renders without errors
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget respects constraints
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, greaterThanOrEqualTo(300));
      expect(widgetSize.width, lessThanOrEqualTo(500));
      expect(widgetSize.height, greaterThanOrEqualTo(200));
      expect(widgetSize.height, lessThanOrEqualTo(400));
    });

    testWidgets('should work in nested layout widgets', (tester) async {
      // Validates: Requirement 20.7
      // Test that the widget works in complex nested layouts

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Container(color: Colors.blue)),
                      Expanded(
                        flex: 3,
                        child: MindMapWidget(initialData: testData),
                      ),
                    ],
                  ),
                ),
                Container(height: 100, color: Colors.red),
              ],
            ),
          ),
        ),
      );

      // Verify widget renders without errors
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget has a reasonable size
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, greaterThan(0));
      expect(widgetSize.height, greaterThan(0));
    });

    testWidgets('should work with very small constraints', (tester) async {
      // Validates: Requirement 20.7
      // Test edge case: very small size

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

      // Verify widget renders without errors even with very small size
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget respects the small constraints
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, equals(50));
      expect(widgetSize.height, equals(50));
    });

    testWidgets('should work with very large constraints', (tester) async {
      // Validates: Requirement 20.7
      // Test edge case: very large size
      // Note: Test environment limits actual rendered size, but widget should handle large constraints

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 2000,
              height: 1500,
              child: MindMapWidget(initialData: testData),
            ),
          ),
        ),
      );

      // Verify widget renders without errors even with very large size
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget accepts the large constraints (may be limited by test environment)
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      // In test environment, size may be limited to screen size (800x600 default)
      // The important thing is that it doesn't crash and renders successfully
      expect(widgetSize.width, greaterThan(0));
      expect(widgetSize.height, greaterThan(0));
    });

    testWidgets('should work with zero-sized constraints', (tester) async {
      // Validates: Requirement 20.7
      // Test edge case: zero size (should handle gracefully)

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

      // Verify widget renders without errors even with zero size
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget respects the zero constraints
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, equals(0));
      expect(widgetSize.height, equals(0));
    });

    testWidgets('should maintain functionality when resized', (tester) async {
      // Validates: Requirement 20.7
      // Test that the widget maintains functionality when constraints change

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

      // Verify initial render
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Add a node
      controller.addChildNode(testData.nodeData.id, topic: 'New Child');
      await tester.pump();

      // Verify node was added
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

      // Verify widget still works after resize
      expect(find.byType(MindMapWidget), findsOneWidget);
      expect(controller.getData().nodeData.children.length, equals(4));

      // Verify widget respects new constraints
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, equals(800));
      expect(widgetSize.height, equals(600));
    });

    testWidgets('should work in TabBarView', (tester) async {
      // Validates: Requirement 20.7
      // Test that the widget works in a TabBarView (common use case)

      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Tab 1'),
                    Tab(text: 'Tab 2'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  MindMapWidget(initialData: testData),
                  Container(color: Colors.blue),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify widget renders without errors in TabBarView
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget has a reasonable size
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, greaterThan(0));
      expect(widgetSize.height, greaterThan(0));
    });

    testWidgets('should work in PageView', (tester) async {
      // Validates: Requirement 20.7
      // Test that the widget works in a PageView (common use case)

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageView(
              children: [
                MindMapWidget(initialData: testData),
                Container(color: Colors.blue),
                Container(color: Colors.red),
              ],
            ),
          ),
        ),
      );

      // Verify widget renders without errors in PageView
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget fills the page
      final pageSize = tester.getSize(find.byType(PageView));
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize, equals(pageSize));
    });

    testWidgets('should work in ListView', (tester) async {
      // Validates: Requirement 20.7
      // Test that the widget works in a ListView

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                Container(height: 100, color: Colors.blue),
                SizedBox(
                  height: 400,
                  child: MindMapWidget(initialData: testData),
                ),
                Container(height: 100, color: Colors.red),
              ],
            ),
          ),
        ),
      );

      // Verify widget renders without errors in ListView
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget has the specified height
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.height, equals(400));
    });

    testWidgets('should handle orientation changes', (tester) async {
      // Validates: Requirement 20.7
      // Test that the widget adapts to orientation changes

      final controller = MindMapController(initialData: testData);

      // Build in portrait mode
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller),
          ),
        ),
      );

      // Verify widget renders in portrait
      expect(find.byType(MindMapWidget), findsOneWidget);
      final portraitSize = tester.getSize(find.byType(MindMapWidget));
      expect(portraitSize.width, lessThan(portraitSize.height));

      // Change to landscape mode
      tester.view.physicalSize = const Size(1200, 800);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(initialData: testData, controller: controller),
          ),
        ),
      );

      // Verify widget adapts to landscape
      expect(find.byType(MindMapWidget), findsOneWidget);
      final landscapeSize = tester.getSize(find.byType(MindMapWidget));
      expect(landscapeSize.width, greaterThan(landscapeSize.height));

      // Clean up
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('Layout Edge Cases', () {
    late MindMapData testData;

    setUp(() {
      testData = MindMapData(
        nodeData: NodeData.create(
          topic: 'Root',
          children: [NodeData.create(topic: 'Child 1')],
        ),
        theme: MindMapTheme.light,
      );
    });

    testWidgets('should handle rapid constraint changes', (tester) async {
      // Validates: Requirement 20.7
      // Test that the widget handles rapid size changes gracefully

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

      // Rapidly change sizes
      for (int i = 0; i < 5; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400 + i * 100,
                height: 300 + i * 50,
                child: MindMapWidget(
                  initialData: testData,
                  controller: controller,
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Verify widget still works
      expect(find.byType(MindMapWidget), findsOneWidget);
      expect(controller.getData().nodeData.children.length, equals(1));
    });

    testWidgets('should handle constraints with decimal values', (
      tester,
    ) async {
      // Validates: Requirement 20.7
      // Test that the widget handles non-integer constraints

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 399.7,
              height: 299.3,
              child: MindMapWidget(initialData: testData),
            ),
          ),
        ),
      );

      // Verify widget renders without errors
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget respects the decimal constraints
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, closeTo(399.7, 0.1));
      expect(widgetSize.height, closeTo(299.3, 0.1));
    });

    testWidgets('should work with IntrinsicHeight and IntrinsicWidth', (
      tester,
    ) async {
      // Validates: Requirement 20.7
      // Test that the widget works with intrinsic size widgets

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: IntrinsicHeight(
                child: IntrinsicWidth(
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 300,
                      minHeight: 200,
                    ),
                    child: MindMapWidget(initialData: testData),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Verify widget renders without errors
      expect(find.byType(MindMapWidget), findsOneWidget);

      // Verify widget has a reasonable size
      final widgetSize = tester.getSize(find.byType(MindMapWidget));
      expect(widgetSize.width, greaterThanOrEqualTo(300));
      expect(widgetSize.height, greaterThanOrEqualTo(200));
    });
  });
}
