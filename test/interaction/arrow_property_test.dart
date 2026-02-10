import 'dart:ui' show PictureRecorder, Canvas;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';
import '../helpers/generators.dart';
import 'dart:math';

// Feature: mind-map-flutter, Property 19: 箭头创建和持久化
// Feature: mind-map-flutter, Property 20: 箭头样式渲染
// Feature: mind-map-flutter, Property 21: 箭头曲线渲染

void main() {
  group('Arrow Property Tests', () {
    const iterations = 100;

    // For any node pair, creating an arrow should add an arrow record in data,
    // including source, target, label, control points, and style
    test('Property 19: Arrow creation and persistence', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data with at least 2 nodes
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 3,
          maxArrows: 0, // Start with no arrows
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Collect all node IDs
        final nodeIds = collectAllNodeIds(initialData.nodeData).toList();
        
        // Skip if less than 2 nodes
        if (nodeIds.length < 2) {
          controller.dispose();
          continue;
        }

        // Select random source and target nodes
        final random = Random(i);
        final fromNodeId = nodeIds[random.nextInt(nodeIds.length)];
        var toNodeId = nodeIds[random.nextInt(nodeIds.length)];
        
        // Ensure source and target are different
        while (toNodeId == fromNodeId && nodeIds.length > 1) {
          toNodeId = nodeIds[random.nextInt(nodeIds.length)];
        }

        // Generate random arrow properties
        final label = random.nextBool() ? 'Arrow Label $i' : null;
        final bidirectional = random.nextBool();
        final delta1 = Offset(
          random.nextDouble() * 100 - 50,
          random.nextDouble() * 100 - 50,
        );
        final delta2 = Offset(
          random.nextDouble() * 100 - 50,
          random.nextDouble() * 100 - 50,
        );
        final style = random.nextBool()
            ? ArrowStyle(
                strokeColor: Color(0xFF000000 + random.nextInt(0xFFFFFF)),
                strokeWidth: 1.0 + random.nextDouble() * 4.0,
                opacity: 0.5 + random.nextDouble() * 0.5,
                dashPattern: random.nextBool() ? [5.0, 3.0] : null,
              )
            : null;

        // Capture initial arrow count
        final initialArrowCount = controller.getData().arrows.length;

        // Create arrow (Requirement 9.3)
        controller.addArrow(
          fromNodeId: fromNodeId,
          toNodeId: toNodeId,
          label: label,
          bidirectional: bidirectional,
          delta1: delta1,
          delta2: delta2,
          style: style,
        );

        // Verify arrow was added to data
        final data = controller.getData();
        expect(data.arrows.length, initialArrowCount + 1,
            reason: 'Arrow should be added to data');

        // Get the created arrow
        final arrow = data.arrows.last;

        // Verify arrow data persistence (Requirement 9.9)
        expect(arrow.fromNodeId, fromNodeId,
            reason: 'Arrow should persist source node ID');
        expect(arrow.toNodeId, toNodeId,
            reason: 'Arrow should persist target node ID');
        expect(arrow.label, label,
            reason: 'Arrow should persist label');
        expect(arrow.bidirectional, bidirectional,
            reason: 'Arrow should persist bidirectional flag');
        expect(arrow.delta1, delta1,
            reason: 'Arrow should persist control point delta1');
        expect(arrow.delta2, delta2,
            reason: 'Arrow should persist control point delta2');
        
        // Verify style persistence
        if (style != null) {
          expect(arrow.style, isNotNull,
              reason: 'Arrow should persist style when provided');
          expect(arrow.style!.strokeColor, style.strokeColor,
              reason: 'Arrow should persist stroke color');
          expect(arrow.style!.strokeWidth, style.strokeWidth,
              reason: 'Arrow should persist stroke width');
          expect(arrow.style!.opacity, style.opacity,
              reason: 'Arrow should persist opacity');
          expect(arrow.style!.dashPattern, style.dashPattern,
              reason: 'Arrow should persist dash pattern');
        }

        // Verify arrow has unique ID
        expect(arrow.id, isNotEmpty,
            reason: 'Arrow should have a unique ID');

        // Verify arrow can be retrieved
        final retrievedArrow = controller.getArrow(arrow.id);
        expect(retrievedArrow, isNotNull,
            reason: 'Arrow should be retrievable by ID');
        expect(retrievedArrow!.id, arrow.id,
            reason: 'Retrieved arrow should match created arrow');

        controller.dispose();
      }
    });

    // For any arrow with custom style, rendering should apply stroke color,
    // width, dash pattern, and opacity
    test('Property 20: Arrow style rendering', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 3,
          maxArrows: 0,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Collect all node IDs
        final nodeIds = collectAllNodeIds(initialData.nodeData).toList();
        
        // Skip if less than 2 nodes
        if (nodeIds.length < 2) {
          controller.dispose();
          continue;
        }

        // Select random source and target nodes
        final random = Random(i);
        final fromNodeId = nodeIds[random.nextInt(nodeIds.length)];
        var toNodeId = nodeIds[random.nextInt(nodeIds.length)];
        
        while (toNodeId == fromNodeId && nodeIds.length > 1) {
          toNodeId = nodeIds[random.nextInt(nodeIds.length)];
        }

        // Generate random custom style (Requirement 9.6)
        final strokeColor = Color(0xFF000000 + random.nextInt(0xFFFFFF));
        final strokeWidth = 1.0 + random.nextDouble() * 5.0;
        final opacity = 0.3 + random.nextDouble() * 0.7;
        final dashPattern = random.nextBool() 
            ? [random.nextDouble() * 10 + 2, random.nextDouble() * 10 + 2]
            : null;

        final style = ArrowStyle(
          strokeColor: strokeColor,
          strokeWidth: strokeWidth,
          opacity: opacity,
          dashPattern: dashPattern,
        );

        // Create arrow with custom style
        controller.addArrow(
          fromNodeId: fromNodeId,
          toNodeId: toNodeId,
          style: style,
        );

        final arrow = controller.getData().arrows.last;

        // Verify style is persisted correctly
        expect(arrow.style, isNotNull,
            reason: 'Arrow should have style');
        expect(arrow.style!.strokeColor, strokeColor,
            reason: 'Arrow should persist stroke color');
        expect(arrow.style!.strokeWidth, strokeWidth,
            reason: 'Arrow should persist stroke width');
        expect(arrow.style!.opacity, opacity,
            reason: 'Arrow should persist opacity');
        expect(arrow.style!.dashPattern, dashPattern,
            reason: 'Arrow should persist dash pattern');

        // Verify style values are within valid ranges
        expect(arrow.style!.strokeWidth, greaterThan(0),
            reason: 'Stroke width should be positive');
        expect(arrow.style!.opacity, greaterThanOrEqualTo(0),
            reason: 'Opacity should be >= 0');
        expect(arrow.style!.opacity, lessThanOrEqualTo(1),
            reason: 'Opacity should be <= 1');

        if (arrow.style!.dashPattern != null) {
          expect(arrow.style!.dashPattern!.length, greaterThan(0),
              reason: 'Dash pattern should not be empty if provided');
          for (final dash in arrow.style!.dashPattern!) {
            expect(dash, greaterThan(0),
                reason: 'Dash pattern values should be positive');
          }
        }

        // Calculate layout to verify arrow can be rendered
        final layoutEngine = LayoutEngine();
        final nodeLayouts = layoutEngine.calculateLayout(
          controller.getData().nodeData,
          controller.getData().theme,
          controller.getData().direction,
        );

        // Skip if nodes are not in layout (e.g., parent is collapsed)
        if (!nodeLayouts.containsKey(fromNodeId) || !nodeLayouts.containsKey(toNodeId)) {
          controller.dispose();
          continue;
        }

        // Verify both nodes are in layout (required for rendering)
        expect(nodeLayouts.containsKey(fromNodeId), true,
            reason: 'Source node should be in layout for rendering');
        expect(nodeLayouts.containsKey(toNodeId), true,
            reason: 'Target node should be in layout for rendering');

        // Verify arrow can be rendered (this validates the style is usable)
        // ArrowRenderer.drawArrow should not throw
        expect(
          () {
            final recorder = PictureRecorder();
            final canvas = Canvas(recorder);
            ArrowRenderer.drawArrow(
              canvas,
              arrow,
              nodeLayouts,
              controller.getData().theme,
            );
          },
          returnsNormally,
          reason: 'Arrow with custom style should render without errors',
        );

        controller.dispose();
      }
    });

    // For any arrow, it should be rendered as a curve with control points,
    // and control points should be visible when selected
    test('Property 21: Arrow curve rendering', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 3,
          maxArrows: 0,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Collect all node IDs
        final nodeIds = collectAllNodeIds(initialData.nodeData).toList();
        
        // Skip if less than 2 nodes
        if (nodeIds.length < 2) {
          controller.dispose();
          continue;
        }

        // Select random source and target nodes
        final random = Random(i);
        final fromNodeId = nodeIds[random.nextInt(nodeIds.length)];
        var toNodeId = nodeIds[random.nextInt(nodeIds.length)];
        
        while (toNodeId == fromNodeId && nodeIds.length > 1) {
          toNodeId = nodeIds[random.nextInt(nodeIds.length)];
        }

        // Generate random control point deltas (Requirement 9.7)
        final delta1 = Offset(
          random.nextDouble() * 200 - 100,
          random.nextDouble() * 200 - 100,
        );
        final delta2 = Offset(
          random.nextDouble() * 200 - 100,
          random.nextDouble() * 200 - 100,
        );

        // Create arrow with control points
        controller.addArrow(
          fromNodeId: fromNodeId,
          toNodeId: toNodeId,
          delta1: delta1,
          delta2: delta2,
        );

        final arrow = controller.getData().arrows.last;

        // Verify control points are persisted
        expect(arrow.delta1, delta1,
            reason: 'Arrow should persist control point delta1');
        expect(arrow.delta2, delta2,
            reason: 'Arrow should persist control point delta2');

        // Calculate layout
        final layoutEngine = LayoutEngine();
        final nodeLayouts = layoutEngine.calculateLayout(
          controller.getData().nodeData,
          controller.getData().theme,
          controller.getData().direction,
        );

        // Skip if nodes are not in layout (e.g., parent is collapsed)
        if (!nodeLayouts.containsKey(fromNodeId) || !nodeLayouts.containsKey(toNodeId)) {
          controller.dispose();
          continue;
        }

        // Verify arrow can be rendered as a curve (Requirement 9.7)
        expect(
          () {
            final recorder = PictureRecorder();
            final canvas = Canvas(recorder);
            ArrowRenderer.drawArrow(
              canvas,
              arrow,
              nodeLayouts,
              controller.getData().theme,
            );
          },
          returnsNormally,
          reason: 'Arrow should render as a curve without errors',
        );

        // Test control point visibility when arrow is selected (Requirement 9.8)
        controller.selectArrow(arrow.id);
        
        expect(controller.selectedArrowId, arrow.id,
            reason: 'Arrow should be selected');

        // Verify control points can be rendered when selected
        expect(
          () {
            final recorder = PictureRecorder();
            final canvas = Canvas(recorder);
            ArrowRenderer.drawControlPoints(
              canvas,
              arrow,
              nodeLayouts,
              controller.getData().theme,
            );
          },
          returnsNormally,
          reason: 'Control points should render when arrow is selected',
        );

        // Verify control point bounds can be calculated (for hit testing)
        final controlPoint1Bounds = ArrowRenderer.getControlPointBounds(
          arrow,
          nodeLayouts,
          0,
        );
        final controlPoint2Bounds = ArrowRenderer.getControlPointBounds(
          arrow,
          nodeLayouts,
          1,
        );

        expect(controlPoint1Bounds, isNotNull,
            reason: 'Control point 1 bounds should be calculable');
        expect(controlPoint2Bounds, isNotNull,
            reason: 'Control point 2 bounds should be calculable');

        // Verify control point bounds have valid dimensions
        expect(controlPoint1Bounds!.width, greaterThan(0),
            reason: 'Control point 1 should have positive width');
        expect(controlPoint1Bounds.height, greaterThan(0),
            reason: 'Control point 1 should have positive height');
        expect(controlPoint2Bounds!.width, greaterThan(0),
            reason: 'Control point 2 should have positive width');
        expect(controlPoint2Bounds.height, greaterThan(0),
            reason: 'Control point 2 should have positive height');

        // Test updating control points
        final newDelta1 = Offset(
          random.nextDouble() * 200 - 100,
          random.nextDouble() * 200 - 100,
        );
        final newDelta2 = Offset(
          random.nextDouble() * 200 - 100,
          random.nextDouble() * 200 - 100,
        );

        controller.updateArrowControlPoints(arrow.id, newDelta1, newDelta2);

        final updatedArrow = controller.getArrow(arrow.id);
        expect(updatedArrow, isNotNull);
        expect(updatedArrow!.delta1, newDelta1,
            reason: 'Control point delta1 should be updated');
        expect(updatedArrow.delta2, newDelta2,
            reason: 'Control point delta2 should be updated');

        // Verify updated arrow can still be rendered
        expect(
          () {
            final recorder = PictureRecorder();
            final canvas = Canvas(recorder);
            ArrowRenderer.drawArrow(
              canvas,
              updatedArrow,
              nodeLayouts,
              controller.getData().theme,
            );
          },
          returnsNormally,
          reason: 'Arrow should render after control point update',
        );

        controller.dispose();
      }
    });

    // Additional property test: Arrow bidirectionality
    test('Property 19 (Extended): Bidirectional arrow rendering', () {
      for (int i = 0; i < iterations; i++) {
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 3,
          maxArrows: 0,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        final nodeIds = collectAllNodeIds(initialData.nodeData).toList();
        
        if (nodeIds.length < 2) {
          controller.dispose();
          continue;
        }

        final random = Random(i);
        final fromNodeId = nodeIds[random.nextInt(nodeIds.length)];
        var toNodeId = nodeIds[random.nextInt(nodeIds.length)];
        
        while (toNodeId == fromNodeId && nodeIds.length > 1) {
          toNodeId = nodeIds[random.nextInt(nodeIds.length)];
        }

        // Create bidirectional arrow
        controller.addArrow(
          fromNodeId: fromNodeId,
          toNodeId: toNodeId,
          bidirectional: true,
        );

        final arrow = controller.getData().arrows.last;

        // Verify bidirectional flag is persisted
        expect(arrow.bidirectional, true,
            reason: 'Bidirectional flag should be persisted');

        // Calculate layout
        final layoutEngine = LayoutEngine();
        final nodeLayouts = layoutEngine.calculateLayout(
          controller.getData().nodeData,
          controller.getData().theme,
          controller.getData().direction,
        );

        // Verify bidirectional arrow can be rendered
        expect(
          () {
            final recorder = PictureRecorder();
            final canvas = Canvas(recorder);
            ArrowRenderer.drawArrow(
              canvas,
              arrow,
              nodeLayouts,
              controller.getData().theme,
            );
          },
          returnsNormally,
          reason: 'Bidirectional arrow should render without errors',
        );

        controller.dispose();
      }
    });

    // Additional property test: Arrow with label
    test('Property 19 (Extended): Arrow label rendering', () {
      for (int i = 0; i < iterations; i++) {
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 3,
          maxArrows: 0,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        final nodeIds = collectAllNodeIds(initialData.nodeData).toList();
        
        if (nodeIds.length < 2) {
          controller.dispose();
          continue;
        }

        final random = Random(i);
        final fromNodeId = nodeIds[random.nextInt(nodeIds.length)];
        var toNodeId = nodeIds[random.nextInt(nodeIds.length)];
        
        while (toNodeId == fromNodeId && nodeIds.length > 1) {
          toNodeId = nodeIds[random.nextInt(nodeIds.length)];
        }

        // Create arrow with label
        final label = 'Test Label $i';
        controller.addArrow(
          fromNodeId: fromNodeId,
          toNodeId: toNodeId,
          label: label,
        );

        final arrow = controller.getData().arrows.last;

        // Verify label is persisted
        expect(arrow.label, label,
            reason: 'Arrow label should be persisted');

        // Calculate layout
        final layoutEngine = LayoutEngine();
        final nodeLayouts = layoutEngine.calculateLayout(
          controller.getData().nodeData,
          controller.getData().theme,
          controller.getData().direction,
        );

        // Verify arrow with label can be rendered
        expect(
          () {
            final recorder = PictureRecorder();
            final canvas = Canvas(recorder);
            ArrowRenderer.drawArrow(
              canvas,
              arrow,
              nodeLayouts,
              controller.getData().theme,
            );
          },
          returnsNormally,
          reason: 'Arrow with label should render without errors',
        );

        controller.dispose();
      }
    });

    // Additional property test: Multiple arrows
    test('Property 19 (Extended): Multiple arrows persistence', () {
      for (int i = 0; i < iterations; i++) {
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 4,
          maxArrows: 0,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        final nodeIds = collectAllNodeIds(initialData.nodeData).toList();
        
        if (nodeIds.length < 3) {
          controller.dispose();
          continue;
        }

        final random = Random(i);
        
        // Create multiple arrows (2-5)
        final arrowCount = 2 + random.nextInt(4);
        final createdArrowIds = <String>[];

        for (int j = 0; j < arrowCount && nodeIds.length >= 2; j++) {
          final fromNodeId = nodeIds[random.nextInt(nodeIds.length)];
          var toNodeId = nodeIds[random.nextInt(nodeIds.length)];
          
          while (toNodeId == fromNodeId && nodeIds.length > 1) {
            toNodeId = nodeIds[random.nextInt(nodeIds.length)];
          }

          controller.addArrow(
            fromNodeId: fromNodeId,
            toNodeId: toNodeId,
            label: 'Arrow $j',
          );

          createdArrowIds.add(controller.getData().arrows.last.id);
        }

        // Verify all arrows are persisted
        final data = controller.getData();
        expect(data.arrows.length, greaterThanOrEqualTo(arrowCount),
            reason: 'All created arrows should be persisted');

        // Verify each arrow can be retrieved
        for (final arrowId in createdArrowIds) {
          final arrow = controller.getArrow(arrowId);
          expect(arrow, isNotNull,
              reason: 'Each arrow should be retrievable by ID');
        }

        // Calculate layout
        final layoutEngine = LayoutEngine();
        final nodeLayouts = layoutEngine.calculateLayout(
          data.nodeData,
          data.theme,
          data.direction,
        );

        // Verify all arrows can be rendered
        expect(
          () {
            final recorder = PictureRecorder();
            final canvas = Canvas(recorder);
            ArrowRenderer.drawAllArrows(
              canvas,
              data.arrows,
              nodeLayouts,
              data.theme,
            );
          },
          returnsNormally,
          reason: 'All arrows should render without errors',
        );

        controller.dispose();
      }
    });

    // Additional property test: Arrow removal
    test('Property 19 (Extended): Arrow removal', () {
      for (int i = 0; i < iterations; i++) {
        final initialData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 3,
          maxArrows: 0,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        final nodeIds = collectAllNodeIds(initialData.nodeData).toList();
        
        if (nodeIds.length < 2) {
          controller.dispose();
          continue;
        }

        final random = Random(i);
        final fromNodeId = nodeIds[random.nextInt(nodeIds.length)];
        var toNodeId = nodeIds[random.nextInt(nodeIds.length)];
        
        while (toNodeId == fromNodeId && nodeIds.length > 1) {
          toNodeId = nodeIds[random.nextInt(nodeIds.length)];
        }

        // Create arrow
        controller.addArrow(
          fromNodeId: fromNodeId,
          toNodeId: toNodeId,
        );

        final arrowId = controller.getData().arrows.last.id;
        final arrowCountBefore = controller.getData().arrows.length;

        // Remove arrow
        controller.removeArrow(arrowId);

        // Verify arrow is removed
        final data = controller.getData();
        expect(data.arrows.length, arrowCountBefore - 1,
            reason: 'Arrow should be removed from data');

        // Verify arrow cannot be retrieved
        final arrow = controller.getArrow(arrowId);
        expect(arrow, isNull,
            reason: 'Removed arrow should not be retrievable');

        // Verify selected arrow is cleared if it was the removed arrow
        expect(controller.selectedArrowId, isNull,
            reason: 'Selected arrow should be cleared when removed');

        controller.dispose();
      }
    });
  });
}
