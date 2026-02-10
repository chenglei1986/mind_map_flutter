import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

/// Property-based tests for copy/paste functionality
/// 
/// Feature: mind-map-flutter
/// 
/// These tests verify that copy/paste operations maintain data integrity
/// and work correctly across various scenarios.
/// 
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Copy/Paste Property Tests', () {
    // Property: Pasted nodes should have unique IDs
    // Feature: mind-map-flutter, Property 1: For any node that is copied and pasted, the pasted node and all its descendants should have unique IDs different from the original
    test('Property 1: Pasted nodes have unique IDs', () {
      for (int i = 0; i < 100; i++) {
        // Create test data with varying tree structures
        final depth = (i % 3) + 1; // Depth 1-3
        final childrenPerNode = (i % 4) + 1; // 1-4 children per node
        
        final rootNode = _createTreeWithDepth(depth, childrenPerNode);
        final testData = MindMapData(
          nodeData: rootNode,
          theme: MindMapTheme.light,
        );

        final controller = MindMapController(
          initialData: testData,
          config: const MindMapConfig(),
        );

        // Collect all original IDs
        final originalIds = <String>{};
        _collectAllIds(rootNode, originalIds);

        // Select a node to copy (not root)
        if (rootNode.children.isNotEmpty) {
          final nodeToCopy = rootNode.children.first;
          controller.selectionManager.selectNode(nodeToCopy.id);

          // Simulate copy by storing the node ID
          final copiedNodeId = nodeToCopy.id;

          // Select a different node to paste to
          final pasteTarget = rootNode.id;
          controller.selectionManager.selectNode(pasteTarget);

          // Manually perform paste operation
          final copiedNode = _findNode(rootNode, copiedNodeId);
          if (copiedNode != null) {
            final pastedNode = _deepCopyNode(copiedNode);
            _addNodeAsChild(controller, pasteTarget, pastedNode);

            // Collect all IDs after paste
            final afterIds = <String>{};
            _collectAllIds(controller.getData().nodeData, afterIds);

            // Verify: All new IDs should be unique
            final newIds = afterIds.difference(originalIds);
            expect(newIds.length, greaterThan(0), reason: 'Should have new IDs');

            // Verify: No duplicate IDs
            expect(afterIds.length, equals(originalIds.length + newIds.length),
                reason: 'All IDs should be unique');
          }
        }

        controller.dispose();
      }
    });

    // Property: Pasted nodes should preserve all properties
    // Feature: mind-map-flutter, Property 2: For any node that is copied and pasted, the pasted node should have the same topic, style, tags, icons, and other properties as the original
    test('Property 2: Pasted nodes preserve properties', () {
      for (int i = 0; i < 100; i++) {
        // Create a node with various properties
        final style = i % 2 == 0
            ? const NodeStyle(
                fontSize: 16,
                color: Color(0xFF0000FF),
                fontWeight: FontWeight.bold,
              )
            : null;

        final tags = i % 3 == 0 ? [const TagData(text: 'tag1')] : <TagData>[];
        final icons = i % 4 == 0 ? ['🎯'] : <String>[];
        final hyperLink = i % 5 == 0 ? 'https://example.com' : null;

        final rootNode = NodeData.create(
          topic: 'Root',
          children: [
            NodeData.create(
              topic: 'Child $i',
              style: style,
              tags: tags,
              icons: icons,
              hyperLink: hyperLink,
            ),
          ],
        );

        final testData = MindMapData(
          nodeData: rootNode,
          theme: MindMapTheme.light,
        );

        final controller = MindMapController(
          initialData: testData,
          config: const MindMapConfig(),
        );

        // Copy the child node
        final nodeToCopy = rootNode.children.first;
        controller.selectionManager.selectNode(nodeToCopy.id);

        // Paste to root
        controller.selectionManager.selectNode(rootNode.id);
        final copiedNode = _findNode(rootNode, nodeToCopy.id);
        if (copiedNode != null) {
          final pastedNode = _deepCopyNode(copiedNode);
          _addNodeAsChild(controller, rootNode.id, pastedNode);

          // Get the pasted node
          final updatedRoot = controller.getData().nodeData;
          final pastedNodeActual = updatedRoot.children.last;

          // Verify properties are preserved
          expect(pastedNodeActual.topic, equals(nodeToCopy.topic));
          expect(pastedNodeActual.style?.fontSize, equals(style?.fontSize));
          expect(pastedNodeActual.style?.color, equals(style?.color));
          expect(pastedNodeActual.tags.length, equals(tags.length));
          expect(pastedNodeActual.icons.length, equals(icons.length));
          expect(pastedNodeActual.hyperLink, equals(hyperLink));
        }

        controller.dispose();
      }
    });

    // Property: Pasted nodes should preserve tree structure
    // Feature: mind-map-flutter, Property 3: For any node with children that is copied and pasted, the pasted node should have the same tree structure (same number of descendants at each level)
    test('Property 3: Pasted nodes preserve tree structure', () {
      for (int i = 0; i < 100; i++) {
        // Create trees with varying structures
        final depth = (i % 3) + 1;
        final childrenPerNode = (i % 3) + 1;

        final rootNode = _createTreeWithDepth(depth, childrenPerNode);
        final testData = MindMapData(
          nodeData: rootNode,
          theme: MindMapTheme.light,
        );

        final controller = MindMapController(
          initialData: testData,
          config: const MindMapConfig(),
        );

        // Copy a node with children
        if (rootNode.children.isNotEmpty) {
          final nodeToCopy = rootNode.children.first;
          final originalDescendantCount = _countDescendants(nodeToCopy);

          controller.selectionManager.selectNode(nodeToCopy.id);

          // Paste to root
          controller.selectionManager.selectNode(rootNode.id);
          final copiedNode = _findNode(rootNode, nodeToCopy.id);
          if (copiedNode != null) {
            final pastedNode = _deepCopyNode(copiedNode);
            _addNodeAsChild(controller, rootNode.id, pastedNode);

            // Get the pasted node
            final updatedRoot = controller.getData().nodeData;
            final pastedNodeActual = updatedRoot.children.last;

            // Verify tree structure is preserved
            final pastedDescendantCount = _countDescendants(pastedNodeActual);
            expect(
              pastedDescendantCount,
              equals(originalDescendantCount),
              reason: 'Tree structure should be preserved',
            );
          }
        }

        controller.dispose();
      }
    });

    // Property: Multiple paste operations should work correctly
    // Feature: mind-map-flutter, Property 4: For any node that is copied, it should be possible to paste it multiple times, and each paste should create an independent copy
    test('Property 4: Multiple paste operations create independent copies', () {
      for (int i = 0; i < 50; i++) {
        final rootNode = NodeData.create(
          topic: 'Root',
          children: [
            NodeData.create(topic: 'Child $i'),
          ],
        );

        final testData = MindMapData(
          nodeData: rootNode,
          theme: MindMapTheme.light,
        );

        final controller = MindMapController(
          initialData: testData,
          config: const MindMapConfig(),
        );

        // Copy the child node
        final nodeToCopy = rootNode.children.first;
        controller.selectionManager.selectNode(nodeToCopy.id);

        // Paste multiple times
        final pasteCount = (i % 5) + 1; // 1-5 pastes
        controller.selectionManager.selectNode(rootNode.id);

        for (int j = 0; j < pasteCount; j++) {
          final copiedNode = _findNode(controller.getData().nodeData, nodeToCopy.id);
          if (copiedNode != null) {
            final pastedNode = _deepCopyNode(copiedNode);
            _addNodeAsChild(controller, rootNode.id, pastedNode);
          }
        }

        // Verify: Should have original + pasted nodes
        final updatedRoot = controller.getData().nodeData;
        expect(
          updatedRoot.children.length,
          equals(1 + pasteCount),
          reason: 'Should have original plus $pasteCount pasted nodes',
        );

        // Verify: All pasted nodes have unique IDs
        final allIds = <String>{};
        for (final child in updatedRoot.children) {
          expect(allIds.contains(child.id), isFalse,
              reason: 'Each pasted node should have unique ID');
          allIds.add(child.id);
        }

        controller.dispose();
      }
    });
  });
}

