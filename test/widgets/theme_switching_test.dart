import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_controller.dart';

/// Tests for runtime theme switching functionality
/// 
void main() {
  group('Theme Switching', () {
    late MindMapController controller;
    late MindMapData initialData;

    setUp(() {
      // Create initial data with light theme
      final rootNode = NodeData.create(topic: 'Root');
      initialData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
      controller = MindMapController(initialData: initialData);
    });

    tearDown(() {
      controller.dispose();
    });

    test('should start with light theme', () {
      expect(controller.getTheme().name, 'light');
      expect(controller.getData().theme.name, 'light');
    });

    test('should switch to dark theme at runtime', () {
      // Switch to dark theme
      controller.setTheme(MindMapTheme.dark);

      // Verify theme changed
      expect(controller.getTheme().name, 'dark');
      expect(controller.getData().theme.name, 'dark');
      
      // Verify theme variables changed
      expect(
        controller.getTheme().variables.bgColor,
        MindMapTheme.dark.variables.bgColor,
      );
    });

    test('should switch back to light theme', () {
      // Switch to dark then back to light
      controller.setTheme(MindMapTheme.dark);
      controller.setTheme(MindMapTheme.light);

      // Verify theme changed back
      expect(controller.getTheme().name, 'light');
      expect(
        controller.getTheme().variables.bgColor,
        MindMapTheme.light.variables.bgColor,
      );
    });

    test('should notify listeners when theme changes', () {
      int notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      // Switch theme
      controller.setTheme(MindMapTheme.dark);

      // Verify listener was notified
      expect(notificationCount, 1);
    });

    test('should preserve node data when switching themes', () {
      // Add some nodes
      controller.addChildNode(initialData.nodeData.id, topic: 'Child 1');
      controller.addChildNode(initialData.nodeData.id, topic: 'Child 2');

      final nodeCountBefore = controller.getData().nodeData.children.length;

      // Switch theme
      controller.setTheme(MindMapTheme.dark);

      // Verify node data is preserved
      final nodeCountAfter = controller.getData().nodeData.children.length;
      expect(nodeCountAfter, nodeCountBefore);
      expect(nodeCountAfter, 2);
      expect(controller.getData().nodeData.children[0].topic, 'Child 1');
      expect(controller.getData().nodeData.children[1].topic, 'Child 2');
    });

    test('should preserve arrows when switching themes', () {
      // Add some nodes and an arrow
      controller.addChildNode(initialData.nodeData.id, topic: 'Child 1');
      controller.addChildNode(initialData.nodeData.id, topic: 'Child 2');
      
      final child1Id = controller.getData().nodeData.children[0].id;
      final child2Id = controller.getData().nodeData.children[1].id;
      
      controller.addArrow(
        fromNodeId: child1Id,
        toNodeId: child2Id,
        label: 'Test Arrow',
      );

      final arrowCountBefore = controller.getData().arrows.length;

      // Switch theme
      controller.setTheme(MindMapTheme.dark);

      // Verify arrows are preserved
      final arrowCountAfter = controller.getData().arrows.length;
      expect(arrowCountAfter, arrowCountBefore);
      expect(arrowCountAfter, 1);
      expect(controller.getData().arrows[0].label, 'Test Arrow');
    });

    test('should preserve summaries when switching themes', () {
      // Add some nodes and a summary
      controller.addChildNode(initialData.nodeData.id, topic: 'Child 1');
      controller.addChildNode(initialData.nodeData.id, topic: 'Child 2');
      controller.addChildNode(initialData.nodeData.id, topic: 'Child 3');
      
      controller.addSummary(
        parentNodeId: initialData.nodeData.id,
        startIndex: 0,
        endIndex: 2,
        label: 'Test Summary',
      );

      final summaryCountBefore = controller.getData().summaries.length;

      // Switch theme
      controller.setTheme(MindMapTheme.dark);

      // Verify summaries are preserved
      final summaryCountAfter = controller.getData().summaries.length;
      expect(summaryCountAfter, summaryCountBefore);
      expect(summaryCountAfter, 1);
      expect(controller.getData().summaries[0].label, 'Test Summary');
    });

    test('should use custom theme', () {
      // Create a custom theme
      final customTheme = MindMapTheme.light.copyWith(
        name: 'custom',
        palette: [
          const Color(0xFFFF0000),
          const Color(0xFF00FF00),
          const Color(0xFF0000FF),
        ],
      );

      // Apply custom theme
      controller.setTheme(customTheme);

      // Verify custom theme is applied
      expect(controller.getTheme().name, 'custom');
      expect(controller.getTheme().palette.length, 3);
      expect(controller.getTheme().palette[0], const Color(0xFFFF0000));
    });

    test('should switch themes multiple times', () {
      // Switch themes multiple times
      controller.setTheme(MindMapTheme.dark);
      expect(controller.getTheme().name, 'dark');

      controller.setTheme(MindMapTheme.light);
      expect(controller.getTheme().name, 'light');

      controller.setTheme(MindMapTheme.dark);
      expect(controller.getTheme().name, 'dark');

      controller.setTheme(MindMapTheme.light);
      expect(controller.getTheme().name, 'light');
    });
  });
}
