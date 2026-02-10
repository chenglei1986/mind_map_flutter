import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';
import '../helpers/generators.dart';

void main() {
  group('Layout Engine Property Tests', () {
    const iterations = 100;

    // Feature: mind-map-flutter, Property 2: Node layout direction consistency
    test('Property 2: Node layout direction consistency - child positions should match direction', () {
      final layoutEngine = LayoutEngine();

      for (int i = 0; i < iterations; i++) {
        // Generate a random mind map with children
        final mindMapData = generateRandomMindMapData(
          maxDepth: 3,
          maxChildren: 4,
        );

        // Test all three directions
        for (final direction in LayoutDirection.values) {
          final layouts = layoutEngine.calculateLayout(
            mindMapData.nodeData,
            mindMapData.theme,
            direction,
          );

          // Get root layout
          final rootLayout = layouts[mindMapData.nodeData.id];
          expect(rootLayout, isNotNull, reason: 'Root node should have layout');

          // Check each child's position relative to parent
          _verifyChildrenDirection(
            mindMapData.nodeData,
            layouts,
            direction,
            isRoot: true,
          );
        }
      }
    });
  });
}

/// Recursively verify that children are positioned according to direction
void _verifyChildrenDirection(
  NodeData node,
  Map<String, NodeLayout> layouts,
  LayoutDirection direction, {
  required bool isRoot,
}) {
  if (node.children.isEmpty || !node.expanded) return;

  final parentLayout = layouts[node.id];
  expect(parentLayout, isNotNull, reason: 'Parent node ${node.id} should have layout');

  final parentCenterX = parentLayout!.position.dx + parentLayout.size.width / 2;

  for (int i = 0; i < node.children.length; i++) {
    final child = node.children[i];
    final childLayout = layouts[child.id];
    
    expect(childLayout, isNotNull, reason: 'Child node ${child.id} should have layout');

    final childCenterX = childLayout!.position.dx + childLayout.size.width / 2;

    // Verify position based on direction
    switch (direction) {
      case LayoutDirection.left:
        // All children should be to the left of parent
        expect(
          childCenterX < parentCenterX,
          isTrue,
          reason: 'Child ${child.id} should be left of parent ${node.id} for LEFT direction',
        );
        break;

      case LayoutDirection.right:
        // All children should be to the right of parent
        expect(
          childCenterX > parentCenterX,
          isTrue,
          reason: 'Child ${child.id} should be right of parent ${node.id} for RIGHT direction',
        );
        break;

      case LayoutDirection.side:
        if (isRoot) {
          // For root node in SIDE mode, children alternate left/right
          // Even indices go right, odd indices go left
          if (i % 2 == 0) {
            expect(
              childCenterX > parentCenterX,
              isTrue,
              reason: 'Even-indexed child ${child.id} should be right of root for SIDE direction',
            );
          } else {
            expect(
              childCenterX < parentCenterX,
              isTrue,
              reason: 'Odd-indexed child ${child.id} should be left of root for SIDE direction',
            );
          }
        } else {
          // For non-root nodes, all children stay on the same side as parent
          // This is determined by the parent's position relative to its parent
          // We just verify they maintain consistent direction
        }
        break;
    }

    // Recursively verify children's children
    // Non-root children inherit direction based on their side
    final childDirection = isRoot && direction == LayoutDirection.side
        ? (i % 2 == 0 ? LayoutDirection.right : LayoutDirection.left)
        : direction;
    
    _verifyChildrenDirection(
      child,
      layouts,
      childDirection,
      isRoot: false,
    );
  }
}
