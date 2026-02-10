import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';
import '../helpers/generators.dart';

// Feature: mind-map-flutter, Property 32: 聚焦模式可见性

void main() {
  group('Focus Mode Property Tests', () {
    const iterations = 100;

    // For any node, activating focus mode should only display that node and its descendants,
    // exiting focus mode should restore the full view
    test('Property 32: Focus mode visibility', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data with guaranteed depth
        final initialData = generateRandomMindMapData(
          maxDepth: 4,
          maxChildren: 4,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Collect all node IDs in the full tree
        final allNodeIds = collectAllNodeIds(initialData.nodeData);

        // Skip if tree is too small (need at least root + some children)
        if (allNodeIds.length < 3) {
          controller.dispose();
          continue;
        }

        // Choose a random node to focus on (not the root for more interesting test)
        final candidateNodes = allNodeIds.where((id) => id != initialData.nodeData.id).toList();
        if (candidateNodes.isEmpty) {
          controller.dispose();
          continue;
        }

        final focusNodeId = candidateNodes[i % candidateNodes.length];
        final focusNode = _findNode(initialData.nodeData, focusNodeId);
        if (focusNode == null) {
          controller.dispose();
          continue;
        }

        // Collect descendants of the focus node
        final focusSubtreeIds = collectAllNodeIds(focusNode);

        // Calculate layout before focus mode
        final layoutEngine = LayoutEngine();
        final beforeFocusLayouts = layoutEngine.calculateLayout(
          controller.getData().nodeData,
          controller.getData().theme,
          controller.getData().direction,
        );

        // Verify all nodes are visible before focus mode
        final visibleBeforeFocus = allNodeIds.where((id) => beforeFocusLayouts.containsKey(id)).toSet();
        expect(visibleBeforeFocus.length, greaterThan(0),
            reason: 'Some nodes should be visible before focus mode');

        // Step 1: Activate focus mode (Requirement 18.1)
        controller.focusNode(focusNodeId);

        // Verify focus mode is active
        expect(controller.isFocusMode, true,
            reason: 'Focus mode should be active after focusNode');
        expect(controller.focusedNodeId, focusNodeId,
            reason: 'Focused node ID should be set correctly');

        // Calculate layout in focus mode
        // In focus mode, the layout should be calculated from the focused node as root
        final focusLayouts = layoutEngine.calculateLayout(
          focusNode,
          controller.getData().theme,
          controller.getData().direction,
        );

        // Verify only the focused node and its descendants are in the layout (Requirement 18.1)
        // Note: Collapsed nodes' children won't be in the layout
        // So we only check for nodes that should be visible based on expand state
        final visibleInFocusSubtree = _getVisibleNodeIds(focusNode);
        for (final nodeId in visibleInFocusSubtree) {
          expect(focusLayouts.containsKey(nodeId), true,
              reason: 'Node $nodeId in focused subtree should be visible in focus mode');
        }

        // Verify nodes outside the focused subtree are NOT in the layout (Requirement 18.1)
        final nodesOutsideSubtree = allNodeIds.difference(focusSubtreeIds);
        for (final nodeId in nodesOutsideSubtree) {
          expect(focusLayouts.containsKey(nodeId), false,
              reason: 'Node $nodeId outside focused subtree should NOT be visible in focus mode');
        }

        // Verify the focused node is treated as root in layout (Requirement 18.2)
        final focusNodeLayout = focusLayouts[focusNodeId];
        expect(focusNodeLayout, isNotNull,
            reason: 'Focused node should have a layout');

        // Step 2: Exit focus mode (Requirement 18.3)
        controller.exitFocusMode();

        // Verify focus mode is deactivated
        expect(controller.isFocusMode, false,
            reason: 'Focus mode should be inactive after exitFocusMode');
        expect(controller.focusedNodeId, null,
            reason: 'Focused node ID should be cleared after exitFocusMode');

        // Calculate layout after exiting focus mode
        final afterExitLayouts = layoutEngine.calculateLayout(
          controller.getData().nodeData,
          controller.getData().theme,
          controller.getData().direction,
        );

        // Verify full view is restored (Requirement 18.3)
        // All nodes that were visible before focus mode should be visible again
        for (final nodeId in visibleBeforeFocus) {
          expect(afterExitLayouts.containsKey(nodeId), true,
              reason: 'Node $nodeId should be visible again after exiting focus mode');
        }

        // Verify the layout is calculated from the original root
        expect(afterExitLayouts.containsKey(initialData.nodeData.id), true,
            reason: 'Root node should be in layout after exiting focus mode');

        controller.dispose();
      }
    });

    // Property 32 (Extended): Focus mode on root node
    test('Property 32 (Extended): Focus mode on root node shows all nodes', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 3,
          maxChildren: 3,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Collect all node IDs
        final allNodeIds = collectAllNodeIds(initialData.nodeData);

        // Calculate layout before focus mode
        final layoutEngine = LayoutEngine();
        final beforeFocusLayouts = layoutEngine.calculateLayout(
          controller.getData().nodeData,
          controller.getData().theme,
          controller.getData().direction,
        );

        // Focus on root node
        controller.focusNode(initialData.nodeData.id);

        // Verify focus mode is active
        expect(controller.isFocusMode, true);
        expect(controller.focusedNodeId, initialData.nodeData.id);

        // Calculate layout in focus mode
        final focusLayouts = layoutEngine.calculateLayout(
          initialData.nodeData,
          controller.getData().theme,
          controller.getData().direction,
        );

        // When focusing on root, all nodes should still be visible
        // (since root's subtree is the entire tree)
        for (final nodeId in allNodeIds) {
          final wasVisibleBefore = beforeFocusLayouts.containsKey(nodeId);
          final isVisibleInFocus = focusLayouts.containsKey(nodeId);
          
          expect(isVisibleInFocus, wasVisibleBefore,
              reason: 'Node $nodeId visibility should be same when focusing on root');
        }

        controller.dispose();
      }
    });

    // Property 32 (Extended): Focus mode on leaf node
    test('Property 32 (Extended): Focus mode on leaf node shows only that node', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 3,
          maxChildren: 3,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Find all leaf nodes (nodes with no children)
        final leafNodes = <String>[];
        void findLeafNodes(NodeData node) {
          if (node.children.isEmpty) {
            leafNodes.add(node.id);
          }
          for (final child in node.children) {
            findLeafNodes(child);
          }
        }
        findLeafNodes(initialData.nodeData);

        // Skip if no leaf nodes
        if (leafNodes.isEmpty) {
          controller.dispose();
          continue;
        }

        // Choose a random leaf node
        final leafNodeId = leafNodes[i % leafNodes.length];

        // Focus on the leaf node
        controller.focusNode(leafNodeId);

        // Verify focus mode is active
        expect(controller.isFocusMode, true);
        expect(controller.focusedNodeId, leafNodeId);

        // Calculate layout in focus mode
        final layoutEngine = LayoutEngine();
        final leafNode = _findNode(initialData.nodeData, leafNodeId);
        expect(leafNode, isNotNull);

        final focusLayouts = layoutEngine.calculateLayout(
          leafNode!,
          controller.getData().theme,
          controller.getData().direction,
        );

        // Only the leaf node itself should be in the layout
        expect(focusLayouts.length, 1,
            reason: 'Only the focused leaf node should be in layout');
        expect(focusLayouts.containsKey(leafNodeId), true,
            reason: 'The focused leaf node should be visible');

        controller.dispose();
      }
    });

    // Property 32 (Extended): Switching focus between nodes
    test('Property 32 (Extended): Switching focus updates visibility correctly', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data with guaranteed depth
        final initialData = generateRandomMindMapData(
          maxDepth: 3,
          maxChildren: 3,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Collect all node IDs
        final allNodeIds = collectAllNodeIds(initialData.nodeData);

        // Skip if tree is too small
        if (allNodeIds.length < 4) {
          controller.dispose();
          continue;
        }

        // Choose two different nodes to focus on
        final candidateNodes = allNodeIds.where((id) => id != initialData.nodeData.id).toList();
        if (candidateNodes.length < 2) {
          controller.dispose();
          continue;
        }

        final firstFocusId = candidateNodes[i % candidateNodes.length];
        final secondFocusId = candidateNodes[(i + 1) % candidateNodes.length];

        if (firstFocusId == secondFocusId) {
          controller.dispose();
          continue;
        }

        final firstFocusNode = _findNode(initialData.nodeData, firstFocusId);
        final secondFocusNode = _findNode(initialData.nodeData, secondFocusId);

        if (firstFocusNode == null || secondFocusNode == null) {
          controller.dispose();
          continue;
        }

        final layoutEngine = LayoutEngine();

        // Focus on first node
        controller.focusNode(firstFocusId);
        expect(controller.focusedNodeId, firstFocusId);

        // Calculate layout for first focus
        final firstFocusLayouts = layoutEngine.calculateLayout(
          firstFocusNode,
          controller.getData().theme,
          controller.getData().direction,
        );

        // Verify only first subtree is visible
        final visibleInFirstSubtree = _getVisibleNodeIds(firstFocusNode);
        for (final nodeId in visibleInFirstSubtree) {
          expect(firstFocusLayouts.containsKey(nodeId), true,
              reason: 'Node $nodeId should be visible when focusing on first node');
        }

        // Switch focus to second node
        controller.focusNode(secondFocusId);
        expect(controller.focusedNodeId, secondFocusId);

        // Calculate layout for second focus
        final secondFocusLayouts = layoutEngine.calculateLayout(
          secondFocusNode,
          controller.getData().theme,
          controller.getData().direction,
        );

        // Verify only second subtree is visible
        final visibleInSecondSubtree = _getVisibleNodeIds(secondFocusNode);
        for (final nodeId in visibleInSecondSubtree) {
          expect(secondFocusLayouts.containsKey(nodeId), true,
              reason: 'Node $nodeId should be visible when focusing on second node');
        }

        // Verify nodes from first subtree that are not in second subtree are not visible
        final visibleInFirst = _getVisibleNodeIds(firstFocusNode);
        final visibleInSecond = _getVisibleNodeIds(secondFocusNode);
        final nodesOnlyInFirst = visibleInFirst.difference(visibleInSecond);
        for (final nodeId in nodesOnlyInFirst) {
          expect(secondFocusLayouts.containsKey(nodeId), false,
              reason: 'Node $nodeId from first subtree should not be visible when focusing on second node');
        }

        controller.dispose();
      }
    });

    // Property 32 (Extended): Focus mode persists across other operations
    test('Property 32 (Extended): Focus mode persists across operations', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 3,
          maxChildren: 3,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Find a node with children to focus on
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
        if (nodesWithChildren.isEmpty) {
          controller.dispose();
          continue;
        }

        final focusNodeId = nodesWithChildren[i % nodesWithChildren.length];

        // Enter focus mode
        controller.focusNode(focusNodeId);
        expect(controller.isFocusMode, true);
        expect(controller.focusedNodeId, focusNodeId);

        // Perform various operations
        // 1. Add a child node
        controller.addChildNode(focusNodeId, topic: 'New Child');
        expect(controller.isFocusMode, true,
            reason: 'Focus mode should persist after adding child');
        expect(controller.focusedNodeId, focusNodeId,
            reason: 'Focused node ID should remain same after adding child');

        // 2. Collapse/expand a node
        controller.collapseNode(focusNodeId);
        expect(controller.isFocusMode, true,
            reason: 'Focus mode should persist after collapse');
        expect(controller.focusedNodeId, focusNodeId,
            reason: 'Focused node ID should remain same after collapse');

        controller.expandNode(focusNodeId);
        expect(controller.isFocusMode, true,
            reason: 'Focus mode should persist after expand');
        expect(controller.focusedNodeId, focusNodeId,
            reason: 'Focused node ID should remain same after expand');

        // 3. Undo operation
        if (controller.canUndo()) {
          controller.undo();
          expect(controller.isFocusMode, true,
              reason: 'Focus mode should persist after undo');
          expect(controller.focusedNodeId, focusNodeId,
              reason: 'Focused node ID should remain same after undo');
        }

        // 4. Redo operation
        if (controller.canRedo()) {
          controller.redo();
          expect(controller.isFocusMode, true,
              reason: 'Focus mode should persist after redo');
          expect(controller.focusedNodeId, focusNodeId,
              reason: 'Focused node ID should remain same after redo');
        }

        // Finally exit focus mode
        controller.exitFocusMode();
        expect(controller.isFocusMode, false);
        expect(controller.focusedNodeId, null);

        controller.dispose();
      }
    });

    // Property 32 (Extended): Focus mode clears selection
    test('Property 32 (Extended): Focus mode clears selection', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 3,
          maxChildren: 3,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Collect all node IDs
        final allNodeIds = collectAllNodeIds(initialData.nodeData);

        // Skip if tree is too small
        if (allNodeIds.length < 3) {
          controller.dispose();
          continue;
        }

        // Select some nodes
        final nodesToSelect = allNodeIds.take(2).toList();
        for (final nodeId in nodesToSelect) {
          controller.selectionManager.addToSelection(nodeId);
        }

        // Verify nodes are selected
        expect(controller.getSelectedNodeIds().length, greaterThan(0),
            reason: 'Some nodes should be selected before focus mode');

        // Choose a node to focus on
        final focusNodeId = allNodeIds.elementAt(i % allNodeIds.length);

        // Enter focus mode
        controller.focusNode(focusNodeId);

        // Verify selection is cleared (Requirement 18.1)
        expect(controller.getSelectedNodeIds(), isEmpty,
            reason: 'Selection should be cleared when entering focus mode');

        // Verify focus mode is active
        expect(controller.isFocusMode, true);
        expect(controller.focusedNodeId, focusNodeId);

        controller.dispose();
      }
    });

    // Property 32 (Extended): Invalid node ID throws exception
    test('Property 32 (Extended): Focus on invalid node throws exception', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 2,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Try to focus on a non-existent node
        expect(
          () => controller.focusNode('non-existent-node-id-$i'),
          throwsA(isA<InvalidNodeIdException>()),
          reason: 'Focusing on invalid node ID should throw InvalidNodeIdException',
        );

        // Verify focus mode is not activated
        expect(controller.isFocusMode, false,
            reason: 'Focus mode should not be active after failed focus attempt');
        expect(controller.focusedNodeId, null,
            reason: 'Focused node ID should be null after failed focus attempt');

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

// Get all node IDs that should be visible (respecting collapsed state)
Set<String> _getVisibleNodeIds(NodeData node) {
  final visibleIds = <String>{node.id};
  
  // Only include children if the node is expanded
  if (node.expanded) {
    for (final child in node.children) {
      visibleIds.addAll(_getVisibleNodeIds(child));
    }
  }
  
  return visibleIds;
}
