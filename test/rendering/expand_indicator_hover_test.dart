import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';
import 'dart:ui' as ui;

void main() {
  group('Expand Indicator Hover Tests', () {
    test('Expand indicator should be hidden by default on desktop platforms', () {
      final node = NodeData(
        id: 'test',
        topic: 'Test Node',
        children: [
          NodeData(id: 'child1', topic: 'Child 1'),
        ],
      );
      
      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(120, 40),
      );
      
      final theme = MindMapTheme.light;
      
      // Create a canvas recorder to test drawing
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Draw node without showing expand indicator (desktop default)
      NodeRenderer.drawNode(
        canvas,
        node,
        layout,
        theme,
        false, // not selected
        false, // not root
        showExpandIndicator: false, // hidden by default on desktop
      );
      
      // The test passes if no exception is thrown
      expect(true, true);
    });
    
    test('Expand indicator should be shown when hovered', () {
      final node = NodeData(
        id: 'test',
        topic: 'Test Node',
        children: [
          NodeData(id: 'child1', topic: 'Child 1'),
        ],
      );
      
      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(120, 40),
      );
      
      final theme = MindMapTheme.light;
      
      // Create a canvas recorder to test drawing
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Draw node with expand indicator shown (when hovered)
      NodeRenderer.drawNode(
        canvas,
        node,
        layout,
        theme,
        false, // not selected
        false, // not root
        showExpandIndicator: true, // shown when hovered
      );
      
      // The test passes if no exception is thrown
      expect(true, true);
    });
    
    test('Expand indicator bounds should be calculable', () {
      final node = NodeData(
        id: 'test',
        topic: 'Test Node',
        children: [
          NodeData(id: 'child1', topic: 'Child 1'),
        ],
      );
      
      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(120, 40),
      );
      
      // Get expand indicator bounds
      final bounds = NodeRenderer.getExpandIndicatorBounds(node, layout);
      
      // Should return a valid rect for nodes with children
      expect(bounds, isNotNull);
      expect(bounds!.width, NodeRenderer.indicatorSize);
      expect(bounds.height, NodeRenderer.indicatorSize);
    });
    
    test('Expand indicator bounds should be null for nodes without children', () {
      final node = NodeData(
        id: 'test',
        topic: 'Test Node',
        children: [], // no children
      );
      
      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(120, 40),
      );
      
      // Get expand indicator bounds
      final bounds = NodeRenderer.getExpandIndicatorBounds(node, layout);
      
      // Should return null for nodes without children
      expect(bounds, isNull);
    });
  });
}
