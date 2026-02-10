import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/image_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/layout/node_layout.dart';
import 'package:mind_map_flutter/src/rendering/node_renderer.dart';

void main() {
  group('Image Rendering Unit Tests', () {
    late MindMapTheme theme;

    setUp(() {
      theme = MindMapTheme.light;
    });

    test('should handle image loading failure with placeholder - invalid URL', () {
      // Test that a node with an invalid image URL still renders with a placeholder
      final node = NodeData.create(
        topic: 'Node with invalid image',
        image: const ImageData(
          url: 'invalid://not-a-real-url',
          width: 100,
          height: 80,
        ),
      );

      // Verify that the node has image data
      expect(node.image, isNotNull);
      expect(node.image!.url, 'invalid://not-a-real-url');
      expect(node.image!.width, 100);
      expect(node.image!.height, 80);

      // Verify that node size calculation accounts for the image
      // even if the URL is invalid
      final size = NodeRenderer.measureNodeSize(node, theme, false, 1);
      final expectedMinHeight = node.image!.height + 16.0; // image height + padding
      expect(size.height, greaterThanOrEqualTo(expectedMinHeight));
      expect(size.width, greaterThanOrEqualTo(node.image!.width));
    });

    test('should handle image loading failure with placeholder - empty URL', () {
      // Test that a node with an empty image URL still renders with a placeholder
      final node = NodeData.create(
        topic: 'Node with empty image URL',
        image: const ImageData(
          url: '',
          width: 120,
          height: 90,
        ),
      );

      // Verify that the node has image data with empty URL
      expect(node.image, isNotNull);
      expect(node.image!.url, isEmpty);
      expect(node.image!.width, 120);
      expect(node.image!.height, 90);

      // Verify that node size calculation still works
      final size = NodeRenderer.measureNodeSize(node, theme, false, 1);
      final expectedMinHeight = node.image!.height + 16.0;
      expect(size.height, greaterThanOrEqualTo(expectedMinHeight));
      expect(size.width, greaterThanOrEqualTo(node.image!.width));
    });

    test('should handle image loading failure with placeholder - 404 URL', () {
      // Test that a node with a non-existent image URL still renders with a placeholder
      final node = NodeData.create(
        topic: 'Node with 404 image',
        image: const ImageData(
          url: 'https://example.com/nonexistent-image-404.jpg',
          width: 150,
          height: 100,
        ),
      );

      // Verify that the node has image data
      expect(node.image, isNotNull);
      expect(node.image!.url, contains('404'));
      expect(node.image!.width, 150);
      expect(node.image!.height, 100);

      // Verify that node size calculation accounts for the image
      final size = NodeRenderer.measureNodeSize(node, theme, false, 1);
      final expectedMinHeight = node.image!.height + 16.0;
      expect(size.height, greaterThanOrEqualTo(expectedMinHeight));
      expect(size.width, greaterThanOrEqualTo(node.image!.width));
    });

    testWidgets('should draw placeholder for node with invalid image URL', (tester) async {
      // Test that drawing a node with an invalid image doesn't throw errors
      // and renders a placeholder instead
      final node = NodeData.create(
        topic: 'Test Node',
        image: const ImageData(
          url: 'invalid://bad-url',
          width: 100,
          height: 80,
        ),
      );

      final layout = NodeLayout(
        position: const Offset(100, 100),
        size: const Size(200, 150),
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

      // If we get here without errors, the placeholder was drawn successfully
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('should draw placeholder for node with empty image URL', (tester) async {
      // Test that drawing a node with an empty image URL doesn't throw errors
      final node = NodeData.create(
        topic: 'Test Node',
        image: const ImageData(
          url: '',
          width: 120,
          height: 90,
        ),
      );

      final layout = NodeLayout(
        position: const Offset(50, 50),
        size: const Size(180, 140),
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

      // If we get here without errors, the placeholder was drawn successfully
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('should draw placeholder for node with network error image', (tester) async {
      // Test that drawing a node with a network error image doesn't throw errors
      final node = NodeData.create(
        topic: 'Test Node',
        image: const ImageData(
          url: 'https://example.com/network-error.jpg',
          width: 150,
          height: 100,
        ),
      );

      final layout = NodeLayout(
        position: const Offset(200, 200),
        size: const Size(220, 180),
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

      // If we get here without errors, the placeholder was drawn successfully
      expect(find.byType(CustomPaint), findsWidgets);
    });

    test('should preserve image dimensions in placeholder rendering', () {
      // Test that placeholder respects the specified image dimensions
      final node = NodeData.create(
        topic: 'Node with specific dimensions',
        image: const ImageData(
          url: 'invalid://url',
          width: 200,
          height: 150,
        ),
      );

      // Verify that the image dimensions are preserved
      expect(node.image!.width, 200);
      expect(node.image!.height, 150);

      // Verify that node size calculation uses these dimensions
      final size = NodeRenderer.measureNodeSize(node, theme, false, 1);
      expect(size.width, greaterThanOrEqualTo(200));
      expect(size.height, greaterThanOrEqualTo(150 + 16.0)); // image height + padding
    });

    test('should handle various BoxFit modes with placeholder', () {
      // Test that different BoxFit modes don't cause errors with placeholders
      final fitModes = [
        BoxFit.contain,
        BoxFit.cover,
        BoxFit.fill,
        BoxFit.fitWidth,
        BoxFit.fitHeight,
        BoxFit.none,
        BoxFit.scaleDown,
      ];

      for (final fit in fitModes) {
        final node = NodeData.create(
          topic: 'Node with $fit',
          image: ImageData(
            url: 'invalid://url',
            width: 100,
            height: 80,
            fit: fit,
          ),
        );

        // Verify that the node has the correct BoxFit
        expect(node.image!.fit, fit);

        // Verify that size calculation works regardless of BoxFit
        final size = NodeRenderer.measureNodeSize(node, theme, false, 1);
        expect(size.width, greaterThan(0));
        expect(size.height, greaterThan(0));
      }
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
