import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

void main() {
  group('Controller Unit Tests', () {
    late MindMapData testData;
    late MindMapController controller;

    setUp(() {
      testData = MindMapData.empty(rootTopic: '测试根节点');
      controller = MindMapController(initialData: testData);
    });

    tearDown(() {
      controller.dispose();
    });

    // Test root node deletion protection (edge case)
    test('should prevent deletion of root node', () {
      expect(
        () => controller.removeNode(testData.nodeData.id),
        throwsA(isA<RootNodeDeletionException>()),
      );
    });

    // Test default topic name
    test('should create child node with default topic', () {
      controller.addChildNode(testData.nodeData.id, topic: 'Test');
      
      final rootNode = controller.getData().nodeData;
      expect(rootNode.children.length, 1);
      expect(rootNode.children.first.topic, 'Test');
    });

    test('should create sibling node with default topic', () {
      // First add a child
      controller.addChildNode(testData.nodeData.id, topic: 'First');
      final firstChildId = controller.getData().nodeData.children.first.id;
      
      // Then add a sibling
      controller.addSiblingNode(firstChildId, topic: 'Second');
      
      final rootNode = controller.getData().nodeData;
      expect(rootNode.children.length, 2);
      expect(rootNode.children[1].topic, 'Second');
    });

    test('should create node with custom topic', () {
      controller.addChildNode(testData.nodeData.id, topic: '自定义主题');
      
      final rootNode = controller.getData().nodeData;
      expect(rootNode.children.first.topic, '自定义主题');
    });

    // Test operation events emitted
    test('should emit addChild event when adding child node', () {
      controller.addChildNode(testData.nodeData.id, topic: 'Test Node');
      
      expect(controller.lastEvent, isA<NodeOperationEvent>());
      final event = controller.lastEvent as NodeOperationEvent;
      expect(event.operation, 'addChild');
      expect(event.nodeId, isNotEmpty);
    });

    test('should emit addSibling event when adding sibling node', () {
      // First add a child
      controller.addChildNode(testData.nodeData.id, topic: 'First');
      final firstChildId = controller.getData().nodeData.children.first.id;
      
      // Then add a sibling
      controller.addSiblingNode(firstChildId, topic: 'Second');
      
      expect(controller.lastEvent, isA<NodeOperationEvent>());
      final event = controller.lastEvent as NodeOperationEvent;
      expect(event.operation, 'addSibling');
      expect(event.nodeId, isNotEmpty);
    });

    test('should emit removeNode event when deleting node', () {
      // First add a child
      controller.addChildNode(testData.nodeData.id, topic: 'Test');
      final childId = controller.getData().nodeData.children.first.id;
      
      // Then remove it
      controller.removeNode(childId);
      
      expect(controller.lastEvent, isA<NodeOperationEvent>());
      final event = controller.lastEvent as NodeOperationEvent;
      expect(event.operation, 'removeNode');
      expect(event.nodeId, childId);
    });

    test('should throw InvalidNodeIdException for non-existent node', () {
      expect(
        () => controller.addChildNode('non-existent-id'),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should throw InvalidNodeIdException when adding sibling to non-existent node', () {
      expect(
        () => controller.addSiblingNode('non-existent-id'),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should throw InvalidNodeIdException when removing non-existent node', () {
      expect(
        () => controller.removeNode('non-existent-id'),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should maintain tree structure after multiple operations', () {
      // Add multiple children
      controller.addChildNode(testData.nodeData.id, topic: 'Child 1');
      controller.addChildNode(testData.nodeData.id, topic: 'Child 2');
      controller.addChildNode(testData.nodeData.id, topic: 'Child 3');
      
      final rootNode = controller.getData().nodeData;
      expect(rootNode.children.length, 3);
      expect(rootNode.children[0].topic, 'Child 1');
      expect(rootNode.children[1].topic, 'Child 2');
      expect(rootNode.children[2].topic, 'Child 3');
    });

    test('should assign branch color for new root child', () {
      controller.addChildNode(testData.nodeData.id, topic: 'Child A');

      final rootNode = controller.getData().nodeData;
      expect(rootNode.children.length, 1);
      expect(rootNode.children.first.branchColor, isNotNull);
    });

    test('should inherit branch color for non-root child', () {
      controller.addChildNode(testData.nodeData.id, topic: 'Child A');
      final childA = controller.getData().nodeData.children.first;

      controller.addChildNode(childA.id, topic: 'Grandchild A1');

      final updatedRoot = controller.getData().nodeData;
      final updatedChildA = updatedRoot.children.first;
      expect(updatedChildA.children.length, 1);
      expect(updatedChildA.children.first.branchColor, updatedChildA.branchColor);
    });

    test('should assign branch color for root-level sibling', () {
      controller.addChildNode(testData.nodeData.id, topic: 'Child A');
      final firstChildId = controller.getData().nodeData.children.first.id;

      controller.addSiblingNode(firstChildId, topic: 'Child B');

      final rootNode = controller.getData().nodeData;
      expect(rootNode.children.length, 2);
      expect(rootNode.children[1].branchColor, isNotNull);
    });

    test('should inherit branch color for non-root sibling', () {
      controller.addChildNode(testData.nodeData.id, topic: 'Child A');
      final childA = controller.getData().nodeData.children.first;
      controller.addChildNode(childA.id, topic: 'Grandchild A1');
      final grandchildId = controller
          .getData()
          .nodeData
          .children
          .first
          .children
          .first
          .id;

      controller.addSiblingNode(grandchildId, topic: 'Grandchild A2');

      final updatedRoot = controller.getData().nodeData;
      final updatedChildA = updatedRoot.children.first;
      expect(updatedChildA.children.length, 2);
      expect(
        updatedChildA.children[1].branchColor,
        updatedChildA.children[0].branchColor,
      );
    });

    test('should refresh data correctly', () {
      final newData = MindMapData.empty(rootTopic: '新根节点');
      controller.refresh(newData);
      
      expect(controller.getData().nodeData.topic, '新根节点');
      expect(controller.lastEvent, isNull);
    });

    test('should clear selection when refreshing data', () {
      // This test verifies that selection is cleared
      // Full selection functionality will be tested in task 7
      controller.refresh(testData);
      expect(controller.getSelectedNodeIds(), isEmpty);
    });
  });

  group('Node Style Methods Unit Tests', () {
    late MindMapData testData;
    late MindMapController controller;
    late String childNodeId;

    setUp(() {
      testData = MindMapData.empty(rootTopic: '测试根节点');
      controller = MindMapController(initialData: testData);
      
      // Add a child node for testing
      controller.addChildNode(testData.nodeData.id, topic: '测试节点');
      childNodeId = controller.getData().nodeData.children.first.id;
    });

    tearDown(() {
      controller.dispose();
    });

    // Test setNodeFontSize
    test('should set node font size', () {
      controller.setNodeFontSize(childNodeId, 24.0);
      
      final node = controller.getData().nodeData.children.first;
      expect(node.style, isNotNull);
      expect(node.style!.fontSize, 24.0);
    });

    test('should update existing style when setting font size', () {
      // First set a color
      controller.setNodeColor(childNodeId, Colors.red);
      
      // Then set font size
      controller.setNodeFontSize(childNodeId, 20.0);
      
      final node = controller.getData().nodeData.children.first;
      expect(node.style!.fontSize, 20.0);
      expect(node.style!.color, Colors.red); // Color should be preserved
    });

    // Test setNodeColor
    test('should set node text color', () {
      controller.setNodeColor(childNodeId, Colors.blue);
      
      final node = controller.getData().nodeData.children.first;
      expect(node.style, isNotNull);
      expect(node.style!.color, Colors.blue);
    });

    // Test setNodeBackground
    test('should set node background color', () {
      controller.setNodeBackground(childNodeId, Colors.yellow);
      
      final node = controller.getData().nodeData.children.first;
      expect(node.style, isNotNull);
      expect(node.style!.background, Colors.yellow);
    });

    // Test setNodeFontWeight
    test('should set node font weight', () {
      controller.setNodeFontWeight(childNodeId, FontWeight.bold);
      
      final node = controller.getData().nodeData.children.first;
      expect(node.style, isNotNull);
      expect(node.style!.fontWeight, FontWeight.bold);
    });

    test('should set node font weight to normal', () {
      // First set to bold
      controller.setNodeFontWeight(childNodeId, FontWeight.bold);
      
      // Then set to normal
      controller.setNodeFontWeight(childNodeId, FontWeight.normal);
      
      final node = controller.getData().nodeData.children.first;
      expect(node.style!.fontWeight, FontWeight.normal);
    });

    // Test addNodeTag and removeNodeTag
    test('should add tag to node', () {
      final tag = TagData(text: '重要');
      controller.addNodeTag(childNodeId, tag);
      
      final node = controller.getData().nodeData.children.first;
      expect(node.tags.length, 1);
      expect(node.tags.first.text, '重要');
    });

    test('should add multiple tags to node', () {
      final tag1 = TagData(text: '重要');
      final tag2 = TagData(text: '紧急');
      
      controller.addNodeTag(childNodeId, tag1);
      controller.addNodeTag(childNodeId, tag2);
      
      final node = controller.getData().nodeData.children.first;
      expect(node.tags.length, 2);
      expect(node.tags[0].text, '重要');
      expect(node.tags[1].text, '紧急');
    });

    test('should not add duplicate tag', () {
      final tag = TagData(text: '重要');
      
      controller.addNodeTag(childNodeId, tag);
      controller.addNodeTag(childNodeId, tag); // Try to add again
      
      final node = controller.getData().nodeData.children.first;
      expect(node.tags.length, 1); // Should still be 1
    });

    test('should remove tag from node', () {
      final tag = TagData(text: '重要');
      controller.addNodeTag(childNodeId, tag);
      
      // Verify tag was added
      var node = controller.getData().nodeData.children.first;
      expect(node.tags.length, 1);
      
      // Remove tag
      controller.removeNodeTag(childNodeId, '重要');
      
      node = controller.getData().nodeData.children.first;
      expect(node.tags.length, 0);
    });

    test('should remove specific tag when multiple tags exist', () {
      final tag1 = TagData(text: '重要');
      final tag2 = TagData(text: '紧急');
      
      controller.addNodeTag(childNodeId, tag1);
      controller.addNodeTag(childNodeId, tag2);
      
      // Remove only the first tag
      controller.removeNodeTag(childNodeId, '重要');
      
      final node = controller.getData().nodeData.children.first;
      expect(node.tags.length, 1);
      expect(node.tags.first.text, '紧急');
    });

    // Test addNodeIcon and removeNodeIcon
    test('should add icon to node', () {
      controller.addNodeIcon(childNodeId, '⭐');
      
      final node = controller.getData().nodeData.children.first;
      expect(node.icons.length, 1);
      expect(node.icons.first, '⭐');
    });

    test('should add multiple icons to node', () {
      controller.addNodeIcon(childNodeId, '⭐');
      controller.addNodeIcon(childNodeId, '🔥');
      
      final node = controller.getData().nodeData.children.first;
      expect(node.icons.length, 2);
      expect(node.icons[0], '⭐');
      expect(node.icons[1], '🔥');
    });

    test('should not add duplicate icon', () {
      controller.addNodeIcon(childNodeId, '⭐');
      controller.addNodeIcon(childNodeId, '⭐'); // Try to add again
      
      final node = controller.getData().nodeData.children.first;
      expect(node.icons.length, 1); // Should still be 1
    });

    test('should remove icon from node', () {
      controller.addNodeIcon(childNodeId, '⭐');
      
      // Verify icon was added
      var node = controller.getData().nodeData.children.first;
      expect(node.icons.length, 1);
      
      // Remove icon
      controller.removeNodeIcon(childNodeId, '⭐');
      
      node = controller.getData().nodeData.children.first;
      expect(node.icons.length, 0);
    });

    test('should remove specific icon when multiple icons exist', () {
      controller.addNodeIcon(childNodeId, '⭐');
      controller.addNodeIcon(childNodeId, '🔥');
      
      // Remove only the first icon
      controller.removeNodeIcon(childNodeId, '⭐');
      
      final node = controller.getData().nodeData.children.first;
      expect(node.icons.length, 1);
      expect(node.icons.first, '🔥');
    });

    // Test setNodeHyperLink
    test('should set hyperlink on node', () {
      controller.setNodeHyperLink(childNodeId, 'https://example.com');
      
      final node = controller.getData().nodeData.children.first;
      expect(node.hyperLink, 'https://example.com');
    });

    test('should update existing hyperlink', () {
      controller.setNodeHyperLink(childNodeId, 'https://example.com');
      controller.setNodeHyperLink(childNodeId, 'https://newurl.com');
      
      final node = controller.getData().nodeData.children.first;
      expect(node.hyperLink, 'https://newurl.com');
    });

    test('should remove hyperlink by setting null', () {
      controller.setNodeHyperLink(childNodeId, 'https://example.com');
      
      // Verify hyperlink was set
      var node = controller.getData().nodeData.children.first;
      expect(node.hyperLink, 'https://example.com');
      
      // Remove hyperlink
      controller.setNodeHyperLink(childNodeId, null);
      
      node = controller.getData().nodeData.children.first;
      expect(node.hyperLink, isNull);
    });

    // Test error handling
    test('should throw InvalidNodeIdException when setting style on non-existent node', () {
      expect(
        () => controller.setNodeFontSize('non-existent-id', 20.0),
        throwsA(isA<InvalidNodeIdException>()),
      );
      
      expect(
        () => controller.setNodeColor('non-existent-id', Colors.red),
        throwsA(isA<InvalidNodeIdException>()),
      );
      
      expect(
        () => controller.setNodeBackground('non-existent-id', Colors.blue),
        throwsA(isA<InvalidNodeIdException>()),
      );
      
      expect(
        () => controller.setNodeFontWeight('non-existent-id', FontWeight.bold),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should throw InvalidNodeIdException when adding tag to non-existent node', () {
      expect(
        () => controller.addNodeTag('non-existent-id', TagData(text: 'test')),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should throw InvalidNodeIdException when adding icon to non-existent node', () {
      expect(
        () => controller.addNodeIcon('non-existent-id', '⭐'),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should throw InvalidNodeIdException when setting hyperlink on non-existent node', () {
      expect(
        () => controller.setNodeHyperLink('non-existent-id', 'https://example.com'),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    // Test combined style operations
    test('should apply multiple style properties to same node', () {
      controller.setNodeFontSize(childNodeId, 24.0);
      controller.setNodeColor(childNodeId, Colors.red);
      controller.setNodeBackground(childNodeId, Colors.yellow);
      controller.setNodeFontWeight(childNodeId, FontWeight.bold);
      
      final node = controller.getData().nodeData.children.first;
      expect(node.style!.fontSize, 24.0);
      expect(node.style!.color, Colors.red);
      expect(node.style!.background, Colors.yellow);
      expect(node.style!.fontWeight, FontWeight.bold);
    });

    test('should apply style, tags, icons, and hyperlink to same node', () {
      controller.setNodeFontSize(childNodeId, 20.0);
      controller.addNodeTag(childNodeId, TagData(text: '重要'));
      controller.addNodeIcon(childNodeId, '⭐');
      controller.setNodeHyperLink(childNodeId, 'https://example.com');
      
      final node = controller.getData().nodeData.children.first;
      expect(node.style!.fontSize, 20.0);
      expect(node.tags.length, 1);
      expect(node.icons.length, 1);
      expect(node.hyperLink, 'https://example.com');
    });
  });
}
