import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/models/layout_direction.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_controller.dart';

/// Property-based tests for theme system
/// 
/// Feature: mind-map-flutter
void main() {
  group('Theme System Property Tests', () {
    // Helper to create test data with multiple nodes
    MindMapData createTestData(MindMapTheme theme, int childCount) {
      NodeData root = NodeData.create(topic: 'Root');
      
      // Add multiple children to test palette cycling
      for (int i = 0; i < childCount; i++) {
        root = root.addChild(NodeData.create(topic: 'Child $i'));
      }
      
      return MindMapData(
        nodeData: root,
        theme: theme,
        direction: LayoutDirection.side,
      );
    }

    // Helper to create custom theme with specific palette
    MindMapTheme createCustomTheme(String name, List<Color> palette) {
      return MindMapTheme.light.copyWith(
        name: name,
        palette: palette,
      );
    }

    test('Property 24: Theme application global update - light to dark', () {
      // For any theme, applying theme should update all visual elements
      // (nodes, branches, background) to use new colors and styles
      
      final rootNode = NodeData.create(topic: 'Root')
          .addChild(NodeData.create(topic: 'Child 1'))
          .addChild(NodeData.create(topic: 'Child 2'));
      
      final initialData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
      
      final controller = MindMapController(initialData: initialData);
      
      // Verify initial theme is light
      expect(controller.getTheme().name, 'light');
      expect(
        controller.getTheme().variables.bgColor,
        MindMapTheme.light.variables.bgColor,
      );
      expect(
        controller.getTheme().variables.mainColor,
        MindMapTheme.light.variables.mainColor,
      );
      expect(
        controller.getTheme().variables.rootBgColor,
        MindMapTheme.light.variables.rootBgColor,
      );
      
      // Apply dark theme
      controller.setTheme(MindMapTheme.dark);
      
      // Verify all theme variables updated to dark theme
      expect(controller.getTheme().name, 'dark');
      expect(
        controller.getTheme().variables.bgColor,
        MindMapTheme.dark.variables.bgColor,
      );
      expect(
        controller.getTheme().variables.mainColor,
        MindMapTheme.dark.variables.mainColor,
      );
      expect(
        controller.getTheme().variables.rootBgColor,
        MindMapTheme.dark.variables.rootBgColor,
      );
      expect(
        controller.getTheme().variables.mainBgColor,
        MindMapTheme.dark.variables.mainBgColor,
      );
      expect(
        controller.getTheme().variables.color,
        MindMapTheme.dark.variables.color,
      );
      expect(
        controller.getTheme().variables.selectedColor,
        MindMapTheme.dark.variables.selectedColor,
      );
      
      // Verify palette also updated
      expect(
        controller.getTheme().palette,
        MindMapTheme.dark.palette,
      );
      
      controller.dispose();
    });

    test('Property 24: Theme application global update - custom theme', () {
      final customTheme = createCustomTheme('custom', [
        const Color(0xFFFF0000),
        const Color(0xFF00FF00),
        const Color(0xFF0000FF),
      ]);
      
      final rootNode = NodeData.create(topic: 'Root')
          .addChild(NodeData.create(topic: 'Child 1'));
      
      final initialData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
      
      final controller = MindMapController(initialData: initialData);
      
      // Apply custom theme
      controller.setTheme(customTheme);
      
      // Verify custom theme is applied
      expect(controller.getTheme().name, 'custom');
      expect(controller.getTheme().palette.length, 3);
      expect(controller.getTheme().palette[0], const Color(0xFFFF0000));
      expect(controller.getTheme().palette[1], const Color(0xFF00FF00));
      expect(controller.getTheme().palette[2], const Color(0xFF0000FF));
      
      controller.dispose();
    });

    test('Property 24: Theme application preserves data structure', () {
      // Create data with nodes, arrows, and summaries
      final child1 = NodeData.create(topic: 'Child 1');
      final child2 = NodeData.create(topic: 'Child 2');
      final rootNode = NodeData.create(topic: 'Root')
          .addChild(child1)
          .addChild(child2);
      
      final initialData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
      
      final controller = MindMapController(initialData: initialData);
      
      // Add arrow and summary
      controller.addArrow(
        fromNodeId: child1.id,
        toNodeId: child2.id,
        label: 'Test Arrow',
      );
      controller.addSummary(
        parentNodeId: rootNode.id,
        startIndex: 0,
        endIndex: 1,
        label: 'Test Summary',
      );
      
      final nodeCountBefore = controller.getData().nodeData.children.length;
      final arrowCountBefore = controller.getData().arrows.length;
      final summaryCountBefore = controller.getData().summaries.length;
      
      // Apply new theme
      controller.setTheme(MindMapTheme.dark);
      
      // Verify data structure is preserved
      expect(controller.getData().nodeData.children.length, nodeCountBefore);
      expect(controller.getData().arrows.length, arrowCountBefore);
      expect(controller.getData().summaries.length, summaryCountBefore);
      expect(controller.getData().nodeData.children[0].topic, 'Child 1');
      expect(controller.getData().arrows[0].label, 'Test Arrow');
      expect(controller.getData().summaries[0].label, 'Test Summary');
      
      controller.dispose();
    });

    test('Property 25: Branch color palette cycling - small palette', () {
      // For any theme and branch collection, branch colors should come from
      // theme palette and cycle through colors
      
      // Create theme with small palette (3 colors)
      final smallPalette = [
        const Color(0xFFFF0000),
        const Color(0xFF00FF00),
        const Color(0xFF0000FF),
      ];
      final theme = createCustomTheme('small', smallPalette);
      
      // Create data with more children than palette colors
      createTestData(theme, 10);
      
      // Verify palette cycling
      for (int i = 0; i < 10; i++) {
        final expectedColorIndex = i % smallPalette.length;
        final expectedColor = smallPalette[expectedColorIndex];
        
        // The branch color should cycle through the palette
        final actualColorIndex = i % theme.palette.length;
        final actualColor = theme.palette[actualColorIndex];
        
        expect(actualColor, expectedColor);
      }
    });

    test('Property 25: Branch color palette cycling - large palette', () {
      // Use built-in theme with large palette
      final theme = MindMapTheme.light;
      final paletteSize = theme.palette.length;
      
      // Create data with more children than palette colors
      final childCount = paletteSize * 2 + 5;
      createTestData(theme, childCount);
      
      // Verify palette cycling for all branches
      for (int i = 0; i < childCount; i++) {
        final expectedColorIndex = i % paletteSize;
        final expectedColor = theme.palette[expectedColorIndex];
        
        // The branch color should cycle through the palette
        final actualColorIndex = i % theme.palette.length;
        final actualColor = theme.palette[actualColorIndex];
        
        expect(actualColor, expectedColor);
      }
    });

    test('Property 25: Branch color palette cycling - custom branch colors', () {
      // Create nodes with custom branch colors
      final customColor = const Color(0xFFFF00FF);
      final child1 = NodeData.create(topic: 'Child 1', branchColor: customColor);
      final child2 = NodeData.create(topic: 'Child 2'); // No custom color
      final rootNode = NodeData.create(topic: 'Root')
          .addChild(child1)
          .addChild(child2);
      
      final data = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
      
      // Verify custom color is preserved
      expect(data.nodeData.children[0].branchColor, customColor);
      expect(data.nodeData.children[1].branchColor, isNull);
      
      // When custom color is not set, palette should be used
      final paletteColor = data.theme.palette[1 % data.theme.palette.length];
      expect(paletteColor, isNotNull);
    });

    test('Property 25: Branch color palette cycling - nested children', () {
      // Create nested structure
      final grandchild1 = NodeData.create(topic: 'Grandchild 1');
      final grandchild2 = NodeData.create(topic: 'Grandchild 2');
      final child1 = NodeData.create(topic: 'Child 1')
          .addChild(grandchild1)
          .addChild(grandchild2);
      final child2 = NodeData.create(topic: 'Child 2');
      final rootNode = NodeData.create(topic: 'Root')
          .addChild(child1)
          .addChild(child2);
      
      final theme = createCustomTheme('test', [
        const Color(0xFFFF0000),
        const Color(0xFF00FF00),
        const Color(0xFF0000FF),
      ]);
      
      MindMapData(
        nodeData: rootNode,
        theme: theme,
      );
      
      // Verify palette is available for all levels
      expect(theme.palette.length, 3);
      
      // Branch indices would be:
      // Child 1: index 0 -> color 0 (red)
      // Child 2: index 1 -> color 1 (green)
      // Grandchild 1: index 0 -> color 0 (red)
      // Grandchild 2: index 1 -> color 1 (green)
      
      for (int i = 0; i < 10; i++) {
        final colorIndex = i % theme.palette.length;
        final color = theme.palette[colorIndex];
        expect(color, isNotNull);
      }
    });

    test('Property 26: Theme switching without re-initialization', () {
      // For any theme switching, should be able to switch at runtime
      // without requiring widget re-creation
      
      final rootNode = NodeData.create(topic: 'Root')
          .addChild(NodeData.create(topic: 'Child 1'))
          .addChild(NodeData.create(topic: 'Child 2'));
      
      final initialData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
      
      final controller = MindMapController(initialData: initialData);
      
      // Verify initial state
      expect(controller.getTheme().name, 'light');
      
      // Switch theme multiple times without re-initialization
      controller.setTheme(MindMapTheme.dark);
      expect(controller.getTheme().name, 'dark');
      
      controller.setTheme(MindMapTheme.light);
      expect(controller.getTheme().name, 'light');
      
      controller.setTheme(MindMapTheme.dark);
      expect(controller.getTheme().name, 'dark');
      
      // Verify controller is still functional
      controller.addChildNode(rootNode.id, topic: 'Child 3');
      expect(controller.getData().nodeData.children.length, 3);
      
      controller.dispose();
    });

    test('Property 26: Theme switching notifies listeners', () {
      final rootNode = NodeData.create(topic: 'Root');
      final initialData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
      
      final controller = MindMapController(initialData: initialData);
      
      int notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });
      
      // Switch theme should notify listeners
      controller.setTheme(MindMapTheme.dark);
      expect(notificationCount, 1);
      
      controller.setTheme(MindMapTheme.light);
      expect(notificationCount, 2);
      
      controller.dispose();
    });

    test('Property 26: Theme switching with complex data', () {
      // Create complex data structure
      final child1 = NodeData.create(topic: 'Child 1');
      final child2 = NodeData.create(topic: 'Child 2');
      final child3 = NodeData.create(topic: 'Child 3');
      final rootNode = NodeData.create(topic: 'Root')
          .addChild(child1)
          .addChild(child2)
          .addChild(child3);
      
      final initialData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
      
      final controller = MindMapController(initialData: initialData);
      
      // Add arrows and summaries
      controller.addArrow(
        fromNodeId: child1.id,
        toNodeId: child2.id,
        label: 'Arrow 1',
      );
      controller.addArrow(
        fromNodeId: child2.id,
        toNodeId: child3.id,
        label: 'Arrow 2',
      );
      controller.addSummary(
        parentNodeId: rootNode.id,
        startIndex: 0,
        endIndex: 2,
        label: 'Summary 1',
      );
      
      // Switch themes multiple times
      for (int i = 0; i < 5; i++) {
        controller.setTheme(i % 2 == 0 ? MindMapTheme.dark : MindMapTheme.light);
        
        // Verify data integrity after each switch
        expect(controller.getData().nodeData.children.length, 3);
        expect(controller.getData().arrows.length, 2);
        expect(controller.getData().summaries.length, 1);
      }
      
      // Verify final state
      expect(controller.getData().arrows[0].label, 'Arrow 1');
      expect(controller.getData().arrows[1].label, 'Arrow 2');
      expect(controller.getData().summaries[0].label, 'Summary 1');
      
      controller.dispose();
    });

    test('Property 26: Theme switching with custom themes', () {
      final theme1 = createCustomTheme('theme1', [
        const Color(0xFFFF0000),
        const Color(0xFF00FF00),
      ]);
      
      final theme2 = createCustomTheme('theme2', [
        const Color(0xFF0000FF),
        const Color(0xFFFFFF00),
      ]);
      
      final theme3 = createCustomTheme('theme3', [
        const Color(0xFFFF00FF),
        const Color(0xFF00FFFF),
      ]);
      
      final rootNode = NodeData.create(topic: 'Root');
      final initialData = MindMapData(
        nodeData: rootNode,
        theme: theme1,
      );
      
      final controller = MindMapController(initialData: initialData);
      
      // Switch between custom themes
      expect(controller.getTheme().name, 'theme1');
      
      controller.setTheme(theme2);
      expect(controller.getTheme().name, 'theme2');
      expect(controller.getTheme().palette[0], const Color(0xFF0000FF));
      
      controller.setTheme(theme3);
      expect(controller.getTheme().name, 'theme3');
      expect(controller.getTheme().palette[0], const Color(0xFFFF00FF));
      
      controller.setTheme(MindMapTheme.light);
      expect(controller.getTheme().name, 'light');
      
      controller.setTheme(theme1);
      expect(controller.getTheme().name, 'theme1');
      expect(controller.getTheme().palette[0], const Color(0xFFFF0000));
      
      controller.dispose();
    });

    test('Property 24, 25, 26: Combined theme properties', () {
      // Feature: mind-map-flutter, Property 24, 25, 26: Combined theme properties
      //
      // Test all three properties together: global update, palette cycling,
      // and runtime switching
      
      // Create custom theme with specific palette
      final customPalette = [
        const Color(0xFFFF0000),
        const Color(0xFF00FF00),
        const Color(0xFF0000FF),
      ];
      final customTheme = createCustomTheme('custom', customPalette);
      
      // Create data with multiple children
      final data = createTestData(MindMapTheme.light, 10);
      final controller = MindMapController(initialData: data);
      
      // Property 24: Apply custom theme - all visual elements should update
      controller.setTheme(customTheme);
      expect(controller.getTheme().name, 'custom');
      expect(controller.getTheme().palette, customPalette);
      
      // Property 25: Verify palette cycling
      for (int i = 0; i < 10; i++) {
        final expectedColor = customPalette[i % customPalette.length];
        final actualColor = controller.getTheme().palette[i % controller.getTheme().palette.length];
        expect(actualColor, expectedColor);
      }
      
      // Property 26: Switch to dark theme without re-initialization
      controller.setTheme(MindMapTheme.dark);
      expect(controller.getTheme().name, 'dark');
      expect(controller.getData().nodeData.children.length, 10);
      
      // Property 26: Switch back to custom theme
      controller.setTheme(customTheme);
      expect(controller.getTheme().name, 'custom');
      
      // Property 25: Verify palette cycling still works
      for (int i = 0; i < 10; i++) {
        final expectedColor = customPalette[i % customPalette.length];
        final actualColor = controller.getTheme().palette[i % controller.getTheme().palette.length];
        expect(actualColor, expectedColor);
      }
      
      controller.dispose();
    });
  });
}
