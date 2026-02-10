import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_controller.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_widget.dart';
import 'package:mind_map_flutter/src/interaction/gesture_handler.dart';
import 'package:mind_map_flutter/src/layout/node_layout.dart';
import 'package:mind_map_flutter/src/rendering/node_renderer.dart';

void main() {
  group('Hyperlink Click Tests', () {
    test('should detect hyperlink indicator hit', () {
      final rootNode = NodeData.create(
        topic: 'Root',
        hyperLink: 'https://example.com',
        children: [],
      );

      final data = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );

      final controller = MindMapController(initialData: data);

      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(150, 50),
      );

      final nodeLayouts = {rootNode.id: layout};

      final gestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: nodeLayouts,
        transform: Matrix4.identity(),
      );

      final indicatorBounds = NodeRenderer.getHyperlinkIndicatorBounds(
        rootNode,
        layout,
        MindMapTheme.light,
        0,
      )!;
      final indicatorPosition = indicatorBounds.center;

      final hitNodeId = gestureHandler.hitTestHyperlinkIndicator(indicatorPosition);

      expect(hitNodeId, equals(rootNode.id));
    });

    test('should not detect hyperlink indicator hit outside bounds', () {
      final rootNode = NodeData.create(
        topic: 'Root',
        hyperLink: 'https://example.com',
        children: [],
      );

      final data = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );

      final controller = MindMapController(initialData: data);

      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(150, 50),
      );

      final nodeLayouts = {rootNode.id: layout};

      final gestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: nodeLayouts,
        transform: Matrix4.identity(),
      );

      // Position outside the indicator
      final outsidePosition = Offset(
        layout.bounds.left,
        layout.bounds.top,
      );

      final hitNodeId = gestureHandler.hitTestHyperlinkIndicator(outsidePosition);

      expect(hitNodeId, isNull);
    });

    test('should not detect hyperlink indicator for node without hyperlink', () {
      final rootNode = NodeData.create(
        topic: 'Root',
        children: [],
      );

      final data = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );

      final controller = MindMapController(initialData: data);

      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(150, 50),
      );

      final nodeLayouts = {rootNode.id: layout};

      final gestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: nodeLayouts,
        transform: Matrix4.identity(),
      );

      final indicatorBounds = NodeRenderer.getHyperlinkIndicatorBounds(
        rootNode,
        layout,
        MindMapTheme.light,
        0,
      );
      final indicatorPosition = indicatorBounds?.center ?? layout.bounds.center;

      final hitNodeId = gestureHandler.hitTestHyperlinkIndicator(indicatorPosition);

      expect(hitNodeId, isNull);
    });

    test('should emit HyperlinkClickEvent when hyperlink is clicked', () {
      final rootNode = NodeData.create(
        topic: 'Root',
        hyperLink: 'https://example.com',
        children: [],
      );

      final data = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );

      final controller = MindMapController(initialData: data);

      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(150, 50),
      );

      final nodeLayouts = {rootNode.id: layout};

      final gestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: nodeLayouts,
        transform: Matrix4.identity(),
      );

      final indicatorBounds = NodeRenderer.getHyperlinkIndicatorBounds(
        rootNode,
        layout,
        MindMapTheme.light,
        0,
      )!;
      final indicatorPosition = indicatorBounds.center;

      gestureHandler.handleTapUp(
        TapUpDetails(
          kind: PointerDeviceKind.touch,
          localPosition: indicatorPosition,
        ),
      );

      // Verify event was emitted
      expect(controller.lastEvent, isNotNull);
      expect(controller.lastEvent, isA<HyperlinkClickEvent>());
      final hyperlinkEvent = controller.lastEvent as HyperlinkClickEvent;
      expect(hyperlinkEvent.nodeId, equals(rootNode.id));
      expect(hyperlinkEvent.url, equals('https://example.com'));
    });

    test('should prioritize hyperlink click over node selection', () {
      final rootNode = NodeData.create(
        topic: 'Root',
        hyperLink: 'https://example.com',
        children: [],
      );

      final data = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );

      final controller = MindMapController(initialData: data);

      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(150, 50),
      );

      final nodeLayouts = {rootNode.id: layout};

      final gestureHandler = GestureHandler(
        controller: controller,
        nodeLayouts: nodeLayouts,
        transform: Matrix4.identity(),
      );

      final indicatorBounds = NodeRenderer.getHyperlinkIndicatorBounds(
        rootNode,
        layout,
        MindMapTheme.light,
        0,
      )!;
      final indicatorPosition = indicatorBounds.center;

      gestureHandler.handleTapUp(
        TapUpDetails(
          kind: PointerDeviceKind.touch,
          localPosition: indicatorPosition,
        ),
      );

      // Should emit HyperlinkClickEvent, not SelectNodesEvent
      expect(controller.lastEvent, isA<HyperlinkClickEvent>());
      
      // Node should not be selected
      expect(controller.selectionManager.selectedNodeIds, isEmpty);
    });
  });
}
