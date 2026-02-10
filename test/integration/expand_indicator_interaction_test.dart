import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/models/layout_direction.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_controller.dart';
import 'package:mind_map_flutter/src/layout/layout_engine.dart';
import 'package:mind_map_flutter/src/interaction/gesture_handler.dart';
import 'package:mind_map_flutter/src/rendering/node_renderer.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_widget.dart';

void main() {
  group('Expand Indicator Interaction', () {
    late MindMapData testData;
    late MindMapController controller;
    late LayoutEngine layoutEngine;

    setUp(() {
      final rootNode = NodeData.create(
        id: 'root',
        topic: 'Root',
        children: [
          NodeData.create(
            id: 'child1',
            topic: 'Child 1',
            expanded: true,
            children: [
              NodeData.create(id: 'grandchild1', topic: 'Grandchild 1'),
            ],
          ),
          NodeData.create(
            id: 'child2',
            topic: 'Child 2',
            expanded: false,
            children: [
              NodeData.create(id: 'grandchild2', topic: 'Grandchild 2'),
            ],
          ),
        ],
      );

      testData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
        direction: LayoutDirection.side,
      );

      controller = MindMapController(initialData: testData);
      layoutEngine = LayoutEngine();
    });

    tearDown(() {
      controller.dispose();
    });

    test(
      'hitTestExpandIndicator returns null for position outside indicators',
      () {
        final layouts = layoutEngine.calculateLayout(
          controller.getData().nodeData,
          controller.getData().theme,
          controller.getData().direction,
        );

        final gestureHandler = GestureHandler(
          controller: controller,
          nodeLayouts: layouts,
          transform: Matrix4.identity(),
        );

        // Test a position far from any node
        final result = gestureHandler.hitTestExpandIndicator(
          const Offset(1000, 1000),
        );

        expect(result, isNull);
      },
    );

    test('hitTestExpandIndicator returns null for node without children', () {
      final leafNode = NodeData.create(id: 'leaf', topic: 'Leaf Node');

      final leafData = MindMapData(
        nodeData: leafNode,
        theme: MindMapTheme.light,
        direction: LayoutDirection.side,
      );

      final leafController = MindMapController(initialData: leafData);
      final layouts = layoutEngine.calculateLayout(
        leafData.nodeData,
        leafData.theme,
        leafData.direction,
      );

      final gestureHandler = GestureHandler(
        controller: leafController,
        nodeLayouts: layouts,
        transform: Matrix4.identity(),
      );

      // Get the root node layout
      final rootLayout = layouts['leaf']!;

      // Try to hit test at the indicator position (even though there isn't one)
      final indicatorPosition = Offset(
        rootLayout.bounds.right +
            NodeRenderer.indicatorPadding +
            NodeRenderer.indicatorSize / 2,
        rootLayout.bounds.center.dy,
      );

      final result = gestureHandler.hitTestExpandIndicator(indicatorPosition);

      expect(result, isNull);

      leafController.dispose();
    });

    test(
      'hitTestExpandIndicator returns node ID when indicator is clicked',
      () {
        final layouts = layoutEngine.calculateLayout(
          controller.getData().nodeData,
          controller.getData().theme,
          controller.getData().direction,
        );

        final gestureHandler = GestureHandler(
          controller: controller,
          nodeLayouts: layouts,
          transform: Matrix4.identity(),
        );

        // Get child1 layout (which has children)
        final child1Layout = layouts['child1']!;
        final child1Node = controller.getData().nodeData.children[0];

        // Calculate the indicator position
        final indicatorBounds = NodeRenderer.getExpandIndicatorBounds(
          child1Node,
          child1Layout,
          controller.getData().theme,
          1,
        );
        expect(indicatorBounds, isNotNull);

        // Test clicking on the indicator
        final result = gestureHandler.hitTestExpandIndicator(
          indicatorBounds!.center,
        );

        expect(result, 'child1');
      },
    );

    test('hitTestExpandIndicator works for child nodes with children', () {
      final layouts = layoutEngine.calculateLayout(
        controller.getData().nodeData,
        controller.getData().theme,
        controller.getData().direction,
      );

      final gestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: layouts,
        transform: Matrix4.identity(),
      );

      // Get child1 layout (which has children)
      final child1Layout = layouts['child1']!;
      final child1Node = controller.getData().nodeData.children[0];

      // Calculate the indicator position
      final indicatorBounds = NodeRenderer.getExpandIndicatorBounds(
        child1Node,
        child1Layout,
        controller.getData().theme,
        1,
      );
      expect(indicatorBounds, isNotNull);

      // Test clicking on the indicator
      final result = gestureHandler.hitTestExpandIndicator(
        indicatorBounds!.center,
      );

      expect(result, 'child1');
    });

    test('clicking expand indicator toggles node expanded state', () {
      final layouts = layoutEngine.calculateLayout(
        controller.getData().nodeData,
        controller.getData().theme,
        controller.getData().direction,
      );

      final gestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: layouts,
        transform: Matrix4.identity(),
      );

      // Get child1 layout (currently expanded)
      final child1Layout = layouts['child1']!;
      final child1Node = controller.getData().nodeData.children[0];
      final indicatorBounds = NodeRenderer.getExpandIndicatorBounds(
        child1Node,
        child1Layout,
        controller.getData().theme,
        1,
      );

      // Simulate tap on indicator
      final tapDetails = TapUpDetails(
        kind: PointerDeviceKind.touch,
        globalPosition: indicatorBounds!.center,
        localPosition: indicatorBounds.center,
      );

      // Initial state: expanded
      expect(controller.getData().nodeData.children[0].expanded, true);

      // Click the indicator
      gestureHandler.handleTapUp(tapDetails);

      // Should now be collapsed
      expect(controller.getData().nodeData.children[0].expanded, false);

      // Click again
      gestureHandler.handleTapUp(tapDetails);

      // Should be expanded again
      expect(controller.getData().nodeData.children[0].expanded, true);
    });

    test('clicking expand indicator emits ExpandNodeEvent', () {
      final layouts = layoutEngine.calculateLayout(
        controller.getData().nodeData,
        controller.getData().theme,
        controller.getData().direction,
      );

      final gestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: layouts,
        transform: Matrix4.identity(),
      );

      // Get child2 layout (currently collapsed)
      final child2Layout = layouts['child2']!;
      final child2Node = controller.getData().nodeData.children[1];
      final indicatorBounds = NodeRenderer.getExpandIndicatorBounds(
        child2Node,
        child2Layout,
        controller.getData().theme,
        1,
      );

      // Simulate tap on indicator
      final tapDetails = TapUpDetails(
        kind: PointerDeviceKind.touch,
        globalPosition: indicatorBounds!.center,
        localPosition: indicatorBounds.center,
      );

      // Click the indicator
      gestureHandler.handleTapUp(tapDetails);

      // Check that event was emitted
      final event = controller.lastEvent;
      expect(event, isA<ExpandNodeEvent>());
      expect((event as ExpandNodeEvent).nodeId, 'child2');
      expect(event.expanded, true); // Was collapsed, now expanded
    });

    test('clicking expand indicator does not select the node', () {
      final layouts = layoutEngine.calculateLayout(
        controller.getData().nodeData,
        controller.getData().theme,
        controller.getData().direction,
      );

      final gestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: layouts,
        transform: Matrix4.identity(),
      );

      // Get child2 layout
      final child2Layout = layouts['child2']!;
      final child2Node = controller.getData().nodeData.children[1];
      final indicatorBounds = NodeRenderer.getExpandIndicatorBounds(
        child2Node,
        child2Layout,
        controller.getData().theme,
        1,
      );

      // Simulate tap on indicator
      final tapDetails = TapUpDetails(
        kind: PointerDeviceKind.touch,
        globalPosition: indicatorBounds!.center,
        localPosition: indicatorBounds.center,
      );

      // Initial state: no selection
      expect(controller.getSelectedNodeIds(), isEmpty);

      // Click the indicator
      gestureHandler.handleTapUp(tapDetails);

      // Should still have no selection (indicator click doesn't select)
      expect(controller.getSelectedNodeIds(), isEmpty);
    });

    test('clicking node body (not indicator) selects node', () {
      final layouts = layoutEngine.calculateLayout(
        controller.getData().nodeData,
        controller.getData().theme,
        controller.getData().direction,
      );

      final gestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: layouts,
        transform: Matrix4.identity(),
      );

      // Get root layout
      final rootLayout = layouts['root']!;

      // Simulate tap on node body (center of node, not indicator)
      final tapDetails = TapUpDetails(
        kind: PointerDeviceKind.touch,
        globalPosition: rootLayout.bounds.center,
        localPosition: rootLayout.bounds.center,
      );

      // Initial state: no selection
      expect(controller.getSelectedNodeIds(), isEmpty);

      // Click the node body
      gestureHandler.handleTapUp(tapDetails);

      // Should now be selected
      expect(controller.getSelectedNodeIds(), ['root']);
    });

    test('hitTestExpandIndicator works with transformed coordinates', () {
      final layouts = layoutEngine.calculateLayout(
        controller.getData().nodeData,
        controller.getData().theme,
        controller.getData().direction,
      );

      // Create a transform (scale and translate)
      final transform = Matrix4.identity()
        ..translateByDouble(100.0, 50.0, 0.0, 1.0)
        ..scaleByDouble(2.0, 2.0, 1.0, 1.0);

      final gestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: layouts,
        transform: transform,
      );

      // Get child1 layout in canvas coordinates
      final child1Layout = layouts['child1']!;
      final child1Node = controller.getData().nodeData.children[0];
      final indicatorBounds = NodeRenderer.getExpandIndicatorBounds(
        child1Node,
        child1Layout,
        controller.getData().theme,
        1,
      );

      // Transform the indicator position to screen coordinates
      final screenPosition = MatrixUtils.transformPoint(
        transform,
        indicatorBounds!.center,
      );

      // Test clicking on the transformed indicator position
      final result = gestureHandler.hitTestExpandIndicator(screenPosition);

      expect(result, 'child1');
    });

    test('expand indicator interaction updates layout', () {
      final layouts = layoutEngine.calculateLayout(
        controller.getData().nodeData,
        controller.getData().theme,
        controller.getData().direction,
      );

      final gestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: layouts,
        transform: Matrix4.identity(),
      );

      // Get child2 layout (currently collapsed, has hidden children)
      final child2Layout = layouts['child2']!;
      final child2Node = controller.getData().nodeData.children[1];
      final indicatorBounds = NodeRenderer.getExpandIndicatorBounds(
        child2Node,
        child2Layout,
        controller.getData().theme,
        1,
      );

      // Grandchild2 should not be in layouts (parent is collapsed)
      expect(layouts.containsKey('grandchild2'), false);

      // Simulate tap on indicator to expand
      final tapDetails = TapUpDetails(
        kind: PointerDeviceKind.touch,
        globalPosition: indicatorBounds!.center,
        localPosition: indicatorBounds.center,
      );

      gestureHandler.handleTapUp(tapDetails);

      // Recalculate layout after expansion
      final newLayouts = layoutEngine.calculateLayout(
        controller.getData().nodeData,
        controller.getData().theme,
        controller.getData().direction,
      );

      // Grandchild2 should now be in layouts (parent is expanded)
      expect(newLayouts.containsKey('grandchild2'), true);
    });
  });
}
