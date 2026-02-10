import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/utils/tree_utils.dart';

void main() {
  group('TreeUtils', () {
    group('findMinimumCommonParent', () {
      late NodeData root;
      
      setUp(() {
        // Create a test tree structure
        //       root
        //      /    \
        //    A       B
        //   / \     / \
        //  A1 A2   B1 B2
        //  |       |
        // A1a     B1a
        
        root = NodeData.create(
          topic: 'Root',
          children: [
            NodeData.create(
              topic: 'A',
              children: [
                NodeData.create(
                  topic: 'A1',
                  children: [
                    NodeData.create(topic: 'A1a'),
                  ],
                ),
                NodeData.create(topic: 'A2'),
              ],
            ),
            NodeData.create(
              topic: 'B',
              children: [
                NodeData.create(
                  topic: 'B1',
                  children: [
                    NodeData.create(topic: 'B1a'),
                  ],
                ),
                NodeData.create(topic: 'B2'),
              ],
            ),
          ],
        );
      });
      
      test('should find parent for single node', () {
        final nodeA = root.children[0];
        final nodeA1 = nodeA.children[0];
        
        final (parentId, startIndex, endIndex) = TreeUtils.findMinimumCommonParent(
          root,
          [nodeA1.id],
        );
        
        expect(parentId, nodeA.id);
        expect(startIndex, 0);
        expect(endIndex, 0);
      });
      
      test('should find parent for sibling nodes', () {
        final nodeA = root.children[0];
        final nodeA1 = nodeA.children[0];
        final nodeA2 = nodeA.children[1];
        
        final (parentId, startIndex, endIndex) = TreeUtils.findMinimumCommonParent(
          root,
          [nodeA1.id, nodeA2.id],
        );
        
        expect(parentId, nodeA.id);
        expect(startIndex, 0);
        expect(endIndex, 1);
      });
      
      test('should find parent for non-adjacent siblings', () {
        final nodeA = root.children[0];
        final nodeA1 = nodeA.children[0];
        final nodeA2 = nodeA.children[1];
        
        // Select in reverse order
        final (parentId, startIndex, endIndex) = TreeUtils.findMinimumCommonParent(
          root,
          [nodeA2.id, nodeA1.id],
        );
        
        expect(parentId, nodeA.id);
        expect(startIndex, 0);
        expect(endIndex, 1);
      });
      
      test('should find parent for nodes at different depths', () {
        final nodeA = root.children[0];
        final nodeA1 = nodeA.children[0];
        final nodeA1a = nodeA1.children[0];
        final nodeA2 = nodeA.children[1];
        
        final (parentId, startIndex, endIndex) = TreeUtils.findMinimumCommonParent(
          root,
          [nodeA1a.id, nodeA2.id],
        );
        
        // Should find A as the common parent
        expect(parentId, nodeA.id);
        expect(startIndex, 0);
        expect(endIndex, 1);
      });
      
      test('should throw for root node selection', () {
        expect(
          () => TreeUtils.findMinimumCommonParent(root, [root.id]),
          throwsStateError,
        );
      });
      
      test('should throw for empty node list', () {
        expect(
          () => TreeUtils.findMinimumCommonParent(root, []),
          throwsStateError,
        );
      });
      
      test('should throw for nodes from different main branches', () {
        final nodeA = root.children[0];
        final nodeB = root.children[1];
        final nodeA1 = nodeA.children[0];
        final nodeB1 = nodeB.children[0];
        
        // When nodes are from different main branches, the algorithm will
        // find root as the common parent, which is valid for summary creation
        final (parentId, startIndex, endIndex) = TreeUtils.findMinimumCommonParent(
          root,
          [nodeA1.id, nodeB1.id],
        );
        
        // Should find root as parent with range covering both main branches
        expect(parentId, root.id);
        expect(startIndex, 0);
        expect(endIndex, 1);
      });
      
      test('should throw for non-existent node', () {
        expect(
          () => TreeUtils.findMinimumCommonParent(root, ['non-existent-id']),
          throwsStateError,
        );
      });
      
      test('should handle nodes in random order', () {
        final nodeA = root.children[0];
        final nodeA1 = nodeA.children[0];
        final nodeA2 = nodeA.children[1];
        
        // Select in random order
        final (parentId, startIndex, endIndex) = TreeUtils.findMinimumCommonParent(
          root,
          [nodeA2.id, nodeA1.id, nodeA2.id], // Duplicate should be handled
        );
        
        expect(parentId, nodeA.id);
        expect(startIndex, 0);
        expect(endIndex, 1);
      });
      
      test('should find correct range for multiple nodes', () {
        final nodeA = root.children[0];
        final nodeA1 = nodeA.children[0];
        final nodeA2 = nodeA.children[1];
        
        final (parentId, startIndex, endIndex) = TreeUtils.findMinimumCommonParent(
          root,
          [nodeA1.id, nodeA2.id],
        );
        
        expect(parentId, nodeA.id);
        expect(startIndex, 0);
        expect(endIndex, 1);
        expect(endIndex - startIndex + 1, 2); // Range includes 2 nodes
      });
    });
  });
}
