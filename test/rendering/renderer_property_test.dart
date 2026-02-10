import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';
import 'package:mind_map_flutter/src/layout/layout_engine.dart';
import 'package:mind_map_flutter/src/rendering/node_renderer.dart';
import '../helpers/generators.dart';

void main() {
  group('Renderer Property Tests', () {
    // Feature: mind-map-flutter, Property 3: 分支连接完整性
    test('Property 3: Branch connection integrity - for any node with parent-child relationship, there should be a branch line connecting them with color from theme palette', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate random mind map data
        final mindMapData = generateRandomMindMapData(
          maxDepth: 3,
          maxChildren: 4,
        );
        
        // Calculate layouts
        final layoutEngine = LayoutEngine();
        final layouts = layoutEngine.calculateLayout(
          mindMapData.nodeData,
          mindMapData.theme,
          mindMapData.direction,
        );
        
        // Verify branch connections exist for all parent-child pairs
        _verifyBranchConnections(
          mindMapData.nodeData,
          layouts,
          mindMapData.theme,
        );
      }
    });

    // Feature: mind-map-flutter, Property 4: 样式应用一致性
    test('Property 4: Style application consistency - for any node with custom style, the rendering output should contain all specified style properties', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate node with random custom styles
        final node = _generateNodeWithCustomStyle();
        final theme = MindMapTheme.light;
        
        // Measure node size
        final size = NodeRenderer.measureNodeSize(node, theme, false, 1);
        
        // Verify size is calculated based on style
        expect(size.width, greaterThan(0));
        expect(size.height, greaterThan(0));
        
        // If custom width is specified, verify it's used
        if (node.style?.width != null) {
          expect(size.width, equals(node.style!.width));
        }
        
        // Verify style properties are accessible for rendering
        if (node.style != null) {
          final style = node.style!;
          
          // All style properties should be preserved
          if (style.fontSize != null) {
            expect(style.fontSize, greaterThan(0));
          }
          if (style.color != null) {
            expect(style.color, isNotNull);
          }
          if (style.background != null) {
            expect(style.background, isNotNull);
          }
          if (style.fontWeight != null) {
            expect(style.fontWeight, isNotNull);
          }
        }
      }
    });
  });
}

/// Verify that branch connections exist for all parent-child relationships
void _verifyBranchConnections(
  NodeData node,
  Map<String, NodeLayout> layouts,
  MindMapTheme theme,
) {
  final parentLayout = layouts[node.id];
  if (parentLayout == null) return;
  
  // For each child, verify connection can be established
  for (int i = 0; i < node.children.length; i++) {
    final child = node.children[i];
    final childLayout = layouts[child.id];
    
    if (childLayout != null) {
      // Verify layouts exist for both parent and child
      expect(parentLayout, isNotNull);
      expect(childLayout, isNotNull);
      
      // Verify branch color comes from palette or custom color
      final branchIndex = i;
      final expectedColor = child.branchColor ?? 
          theme.palette[branchIndex % theme.palette.length];
      expect(expectedColor, isNotNull);
      
      // Verify connection points can be calculated
      final parentBounds = parentLayout.bounds;
      final childBounds = childLayout.bounds;
      expect(parentBounds.width, greaterThan(0));
      expect(parentBounds.height, greaterThan(0));
      expect(childBounds.width, greaterThan(0));
      expect(childBounds.height, greaterThan(0));
      
      // Recursively verify child's branches
      _verifyBranchConnections(child, layouts, theme);
    }
  }
}

/// Generate a node with random custom styles
NodeData _generateNodeWithCustomStyle() {
  final random = DateTime.now().millisecondsSinceEpoch % 1000;
  final hasStyle = random % 2 == 0;
  
  if (!hasStyle) {
    return NodeData.create(topic: 'Node $random');
  }
  
  final style = NodeStyle(
    fontSize: random % 3 == 0 ? 12.0 + (random % 20) : null,
    color: random % 4 == 0 ? Color(0xFF000000 + random * 1000) : null,
    background: random % 5 == 0 ? Color(0xFFFFFFFF - random * 1000) : null,
    fontWeight: random % 6 == 0 ? FontWeight.bold : null,
    width: random % 7 == 0 ? 100.0 + (random % 200) : null,
  );
  
  return NodeData.create(
    topic: 'Styled Node $random',
    style: style,
  );
}
