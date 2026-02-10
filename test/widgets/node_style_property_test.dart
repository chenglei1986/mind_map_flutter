import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';
import '../helpers/generators.dart';

// Feature: mind-map-flutter, Property 33: 节点样式更新

void main() {
  group('Node Style Property Tests', () {
    const iterations = 100;

    // For any node and style attribute (font size, color, background, weight, tags, icons, hyperlink),
    // setting the style should update the node data and trigger re-rendering
    test('Property 33: Node style updates', () {
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

        try {
          // Select a random node to test
          final nodeId = allNodeIds[i % allNodeIds.length];
          final originalNode = controller.getData().nodeData;
          final targetNode = _findNode(originalNode, nodeId);
          expect(targetNode, isNotNull, reason: 'Node should exist');

          // Test 1: Set node font size (Requirement 19.1)
          // THE system SHALL provide a method to set node font size
          final testFontSize = 16.0 + (i % 20).toDouble();
          controller.setNodeFontSize(nodeId, testFontSize);

          // Verify node data was updated
          var updatedData = controller.getData();
          var updatedNode = _findNode(updatedData.nodeData, nodeId);
          expect(updatedNode, isNotNull, reason: 'Node should still exist after update');
          expect(updatedNode!.style, isNotNull, reason: 'Node should have style after font size update');
          expect(updatedNode.style!.fontSize, testFontSize,
              reason: 'Font size should be updated to $testFontSize');

          // Verify controller notified listeners (triggers re-rendering)
          expect(updatedData, isNot(equals(initialData)),
              reason: 'Data should be updated after style change');

          // Test 2: Set node text color (Requirement 19.2)
          // THE system SHALL provide a method to set node text color
          final testColor = Color(0xFF000000 + (i * 1000) % 0xFFFFFF);
          controller.setNodeColor(nodeId, testColor);

          updatedData = controller.getData();
          updatedNode = _findNode(updatedData.nodeData, nodeId);
          expect(updatedNode, isNotNull);
          expect(updatedNode!.style, isNotNull, reason: 'Node should have style after color update');
          expect(updatedNode.style!.color, testColor,
              reason: 'Text color should be updated to $testColor');

          // Test 3: Set node background color (Requirement 19.3)
          // THE system SHALL provide a method to set node background color
          final testBackground = Color(0xFF000000 + ((i + 500) * 1000) % 0xFFFFFF);
          controller.setNodeBackground(nodeId, testBackground);

          updatedData = controller.getData();
          updatedNode = _findNode(updatedData.nodeData, nodeId);
          expect(updatedNode, isNotNull);
          expect(updatedNode!.style, isNotNull, reason: 'Node should have style after background update');
          expect(updatedNode.style!.background, testBackground,
              reason: 'Background color should be updated to $testBackground');

          // Test 4: Set node font weight (Requirement 19.4)
          // THE system SHALL provide a method to set node font weight (bold)
          final testFontWeight = (i % 2 == 0) ? FontWeight.bold : FontWeight.normal;
          controller.setNodeFontWeight(nodeId, testFontWeight);

          updatedData = controller.getData();
          updatedNode = _findNode(updatedData.nodeData, nodeId);
          expect(updatedNode, isNotNull);
          expect(updatedNode!.style, isNotNull, reason: 'Node should have style after font weight update');
          expect(updatedNode.style!.fontWeight, testFontWeight,
              reason: 'Font weight should be updated to $testFontWeight');

          // Test 5: Add and remove tags (Requirement 19.5)
          // THE system SHALL provide methods to add and remove tags from nodes
          final testTag = TagData(text: 'TestTag$i');
          final originalTagCount = updatedNode.tags.length;

          // Add tag
          controller.addNodeTag(nodeId, testTag);

          updatedData = controller.getData();
          updatedNode = _findNode(updatedData.nodeData, nodeId);
          expect(updatedNode, isNotNull);
          expect(updatedNode!.tags.length, originalTagCount + 1,
              reason: 'Tag count should increase by 1 after adding tag');
          expect(updatedNode.tags.any((t) => t.text == testTag.text), isTrue,
              reason: 'Added tag should be present in node tags');

          // Try adding duplicate tag - should not add
          controller.addNodeTag(nodeId, testTag);
          updatedData = controller.getData();
          updatedNode = _findNode(updatedData.nodeData, nodeId);
          expect(updatedNode!.tags.length, originalTagCount + 1,
              reason: 'Duplicate tag should not be added');

          // Remove tag
          controller.removeNodeTag(nodeId, testTag.text);

          updatedData = controller.getData();
          updatedNode = _findNode(updatedData.nodeData, nodeId);
          expect(updatedNode, isNotNull);
          expect(updatedNode!.tags.length, originalTagCount,
              reason: 'Tag count should return to original after removing tag');
          expect(updatedNode.tags.any((t) => t.text == testTag.text), isFalse,
              reason: 'Removed tag should not be present in node tags');

          // Test 6: Add and remove icons (Requirement 19.6)
          // THE system SHALL provide methods to add and remove icons from nodes
          // Use a unique icon that's unlikely to already exist
          final testIcon = '🔮${i}_${DateTime.now().millisecondsSinceEpoch}';
          final originalIconCount = updatedNode.icons.length;

          // Add icon
          controller.addNodeIcon(nodeId, testIcon);

          updatedData = controller.getData();
          updatedNode = _findNode(updatedData.nodeData, nodeId);
          expect(updatedNode, isNotNull);
          expect(updatedNode!.icons.length, originalIconCount + 1,
              reason: 'Icon count should increase by 1 after adding icon');
          expect(updatedNode.icons.contains(testIcon), isTrue,
              reason: 'Added icon should be present in node icons');

          // Try adding duplicate icon - should not add
          controller.addNodeIcon(nodeId, testIcon);
          updatedData = controller.getData();
          updatedNode = _findNode(updatedData.nodeData, nodeId);
          expect(updatedNode!.icons.length, originalIconCount + 1,
              reason: 'Duplicate icon should not be added');

          // Remove icon
          controller.removeNodeIcon(nodeId, testIcon);

          updatedData = controller.getData();
          updatedNode = _findNode(updatedData.nodeData, nodeId);
          expect(updatedNode, isNotNull);
          expect(updatedNode!.icons.length, originalIconCount,
              reason: 'Icon count should return to original after removing icon');
          expect(updatedNode.icons.contains(testIcon), isFalse,
              reason: 'Removed icon should not be present in node icons');

          // Test 7: Set hyperlink (Requirements 19.7, 19.8)
          // THE system SHALL provide a method to set hyperlink on a node
          // WHEN a node has a hyperlink, THE system SHALL provide visual indicator
          // and allow opening the link
          final testHyperLink = 'https://example.com/test$i';

          // Set hyperlink
          controller.setNodeHyperLink(nodeId, testHyperLink);

          updatedData = controller.getData();
          updatedNode = _findNode(updatedData.nodeData, nodeId);
          expect(updatedNode, isNotNull);
          expect(updatedNode!.hyperLink, testHyperLink,
              reason: 'Hyperlink should be updated to $testHyperLink');

          // Remove hyperlink (set to null)
          controller.setNodeHyperLink(nodeId, null);

          updatedData = controller.getData();
          updatedNode = _findNode(updatedData.nodeData, nodeId);
          expect(updatedNode, isNotNull);
          expect(updatedNode!.hyperLink, isNull,
              reason: 'Hyperlink should be removed (null) after setting to null');

          // Test 8: Multiple style updates should accumulate
          // Setting multiple style properties should preserve previous changes
          controller.setNodeFontSize(nodeId, 20.0);
          controller.setNodeColor(nodeId, Colors.red);
          controller.setNodeBackground(nodeId, Colors.yellow);
          controller.setNodeFontWeight(nodeId, FontWeight.bold);

          updatedData = controller.getData();
          updatedNode = _findNode(updatedData.nodeData, nodeId);
          expect(updatedNode, isNotNull);
          expect(updatedNode!.style, isNotNull, reason: 'Node should have style after multiple updates');
          expect(updatedNode.style!.fontSize, 20.0,
              reason: 'Font size should be preserved after multiple updates');
          expect(updatedNode.style!.color, Colors.red,
              reason: 'Color should be preserved after multiple updates');
          expect(updatedNode.style!.background, Colors.yellow,
              reason: 'Background should be preserved after multiple updates');
          expect(updatedNode.style!.fontWeight, FontWeight.bold,
              reason: 'Font weight should be preserved after multiple updates');

          // Test 9: Style updates should trigger re-rendering
          // Verify that notifyListeners is called (data reference changes)
          final dataBeforeStyleUpdate = controller.getData();
          controller.setNodeFontSize(nodeId, 24.0);
          final dataAfterStyleUpdate = controller.getData();

          expect(dataAfterStyleUpdate, isNot(same(dataBeforeStyleUpdate)),
              reason: 'Data reference should change after style update to trigger re-rendering');

          // Test 10: Style updates should work with undo/redo if enabled
          if (controller.canUndo()) {
            // Record current state
            final beforeUndoData = controller.getData();
            final beforeUndoNode = _findNode(beforeUndoData.nodeData, nodeId);
            final beforeUndoStyle = beforeUndoNode!.style;

            // Make a style change
            controller.setNodeFontSize(nodeId, 30.0);
            final afterChangeData = controller.getData();
            final afterChangeNode = _findNode(afterChangeData.nodeData, nodeId);
            expect(afterChangeNode!.style!.fontSize, 30.0);

            // Undo the change
            final undoSuccess = controller.undo();
            expect(undoSuccess, isTrue, reason: 'Undo should succeed');

            final afterUndoData = controller.getData();
            final afterUndoNode = _findNode(afterUndoData.nodeData, nodeId);

            // Style should be reverted
            if (beforeUndoStyle != null) {
              expect(afterUndoNode!.style?.fontSize, beforeUndoStyle.fontSize,
                  reason: 'Font size should be reverted after undo');
            } else {
              // If there was no style before, it should be null or have default values
              expect(afterUndoNode!.style?.fontSize, isNot(30.0),
                  reason: 'Font size should not be 30.0 after undo');
            }
          }

          // Test 11: Invalid node ID should throw exception
          expect(
            () => controller.setNodeFontSize('invalid-node-id', 16.0),
            throwsA(isA<InvalidNodeIdException>()),
            reason: 'Setting style on invalid node ID should throw exception',
          );

          expect(
            () => controller.setNodeColor('invalid-node-id', Colors.red),
            throwsA(isA<InvalidNodeIdException>()),
            reason: 'Setting color on invalid node ID should throw exception',
          );

          expect(
            () => controller.addNodeTag('invalid-node-id', TagData(text: 'test')),
            throwsA(isA<InvalidNodeIdException>()),
            reason: 'Adding tag to invalid node ID should throw exception',
          );

          expect(
            () => controller.addNodeIcon('invalid-node-id', '🎯'),
            throwsA(isA<InvalidNodeIdException>()),
            reason: 'Adding icon to invalid node ID should throw exception',
          );

          expect(
            () => controller.setNodeHyperLink('invalid-node-id', 'https://example.com'),
            throwsA(isA<InvalidNodeIdException>()),
            reason: 'Setting hyperlink on invalid node ID should throw exception',
          );

        } finally {
          controller.dispose();
        }
      }
    });

    // Additional property test: Style updates preserve node structure
    test('Property 33 (Extended): Style updates preserve node structure', () {
      for (int i = 0; i < iterations; i++) {
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 3,
        );

        final controller = MindMapController(initialData: initialData);
        final allNodeIds = collectAllNodeIds(initialData.nodeData).toList();

        try {
          if (allNodeIds.isNotEmpty) {
            final nodeId = allNodeIds[i % allNodeIds.length];
            final originalNode = _findNode(initialData.nodeData, nodeId);

            // Record original node structure
            final originalTopic = originalNode!.topic;
            final originalChildrenCount = originalNode.children.length;
            final originalExpanded = originalNode.expanded;

            // Apply various style updates
            controller.setNodeFontSize(nodeId, 18.0);
            controller.setNodeColor(nodeId, Colors.blue);
            
            // Use unique tag and icon to avoid duplicates
            final uniqueTag = TagData(text: 'TestTag_${i}_${DateTime.now().millisecondsSinceEpoch}');
            final uniqueIcon = '🔮${i}_${DateTime.now().millisecondsSinceEpoch}';
            
            controller.addNodeTag(nodeId, uniqueTag);
            controller.addNodeIcon(nodeId, uniqueIcon);
            controller.setNodeHyperLink(nodeId, 'https://example.com');

            // Verify node structure is preserved
            final updatedData = controller.getData();
            final updatedNode = _findNode(updatedData.nodeData, nodeId);

            expect(updatedNode, isNotNull);
            expect(updatedNode!.id, nodeId,
                reason: 'Node ID should be preserved');
            expect(updatedNode.topic, originalTopic,
                reason: 'Node topic should be preserved');
            expect(updatedNode.children.length, originalChildrenCount,
                reason: 'Node children count should be preserved');
            expect(updatedNode.expanded, originalExpanded,
                reason: 'Node expanded state should be preserved');

            // Verify only style-related properties changed
            expect(updatedNode.style, isNotNull,
                reason: 'Node should have style after updates');
            expect(updatedNode.tags.length, originalNode.tags.length + 1,
                reason: 'One tag should be added');
            expect(updatedNode.icons.length, originalNode.icons.length + 1,
                reason: 'One icon should be added');
            expect(updatedNode.hyperLink, 'https://example.com',
                reason: 'Hyperlink should be set');
          }

        } finally {
          controller.dispose();
        }
      }
    });

    // Additional property test: Style updates are independent per node
    test('Property 33 (Extended): Style updates are independent per node', () {
      for (int i = 0; i < iterations; i++) {
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 3,
        );

        final controller = MindMapController(initialData: initialData);
        final allNodeIds = collectAllNodeIds(initialData.nodeData).toList();

        try {
          if (allNodeIds.length >= 2) {
            final nodeId1 = allNodeIds[0];
            final nodeId2 = allNodeIds[1];

            // Apply different styles to different nodes
            controller.setNodeFontSize(nodeId1, 20.0);
            controller.setNodeColor(nodeId1, Colors.red);

            controller.setNodeFontSize(nodeId2, 16.0);
            controller.setNodeColor(nodeId2, Colors.blue);

            // Verify each node has its own style
            final updatedData = controller.getData();
            final updatedNode1 = _findNode(updatedData.nodeData, nodeId1);
            final updatedNode2 = _findNode(updatedData.nodeData, nodeId2);

            expect(updatedNode1, isNotNull);
            expect(updatedNode2, isNotNull);

            expect(updatedNode1!.style!.fontSize, 20.0,
                reason: 'Node 1 should have font size 20.0');
            expect(updatedNode1.style!.color, Colors.red,
                reason: 'Node 1 should have red color');

            expect(updatedNode2!.style!.fontSize, 16.0,
                reason: 'Node 2 should have font size 16.0');
            expect(updatedNode2.style!.color, Colors.blue,
                reason: 'Node 2 should have blue color');

            // Verify styles are independent
            expect(updatedNode1.style!.fontSize, isNot(equals(updatedNode2.style!.fontSize)),
                reason: 'Node styles should be independent');
            expect(updatedNode1.style!.color, isNot(equals(updatedNode2.style!.color)),
                reason: 'Node colors should be independent');
          }

        } finally {
          controller.dispose();
        }
      }
    });
  });
}

/// Helper function to find a node in the tree
NodeData? _findNode(NodeData node, String nodeId) {
  if (node.id == nodeId) {
    return node;
  }

  for (final child in node.children) {
    final found = _findNode(child, nodeId);
    if (found != null) return found;
  }

  return null;
}
