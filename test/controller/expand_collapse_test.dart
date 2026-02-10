import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_controller.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_widget.dart';

void main() {
  group('Expand/Collapse Functionality', () {
    late MindMapController controller;
    late NodeData rootNode;
    late NodeData childNode1;
    late NodeData childNode2;
    late NodeData grandchildNode;

    setUp(() {
      // Create a test tree structure
      grandchildNode = NodeData.create(
        id: 'grandchild-1',
        topic: 'Grandchild 1',
        expanded: true,
      );

      childNode1 = NodeData.create(
        id: 'child-1',
        topic: 'Child 1',
        expanded: true,
        children: [grandchildNode],
      );

      childNode2 = NodeData.create(
        id: 'child-2',
        topic: 'Child 2',
        expanded: true,
      );

      rootNode = NodeData.create(
        id: 'root',
        topic: 'Root',
        expanded: true,
        children: [childNode1, childNode2],
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

    test('should toggle node expanded state from true to false', () {
      // Initially expanded
      expect(controller.getData().nodeData.children.first.expanded, true);

      // Toggle to collapsed
      controller.toggleNodeExpanded('child-1');

      // Verify state changed
      final updatedNode = controller.getData().nodeData.children.first;
      expect(updatedNode.expanded, false);
    });

    test('should toggle node expanded state from false to true', () {
      // First collapse the node
      controller.toggleNodeExpanded('child-1');
      expect(controller.getData().nodeData.children.first.expanded, false);

      // Toggle back to expanded
      controller.toggleNodeExpanded('child-1');

      // Verify state changed back
      final updatedNode = controller.getData().nodeData.children.first;
      expect(updatedNode.expanded, true);
    });

    test('should emit ExpandNodeEvent when toggling to collapsed', () {
      ExpandNodeEvent? emittedEvent;
      
      controller.addListener(() {
        final event = controller.lastEvent;
        if (event is ExpandNodeEvent) {
          emittedEvent = event;
        }
      });

      controller.toggleNodeExpanded('child-1');

      expect(emittedEvent, isNotNull);
      expect(emittedEvent!.nodeId, 'child-1');
      expect(emittedEvent!.expanded, false);
    });

    test('should emit ExpandNodeEvent when toggling to expanded', () {
      // First collapse
      controller.toggleNodeExpanded('child-1');
      
      ExpandNodeEvent? emittedEvent;
      controller.addListener(() {
        final event = controller.lastEvent;
        if (event is ExpandNodeEvent) {
          emittedEvent = event;
        }
      });

      // Then expand
      controller.toggleNodeExpanded('child-1');

      expect(emittedEvent, isNotNull);
      expect(emittedEvent!.nodeId, 'child-1');
      expect(emittedEvent!.expanded, true);
    });

    test('should expand a collapsed node', () {
      // First collapse the node
      controller.collapseNode('child-1');
      expect(controller.getData().nodeData.children.first.expanded, false);

      // Expand it
      controller.expandNode('child-1');

      // Verify it's expanded
      final updatedNode = controller.getData().nodeData.children.first;
      expect(updatedNode.expanded, true);
    });

    test('should not emit event when expanding already expanded node', () {
      // Node is already expanded
      expect(controller.getData().nodeData.children.first.expanded, true);

      int listenerCallCount = 0;
      controller.addListener(() {
        listenerCallCount++;
      });

      // Try to expand again
      controller.expandNode('child-1');

      // Should not trigger listener (no change)
      expect(listenerCallCount, 0);
    });

    test('should collapse an expanded node', () {
      // Node is initially expanded
      expect(controller.getData().nodeData.children.first.expanded, true);

      // Collapse it
      controller.collapseNode('child-1');

      // Verify it's collapsed
      final updatedNode = controller.getData().nodeData.children.first;
      expect(updatedNode.expanded, false);
    });

    test('should not emit event when collapsing already collapsed node', () {
      // First collapse the node
      controller.collapseNode('child-1');
      expect(controller.getData().nodeData.children.first.expanded, false);

      int listenerCallCount = 0;
      controller.addListener(() {
        listenerCallCount++;
      });

      // Try to collapse again
      controller.collapseNode('child-1');

      // Should not trigger listener (no change)
      expect(listenerCallCount, 0);
    });

    test('should throw InvalidNodeIdException for non-existent node', () {
      expect(
        () => controller.toggleNodeExpanded('non-existent'),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should persist expanded state in node data', () {
      // Collapse a node
      controller.collapseNode('child-1');

      // Get the data
      final data = controller.getData();
      
      // Verify the expanded state is persisted
      final childNode = data.nodeData.children.first;
      expect(childNode.expanded, false);
      expect(childNode.id, 'child-1');
    });

    test('should handle nested node expansion', () {
      // Collapse parent node
      controller.collapseNode('child-1');
      
      // Verify parent is collapsed
      final parentNode = controller.getData().nodeData.children.first;
      expect(parentNode.expanded, false);
      
      // Grandchild should still exist in data (just not visible)
      expect(parentNode.children.length, 1);
      expect(parentNode.children.first.id, 'grandchild-1');
    });

    test('should allow expanding nested nodes independently', () {
      // Collapse both parent and grandchild
      controller.collapseNode('child-1');
      controller.collapseNode('grandchild-1');
      
      // Expand parent
      controller.expandNode('child-1');
      
      // Parent should be expanded
      final parentNode = controller.getData().nodeData.children.first;
      expect(parentNode.expanded, true);
      
      // Grandchild should still be collapsed
      expect(parentNode.children.first.expanded, false);
    });

    test('should emit correct event when expanding node', () {
      // Collapse first
      controller.collapseNode('child-1');
      
      ExpandNodeEvent? emittedEvent;
      controller.addListener(() {
        final event = controller.lastEvent;
        if (event is ExpandNodeEvent) {
          emittedEvent = event;
        }
      });

      // Expand
      controller.expandNode('child-1');

      expect(emittedEvent, isNotNull);
      expect(emittedEvent!.nodeId, 'child-1');
      expect(emittedEvent!.expanded, true);
    });

    test('should emit correct event when collapsing node', () {
      ExpandNodeEvent? emittedEvent;
      controller.addListener(() {
        final event = controller.lastEvent;
        if (event is ExpandNodeEvent) {
          emittedEvent = event;
        }
      });

      // Collapse
      controller.collapseNode('child-1');

      expect(emittedEvent, isNotNull);
      expect(emittedEvent!.nodeId, 'child-1');
      expect(emittedEvent!.expanded, false);
    });
  });
}
