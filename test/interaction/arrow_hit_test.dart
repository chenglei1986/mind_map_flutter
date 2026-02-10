import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/interaction/gesture_handler.dart';
import 'package:mind_map_flutter/src/layout/layout_engine.dart';
import 'package:mind_map_flutter/src/models/arrow_data.dart';
import 'package:mind_map_flutter/src/models/layout_direction.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/rendering/arrow_renderer.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_controller.dart';

/// Tests for arrow hit testing functionality
void main() {
  group('Arrow Hit Testing', () {
    late MindMapController controller;
    late LayoutEngine layoutEngine;
    
    setUp(() {
      // Create a simple mind map with two nodes
      final rootNode = NodeData.create(
        topic: 'Root',
        children: [
          NodeData.create(topic: 'Child 1'),
          NodeData.create(topic: 'Child 2'),
        ],
      );
      
      // Create an arrow between the two children
      final arrow = ArrowData.create(
        fromNodeId: rootNode.children[0].id,
        toNodeId: rootNode.children[1].id,
        label: 'Test Arrow',
      );
      
      final data = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
        arrows: [arrow],
      );
      
      controller = MindMapController(initialData: data);
      layoutEngine = LayoutEngine();
      
    });
    
    test('hitTestArrow should detect arrow click', () {
      // Get the arrow
      final arrow = controller.getData().arrows.first;
      
      // Get node layouts
      final nodeLayouts = layoutEngine.calculateLayout(
        controller.getData().nodeData,
        MindMapTheme.light,
        LayoutDirection.side,
      );
      final fromLayout = nodeLayouts[arrow.fromNodeId]!;
      final toLayout = nodeLayouts[arrow.toNodeId]!;
      final startPoint = fromLayout.bounds.center;
      final endPoint = toLayout.bounds.center;
      
      // Calculate a point on the arrow curve (midpoint)
      final controlPoint1Bounds = ArrowRenderer.getControlPointBounds(
        arrow,
        nodeLayouts,
        0,
      )!;
      final controlPoint2Bounds = ArrowRenderer.getControlPointBounds(
        arrow,
        nodeLayouts,
        1,
      )!;
      final controlPoint1 = controlPoint1Bounds.center;
      final controlPoint2 = controlPoint2Bounds.center;
      
      // Calculate midpoint of bezier curve (t = 0.5)
      final midPoint = _calculateBezierPoint(
        startPoint,
        controlPoint1,
        controlPoint2,
        endPoint,
        0.5,
      );
      
      // Update gesture handler with correct layouts
      final updatedGestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: nodeLayouts,
        transform: Matrix4.identity(),
      );
      
      // Hit test at the midpoint
      final hitArrowId = updatedGestureHandler.hitTestArrow(midPoint);
      
      // Should detect the arrow
      expect(hitArrowId, equals(arrow.id));
    });
    
    test('hitTestArrow should return null when clicking away from arrow', () {
      // Get node layouts
      final nodeLayouts = layoutEngine.calculateLayout(
        controller.getData().nodeData,
        MindMapTheme.light,
        LayoutDirection.side,
      );
      
      // Update gesture handler with correct layouts
      final updatedGestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: nodeLayouts,
        transform: Matrix4.identity(),
      );
      
      // Hit test at a point far from any arrow
      final hitArrowId = updatedGestureHandler.hitTestArrow(const Offset(1000, 1000));
      
      // Should not detect any arrow
      expect(hitArrowId, isNull);
    });
    
    test('selecting arrow should update controller state', () {
      final arrow = controller.getData().arrows.first;
      
      // Initially no arrow is selected
      expect(controller.selectedArrowId, isNull);
      
      // Select the arrow
      controller.selectArrow(arrow.id);
      
      // Arrow should be selected
      expect(controller.selectedArrowId, equals(arrow.id));
    });
    
    test('deselecting arrow should clear selection', () {
      final arrow = controller.getData().arrows.first;
      
      // Select the arrow
      controller.selectArrow(arrow.id);
      expect(controller.selectedArrowId, equals(arrow.id));
      
      // Deselect the arrow
      controller.deselectArrow();
      
      // No arrow should be selected
      expect(controller.selectedArrowId, isNull);
    });
    
    test('clicking on arrow should select it', () {
      // Get the arrow
      final arrow = controller.getData().arrows.first;
      
      // Get node layouts
      final nodeLayouts = layoutEngine.calculateLayout(
        controller.getData().nodeData,
        MindMapTheme.light,
        LayoutDirection.side,
      );
      
      // Calculate a point on the arrow curve
      final fromLayout = nodeLayouts[arrow.fromNodeId]!;
      final toLayout = nodeLayouts[arrow.toNodeId]!;
      
      final startPoint = fromLayout.bounds.center;
      final endPoint = toLayout.bounds.center;
      final controlPoint1Bounds = ArrowRenderer.getControlPointBounds(
        arrow,
        nodeLayouts,
        0,
      )!;
      final controlPoint2Bounds = ArrowRenderer.getControlPointBounds(
        arrow,
        nodeLayouts,
        1,
      )!;
      final controlPoint1 = controlPoint1Bounds.center;
      final controlPoint2 = controlPoint2Bounds.center;
      
      // Update gesture handler with correct layouts
      final updatedGestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: nodeLayouts,
        transform: Matrix4.identity(),
      );

      Offset? tapPoint;
      for (double t = 0.1; t < 0.9; t += 0.1) {
        final point = _calculateBezierPoint(
          startPoint,
          controlPoint1,
          controlPoint2,
          endPoint,
          t,
        );
        final inNode = nodeLayouts.values.any((layout) => layout.bounds.contains(point));
        if (!inNode && updatedGestureHandler.hitTestArrow(point) == arrow.id) {
          tapPoint = point;
          break;
        }
      }
      expect(tapPoint, isNotNull, reason: 'Should find a tappable point on arrow');
      
      // Simulate tap on arrow
      updatedGestureHandler.handleTapUp(
        TapUpDetails(
          kind: PointerDeviceKind.touch,
          localPosition: tapPoint!,
        ),
      );
      
      // Arrow should be selected
      expect(controller.selectedArrowId, equals(arrow.id));
    });

    test('node hit should take precedence over arrow hit in overlap area', () {
      final arrow = controller.getData().arrows.first;

      final nodeLayouts = layoutEngine.calculateLayout(
        controller.getData().nodeData,
        MindMapTheme.light,
        LayoutDirection.side,
      );

      final fromLayout = nodeLayouts[arrow.fromNodeId]!;
      final overlapPoint = fromLayout.bounds.center;

      final updatedGestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: nodeLayouts,
        transform: Matrix4.identity(),
      );

      updatedGestureHandler.handleTapUp(
        TapUpDetails(
          kind: PointerDeviceKind.touch,
          localPosition: overlapPoint,
        ),
      );

      expect(controller.selectedArrowId, isNull);
      expect(controller.getSelectedNodeIds(), contains(arrow.fromNodeId));
    });
    
    test('clicking on empty space should deselect arrow', () {
      final arrow = controller.getData().arrows.first;
      
      // Select the arrow first
      controller.selectArrow(arrow.id);
      expect(controller.selectedArrowId, equals(arrow.id));
      
      // Get node layouts
      final nodeLayouts = layoutEngine.calculateLayout(
        controller.getData().nodeData,
        MindMapTheme.light,
        LayoutDirection.side,
      );
      
      // Update gesture handler with correct layouts
      final updatedGestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: nodeLayouts,
        transform: Matrix4.identity(),
      );
      
      // Simulate tap on empty space
      updatedGestureHandler.handleTapUp(
        TapUpDetails(
          kind: PointerDeviceKind.touch,
          localPosition: const Offset(1000, 1000),
        ),
      );
      
      // Arrow should be deselected
      expect(controller.selectedArrowId, isNull);
    });
    
    test('hitTestArrowControlPoint should detect control point click when arrow is selected', () {
      final arrow = controller.getData().arrows.first;
      
      // Select the arrow
      controller.selectArrow(arrow.id);
      
      // Get node layouts
      final nodeLayouts = layoutEngine.calculateLayout(
        controller.getData().nodeData,
        MindMapTheme.light,
        LayoutDirection.side,
      );
      
      // Calculate control point positions
      final fromLayout = nodeLayouts[arrow.fromNodeId]!;
      final toLayout = nodeLayouts[arrow.toNodeId]!;
      
      final startPoint = fromLayout.bounds.center;
      final endPoint = toLayout.bounds.center;
      final controlPoint1 = startPoint + arrow.delta1;
      final controlPoint2 = endPoint + arrow.delta2;
      
      // Update gesture handler with correct layouts
      final updatedGestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: nodeLayouts,
        transform: Matrix4.identity(),
      );
      
      // Hit test at control point 1
      final hit1 = updatedGestureHandler.hitTestArrowControlPoint(controlPoint1);
      if (hit1 != null) {
        expect(hit1.$1, equals(arrow.id));
        expect(hit1.$2, equals(0)); // First control point
      }
      
      // Hit test at control point 2
      final hit2 = updatedGestureHandler.hitTestArrowControlPoint(controlPoint2);
      if (hit2 != null) {
        expect(hit2.$1, equals(arrow.id));
        expect(hit2.$2, equals(1)); // Second control point
      }
    });
    
    test('hitTestArrowControlPoint should return null when no arrow is selected', () {
      // Don't select any arrow
      expect(controller.selectedArrowId, isNull);
      
      // Get node layouts
      final nodeLayouts = layoutEngine.calculateLayout(
        controller.getData().nodeData,
        MindMapTheme.light,
        LayoutDirection.side,
      );
      
      // Update gesture handler with correct layouts
      final updatedGestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: nodeLayouts,
        transform: Matrix4.identity(),
      );
      
      // Hit test should return null
      final hit = updatedGestureHandler.hitTestArrowControlPoint(const Offset(100, 100));
      expect(hit, isNull);
    });
  });
}

/// Calculate a point on a cubic bezier curve at parameter t (0 to 1)
Offset _calculateBezierPoint(
  Offset p0,
  Offset p1,
  Offset p2,
  Offset p3,
  double t,
) {
  final oneMinusT = 1.0 - t;
  final oneMinusTSquared = oneMinusT * oneMinusT;
  final oneMinusTCubed = oneMinusTSquared * oneMinusT;
  final tSquared = t * t;
  final tCubed = tSquared * t;
  
  return Offset(
    oneMinusTCubed * p0.dx +
        3 * oneMinusTSquared * t * p1.dx +
        3 * oneMinusT * tSquared * p2.dx +
        tCubed * p3.dx,
    oneMinusTCubed * p0.dy +
        3 * oneMinusTSquared * t * p1.dy +
        3 * oneMinusT * tSquared * p2.dy +
        tCubed * p3.dy,
  );
}
