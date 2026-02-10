import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/layout/node_layout.dart';
import 'package:mind_map_flutter/src/rendering/node_renderer.dart';

void main() {
  group('Expand Indicator Rendering', () {
    late MindMapTheme theme;

    setUp(() {
      theme = MindMapTheme.light;
    });

    test('getExpandIndicatorBounds returns null for node without children', () {
      final node = NodeData.create(topic: 'Test Node');
      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(120, 40),
      );

      final bounds = NodeRenderer.getExpandIndicatorBounds(node, layout);

      expect(bounds, isNull);
    });

    test(
      'getExpandIndicatorBounds returns valid bounds for node with children',
      () {
        final node = NodeData.create(
          topic: 'Parent Node',
          children: [NodeData.create(topic: 'Child 1')],
        );
        final layout = NodeLayout(
          position: const Offset(100, 100),
          size: const Size(120, 40),
        );

        final bounds = NodeRenderer.getExpandIndicatorBounds(node, layout);

        expect(bounds, isNotNull);
        expect(bounds!.width, NodeRenderer.indicatorSize);
        expect(bounds.height, NodeRenderer.indicatorSize);

        // Indicator should be to the right of the node
        expect(bounds.center.dx, greaterThan(layout.bounds.right));

        // Indicator should be vertically centered with the node
        expect(bounds.center.dy, layout.bounds.center.dy);
      },
    );

    test('indicator bounds are positioned correctly with padding', () {
      final node = NodeData.create(
        topic: 'Parent Node',
        children: [NodeData.create(topic: 'Child 1')],
      );
      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(120, 40),
      );

      final bounds = NodeRenderer.getExpandIndicatorBounds(node, layout);

      // Calculate expected center position
      final expectedCenterX =
          layout.bounds.right +
          NodeRenderer.indicatorPadding +
          NodeRenderer.indicatorSize / 2;
      final expectedCenterY = layout.bounds.center.dy;

      expect(bounds!.center.dx, expectedCenterX);
      expect(bounds.center.dy, expectedCenterY);
    });

    test('drawNode renders expand indicator for node with children', () {
      final node = NodeData.create(
        topic: 'Parent Node',
        children: [NodeData.create(topic: 'Child 1')],
      );
      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(120, 40),
      );

      // Create a canvas to draw on
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // This should not throw and should draw the indicator
      expect(
        () => NodeRenderer.drawNode(canvas, node, layout, theme, false, false),
        returnsNormally,
      );

      // Verify a picture was recorded (drawing occurred)
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('drawNode does not render indicator for node without children', () {
      final node = NodeData.create(topic: 'Leaf Node');
      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(120, 40),
      );

      // Create a canvas to draw on
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // This should not throw
      expect(
        () => NodeRenderer.drawNode(canvas, node, layout, theme, false, false),
        returnsNormally,
      );

      // Verify a picture was recorded (drawing occurred)
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test(
      'indicator bounds are consistent for expanded and collapsed nodes',
      () {
        final expandedNode = NodeData.create(
          topic: 'Parent Node',
          expanded: true,
          children: [NodeData.create(topic: 'Child 1')],
        );
        final collapsedNode = expandedNode.copyWith(expanded: false);

        final layout = NodeLayout(
          position: const Offset(100, 100),
          size: const Size(120, 40),
        );

        final expandedBounds = NodeRenderer.getExpandIndicatorBounds(
          expandedNode,
          layout,
        );
        final collapsedBounds = NodeRenderer.getExpandIndicatorBounds(
          collapsedNode,
          layout,
        );

        // Bounds should be the same regardless of expanded state
        expect(expandedBounds, isNotNull);
        expect(collapsedBounds, isNotNull);
        expect(expandedBounds!.center, collapsedBounds!.center);
        expect(expandedBounds.size, collapsedBounds.size);
      },
    );

    test('indicator size constants are reasonable', () {
      // Indicator should be visible but not too large
      expect(NodeRenderer.indicatorSize, greaterThan(10.0));
      expect(NodeRenderer.indicatorSize, lessThan(30.0));

      // Padding should provide reasonable spacing
      expect(NodeRenderer.indicatorPadding, greaterThan(4.0));
      expect(NodeRenderer.indicatorPadding, lessThan(20.0));
    });
  });
}
