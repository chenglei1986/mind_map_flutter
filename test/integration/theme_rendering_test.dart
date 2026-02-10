import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_widget.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_controller.dart';

/// Integration tests for theme rendering across all components
void main() {
  group('Theme Rendering Integration', () {
    testWidgets('should render with light theme initially', (tester) async {
      final rootNode = NodeData.create(topic: 'Root');
      final data = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              initialData: data,
            ),
          ),
        ),
      );

      // Verify widget renders
      expect(find.byType(MindMapWidget), findsOneWidget);
      
      // Verify background color matches light theme
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(MindMapWidget),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.color, MindMapTheme.light.variables.bgColor);
    });

    testWidgets('should switch theme at runtime without re-initialization', (tester) async {
      final rootNode = NodeData.create(topic: 'Root');
      final data = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
      
      final controller = MindMapController(initialData: data);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              initialData: data,
              controller: controller,
            ),
          ),
        ),
      );

      // Verify initial light theme
      Container container = tester.widget<Container>(
        find.descendant(
          of: find.byType(MindMapWidget),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.color, MindMapTheme.light.variables.bgColor);

      // Switch to dark theme
      controller.setTheme(MindMapTheme.dark);
      await tester.pump();

      // Verify dark theme is applied
      container = tester.widget<Container>(
        find.descendant(
          of: find.byType(MindMapWidget),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.color, MindMapTheme.dark.variables.bgColor);
    });

    testWidgets('should render nodes with theme colors after theme switch', (tester) async {
      final rootNode = NodeData.create(topic: 'Root')
          .addChild(NodeData.create(topic: 'Child 1'))
          .addChild(NodeData.create(topic: 'Child 2'));
      
      final data = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
      
      final controller = MindMapController(initialData: data);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              initialData: data,
              controller: controller,
            ),
          ),
        ),
      );

      // Initial render with light theme
      await tester.pump();

      // Switch to dark theme
      controller.setTheme(MindMapTheme.dark);
      await tester.pump();

      // Verify the widget re-rendered (CustomPaint should be present)
      expect(find.byType(CustomPaint), findsWidgets);
      
      // Verify theme is dark
      expect(controller.getTheme().name, 'dark');
    });

    testWidgets('should render arrows with theme colors after theme switch', (tester) async {
      final child1 = NodeData.create(topic: 'Child 1');
      final child2 = NodeData.create(topic: 'Child 2');
      final rootNode = NodeData.create(topic: 'Root')
          .addChild(child1)
          .addChild(child2);
      
      final data = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
      
      final controller = MindMapController(initialData: data);
      
      // Add an arrow
      controller.addArrow(
        fromNodeId: child1.id,
        toNodeId: child2.id,
        label: 'Test Arrow',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              initialData: data,
              controller: controller,
            ),
          ),
        ),
      );

      // Initial render with light theme
      await tester.pump();

      // Switch to dark theme
      controller.setTheme(MindMapTheme.dark);
      await tester.pump();

      // Verify arrow is still present
      expect(controller.getData().arrows.length, 1);
      expect(controller.getData().arrows[0].label, 'Test Arrow');
      
      // Verify theme is dark
      expect(controller.getTheme().name, 'dark');
    });

    testWidgets('should render summaries with theme colors after theme switch', (tester) async {
      final rootNode = NodeData.create(topic: 'Root')
          .addChild(NodeData.create(topic: 'Child 1'))
          .addChild(NodeData.create(topic: 'Child 2'))
          .addChild(NodeData.create(topic: 'Child 3'));
      
      final data = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
      
      final controller = MindMapController(initialData: data);
      
      // Add a summary
      controller.addSummary(
        parentNodeId: rootNode.id,
        startIndex: 0,
        endIndex: 2,
        label: 'Test Summary',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              initialData: data,
              controller: controller,
            ),
          ),
        ),
      );

      // Initial render with light theme
      await tester.pump();

      // Switch to dark theme
      controller.setTheme(MindMapTheme.dark);
      await tester.pump();

      // Verify summary is still present
      expect(controller.getData().summaries.length, 1);
      expect(controller.getData().summaries[0].label, 'Test Summary');
      
      // Verify theme is dark
      expect(controller.getTheme().name, 'dark');
    });

    testWidgets('should switch themes multiple times without issues', (tester) async {
      final rootNode = NodeData.create(topic: 'Root')
          .addChild(NodeData.create(topic: 'Child 1'))
          .addChild(NodeData.create(topic: 'Child 2'));
      
      final data = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
      
      final controller = MindMapController(initialData: data);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              initialData: data,
              controller: controller,
            ),
          ),
        ),
      );

      // Initial render
      await tester.pump();
      expect(controller.getTheme().name, 'light');

      // Switch to dark
      controller.setTheme(MindMapTheme.dark);
      await tester.pump();
      expect(controller.getTheme().name, 'dark');

      // Switch back to light
      controller.setTheme(MindMapTheme.light);
      await tester.pump();
      expect(controller.getTheme().name, 'light');

      // Switch to dark again
      controller.setTheme(MindMapTheme.dark);
      await tester.pump();
      expect(controller.getTheme().name, 'dark');

      // Verify widget is still functional
      expect(find.byType(MindMapWidget), findsOneWidget);
      expect(controller.getData().nodeData.children.length, 2);
    });

    testWidgets('should use custom theme colors', (tester) async {
      final customTheme = MindMapTheme.light.copyWith(
        name: 'custom',
        palette: [
          const Color(0xFFFF0000),
          const Color(0xFF00FF00),
          const Color(0xFF0000FF),
        ],
      );

      final rootNode = NodeData.create(topic: 'Root');
      final data = MindMapData(
        nodeData: rootNode,
        theme: customTheme,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MindMapWidget(
              initialData: data,
            ),
          ),
        ),
      );

      // Verify widget renders with custom theme
      expect(find.byType(MindMapWidget), findsOneWidget);
    });
  });
}
