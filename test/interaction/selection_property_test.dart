import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';
import '../helpers/generators.dart';

void main() {
  group('Selection Property Tests', () {
    const iterations = 100;

    // Feature: mind-map-flutter, Property
    // For any node selection operation (single selection, multi-selection, rectangular selection),
    // the selection state should be correctly updated, selected nodes should have visual feedback,
    // and selectNodes events should be emitted
    test('Property 13: Node selection state consistency', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random mind map data
        final initialData = generateRandomMindMapData(
          maxDepth: 3,
          maxChildren: 4,
        );

        // Create controller
        final controller = MindMapController(initialData: initialData);

        // Collect all node IDs
        final allNodeIds = collectAllNodeIds(initialData.nodeData).toList();
        expect(allNodeIds.isNotEmpty, isTrue, reason: 'Should have at least root node');

        // Track emitted events
        final emittedEvents = <SelectNodesEvent>[];
        final selectionManager = SelectionManager(
          onSelectionChanged: (event) {
            emittedEvents.add(event);
          },
        );

        try {
          // Test 1: Single selection (Requirement 6.1)
          // When user clicks a node, the system SHALL select that node and deselect others
          if (allNodeIds.isNotEmpty) {
            final nodeToSelect = allNodeIds[i % allNodeIds.length];
            selectionManager.selectNode(nodeToSelect);

            // Verify selection state is updated
            expect(selectionManager.selectedNodeIds, [nodeToSelect],
                reason: 'Single selection should contain only the selected node');
            expect(selectionManager.isSelected(nodeToSelect), isTrue,
                reason: 'Selected node should be marked as selected');

            // Verify selectNodes event was emitted (Requirement 6.5)
            expect(emittedEvents.isNotEmpty, isTrue,
                reason: 'selectNodes event should be emitted');
            expect(emittedEvents.last.nodeIds, [nodeToSelect],
                reason: 'Event should contain the selected node ID');

            // Verify other nodes are not selected
            for (final otherId in allNodeIds) {
              if (otherId != nodeToSelect) {
                expect(selectionManager.isSelected(otherId), isFalse,
                    reason: 'Other nodes should not be selected');
              }
            }
          }

          // Test 2: Multi-selection (Requirement 6.2)
          // When user Ctrl/Cmd+clicks a node, the system SHALL add that node to current selection
          if (allNodeIds.length >= 2) {
            emittedEvents.clear();
            selectionManager.clearSelection();

            final firstNode = allNodeIds[0];
            final secondNode = allNodeIds[1];

            // Select first node
            selectionManager.selectNode(firstNode);
            expect(selectionManager.selectedNodeIds, [firstNode]);

            // Add second node to selection
            selectionManager.addToSelection(secondNode);

            // Verify both nodes are selected
            expect(selectionManager.selectedNodeIds, [firstNode, secondNode],
                reason: 'Multi-selection should contain both nodes');
            expect(selectionManager.isSelected(firstNode), isTrue);
            expect(selectionManager.isSelected(secondNode), isTrue);

            // Verify event was emitted
            expect(emittedEvents.length, greaterThanOrEqualTo(2),
                reason: 'Events should be emitted for both selections');
            expect(emittedEvents.last.nodeIds, [firstNode, secondNode],
                reason: 'Event should contain both selected node IDs');
          }

          // Test 3: Batch selection (Requirement 6.3)
          // When user performs drag selection gesture, the system SHALL select all nodes within rectangle
          if (allNodeIds.length >= 3) {
            emittedEvents.clear();

            // Select multiple nodes at once (simulating rectangular selection)
            final nodesToSelect = allNodeIds.take(3).toList();
            selectionManager.selectNodes(nodesToSelect);

            // Verify all nodes are selected
            expect(selectionManager.selectedNodeIds, nodesToSelect,
                reason: 'Batch selection should contain all specified nodes');
            for (final nodeId in nodesToSelect) {
              expect(selectionManager.isSelected(nodeId), isTrue,
                  reason: 'Each node in batch should be selected');
            }

            // Verify event was emitted
            expect(emittedEvents.isNotEmpty, isTrue);
            expect(emittedEvents.last.nodeIds, nodesToSelect,
                reason: 'Event should contain all selected node IDs');
          }

          // Test 4: Visual feedback (Requirement 6.4)
          // The system SHALL provide visual feedback for selected nodes with distinct border or highlight
          // This is verified by checking that selectedNodeIds is accessible for rendering
          if (allNodeIds.isNotEmpty) {
            final nodeToSelect = allNodeIds[0];
            selectionManager.selectNode(nodeToSelect);

            // Verify that selected node IDs are available for visual feedback
            final selectedIds = selectionManager.selectedNodeIds;
            expect(selectedIds, contains(nodeToSelect),
                reason: 'Selected node IDs should be available for rendering visual feedback');
            expect(selectedIds, isNotEmpty,
                reason: 'Visual feedback requires non-empty selection');
          }

          // Test 5: Selection state maintenance (Requirement 6.6)
          // The system SHALL maintain a list of currently selected nodes
          if (allNodeIds.length >= 3) {
            selectionManager.clearSelection();

            // Build up selection state
            selectionManager.selectNode(allNodeIds[0]);
            expect(selectionManager.selectedNodeIds.length, 1);

            selectionManager.addToSelection(allNodeIds[1]);
            expect(selectionManager.selectedNodeIds.length, 2);

            selectionManager.addToSelection(allNodeIds[2]);
            expect(selectionManager.selectedNodeIds.length, 3);

            // Remove one node
            selectionManager.removeFromSelection(allNodeIds[1]);
            expect(selectionManager.selectedNodeIds.length, 2);
            expect(selectionManager.selectedNodeIds, [allNodeIds[0], allNodeIds[2]]);

            // Clear all
            selectionManager.clearSelection();
            expect(selectionManager.selectedNodeIds, isEmpty,
                reason: 'Selection state should be cleared');
          }

          // Test 6: Toggle selection (Requirement 6.2)
          // Toggle should add if not selected, remove if selected
          if (allNodeIds.isNotEmpty) {
            selectionManager.clearSelection();
            emittedEvents.clear();

            final nodeToToggle = allNodeIds[0];

            // Toggle on
            selectionManager.toggleSelection(nodeToToggle);
            expect(selectionManager.isSelected(nodeToToggle), isTrue,
                reason: 'Toggle should select unselected node');
            expect(emittedEvents.length, 1,
                reason: 'Event should be emitted for toggle on');

            // Toggle off
            selectionManager.toggleSelection(nodeToToggle);
            expect(selectionManager.isSelected(nodeToToggle), isFalse,
                reason: 'Toggle should deselect selected node');
            expect(emittedEvents.length, 2,
                reason: 'Event should be emitted for toggle off');
          }

          // Test 7: Event emission consistency (Requirement 6.5)
          // When selecting nodes, the system SHALL emit selectNodes event with list of selected node IDs
          if (allNodeIds.length >= 2) {
            emittedEvents.clear();
            selectionManager.clearSelection();

            // Perform various selection operations
            selectionManager.selectNode(allNodeIds[0]);
            expect(emittedEvents.length, 1);
            expect(emittedEvents.last.nodeIds, [allNodeIds[0]]);

            selectionManager.addToSelection(allNodeIds[1]);
            expect(emittedEvents.length, 2);
            expect(emittedEvents.last.nodeIds, [allNodeIds[0], allNodeIds[1]]);

            selectionManager.clearSelection();
            expect(emittedEvents.length, 3);
            expect(emittedEvents.last.nodeIds, isEmpty);
          }

          // Test 8: Selection replacement
          // Single selection should clear previous selection
          if (allNodeIds.length >= 2) {
            selectionManager.selectNode(allNodeIds[0]);
            expect(selectionManager.selectedNodeIds, [allNodeIds[0]]);

            // Select another node - should replace
            selectionManager.selectNode(allNodeIds[1]);
            expect(selectionManager.selectedNodeIds, [allNodeIds[1]],
                reason: 'Single selection should replace previous selection');
            expect(selectionManager.isSelected(allNodeIds[0]), isFalse,
                reason: 'Previous selection should be cleared');
          }

          // Test 9: Immutability of returned list
          // The returned selectedNodeIds should be immutable
          if (allNodeIds.isNotEmpty) {
            selectionManager.selectNode(allNodeIds[0]);
            final selectedIds = selectionManager.selectedNodeIds;

            // Verify list is unmodifiable
            expect(() => selectedIds.add('fake-id'), throwsUnsupportedError,
                reason: 'Returned list should be immutable');
          }

        } finally {
          controller.dispose();
          selectionManager.dispose();
        }
      }
    });

    // Additional property test: Selection with rectangular selection integration
    test('Property 13 (Extended): Rectangular selection consistency', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random mind map data
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 3,
        );

        final controller = MindMapController(initialData: initialData);

        // Create mock node layouts for rectangular selection testing
        final nodeLayouts = <String, NodeLayout>{};
        final allNodeIds = collectAllNodeIds(initialData.nodeData).toList();

        // Assign random positions to nodes
        for (int j = 0; j < allNodeIds.length; j++) {
          nodeLayouts[allNodeIds[j]] = NodeLayout(
            position: Offset(
              50.0 + (j % 5) * 100.0,
              50.0 + (j ~/ 5) * 80.0,
            ),
            size: const Size(80, 40),
          );
        }

        try {
          // Create gesture handler
          final gestureHandler = GestureHandler(
            controller: controller,
            nodeLayouts: nodeLayouts,
            transform: Matrix4.identity(),
          );

          // Test rectangular selection (Requirement 6.3)
          // Simulate drag selection gesture
          if (allNodeIds.length >= 2) {
            // Start drag in empty space
            gestureHandler.handlePanStart(
              DragStartDetails(
                localPosition: const Offset(20, 20),
              ),
            );

            // Verify selection rectangle is initialized
            expect(gestureHandler.selectionRect, isNotNull,
                reason: 'Selection rectangle should be initialized on drag start');

            // Drag to encompass some nodes
            gestureHandler.handlePanUpdate(
              DragUpdateDetails(
                localPosition: const Offset(200, 150),
                globalPosition: const Offset(200, 150),
                delta: const Offset(180, 130),
              ),
            );

            // Note: Selection is finalized on drag end, so we check after update

            // End drag
            gestureHandler.handlePanEnd(DragEndDetails());

            // Verify selection rectangle is cleared
            expect(gestureHandler.selectionRect, isNull,
                reason: 'Selection rectangle should be cleared after drag end');

            // Verify final selection state
            final finalSelectedIds = controller.getSelectedNodeIds();
            // All selected nodes should be in the original node list
            for (final selectedId in finalSelectedIds) {
              expect(allNodeIds, contains(selectedId),
                  reason: 'Selected node should exist in the tree');
            }

            // Verify event was emitted if nodes were selected
            if (finalSelectedIds.isNotEmpty) {
              expect(controller.lastEvent, isA<SelectNodesEvent>(),
                  reason: 'selectNodes event should be emitted for rectangular selection');
              final event = controller.lastEvent as SelectNodesEvent;
              expect(event.nodeIds, finalSelectedIds,
                  reason: 'Event should contain all selected node IDs');
            }
          }

        } finally {
          controller.dispose();
        }
      }
    });

    // Property test: Selection state consistency across operations
    test('Property 13 (Extended): Selection state consistency across multiple operations', () {
      for (int i = 0; i < iterations; i++) {
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 3,
        );

        final controller = MindMapController(initialData: initialData);
        final allNodeIds = collectAllNodeIds(initialData.nodeData).toList();

        try {
          if (allNodeIds.length >= 4) {
            // Perform a sequence of selection operations
            final selectionManager = controller.selectionManager;

            // Operation 1: Select first node
            selectionManager.selectNode(allNodeIds[0]);
            expect(selectionManager.selectedNodeIds, [allNodeIds[0]]);

            // Operation 2: Add second node
            selectionManager.addToSelection(allNodeIds[1]);
            expect(selectionManager.selectedNodeIds, [allNodeIds[0], allNodeIds[1]]);

            // Operation 3: Toggle third node (add)
            selectionManager.toggleSelection(allNodeIds[2]);
            expect(selectionManager.selectedNodeIds, [allNodeIds[0], allNodeIds[1], allNodeIds[2]]);

            // Operation 4: Toggle first node (remove)
            selectionManager.toggleSelection(allNodeIds[0]);
            expect(selectionManager.selectedNodeIds, [allNodeIds[1], allNodeIds[2]]);

            // Operation 5: Batch select new set
            selectionManager.selectNodes([allNodeIds[2], allNodeIds[3]]);
            expect(selectionManager.selectedNodeIds, [allNodeIds[2], allNodeIds[3]]);

            // Operation 6: Remove one node
            selectionManager.removeFromSelection(allNodeIds[2]);
            expect(selectionManager.selectedNodeIds, [allNodeIds[3]]);

            // Operation 7: Clear all
            selectionManager.clearSelection();
            expect(selectionManager.selectedNodeIds, isEmpty);

            // Verify consistency: all operations maintained valid state
            expect(selectionManager.selectedNodeIds, isEmpty,
                reason: 'Final state should be empty after clear');
          }

        } finally {
          controller.dispose();
        }
      }
    });

    // Property test: Selection events are always emitted when state changes
    test('Property 13 (Extended): Selection events emitted on state changes', () {
      for (int i = 0; i < iterations; i++) {
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 2,
        );

        final controller = MindMapController(initialData: initialData);
        final allNodeIds = collectAllNodeIds(initialData.nodeData).toList();

        try {
          if (allNodeIds.length >= 2) {
            final emittedEvents = <SelectNodesEvent>[];
            final selectionManager = SelectionManager(
              onSelectionChanged: (event) {
                emittedEvents.add(event);
              },
            );

            // Every state-changing operation should emit an event
            selectionManager.selectNode(allNodeIds[0]);
            final eventCount1 = emittedEvents.length;
            expect(eventCount1, greaterThan(0), reason: 'Event should be emitted for selectNode');

            selectionManager.addToSelection(allNodeIds[1]);
            final eventCount2 = emittedEvents.length;
            expect(eventCount2, greaterThan(eventCount1), reason: 'Event should be emitted for addToSelection');

            selectionManager.removeFromSelection(allNodeIds[0]);
            final eventCount3 = emittedEvents.length;
            expect(eventCount3, greaterThan(eventCount2), reason: 'Event should be emitted for removeFromSelection');

            selectionManager.toggleSelection(allNodeIds[0]);
            final eventCount4 = emittedEvents.length;
            expect(eventCount4, greaterThan(eventCount3), reason: 'Event should be emitted for toggleSelection');

            selectionManager.clearSelection();
            final eventCount5 = emittedEvents.length;
            expect(eventCount5, greaterThan(eventCount4), reason: 'Event should be emitted for clearSelection');

            // Verify no events are emitted for no-op operations
            emittedEvents.clear();
            selectionManager.selectNode(allNodeIds[0]);
            emittedEvents.clear();
            
            // Selecting same node again should not emit event
            selectionManager.selectNode(allNodeIds[0]);
            expect(emittedEvents, isEmpty, reason: 'No event should be emitted for no-op selection');

            selectionManager.dispose();
          }

        } finally {
          controller.dispose();
        }
      }
    });
  });
}
