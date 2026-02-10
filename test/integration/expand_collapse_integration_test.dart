import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/layout/layout_engine.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_controller.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_widget.dart';

void main() {
  group('Expand/Collapse Integration Tests', () {
    late MindMapController controller;
    late LayoutEngine layoutEngine;
    late NodeData rootNode;
    late NodeData childNode;
    late NodeData grandchildNode;

    setUp(() {
      layoutEngine = LayoutEngine();

      // Create a test tree structure
      grandchildNode = NodeData.create(
        id: 'grandchild-1',
        topic: 'Grandchild 1',
        expanded: true,
      );

      childNode = NodeData.create(
        id: 'child-1',
        topic: 'Child 1',
        expanded: true,
        children: [grandchildNode],
      );

      rootNode = NodeData.create(
        id: 'root',
        topic: 'Root',
        expanded: true,
        children: [childNode],
      );

      final data = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );

      controller = MindMapController(initialData: data);
    });

    tearDown(() {
      controller.dispose();
    });

    test('should recalculate layout when node is collapsed', () {
      // Initial layout should include all nodes
      final initialData = controller.getData();
      final initialLayouts = layoutEngine.calculateLayout(
        initialData.nodeData,
        initialData.theme,
        initialData.direction,
      );

      expect(initialLayouts.length, 3); // root, child, grandchild
      expect(initialLayouts.containsKey(rootNode.id), isTrue);
      expect(initialLayouts.containsKey(childNode.id), isTrue);
      expect(initialLayouts.containsKey(grandchildNode.id), isTrue);

      // Collapse the child node
      controller.collapseNode('child-1');

      // Recalculate layout
      final updatedData = controller.getData();
      final updatedLayouts = layoutEngine.calculateLayout(
        updatedData.nodeData,
        updatedData.theme,
        updatedData.direction,
      );

      // Layout should only include root and child (grandchild is hidden)
      expect(updatedLayouts.length, 2);
      expect(updatedLayouts.containsKey(rootNode.id), isTrue);
      expect(updatedLayouts.containsKey(childNode.id), isTrue);
      expect(updatedLayouts.containsKey(grandchildNode.id), isFalse);
    });

    test('should recalculate layout when node is expanded', () {
      // First collapse the child node
      controller.collapseNode('child-1');

      final collapsedData = controller.getData();
      final collapsedLayouts = layoutEngine.calculateLayout(
        collapsedData.nodeData,
        collapsedData.theme,
        collapsedData.direction,
      );

      expect(collapsedLayouts.length, 2); // root and child only

      // Expand the child node
      controller.expandNode('child-1');

      // Recalculate layout
      final expandedData = controller.getData();
      final expandedLayouts = layoutEngine.calculateLayout(
        expandedData.nodeData,
        expandedData.theme,
        expandedData.direction,
      );

      // Layout should include all nodes again
      expect(expandedLayouts.length, 3);
      expect(expandedLayouts.containsKey(rootNode.id), isTrue);
      expect(expandedLayouts.containsKey(childNode.id), isTrue);
      expect(expandedLayouts.containsKey(grandchildNode.id), isTrue);
    });

    test('should emit expandNode event and trigger layout recalculation', () {
      ExpandNodeEvent? emittedEvent;
      bool listenerCalled = false;

      controller.addListener(() {
        listenerCalled = true;
        final event = controller.lastEvent;
        if (event is ExpandNodeEvent) {
          emittedEvent = event;
        }
      });

      // Toggle the node
      controller.toggleNodeExpanded('child-1');

      // Verify event was emitted
      expect(listenerCalled, isTrue);
      expect(emittedEvent, isNotNull);
      expect(emittedEvent!.nodeId, 'child-1');
      expect(emittedEvent!.expanded, false);

      // Verify layout would be recalculated (listener was called)
      final updatedData = controller.getData();
      final updatedLayouts = layoutEngine.calculateLayout(
        updatedData.nodeData,
        updatedData.theme,
        updatedData.direction,
      );

      // Grandchild should not be in layout
      expect(updatedLayouts.containsKey(grandchildNode.id), isFalse);
    });

    test('should handle multiple collapse/expand cycles correctly', () {
      // Cycle 1: Collapse
      controller.collapseNode('child-1');
      var data = controller.getData();
      var layouts = layoutEngine.calculateLayout(
        data.nodeData,
        data.theme,
        data.direction,
      );
      expect(layouts.length, 2);

      // Cycle 2: Expand
      controller.expandNode('child-1');
      data = controller.getData();
      layouts = layoutEngine.calculateLayout(
        data.nodeData,
        data.theme,
        data.direction,
      );
      expect(layouts.length, 3);

      // Cycle 3: Collapse again
      controller.collapseNode('child-1');
      data = controller.getData();
      layouts = layoutEngine.calculateLayout(
        data.nodeData,
        data.theme,
        data.direction,
      );
      expect(layouts.length, 2);

      // Cycle 4: Expand again
      controller.expandNode('child-1');
      data = controller.getData();
      layouts = layoutEngine.calculateLayout(
        data.nodeData,
        data.theme,
        data.direction,
      );
      expect(layouts.length, 3);
    });

    test('should preserve node data through collapse/expand cycles', () {
      // Get original grandchild data
      final originalGrandchild = controller.getData()
          .nodeData
          .children
          .first
          .children
          .first;

      // Collapse and expand
      controller.collapseNode('child-1');
      controller.expandNode('child-1');

      // Get grandchild data after cycle
      final afterCycleGrandchild = controller.getData()
          .nodeData
          .children
          .first
          .children
          .first;

      // Data should be preserved
      expect(afterCycleGrandchild.id, originalGrandchild.id);
      expect(afterCycleGrandchild.topic, originalGrandchild.topic);
      expect(afterCycleGrandchild.expanded, originalGrandchild.expanded);
    });

    test('should handle collapsing root node', () {
      // Collapse root
      controller.collapseNode('root');

      final data = controller.getData();
      final layouts = layoutEngine.calculateLayout(
        data.nodeData,
        data.theme,
        data.direction,
      );

      // Only root should be in layout
      expect(layouts.length, 1);
      expect(layouts.containsKey(rootNode.id), isTrue);
      expect(layouts.containsKey(childNode.id), isFalse);
      expect(layouts.containsKey(grandchildNode.id), isFalse);
    });

    test('should handle nested collapse correctly', () {
      // Add another level
      final greatGrandchild = NodeData.create(
        id: 'great-grandchild-1',
        topic: 'Great Grandchild 1',
      );
      
      final updatedGrandchild = grandchildNode.copyWith(
        children: [greatGrandchild],
      );
      
      final updatedChild = childNode.copyWith(
        children: [updatedGrandchild],
      );
      
      final updatedRoot = rootNode.copyWith(
        children: [updatedChild],
      );
      
      controller.refresh(MindMapData(
        nodeData: updatedRoot,
        theme: MindMapTheme.light,
      ));

      // Initial layout should have all 4 nodes
      var data = controller.getData();
      var layouts = layoutEngine.calculateLayout(
        data.nodeData,
        data.theme,
        data.direction,
      );
      expect(layouts.length, 4);

      // Collapse grandchild (should hide great-grandchild)
      controller.collapseNode('grandchild-1');
      data = controller.getData();
      layouts = layoutEngine.calculateLayout(
        data.nodeData,
        data.theme,
        data.direction,
      );
      expect(layouts.length, 3); // root, child, grandchild (great-grandchild hidden)

      // Collapse child (should hide grandchild and great-grandchild)
      controller.collapseNode('child-1');
      data = controller.getData();
      layouts = layoutEngine.calculateLayout(
        data.nodeData,
        data.theme,
        data.direction,
      );
      expect(layouts.length, 2); // root, child only

      // Expand child (should show grandchild but not great-grandchild)
      controller.expandNode('child-1');
      data = controller.getData();
      layouts = layoutEngine.calculateLayout(
        data.nodeData,
        data.theme,
        data.direction,
      );
      expect(layouts.length, 3); // root, child, grandchild (great-grandchild still hidden)

      // Expand grandchild (should show great-grandchild)
      controller.expandNode('grandchild-1');
      data = controller.getData();
      layouts = layoutEngine.calculateLayout(
        data.nodeData,
        data.theme,
        data.direction,
      );
      expect(layouts.length, 4); // all nodes visible
    });
  });
}
