import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

void main() {
  group('Layout Engine Unit Tests', () {
    late LayoutEngine layoutEngine;

    setUp(() {
      layoutEngine = LayoutEngine();
    });

    group('Root Node Layout', () {
      test('should position root node at origin', () {
        final rootNode = NodeData.create(topic: 'Root');
        final theme = MindMapTheme.light;

        final layouts = layoutEngine.calculateLayout(
          rootNode,
          theme,
          LayoutDirection.side,
        );

        final rootLayout = layouts[rootNode.id];
        expect(rootLayout, isNotNull);
        expect(rootLayout!.position, equals(Offset.zero));
        expect(rootLayout.size.width, greaterThan(0));
        expect(rootLayout.size.height, greaterThan(0));
      });

      test('should measure root node size correctly', () {
        final rootNode = NodeData.create(topic: 'Root Node');
        final theme = MindMapTheme.light;

        final layouts = layoutEngine.calculateLayout(
          rootNode,
          theme,
          LayoutDirection.side,
        );

        final rootLayout = layouts[rootNode.id];
        expect(rootLayout, isNotNull);

        // Root node should have reasonable size
        expect(rootLayout!.size.width, greaterThan(50));
        expect(rootLayout.size.height, greaterThan(20));
      });
    });

    group('Direction-Based Layout', () {
      test('should layout all children on left for LEFT direction', () {
        final child1 = NodeData.create(topic: 'Child 1');
        final child2 = NodeData.create(topic: 'Child 2');
        final rootNode = NodeData.create(
          topic: 'Root',
          children: [child1, child2],
        );
        final theme = MindMapTheme.light;

        final layouts = layoutEngine.calculateLayout(
          rootNode,
          theme,
          LayoutDirection.left,
        );

        final rootLayout = layouts[rootNode.id]!;
        final child1Layout = layouts[child1.id]!;
        final child2Layout = layouts[child2.id]!;

        // Both children should be to the left of root
        expect(child1Layout.position.dx < rootLayout.position.dx, isTrue);
        expect(child2Layout.position.dx < rootLayout.position.dx, isTrue);
      });

      test('should layout all children on right for RIGHT direction', () {
        final child1 = NodeData.create(topic: 'Child 1');
        final child2 = NodeData.create(topic: 'Child 2');
        final rootNode = NodeData.create(
          topic: 'Root',
          children: [child1, child2],
        );
        final theme = MindMapTheme.light;

        final layouts = layoutEngine.calculateLayout(
          rootNode,
          theme,
          LayoutDirection.right,
        );

        final rootLayout = layouts[rootNode.id]!;
        final child1Layout = layouts[child1.id]!;
        final child2Layout = layouts[child2.id]!;

        // Both children should be to the right of root
        expect(
          child1Layout.position.dx >
              rootLayout.position.dx + rootLayout.size.width,
          isTrue,
        );
        expect(
          child2Layout.position.dx >
              rootLayout.position.dx + rootLayout.size.width,
          isTrue,
        );
      });

      test('should distribute children on both sides for SIDE direction', () {
        final child1 = NodeData.create(topic: 'Child 1');
        final child2 = NodeData.create(topic: 'Child 2');
        final child3 = NodeData.create(topic: 'Child 3');
        final rootNode = NodeData.create(
          topic: 'Root',
          children: [child1, child2, child3],
        );
        final theme = MindMapTheme.light;

        final layouts = layoutEngine.calculateLayout(
          rootNode,
          theme,
          LayoutDirection.side,
        );

        final rootLayout = layouts[rootNode.id]!;
        final childLayouts = [
          layouts[child1.id]!,
          layouts[child2.id]!,
          layouts[child3.id]!,
        ];

        final leftCount = childLayouts
            .where((layout) => layout.position.dx < rootLayout.position.dx)
            .length;
        final rightCount = childLayouts
            .where(
              (layout) =>
                  layout.position.dx >
                  rootLayout.position.dx + rootLayout.size.width,
            )
            .length;

        expect(leftCount, greaterThan(0), reason: 'At least one child on left');
        expect(
          rightCount,
          greaterThan(0),
          reason: 'At least one child on right',
        );
      });
    });

    group('Node Spacing', () {
      test(
        'should apply correct horizontal gap between parent and children',
        () {
          final child = NodeData.create(topic: 'Child');
          final rootNode = NodeData.create(topic: 'Root', children: [child]);
          final theme = MindMapTheme.light;

          final layouts = layoutEngine.calculateLayout(
            rootNode,
            theme,
            LayoutDirection.right,
          );

          final rootLayout = layouts[rootNode.id]!;
          final childLayout = layouts[child.id]!;

          // Gap should be mainGapX for root's children
          final expectedGap = theme.variables.mainGapX;
          final actualGap =
              childLayout.position.dx -
              (rootLayout.position.dx + rootLayout.size.width);

          expect(actualGap, equals(expectedGap));
        },
      );

      test('should apply correct vertical gap between siblings', () {
        final child1 = NodeData.create(topic: 'Child 1');
        final child2 = NodeData.create(topic: 'Child 2');
        final rootNode = NodeData.create(
          topic: 'Root',
          children: [child1, child2],
        );
        final theme = MindMapTheme.light;

        final layouts = layoutEngine.calculateLayout(
          rootNode,
          theme,
          LayoutDirection.right,
        );

        final child1Layout = layouts[child1.id]!;
        final child2Layout = layouts[child2.id]!;

        // Gap should be mainGapY for root's children
        final expectedGap = theme.variables.mainGapY;
        final actualGap =
            child2Layout.position.dy -
            (child1Layout.position.dy + child1Layout.size.height);

        expect(actualGap, equals(expectedGap));
      });

      test('should use different gaps for non-root nodes', () {
        final grandchild = NodeData.create(topic: 'Grandchild');
        final child = NodeData.create(topic: 'Child', children: [grandchild]);
        final rootNode = NodeData.create(topic: 'Root', children: [child]);
        final theme = MindMapTheme.light;

        final layouts = layoutEngine.calculateLayout(
          rootNode,
          theme,
          LayoutDirection.right,
        );

        final childLayout = layouts[child.id]!;
        final grandchildLayout = layouts[grandchild.id]!;

        // In mind-elixir-core, topic-to-topic distance for depth > 1
        // includes me-parent paddings on both sides (~2 * nodeGapX).
        final expectedGap = theme.variables.nodeGapX * 2;
        final actualGap =
            grandchildLayout.position.dx -
            (childLayout.position.dx + childLayout.size.width);

        expect(actualGap, equals(expectedGap));
      });
    });

    group('Collapsed Nodes', () {
      test('should not layout children of collapsed nodes', () {
        final child = NodeData.create(topic: 'Child');
        final rootNode = NodeData.create(
          topic: 'Root',
          children: [child],
          expanded: false, // Collapsed
        );
        final theme = MindMapTheme.light;

        final layouts = layoutEngine.calculateLayout(
          rootNode,
          theme,
          LayoutDirection.side,
        );

        // Only root should have layout
        expect(layouts.length, equals(1));
        expect(layouts.containsKey(rootNode.id), isTrue);
        expect(layouts.containsKey(child.id), isFalse);
      });

      test('should layout expanded nodes but not their collapsed children', () {
        final grandchild = NodeData.create(topic: 'Grandchild');
        final child = NodeData.create(
          topic: 'Child',
          children: [grandchild],
          expanded: false, // Collapsed
        );
        final rootNode = NodeData.create(
          topic: 'Root',
          children: [child],
          expanded: true,
        );
        final theme = MindMapTheme.light;

        final layouts = layoutEngine.calculateLayout(
          rootNode,
          theme,
          LayoutDirection.side,
        );

        // Root and child should have layout, but not grandchild
        expect(layouts.length, equals(2));
        expect(layouts.containsKey(rootNode.id), isTrue);
        expect(layouts.containsKey(child.id), isTrue);
        expect(layouts.containsKey(grandchild.id), isFalse);
      });
    });

    group('Node Size Measurement', () {
      test('should measure node with tags', () {
        final nodeWithTags = NodeData.create(
          topic: 'Node',
          tags: [
            TagData(text: 'Tag1'),
            TagData(text: 'Tag2'),
          ],
        );
        final nodeWithoutTags = NodeData.create(topic: 'Node');
        final theme = MindMapTheme.light;

        final layoutsWithTags = layoutEngine.calculateLayout(
          nodeWithTags,
          theme,
          LayoutDirection.side,
        );
        final layoutsWithoutTags = layoutEngine.calculateLayout(
          nodeWithoutTags,
          theme,
          LayoutDirection.side,
        );

        final sizeWithTags = layoutsWithTags[nodeWithTags.id]!.size;
        final sizeWithoutTags = layoutsWithoutTags[nodeWithoutTags.id]!.size;

        // Node with tags should be taller
        expect(sizeWithTags.height > sizeWithoutTags.height, isTrue);
      });

      test('should measure node with icons', () {
        final nodeWithIcons = NodeData.create(
          topic: 'Node',
          icons: ['🎯', '⭐', '🔥'],
        );
        final nodeWithoutIcons = NodeData.create(topic: 'Node');
        final theme = MindMapTheme.light;

        final layoutsWithIcons = layoutEngine.calculateLayout(
          nodeWithIcons,
          theme,
          LayoutDirection.side,
        );
        final layoutsWithoutIcons = layoutEngine.calculateLayout(
          nodeWithoutIcons,
          theme,
          LayoutDirection.side,
        );

        final sizeWithIcons = layoutsWithIcons[nodeWithIcons.id]!.size;
        final sizeWithoutIcons = layoutsWithoutIcons[nodeWithoutIcons.id]!.size;

        // Node with icons should be wider
        expect(sizeWithIcons.width > sizeWithoutIcons.width, isTrue);
      });

      test('should measure node with image', () {
        final nodeWithImage = NodeData.create(
          topic: 'Node',
          image: const ImageData(
            url: 'https://example.com/image.png',
            width: 200,
            height: 150,
          ),
        );
        final nodeWithoutImage = NodeData.create(topic: 'Node');
        final theme = MindMapTheme.light;

        final layoutsWithImage = layoutEngine.calculateLayout(
          nodeWithImage,
          theme,
          LayoutDirection.side,
        );
        final layoutsWithoutImage = layoutEngine.calculateLayout(
          nodeWithoutImage,
          theme,
          LayoutDirection.side,
        );

        final sizeWithImage = layoutsWithImage[nodeWithImage.id]!.size;
        final sizeWithoutImage = layoutsWithoutImage[nodeWithoutImage.id]!.size;

        // Node with image should be taller and possibly wider
        expect(sizeWithImage.height > sizeWithoutImage.height, isTrue);
      });

      test('should respect custom node width', () {
        final customWidth = 300.0;
        final nodeWithCustomWidth = NodeData.create(
          topic: 'Node',
          style: NodeStyle(width: customWidth),
        );
        final theme = MindMapTheme.light;

        final layouts = layoutEngine.calculateLayout(
          nodeWithCustomWidth,
          theme,
          LayoutDirection.side,
        );

        final size = layouts[nodeWithCustomWidth.id]!.size;
        expect(size.width, equals(customWidth));
      });
    });

    group('Recursive Layout', () {
      test('should layout multi-level tree correctly', () {
        final grandchild1 = NodeData.create(topic: 'GC1');
        final grandchild2 = NodeData.create(topic: 'GC2');
        final child1 = NodeData.create(
          topic: 'Child 1',
          children: [grandchild1, grandchild2],
        );
        final child2 = NodeData.create(topic: 'Child 2');
        final rootNode = NodeData.create(
          topic: 'Root',
          children: [child1, child2],
        );
        final theme = MindMapTheme.light;

        final layouts = layoutEngine.calculateLayout(
          rootNode,
          theme,
          LayoutDirection.right,
        );

        // All nodes should have layouts
        expect(layouts.length, equals(5));
        expect(layouts.containsKey(rootNode.id), isTrue);
        expect(layouts.containsKey(child1.id), isTrue);
        expect(layouts.containsKey(child2.id), isTrue);
        expect(layouts.containsKey(grandchild1.id), isTrue);
        expect(layouts.containsKey(grandchild2.id), isTrue);

        // Verify hierarchy: grandchildren should be further right than children
        final child1Layout = layouts[child1.id]!;
        final grandchild1Layout = layouts[grandchild1.id]!;

        expect(
          grandchild1Layout.position.dx >
              child1Layout.position.dx + child1Layout.size.width,
          isTrue,
        );
      });
    });
  });
}
