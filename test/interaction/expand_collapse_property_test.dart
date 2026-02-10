import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';
import '../helpers/generators.dart';

// Feature: mind-map-flutter, Property 14: 展开折叠往返
// Feature: mind-map-flutter, Property 15: 折叠指示器可见性
// Feature: mind-map-flutter, Property 7: 折叠状态可见性

void main() {
  group('Expand/Collapse Property Tests', () {
    const iterations = 100;

    // For any node, collapsing then expanding should restore child visibility,
    // expanded state should persist in data, and expandNode events should be emitted
    test('Property 14: Expand-collapse round-trip', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data with guaranteed depth
        final initialData = generateRandomMindMapData(
          maxDepth: 3,
          maxChildren: 4,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Find nodes with children (candidates for expand/collapse)
        final nodesWithChildren = <String>[];
        void findNodesWithChildren(NodeData node) {
          if (node.children.isNotEmpty) {
            nodesWithChildren.add(node.id);
          }
          for (final child in node.children) {
            findNodesWithChildren(child);
          }
        }
        findNodesWithChildren(initialData.nodeData);

        // Skip if no nodes with children
        if (nodesWithChildren.isEmpty) continue;

        // Choose a random node with children
        final nodeId = nodesWithChildren[i % nodesWithChildren.length];
        final node = _findNode(initialData.nodeData, nodeId);
        if (node == null) continue;

        // Capture initial state
        final initialExpanded = node.expanded;
        final childIds = node.children.map((c) => c.id).toSet();

        // Calculate initial layout to check child visibility
        final layoutEngine = LayoutEngine();
        final initialLayouts = layoutEngine.calculateLayout(
          controller.getData().nodeData,
          controller.getData().theme,
          controller.getData().direction,
        );

        // Skip if the node itself is not in the layout (parent might be collapsed)
        if (!initialLayouts.containsKey(nodeId)) continue;

        // Step 1: Collapse the node (if expanded)
        if (initialExpanded) {
          controller.collapseNode(nodeId);

          // Verify collapsed state persists in data (Requirement 7.3)
          final afterCollapse = controller.getData();
          final collapsedNode = _findNode(afterCollapse.nodeData, nodeId);
          expect(collapsedNode, isNotNull);
          expect(collapsedNode!.expanded, false,
              reason: 'Node should be collapsed after collapseNode');

          // Verify expandNode event was emitted (Requirement 7.5)
          expect(controller.lastEvent, isA<ExpandNodeEvent>(),
              reason: 'ExpandNodeEvent should be emitted on collapse');
          final collapseEvent = controller.lastEvent as ExpandNodeEvent;
          expect(collapseEvent.nodeId, nodeId,
              reason: 'Event should contain correct node ID');
          expect(collapseEvent.expanded, false,
              reason: 'Event should indicate collapsed state');

          // Verify children are hidden in rendering (Requirement 7.2)
          final collapsedLayouts = layoutEngine.calculateLayout(
            afterCollapse.nodeData,
            afterCollapse.theme,
            afterCollapse.direction,
          );
          for (final childId in childIds) {
            expect(collapsedLayouts.containsKey(childId), false,
                reason: 'Child $childId should not be in layout when parent is collapsed');
          }

          // Step 2: Expand the node again
          controller.expandNode(nodeId);

          // Verify expanded state persists in data (Requirement 7.3)
          final afterExpand = controller.getData();
          final expandedNode = _findNode(afterExpand.nodeData, nodeId);
          expect(expandedNode, isNotNull);
          expect(expandedNode!.expanded, true,
              reason: 'Node should be expanded after expandNode');

          // Verify expandNode event was emitted (Requirement 7.5)
          expect(controller.lastEvent, isA<ExpandNodeEvent>(),
              reason: 'ExpandNodeEvent should be emitted on expand');
          final expandEvent = controller.lastEvent as ExpandNodeEvent;
          expect(expandEvent.nodeId, nodeId,
              reason: 'Event should contain correct node ID');
          expect(expandEvent.expanded, true,
              reason: 'Event should indicate expanded state');

          // Verify child visibility is restored (Requirement 7.1)
          final expandedLayouts = layoutEngine.calculateLayout(
            afterExpand.nodeData,
            afterExpand.theme,
            afterExpand.direction,
          );
          
          // Get the expanded node from the tree to check its children
          final expandedNodeInTree = _findNode(afterExpand.nodeData, nodeId);
          expect(expandedNodeInTree, isNotNull);
          
          // Direct children should be visible when parent is expanded
          // (unless the child itself is hidden because its own parent is collapsed)
          for (final childId in childIds) {
            // Verify the child still exists in the tree
            final childInTree = _findNode(afterExpand.nodeData, childId);
            expect(childInTree, isNotNull,
                reason: 'Child $childId should exist in tree');
            
            // Child should be in layout if parent is expanded
            expect(expandedLayouts.containsKey(childId), true,
                reason: 'Child $childId should be visible in layout when parent is expanded');
          }
        } else {
          // Node is initially collapsed, test expand then collapse
          controller.expandNode(nodeId);

          // Verify expanded state
          final afterExpand = controller.getData();
          final expandedNode = _findNode(afterExpand.nodeData, nodeId);
          expect(expandedNode, isNotNull);
          expect(expandedNode!.expanded, true,
              reason: 'Node should be expanded after expandNode');

          // Verify event
          expect(controller.lastEvent, isA<ExpandNodeEvent>());
          final expandEvent = controller.lastEvent as ExpandNodeEvent;
          expect(expandEvent.expanded, true);

          // Verify children are visible
          final expandedLayouts = layoutEngine.calculateLayout(
            afterExpand.nodeData,
            afterExpand.theme,
            afterExpand.direction,
          );
          for (final childId in childIds) {
            expect(expandedLayouts.containsKey(childId), true,
                reason: 'Child $childId should be visible after expand');
          }

          // Collapse again
          controller.collapseNode(nodeId);

          // Verify collapsed state
          final afterCollapse = controller.getData();
          final collapsedNode = _findNode(afterCollapse.nodeData, nodeId);
          expect(collapsedNode, isNotNull);
          expect(collapsedNode!.expanded, false,
              reason: 'Node should be collapsed after collapseNode');

          // Verify event
          expect(controller.lastEvent, isA<ExpandNodeEvent>());
          final collapseEvent = controller.lastEvent as ExpandNodeEvent;
          expect(collapseEvent.expanded, false);

          // Verify children are hidden
          final collapsedLayouts = layoutEngine.calculateLayout(
            afterCollapse.nodeData,
            afterCollapse.theme,
            afterCollapse.direction,
          );
          for (final childId in childIds) {
            expect(collapsedLayouts.containsKey(childId), false,
                reason: 'Child $childId should be hidden after collapse');
          }
        }

        controller.dispose();
      }
    });

    // For any collapsed node with children, an expand indicator should be displayed
    test('Property 15: Collapse indicator visibility', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 3,
          maxChildren: 4,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Find all nodes with children
        final nodesWithChildren = <NodeData>[];
        void findNodesWithChildren(NodeData node) {
          if (node.children.isNotEmpty) {
            nodesWithChildren.add(node);
          }
          for (final child in node.children) {
            findNodesWithChildren(child);
          }
        }
        findNodesWithChildren(initialData.nodeData);

        // Skip if no nodes with children
        if (nodesWithChildren.isEmpty) continue;

        // Calculate layout
        final layoutEngine = LayoutEngine();
        final layouts = layoutEngine.calculateLayout(
          controller.getData().nodeData,
          controller.getData().theme,
          controller.getData().direction,
        );

        // Check each node with children
        for (final node in nodesWithChildren) {
          final layout = layouts[node.id];
          if (layout == null) continue; // Node might be hidden if parent is collapsed

          // Get expand indicator bounds
          final indicatorBounds = NodeRenderer.getExpandIndicatorBounds(node, layout);

          // Indicator should exist for nodes with children (Requirement 7.4)
          expect(indicatorBounds, isNotNull,
              reason: 'Node ${node.id} with children should have expand indicator');

          // Indicator should be positioned to the right of the node
          expect(indicatorBounds!.center.dx, greaterThan(layout.bounds.right),
              reason: 'Indicator should be to the right of node');

          // Indicator should be vertically centered with the node
          expect(indicatorBounds.center.dy, closeTo(layout.bounds.center.dy, 1e-9),
              reason: 'Indicator should be vertically centered');

          // Indicator should have reasonable size
          expect(indicatorBounds.width, greaterThan(0),
              reason: 'Indicator should have positive width');
          expect(indicatorBounds.height, greaterThan(0),
              reason: 'Indicator should have positive height');

          // Test with collapsed state
          controller.collapseNode(node.id);
          final collapsedData = controller.getData();
          final collapsedNode = _findNode(collapsedData.nodeData, node.id);
          expect(collapsedNode, isNotNull);

          // Recalculate layout
          final collapsedLayouts = layoutEngine.calculateLayout(
            collapsedData.nodeData,
            collapsedData.theme,
            collapsedData.direction,
          );
          final collapsedLayout = collapsedLayouts[node.id];
          if (collapsedLayout == null) continue;

          // Indicator should still exist for collapsed node with children
          final collapsedIndicatorBounds = NodeRenderer.getExpandIndicatorBounds(
            collapsedNode!,
            collapsedLayout,
          );
          expect(collapsedIndicatorBounds, isNotNull,
              reason: 'Collapsed node ${node.id} with children should have expand indicator');

          // Restore expanded state for next iteration
          controller.expandNode(node.id);
        }

        controller.dispose();
      }
    });

    // For any collapsed node, its children should not be visible in rendering output,
    // and an expand indicator should be displayed
    test('Property 7: Collapsed state visibility', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 3,
          maxChildren: 4,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Find all nodes with children
        final nodesWithChildren = <String>[];
        void findNodesWithChildren(NodeData node) {
          if (node.children.isNotEmpty) {
            nodesWithChildren.add(node.id);
          }
          for (final child in node.children) {
            findNodesWithChildren(child);
          }
        }
        findNodesWithChildren(initialData.nodeData);

        // Skip if no nodes with children
        if (nodesWithChildren.isEmpty) continue;

        // Choose a random node with children
        final nodeId = nodesWithChildren[i % nodesWithChildren.length];
        final node = _findNode(initialData.nodeData, nodeId);
        if (node == null) continue;

        // Collapse the node
        controller.collapseNode(nodeId);

        // Get the collapsed data
        final collapsedData = controller.getData();
        final collapsedNode = _findNode(collapsedData.nodeData, nodeId);
        expect(collapsedNode, isNotNull);
        expect(collapsedNode!.expanded, false,
            reason: 'Node should be collapsed');

        // Calculate layout
        final layoutEngine = LayoutEngine();
        final layouts = layoutEngine.calculateLayout(
          collapsedData.nodeData,
          collapsedData.theme,
          collapsedData.direction,
        );

        // Skip if the node itself is not in the layout (parent might be collapsed)
        final nodeLayout = layouts[nodeId];
        if (nodeLayout == null) continue;

        // Verify children are NOT in the layout (Requirement 2.9)
        final childIds = collapsedNode.children.map((c) => c.id).toSet();
        for (final childId in childIds) {
          expect(layouts.containsKey(childId), false,
              reason: 'Child $childId should not be visible when parent is collapsed');
        }

        // Verify descendants are also not in the layout
        final descendantIds = collectAllNodeIds(collapsedNode);
        descendantIds.remove(nodeId); // Remove the collapsed node itself
        for (final descendantId in descendantIds) {
          expect(layouts.containsKey(descendantId), false,
              reason: 'Descendant $descendantId should not be visible when ancestor is collapsed');
        }

        // Verify expand indicator is displayed (Requirement 2.9)
        final indicatorBounds = NodeRenderer.getExpandIndicatorBounds(
          collapsedNode,
          nodeLayout,
        );
        expect(indicatorBounds, isNotNull,
            reason: 'Collapsed node with children should display expand indicator');

        controller.dispose();
      }
    });

    // Additional property test: Toggle maintains consistency
    test('Property 14 (Extended): Toggle maintains consistency', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 3,
          maxChildren: 4,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Find nodes with children
        final nodesWithChildren = <String>[];
        void findNodesWithChildren(NodeData node) {
          if (node.children.isNotEmpty) {
            nodesWithChildren.add(node.id);
          }
          for (final child in node.children) {
            findNodesWithChildren(child);
          }
        }
        findNodesWithChildren(initialData.nodeData);

        // Skip if no nodes with children
        if (nodesWithChildren.isEmpty) continue;

        // Choose a random node with children
        final nodeId = nodesWithChildren[i % nodesWithChildren.length];
        final node = _findNode(initialData.nodeData, nodeId);
        if (node == null) continue;

        // Capture initial state
        final initialExpanded = node.expanded;

        // Toggle once
        controller.toggleNodeExpanded(nodeId);
        final afterFirstToggle = controller.getData();
        final nodeAfterFirst = _findNode(afterFirstToggle.nodeData, nodeId);
        expect(nodeAfterFirst, isNotNull);
        expect(nodeAfterFirst!.expanded, !initialExpanded,
            reason: 'First toggle should invert expanded state');

        // Verify event
        expect(controller.lastEvent, isA<ExpandNodeEvent>());
        final firstEvent = controller.lastEvent as ExpandNodeEvent;
        expect(firstEvent.nodeId, nodeId);
        expect(firstEvent.expanded, !initialExpanded);

        // Toggle again
        controller.toggleNodeExpanded(nodeId);
        final afterSecondToggle = controller.getData();
        final nodeAfterSecond = _findNode(afterSecondToggle.nodeData, nodeId);
        expect(nodeAfterSecond, isNotNull);
        expect(nodeAfterSecond!.expanded, initialExpanded,
            reason: 'Second toggle should restore original expanded state');

        // Verify event
        expect(controller.lastEvent, isA<ExpandNodeEvent>());
        final secondEvent = controller.lastEvent as ExpandNodeEvent;
        expect(secondEvent.nodeId, nodeId);
        expect(secondEvent.expanded, initialExpanded);

        controller.dispose();
      }
    });

    // Additional property test: Expand/collapse idempotency
    test('Property 14 (Extended): Expand/collapse idempotency', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 3,
          maxChildren: 4,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Find nodes with children
        final nodesWithChildren = <String>[];
        void findNodesWithChildren(NodeData node) {
          if (node.children.isNotEmpty) {
            nodesWithChildren.add(node.id);
          }
          for (final child in node.children) {
            findNodesWithChildren(child);
          }
        }
        findNodesWithChildren(initialData.nodeData);

        // Skip if no nodes with children
        if (nodesWithChildren.isEmpty) continue;

        // Choose a random node with children
        final nodeId = nodesWithChildren[i % nodesWithChildren.length];

        // Collapse multiple times
        controller.collapseNode(nodeId);
        final afterFirstCollapse = controller.getData();
        final nodeAfterFirst = _findNode(afterFirstCollapse.nodeData, nodeId);
        expect(nodeAfterFirst!.expanded, false);

        controller.collapseNode(nodeId);
        final afterSecondCollapse = controller.getData();
        final nodeAfterSecond = _findNode(afterSecondCollapse.nodeData, nodeId);
        expect(nodeAfterSecond!.expanded, false,
            reason: 'Multiple collapses should maintain collapsed state');

        // Expand multiple times
        controller.expandNode(nodeId);
        final afterFirstExpand = controller.getData();
        final nodeAfterFirstExpand = _findNode(afterFirstExpand.nodeData, nodeId);
        expect(nodeAfterFirstExpand!.expanded, true);

        controller.expandNode(nodeId);
        final afterSecondExpand = controller.getData();
        final nodeAfterSecondExpand = _findNode(afterSecondExpand.nodeData, nodeId);
        expect(nodeAfterSecondExpand!.expanded, true,
            reason: 'Multiple expands should maintain expanded state');

        controller.dispose();
      }
    });

    // Additional property test: Nested collapse/expand
    test('Property 7 (Extended): Nested collapse hides all descendants', () {
      for (int i = 0; i < iterations; i++) {
        // Generate data with guaranteed depth
        final initialData = generateRandomMindMapData(
          maxDepth: 4,
          maxChildren: 3,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Find a node with grandchildren
        NodeData? nodeWithGrandchildren;
        void findNodeWithGrandchildren(NodeData node) {
          if (nodeWithGrandchildren != null) return;
          for (final child in node.children) {
            if (child.children.isNotEmpty) {
              nodeWithGrandchildren = node;
              return;
            }
          }
          for (final child in node.children) {
            findNodeWithGrandchildren(child);
          }
        }
        findNodeWithGrandchildren(initialData.nodeData);

        // Skip if no node with grandchildren
        if (nodeWithGrandchildren == null) continue;

        // Collapse the parent node
        controller.collapseNode(nodeWithGrandchildren!.id);

        // Calculate layout
        final layoutEngine = LayoutEngine();
        final layouts = layoutEngine.calculateLayout(
          controller.getData().nodeData,
          controller.getData().theme,
          controller.getData().direction,
        );

        // Verify all descendants are hidden
        final allDescendants = collectAllNodeIds(nodeWithGrandchildren!);
        allDescendants.remove(nodeWithGrandchildren!.id); // Remove parent itself

        for (final descendantId in allDescendants) {
          expect(layouts.containsKey(descendantId), false,
              reason: 'All descendants should be hidden when ancestor is collapsed');
        }

        controller.dispose();
      }
    });
  });
}

// Helper functions

NodeData? _findNode(NodeData node, String nodeId) {
  if (node.id == nodeId) return node;
  for (final child in node.children) {
    final found = _findNode(child, nodeId);
    if (found != null) return found;
  }
  return null;
}
