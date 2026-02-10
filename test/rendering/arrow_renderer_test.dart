import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/models/arrow_data.dart';
import 'package:mind_map_flutter/src/models/arrow_style.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/layout/node_layout.dart';
import 'package:mind_map_flutter/src/rendering/arrow_renderer.dart';

void main() {
  group('ArrowRenderer', () {
    late MindMapTheme theme;
    late Map<String, NodeLayout> nodeLayouts;

    setUp(() {
      theme = MindMapTheme.light;
      
      // Create sample node layouts
      nodeLayouts = {
        'node1': NodeLayout(
          position: const Offset(100, 100),
          size: const Size(120, 40),
        ),
        'node2': NodeLayout(
          position: const Offset(300, 200),
          size: const Size(120, 40),
        ),
      };
    });

    test('should draw basic arrow between two nodes', () {
      final arrow = ArrowData.create(
        fromNodeId: 'node1',
        toNodeId: 'node2',
      );

      // Create a test canvas
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // This should not throw
      expect(
        () => ArrowRenderer.drawArrow(canvas, arrow, nodeLayouts, theme),
        returnsNormally,
      );
    });

    test('should draw arrow with label', () {
      final arrow = ArrowData.create(
        fromNodeId: 'node1',
        toNodeId: 'node2',
        label: 'Test Label',
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // This should not throw
      expect(
        () => ArrowRenderer.drawArrow(canvas, arrow, nodeLayouts, theme),
        returnsNormally,
      );
    });

    test('should draw bidirectional arrow', () {
      final arrow = ArrowData.create(
        fromNodeId: 'node1',
        toNodeId: 'node2',
        bidirectional: true,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // This should not throw
      expect(
        () => ArrowRenderer.drawArrow(canvas, arrow, nodeLayouts, theme),
        returnsNormally,
      );
    });

    test('should apply custom arrow style', () {
      final arrow = ArrowData.create(
        fromNodeId: 'node1',
        toNodeId: 'node2',
        style: const ArrowStyle(
          strokeColor: Colors.red,
          strokeWidth: 3.0,
          opacity: 0.8,
        ),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // This should not throw
      expect(
        () => ArrowRenderer.drawArrow(canvas, arrow, nodeLayouts, theme),
        returnsNormally,
      );
    });

    test('should draw arrow with dashed pattern', () {
      final arrow = ArrowData.create(
        fromNodeId: 'node1',
        toNodeId: 'node2',
        style: const ArrowStyle(
          dashPattern: [5.0, 3.0],
        ),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // This should not throw
      expect(
        () => ArrowRenderer.drawArrow(canvas, arrow, nodeLayouts, theme),
        returnsNormally,
      );
    });

    test('should draw arrow with control point deltas', () {
      final arrow = ArrowData.create(
        fromNodeId: 'node1',
        toNodeId: 'node2',
        delta1: const Offset(50, 20),
        delta2: const Offset(-30, 10),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // This should not throw
      expect(
        () => ArrowRenderer.drawArrow(canvas, arrow, nodeLayouts, theme),
        returnsNormally,
      );
    });

    test('should handle missing node layouts gracefully', () {
      final arrow = ArrowData.create(
        fromNodeId: 'nonexistent1',
        toNodeId: 'nonexistent2',
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // This should not throw, just return early
      expect(
        () => ArrowRenderer.drawArrow(canvas, arrow, nodeLayouts, theme),
        returnsNormally,
      );
    });

    test('should draw all arrows in a list', () {
      final arrows = [
        ArrowData.create(
          fromNodeId: 'node1',
          toNodeId: 'node2',
        ),
        ArrowData.create(
          fromNodeId: 'node2',
          toNodeId: 'node1',
          bidirectional: true,
        ),
      ];

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // This should not throw
      expect(
        () => ArrowRenderer.drawAllArrows(canvas, arrows, nodeLayouts, theme),
        returnsNormally,
      );
    });

    test('should draw control points for selected arrow', () {
      final arrow = ArrowData.create(
        fromNodeId: 'node1',
        toNodeId: 'node2',
        delta1: const Offset(50, 20),
        delta2: const Offset(-30, 10),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // This should not throw
      expect(
        () => ArrowRenderer.drawControlPoints(canvas, arrow, nodeLayouts, theme),
        returnsNormally,
      );
    });

    test('should get control point bounds for hit testing', () {
      final arrow = ArrowData.create(
        fromNodeId: 'node1',
        toNodeId: 'node2',
        delta1: const Offset(50, 20),
        delta2: const Offset(-30, 10),
      );

      // Get bounds for control point 0
      final bounds0 = ArrowRenderer.getControlPointBounds(
        arrow,
        nodeLayouts,
        0,
      );

      expect(bounds0, isNotNull);
      expect(bounds0!.width, equals(12.0)); // 2 * handleRadius
      expect(bounds0.height, equals(12.0));

      // Get bounds for control point 1
      final bounds1 = ArrowRenderer.getControlPointBounds(
        arrow,
        nodeLayouts,
        1,
      );

      expect(bounds1, isNotNull);
      expect(bounds1!.width, equals(12.0));
      expect(bounds1.height, equals(12.0));
    });

    test('should return null bounds for missing node layouts', () {
      final arrow = ArrowData.create(
        fromNodeId: 'nonexistent1',
        toNodeId: 'nonexistent2',
      );

      final bounds = ArrowRenderer.getControlPointBounds(
        arrow,
        nodeLayouts,
        0,
      );

      expect(bounds, isNull);
    });

    test('should handle empty arrow list', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // This should not throw
      expect(
        () => ArrowRenderer.drawAllArrows(canvas, [], nodeLayouts, theme),
        returnsNormally,
      );
    });

    test('should draw arrow with all features combined', () {
      final arrow = ArrowData.create(
        fromNodeId: 'node1',
        toNodeId: 'node2',
        label: 'Complex Arrow',
        bidirectional: true,
        delta1: const Offset(40, 30),
        delta2: const Offset(-40, -30),
        style: const ArrowStyle(
          strokeColor: Colors.blue,
          strokeWidth: 2.5,
          dashPattern: [8.0, 4.0],
          opacity: 0.9,
        ),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      // This should not throw
      expect(
        () => ArrowRenderer.drawArrow(canvas, arrow, nodeLayouts, theme),
        returnsNormally,
      );
    });
  });
}
