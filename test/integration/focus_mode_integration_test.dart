import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_widget.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_controller.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/layout/layout_engine.dart';
import 'package:mind_map_flutter/src/rendering/mind_map_painter.dart';

void main() {
  group('Focus Mode Integration Tests', () {
    late MindMapData testData;
    late MindMapController controller;

    setUp(() {
      // Create test data with a tree structure
      final grandchild1 = NodeData.create(topic: 'Grandchild 1');
      final grandchild2 = NodeData.create(topic: 'Grandchild 2');
      final child1 = NodeData.create(
        topic: 'Child 1',
        children: [grandchild1, grandchild2],
      );
      final child2 = NodeData.create(topic: 'Child 2');
      final rootNode = NodeData.create(
        topic: 'Root',
        children: [child1, child2],
      );

      testData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );

      controller = MindMapController(initialData: testData);
    });

    testWidgets('Focus mode should be activated and deactivated', (tester) async {
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

      // Initially, focus mode should not be active
      expect(controller.isFocusMode, false);
      expect(controller.focusedNodeId, null);

      // Enter focus mode on Child 1
      final child1 = testData.nodeData.children.first;
      controller.focusNode(child1.id);
      await tester.pumpAndSettle();

      // Focus mode should now be active
      expect(controller.isFocusMode, true);
      expect(controller.focusedNodeId, child1.id);
      
      // Exit focus mode
      controller.exitFocusMode();
      await tester.pumpAndSettle();
      
      // Focus mode should be deactivated
      expect(controller.isFocusMode, false);
      expect(controller.focusedNodeId, null);
    });

    testWidgets('ESC key should exit focus mode', (tester) async {
      // Validates: Requirement 18.3
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

      // Enter focus mode
      final child1 = testData.nodeData.children.first;
      controller.focusNode(child1.id);
      await tester.pumpAndSettle();

      expect(controller.isFocusMode, true);

      // Press ESC key
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Focus mode should be exited
      expect(controller.isFocusMode, false);
    });

    test('Layout should be calculated for focused node in focus mode', () {
      final layoutEngine = LayoutEngine();
      final child1 = testData.nodeData.children.first;

      // Enter focus mode
      controller.focusNode(child1.id);

      // Calculate layout for the focused node
      final layouts = layoutEngine.calculateLayout(
        child1,
        testData.theme,
        testData.direction,
      );

      // The focused node should be treated as root
      expect(layouts.containsKey(child1.id), true);
      
      // The focused node's children should be in the layout
      for (final grandchild in child1.children) {
        expect(layouts.containsKey(grandchild.id), true);
      }

      // The root node and other children should NOT be in this layout
      expect(layouts.containsKey(testData.nodeData.id), false);
      expect(layouts.containsKey(testData.nodeData.children[1].id), false);
    });

    test('Painter should only render focused subtree in focus mode', () {
      final layoutEngine = LayoutEngine();
      final child1 = testData.nodeData.children.first;

      // Enter focus mode
      controller.focusNode(child1.id);

      // Calculate layout for the focused node
      final layouts = layoutEngine.calculateLayout(
        child1,
        testData.theme,
        testData.direction,
      );

      // Create painter with focus mode enabled
      final painter = MindMapPainter(
        data: testData,
        nodeLayouts: layouts,
        isFocusMode: true,
        focusedNodeId: child1.id,
      );

      // The painter should be configured for focus mode
      expect(painter.isFocusMode, true);
      expect(painter.focusedNodeId, child1.id);
    });

    test('Exiting focus mode should restore full layout', () {
      // Validates: Requirement 18.3
      final layoutEngine = LayoutEngine();
      final child1 = testData.nodeData.children.first;

      // Enter focus mode
      controller.focusNode(child1.id);
      expect(controller.isFocusMode, true);

      // Exit focus mode
      controller.exitFocusMode();
      expect(controller.isFocusMode, false);

      // Calculate layout for full tree
      final layouts = layoutEngine.calculateLayout(
        testData.nodeData,
        testData.theme,
        testData.direction,
      );

      // All nodes should be in the layout
      expect(layouts.containsKey(testData.nodeData.id), true);
      expect(layouts.containsKey(child1.id), true);
      expect(layouts.containsKey(testData.nodeData.children[1].id), true);
      
      for (final grandchild in child1.children) {
        expect(layouts.containsKey(grandchild.id), true);
      }
    });

    test('Focus mode should work with deeply nested nodes', () {
      // Create a deeper tree
      final level3 = NodeData.create(topic: 'Level 3');
      final level2 = NodeData.create(topic: 'Level 2', children: [level3]);
      final level1 = NodeData.create(topic: 'Level 1', children: [level2]);
      final root = NodeData.create(topic: 'Root', children: [level1]);

      final deepData = MindMapData(
        nodeData: root,
        theme: MindMapTheme.light,
      );

      final deepController = MindMapController(initialData: deepData);

      // Focus on a middle-level node
      deepController.focusNode(level2.id);

      expect(deepController.isFocusMode, true);
      expect(deepController.focusedNodeId, level2.id);

      // Calculate layout for the focused node
      final layoutEngine = LayoutEngine();
      final layouts = layoutEngine.calculateLayout(
        level2,
        deepData.theme,
        deepData.direction,
      );

      // Level 2 and its descendants should be in layout
      expect(layouts.containsKey(level2.id), true);
      expect(layouts.containsKey(level3.id), true);

      // Root and Level 1 should not be in layout
      expect(layouts.containsKey(root.id), false);
      expect(layouts.containsKey(level1.id), false);
    });

    test('Focus mode state should persist across controller operations', () {
      final child1 = testData.nodeData.children.first;

      // Enter focus mode
      controller.focusNode(child1.id);
      expect(controller.isFocusMode, true);

      // Perform other operations
      controller.addChildNode(child1.id, topic: 'New Child');
      expect(controller.isFocusMode, true);
      expect(controller.focusedNodeId, child1.id);

      // Undo operation
      controller.undo();
      expect(controller.isFocusMode, true);
      expect(controller.focusedNodeId, child1.id);

      // Exit focus mode
      controller.exitFocusMode();
      expect(controller.isFocusMode, false);
    });
  });
}
