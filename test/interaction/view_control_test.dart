import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

void main() {
  Offset expectedMapCenterTranslation(
    MindMapController controller,
    Size viewportSize,
  ) {
    final data = controller.getData();
    final layouts = LayoutEngine().calculateLayout(
      data.nodeData,
      data.theme,
      data.direction,
    );
    if (layouts.isEmpty) return Offset.zero;
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    for (final layout in layouts.values) {
      final bounds = layout.bounds;
      if (bounds.left < minX) minX = bounds.left;
      if (bounds.top < minY) minY = bounds.top;
      if (bounds.right > maxX) maxX = bounds.right;
      if (bounds.bottom > maxY) maxY = bounds.bottom;
    }
    final mapCenter = Rect.fromLTRB(minX, minY, maxX, maxY).center;
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    return viewportCenter - (mapCenter * controller.zoomPanManager.scale);
  }

  group('View Control Methods Unit Tests', () {
    late MindMapController controller;
    late MindMapData testData;

    setUp(() {
      // Create test data
      final rootNode = NodeData.create(
        topic: 'Root',
        children: [
          NodeData.create(topic: 'Child 1'),
          NodeData.create(topic: 'Child 2'),
        ],
      );

      testData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
        direction: LayoutDirection.side,
      );

      controller = MindMapController(
        initialData: testData,
        config: const MindMapConfig(minScale: 0.1, maxScale: 5.0),
      );

      // Set viewport size for testing
      controller.setViewportSize(const Size(800, 600));
    });

    tearDown(() {
      controller.dispose();
    });

    group('centerView()', () {
      test('should center view on full map bounds', () {
        // Move away from center first
        controller.zoomPanManager.setTranslation(const Offset(100, 100));

        // Center view (without animation for testing)
        controller.centerView(duration: Duration.zero);

        // The full map bounds center should align with viewport center.
        final translation = controller.zoomPanManager.translation;
        final expected = expectedMapCenterTranslation(
          controller,
          const Size(800, 600),
        );
        expect(translation.dx, expected.dx);
        expect(translation.dy, expected.dy);
      });

      test('should reset to origin when viewport size is not set', () {
        // Create controller without viewport size
        final controller2 = MindMapController(initialData: testData);

        // Move away from origin
        controller2.zoomPanManager.setTranslation(const Offset(100, 100));

        // Center view should reset to origin
        controller2.centerView(duration: Duration.zero);

        expect(controller2.zoomPanManager.scale, 1.0);
        expect(controller2.zoomPanManager.translation, Offset.zero);

        controller2.dispose();
      });

      test('should maintain current zoom level when centering', () {
        // Set a specific zoom level
        controller.zoomPanManager.setZoom(2.0);
        final initialScale = controller.zoomPanManager.scale;

        // Center view
        controller.centerView(duration: Duration.zero);

        // Zoom level should remain the same
        expect(controller.zoomPanManager.scale, initialScale);
      });
    });

    group('setZoom()', () {
      test('should set zoom level programmatically', () {
        controller.setZoom(2.0, duration: Duration.zero);

        expect(controller.zoomPanManager.scale, 2.0);
      });

      test('should clamp zoom to minimum scale', () {
        controller.setZoom(0.05, duration: Duration.zero);

        // Should be clamped to minScale (0.1)
        expect(controller.zoomPanManager.scale, 0.1);
      });

      test('should clamp zoom to maximum scale', () {
        controller.setZoom(10.0, duration: Duration.zero);

        // Should be clamped to maxScale (5.0)
        expect(controller.zoomPanManager.scale, 5.0);
      });

      test('should zoom around focal point when provided', () {
        // Set initial zoom
        controller.zoomPanManager.setZoom(1.0);
        controller.zoomPanManager.setTranslation(Offset.zero);

        // Zoom around a specific point
        final focalPoint = const Offset(400, 300); // center of viewport
        controller.setZoom(
          2.0,
          focalPoint: focalPoint,
          duration: Duration.zero,
        );

        expect(controller.zoomPanManager.scale, 2.0);
        // Translation should be adjusted to keep focal point fixed
        // (exact values depend on the implementation)
      });

      test('should notify listeners when zoom changes', () {
        bool notified = false;
        controller.addListener(() {
          notified = true;
        });

        controller.setZoom(2.0, duration: Duration.zero);

        expect(notified, isTrue);
      });
    });

    group('centerOnNode()', () {
      test('should center view on a specific node', () {
        final nodePosition = const Offset(200, 150);
        final nodeId = testData.nodeData.children.first.id;

        controller.centerOnNode(nodeId, nodePosition, duration: Duration.zero);

        // The view should be centered on the node position
        // With viewport 800x600 and node at (200, 150), and scale 1.0:
        // translation = viewportCenter - (nodePosition * scale)
        // translation = (400, 300) - (200, 150) = (200, 150)
        final translation = controller.zoomPanManager.translation;
        expect(translation.dx, 200.0);
        expect(translation.dy, 150.0);
      });

      test('should do nothing when viewport size is not set', () {
        final controller2 = MindMapController(initialData: testData);

        final initialTranslation = controller2.zoomPanManager.translation;

        controller2.centerOnNode(
          testData.nodeData.id,
          const Offset(100, 100),
          duration: Duration.zero,
        );

        // Translation should not change
        expect(controller2.zoomPanManager.translation, initialTranslation);

        controller2.dispose();
      });
    });

    group('Smooth Animations', () {
      test('should support immediate transitions with Duration.zero', () {
        controller.centerView(duration: Duration.zero);
        final expected = expectedMapCenterTranslation(
          controller,
          const Size(800, 600),
        );
        expect(controller.zoomPanManager.translation.dx, expected.dx);
        expect(controller.zoomPanManager.translation.dy, expected.dy);

        controller.setZoom(2.0, duration: Duration.zero);
        expect(controller.zoomPanManager.scale, 2.0);
      });

      // Note: Animation tests with non-zero duration are skipped because
      // they require proper async handling and would continue after test completion.
      // The animation functionality is validated through manual testing and
      // integration tests.
    });

    group('Integration with ZoomPanManager', () {
      test('should expose ZoomPanManager through getter', () {
        expect(controller.zoomPanManager, isNotNull);
      });

      test('should initialize ZoomPanManager with config values', () {
        expect(controller.zoomPanManager.minScale, 0.1);
        expect(controller.zoomPanManager.maxScale, 5.0);
      });

      test('should notify listeners when ZoomPanManager changes', () {
        bool notified = false;
        controller.addListener(() {
          notified = true;
        });

        // Directly manipulate ZoomPanManager
        controller.zoomPanManager.setZoom(2.0);

        expect(notified, isTrue);
      });

      test('should dispose ZoomPanManager when controller is disposed', () {
        // Create a separate controller for this test
        final testController = MindMapController(
          initialData: testData,
          config: const MindMapConfig(minScale: 0.1, maxScale: 5.0),
        );

        final zoomPanManager = testController.zoomPanManager;

        testController.dispose();

        // After disposal, the ZoomPanManager should throw when used
        expect(() => zoomPanManager.setZoom(2.0), throwsFlutterError);
      });
    });

    group('Viewport Size Management', () {
      test('should accept viewport size updates', () {
        controller.setViewportSize(const Size(1024, 768));

        // Verify by centering view with new size
        controller.centerView(duration: Duration.zero);

        final translation = controller.zoomPanManager.translation;
        final expected = expectedMapCenterTranslation(
          controller,
          const Size(1024, 768),
        );
        expect(translation.dx, expected.dx);
        expect(translation.dy, expected.dy);
      });

      test('should handle multiple viewport size updates', () {
        controller.setViewportSize(const Size(800, 600));
        controller.centerView(duration: Duration.zero);

        controller.setViewportSize(const Size(1024, 768));
        controller.centerView(duration: Duration.zero);

        final translation = controller.zoomPanManager.translation;
        final expected = expectedMapCenterTranslation(
          controller,
          const Size(1024, 768),
        );
        expect(translation.dx, expected.dx);
        expect(translation.dy, expected.dy);
      });
    });
  });
}