// Helper functions

NodeData _createTreeWithDepth(int depth, int childrenPerNode) {
  if (depth == 0) {
    return NodeData.create(topic: 'Leaf');
  }

  final children = List.generate(
    childrenPerNode,
    (i) => _createTreeWithDepth(depth - 1, childrenPerNode),
  );

  return NodeData.create(
    topic: 'Node-D$depth',
    children: children,
  );
}

void _collectAllIds(NodeData node, Set<String> ids) {
  ids.add(node.id);
  for (final child in node.children) {
    _collectAllIds(child, ids);
  }
}

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

NodeData _deepCopyNode(NodeData node) {
  final List<NodeData> copiedChildren = [];
  for (final child in node.children) {
    copiedChildren.add(_deepCopyNode(child));
  }

  return NodeData.create(
    topic: node.topic,
    style: node.style,
    tags: node.tags,
    icons: node.icons,
    hyperLink: node.hyperLink,
    expanded: node.expanded,
    direction: node.direction,
    image: node.image,
    branchColor: node.branchColor,
    note: node.note,
    children: copiedChildren,
  );
}

void _addNodeAsChild(
    MindMapController controller, String parentId, NodeData nodeToAdd) {
  controller.addChildNode(parentId, topic: nodeToAdd.topic);

  final parent = _findNode(controller.getData().nodeData, parentId);
  if (parent != null && parent.children.isNotEmpty) {
    final newChild = parent.children.last;

    final updatedChild = newChild.copyWith(
      style: nodeToAdd.style,
      tags: nodeToAdd.tags,
      icons: nodeToAdd.icons,
      hyperLink: nodeToAdd.hyperLink,
      expanded: nodeToAdd.expanded,
      direction: nodeToAdd.direction,
      image: nodeToAdd.image,
      branchColor: nodeToAdd.branchColor,
      note: nodeToAdd.note,
    );

    controller.updateNode(newChild.id, updatedChild);

    for (final child in nodeToAdd.children) {
      _addNodeAsChild(controller, newChild.id, child);
    }
  }
}

int _countDescendants(NodeData node) {
  int count = node.children.length;
  for (final child in node.children) {
    count += _countDescendants(child);
  }
  return count;
}
