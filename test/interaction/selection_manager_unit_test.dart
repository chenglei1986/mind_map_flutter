import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

void main() {
  group('SelectionManager Unit Tests', () {
    late SelectionManager selectionManager;
    List<SelectNodesEvent> emittedEvents = [];

    setUp(() {
      emittedEvents = [];
      selectionManager = SelectionManager(
        onSelectionChanged: (event) {
          emittedEvents.add(event);
        },
      );
    });

    tearDown(() {
      selectionManager.dispose();
    });

    // Test single selection
    // Validates: Requirement 6.1
    test('should select a single node and clear previous selection', () {
      selectionManager.selectNode('node1');
      expect(selectionManager.selectedNodeIds, ['node1']);
      expect(selectionManager.isSelected('node1'), isTrue);

      // Select another node - should clear previous selection
      selectionManager.selectNode('node2');
      expect(selectionManager.selectedNodeIds, ['node2']);
      expect(selectionManager.isSelected('node1'), isFalse);
      expect(selectionManager.isSelected('node2'), isTrue);
    });

    test('should not emit event when selecting already selected node', () {
      selectionManager.selectNode('node1');
      emittedEvents.clear();

      // Select the same node again
      selectionManager.selectNode('node1');
      expect(emittedEvents, isEmpty);
    });

    // Test multi-selection
    // Validates: Requirement 6.2
    test('should add node to selection without clearing previous selection', () {
      selectionManager.selectNode('node1');
      selectionManager.addToSelection('node2');
      selectionManager.addToSelection('node3');

      expect(selectionManager.selectedNodeIds, ['node1', 'node2', 'node3']);
      expect(selectionManager.isSelected('node1'), isTrue);
      expect(selectionManager.isSelected('node2'), isTrue);
      expect(selectionManager.isSelected('node3'), isTrue);
    });

    test('should not emit event when adding already selected node', () {
      selectionManager.selectNode('node1');
      selectionManager.addToSelection('node2');
      emittedEvents.clear();

      // Add node2 again
      selectionManager.addToSelection('node2');
      expect(emittedEvents, isEmpty);
    });

    test('should toggle node selection', () {
      // Toggle on
      selectionManager.toggleSelection('node1');
      expect(selectionManager.isSelected('node1'), isTrue);

      // Toggle off
      selectionManager.toggleSelection('node1');
      expect(selectionManager.isSelected('node1'), isFalse);

      // Toggle on again
      selectionManager.toggleSelection('node1');
      expect(selectionManager.isSelected('node1'), isTrue);
    });

    test('should toggle multiple nodes independently', () {
      selectionManager.toggleSelection('node1');
      selectionManager.toggleSelection('node2');
      expect(selectionManager.selectedNodeIds, ['node1', 'node2']);

      // Toggle off node1
      selectionManager.toggleSelection('node1');
      expect(selectionManager.selectedNodeIds, ['node2']);

      // Toggle on node3
      selectionManager.toggleSelection('node3');
      expect(selectionManager.selectedNodeIds, ['node2', 'node3']);
    });

    test('should remove node from selection', () {
      selectionManager.selectNode('node1');
      selectionManager.addToSelection('node2');
      selectionManager.addToSelection('node3');

      selectionManager.removeFromSelection('node2');
      expect(selectionManager.selectedNodeIds, ['node1', 'node3']);
      expect(selectionManager.isSelected('node2'), isFalse);
    });

    test('should not emit event when removing non-selected node', () {
      selectionManager.selectNode('node1');
      emittedEvents.clear();

      selectionManager.removeFromSelection('node2');
      expect(emittedEvents, isEmpty);
    });

    // Test batch selection
    // Validates: Requirement 6.3
    test('should select multiple nodes at once', () {
      selectionManager.selectNodes(['node1', 'node2', 'node3']);
      expect(selectionManager.selectedNodeIds, ['node1', 'node2', 'node3']);
    });

    test('should replace selection when selecting multiple nodes', () {
      selectionManager.selectNode('node1');
      selectionManager.selectNodes(['node2', 'node3', 'node4']);
      expect(selectionManager.selectedNodeIds, ['node2', 'node3', 'node4']);
      expect(selectionManager.isSelected('node1'), isFalse);
    });

    test('should not emit event when selecting same nodes', () {
      selectionManager.selectNodes(['node1', 'node2']);
      emittedEvents.clear();

      selectionManager.selectNodes(['node1', 'node2']);
      expect(emittedEvents, isEmpty);
    });

    test('should clear all selections', () {
      selectionManager.selectNodes(['node1', 'node2', 'node3']);
      expect(selectionManager.selectedNodeIds.length, 3);

      selectionManager.clearSelection();
      expect(selectionManager.selectedNodeIds, isEmpty);
    });

    test('should not emit event when clearing empty selection', () {
      selectionManager.clearSelection();
      emittedEvents.clear();

      selectionManager.clearSelection();
      expect(emittedEvents, isEmpty);
    });

    // Test event emission
    // Validates: Requirement 6.5
    test('should emit selectNodes event when selection changes', () {
      selectionManager.selectNode('node1');
      expect(emittedEvents.length, 1);
      expect(emittedEvents.last.nodeIds, ['node1']);

      selectionManager.addToSelection('node2');
      expect(emittedEvents.length, 2);
      expect(emittedEvents.last.nodeIds, ['node1', 'node2']);

      selectionManager.clearSelection();
      expect(emittedEvents.length, 3);
      expect(emittedEvents.last.nodeIds, isEmpty);
    });

    test('should emit event with correct node IDs', () {
      selectionManager.selectNodes(['node1', 'node2', 'node3']);
      expect(emittedEvents.length, 1);
      expect(emittedEvents.last.nodeIds, ['node1', 'node2', 'node3']);
    });

    // Test state management
    // Validates: Requirement 6.6
    test('should maintain selection state correctly', () {
      selectionManager.selectNode('node1');
      expect(selectionManager.selectedNodeIds, ['node1']);

      selectionManager.addToSelection('node2');
      expect(selectionManager.selectedNodeIds, ['node1', 'node2']);

      selectionManager.removeFromSelection('node1');
      expect(selectionManager.selectedNodeIds, ['node2']);

      selectionManager.clearSelection();
      expect(selectionManager.selectedNodeIds, isEmpty);
    });

    test('should return immutable list of selected node IDs', () {
      selectionManager.selectNode('node1');
      final selectedIds = selectionManager.selectedNodeIds;

      // Try to modify the returned list (should not affect internal state)
      expect(() => selectedIds.add('node2'), throwsUnsupportedError);
    });

    test('should handle empty selection correctly', () {
      expect(selectionManager.selectedNodeIds, isEmpty);
      expect(selectionManager.isSelected('node1'), isFalse);
    });

    test('should handle selection of same node multiple times', () {
      selectionManager.selectNode('node1');
      selectionManager.selectNode('node1');
      expect(selectionManager.selectedNodeIds, ['node1']);
    });
  });
}
