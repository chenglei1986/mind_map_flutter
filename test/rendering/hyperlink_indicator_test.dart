import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/layout/node_layout.dart';
import 'package:mind_map_flutter/src/rendering/node_renderer.dart';

void main() {
  group('Hyperlink Indicator Tests', () {
    late MindMapTheme theme;

    setUp(() {
      theme = MindMapTheme.light;
    });

    test('should return hyperlink indicator bounds for node with hyperlink', () {
      final node = NodeData.create(
        topic: 'Test Node',
        hyperLink: 'https://example.com',
      );

      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(150, 50),
      );

      final bounds = NodeRenderer.getHyperlinkIndicatorBounds(node, layout);

      expect(bounds, isNotNull);
      expect(bounds!.width, 14.0);
      expect(bounds.height, 14.0);
      // Should be in bottom-right corner
      expect(bounds.right, closeTo(layout.bounds.right - 4.0, 0.1));
      expect(bounds.bottom, closeTo(layout.bounds.bottom - 4.0, 0.1));
    });

    test('should return null for node without hyperlink', () {
      final node = NodeData.create(
        topic: 'Test Node',
      );

      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(150, 50),
      );

      final bounds = NodeRenderer.getHyperlinkIndicatorBounds(node, layout);

      expect(bounds, isNull);
    });

    test('should return null for node with empty hyperlink', () {
      final node = NodeData.create(
        topic: 'Test Node',
        hyperLink: '',
      );

      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(150, 50),
      );

      final bounds = NodeRenderer.getHyperlinkIndicatorBounds(node, layout);

      expect(bounds, isNull);
    });

    test('should place hyperlink indicator at right tail for right-side node', () {
      final node = NodeData.create(
        topic: 'Test Node',
        hyperLink: 'https://example.com',
      );

      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(150, 50),
      );

      final bounds = NodeRenderer.getHyperlinkIndicatorBounds(
        node,
        layout,
        theme,
        2,
        false,
      );

      expect(bounds, isNotNull);
      expect(bounds!.left, greaterThanOrEqualTo(layout.bounds.right));
    });

    test('should place hyperlink indicator at left tail for left-side node', () {
      final node = NodeData.create(
        topic: 'Test Node',
        hyperLink: 'https://example.com',
      );

      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(150, 50),
      );

      final bounds = NodeRenderer.getHyperlinkIndicatorBounds(
        node,
        layout,
        theme,
        2,
        true,
      );

      expect(bounds, isNotNull);
      expect(bounds!.right, lessThanOrEqualTo(layout.bounds.left));
    });

    testWidgets('should draw hyperlink indicator for node with hyperlink', (tester) async {
      final node = NodeData.create(
        topic: 'Test Node',
        hyperLink: 'https://example.com',
      );

      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(150, 50),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: _TestPainter(node, layout, theme),
            ),
          ),
        ),
      );

      // If we get here without errors, the drawing succeeded
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('should not draw hyperlink indicator for node without hyperlink', (tester) async {
      final node = NodeData.create(
        topic: 'Test Node',
      );

      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(150, 50),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              painter: _TestPainter(node, layout, theme),
            ),
          ),
        ),
      );

      // If we get here without errors, the drawing succeeded
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}

/// Test painter to verify drawing doesn't throw errors
class _TestPainter extends CustomPainter {
  final NodeData node;
  final NodeLayout layout;
  final MindMapTheme theme;

  _TestPainter(this.node, this.layout, this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    NodeRenderer.drawNode(
      canvas,
      node,
      layout,
      theme,
      false,
      false,
    );
  }

  @override
  bool shouldRepaint(_TestPainter oldDelegate) => false;
}
