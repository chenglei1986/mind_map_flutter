import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

void main() {
  group('ZoomPanManager Unit Tests', () {
    late ZoomPanManager zoomPanManager;

    setUp(() {
      zoomPanManager = ZoomPanManager(minScale: 0.1, maxScale: 5.0);
    });

    tearDown(() {
      zoomPanManager.dispose();
    });

    // Test initial state
    test('should initialize with identity transform', () {
      expect(zoomPanManager.scale, 1.0);
      expect(zoomPanManager.translation, Offset.zero);
      expect(zoomPanManager.transform, Matrix4.identity());
    });

    // Test pan gestures
    // Validates: Requirement 15.1 - Pan the viewport when dragging on blank canvas
    group('Pan Gestures', () {
      test('should handle pan start', () {
        zoomPanManager.handlePanStart(const Offset(100, 100));

        // Pan start should not change the transform yet
        expect(zoomPanManager.translation, Offset.zero);
      });

      test('should update translation on pan update', () {
        zoomPanManager.handlePanStart(const Offset(100, 100));
        zoomPanManager.handlePanUpdate(const Offset(50, 30));

        expect(zoomPanManager.translation, const Offset(50, 30));
      });

      test('should accumulate pan deltas', () {
        zoomPanManager.handlePanStart(const Offset(100, 100));
        zoomPanManager.handlePanUpdate(const Offset(50, 30));
        zoomPanManager.handlePanUpdate(const Offset(20, 10));

        expect(zoomPanManager.translation, const Offset(70, 40));
      });

      test('should handle negative pan deltas', () {
        zoomPanManager.handlePanStart(const Offset(100, 100));
        zoomPanManager.handlePanUpdate(const Offset(-50, -30));

        expect(zoomPanManager.translation, const Offset(-50, -30));
      });

      test('should notify listeners on pan update', () {
        bool notified = false;
        zoomPanManager.addListener(() {
          notified = true;
        });

        zoomPanManager.handlePanStart(const Offset(100, 100));
        zoomPanManager.handlePanUpdate(const Offset(50, 30));

        expect(notified, isTrue);
      });

      test('should handle pan end', () {
        zoomPanManager.handlePanStart(const Offset(100, 100));
        zoomPanManager.handlePanUpdate(const Offset(50, 30));
        zoomPanManager.handlePanEnd();

        // Translation should remain after pan end
        expect(zoomPanManager.translation, const Offset(50, 30));
      });

      test('should allow new pan after pan end', () {
        // First pan
        zoomPanManager.handlePanStart(const Offset(100, 100));
        zoomPanManager.handlePanUpdate(const Offset(50, 30));
        zoomPanManager.handlePanEnd();

        // Second pan
        zoomPanManager.handlePanStart(const Offset(200, 200));
        zoomPanManager.handlePanUpdate(const Offset(20, 10));

        expect(zoomPanManager.translation, const Offset(70, 40));
      });
    });

    // Test pinch-to-zoom gestures
    // Validates: Requirement 15.2 - Zoom with pinch gesture
    group('Pinch-to-Zoom Gestures', () {
      test('should handle scale start', () {
        final details = ScaleStartDetails(focalPoint: const Offset(200, 200));

        zoomPanManager.handleScaleStart(details);

        // Scale start should not change the transform yet
        expect(zoomPanManager.scale, 1.0);
      });

      test('should update scale on scale update', () {
        final startDetails = ScaleStartDetails(
          focalPoint: const Offset(200, 200),
        );
        final updateDetails = ScaleUpdateDetails(
          focalPoint: const Offset(200, 200),
          scale: 2.0,
        );

        zoomPanManager.handleScaleStart(startDetails);
        zoomPanManager.handleScaleUpdate(updateDetails);

        expect(zoomPanManager.scale, 2.0);
      });

      test('should constrain scale to minimum', () {
        final startDetails = ScaleStartDetails(
          focalPoint: const Offset(200, 200),
        );
        final updateDetails = ScaleUpdateDetails(
          focalPoint: const Offset(200, 200),
          scale: 0.05, // Below minScale (0.1)
        );

        zoomPanManager.handleScaleStart(startDetails);
        zoomPanManager.handleScaleUpdate(updateDetails);

        expect(zoomPanManager.scale, 0.1);
      });

      test('should constrain scale to maximum', () {
        final startDetails = ScaleStartDetails(
          focalPoint: const Offset(200, 200),
        );
        final updateDetails = ScaleUpdateDetails(
          focalPoint: const Offset(200, 200),
          scale: 10.0, // Above maxScale (5.0)
        );

        zoomPanManager.handleScaleStart(startDetails);
        zoomPanManager.handleScaleUpdate(updateDetails);

        expect(zoomPanManager.scale, 5.0);
      });

      test('should notify listeners on scale update', () {
        bool notified = false;
        zoomPanManager.addListener(() {
          notified = true;
        });

        final startDetails = ScaleStartDetails(
          focalPoint: const Offset(200, 200),
        );
        final updateDetails = ScaleUpdateDetails(
          focalPoint: const Offset(200, 200),
          scale: 2.0,
        );

        zoomPanManager.handleScaleStart(startDetails);
        zoomPanManager.handleScaleUpdate(updateDetails);

        expect(notified, isTrue);
      });

      test('should handle scale end', () {
        final startDetails = ScaleStartDetails(
          focalPoint: const Offset(200, 200),
        );
        final updateDetails = ScaleUpdateDetails(
          focalPoint: const Offset(200, 200),
          scale: 2.0,
        );
        final endDetails = ScaleEndDetails();

        zoomPanManager.handleScaleStart(startDetails);
        zoomPanManager.handleScaleUpdate(updateDetails);
        zoomPanManager.handleScaleEnd(endDetails);

        // Scale should remain after scale end
        expect(zoomPanManager.scale, 2.0);
      });

      test('should zoom around focal point', () {
        // Set initial translation
        zoomPanManager.setTranslation(const Offset(100, 100));
        const focalPoint = Offset(200, 200);
        final canvasPointBefore =
            (focalPoint - zoomPanManager.translation) / zoomPanManager.scale;

        final startDetails = ScaleStartDetails(focalPoint: focalPoint);
        final updateDetails = ScaleUpdateDetails(
          focalPoint: focalPoint,
          scale: 2.0,
        );

        zoomPanManager.handleScaleStart(startDetails);
        zoomPanManager.handleScaleUpdate(updateDetails);
        final canvasPointAfter =
            (focalPoint - zoomPanManager.translation) / zoomPanManager.scale;

        expect(zoomPanManager.scale, 2.0);
        expect(canvasPointAfter.dx, closeTo(canvasPointBefore.dx, 1e-6));
        expect(canvasPointAfter.dy, closeTo(canvasPointBefore.dy, 1e-6));
      });
    });

    // Test mouse wheel zoom
    // Validates: Requirement 15.3 - Zoom with mouse wheel scroll
    group('Mouse Wheel Zoom', () {
      test('should zoom in on scroll up', () {
        final event = PointerScrollEvent(
          scrollDelta: const Offset(0, -100), // Negative = scroll up = zoom in
        );

        zoomPanManager.handleMouseWheel(event, const Offset(200, 200));

        expect(zoomPanManager.scale, greaterThan(1.0));
      });

      test('should zoom out on scroll down', () {
        final event = PointerScrollEvent(
          scrollDelta: const Offset(
            0,
            100,
          ), // Positive = scroll down = zoom out
        );

        zoomPanManager.handleMouseWheel(event, const Offset(200, 200));

        expect(zoomPanManager.scale, lessThan(1.0));
      });

      test('should constrain zoom to minimum on mouse wheel', () {
        // Zoom out a lot
        for (int i = 0; i < 20; i++) {
          final event = PointerScrollEvent(scrollDelta: const Offset(0, 500));
          zoomPanManager.handleMouseWheel(event, const Offset(200, 200));
        }

        expect(zoomPanManager.scale, 0.1);
      });

      test('should constrain zoom to maximum on mouse wheel', () {
        // Zoom in a lot
        for (int i = 0; i < 20; i++) {
          final event = PointerScrollEvent(scrollDelta: const Offset(0, -500));
          zoomPanManager.handleMouseWheel(event, const Offset(200, 200));
        }

        expect(zoomPanManager.scale, 5.0);
      });

      test('should notify listeners on mouse wheel zoom', () {
        bool notified = false;
        zoomPanManager.addListener(() {
          notified = true;
        });

        final event = PointerScrollEvent(scrollDelta: const Offset(0, -100));

        zoomPanManager.handleMouseWheel(event, const Offset(200, 200));

        expect(notified, isTrue);
      });

      test('should zoom around pointer position', () {
        // Set initial translation
        zoomPanManager.setTranslation(const Offset(100, 100));
        const pointer = Offset(200, 200);
        final canvasPointBefore =
            (pointer - zoomPanManager.translation) / zoomPanManager.scale;

        final event = PointerScrollEvent(scrollDelta: const Offset(0, -100));

        zoomPanManager.handleMouseWheel(event, pointer);
        final canvasPointAfter =
            (pointer - zoomPanManager.translation) / zoomPanManager.scale;

        expect(zoomPanManager.scale, greaterThan(1.0));
        expect(canvasPointAfter.dx, closeTo(canvasPointBefore.dx, 1e-6));
        expect(canvasPointAfter.dy, closeTo(canvasPointBefore.dy, 1e-6));
      });
    });

    // Test programmatic zoom control
    group('Programmatic Zoom Control', () {
      test('should set zoom level', () {
        zoomPanManager.setZoom(2.5);

        expect(zoomPanManager.scale, 2.5);
      });

      test('should constrain programmatic zoom to minimum', () {
        zoomPanManager.setZoom(0.05);

        expect(zoomPanManager.scale, 0.1);
      });

      test('should constrain programmatic zoom to maximum', () {
        zoomPanManager.setZoom(10.0);

        expect(zoomPanManager.scale, 5.0);
      });

      test('should notify listeners on programmatic zoom', () {
        bool notified = false;
        zoomPanManager.addListener(() {
          notified = true;
        });

        zoomPanManager.setZoom(2.0);

        expect(notified, isTrue);
      });

      test('should zoom around focal point when provided', () {
        zoomPanManager.setTranslation(const Offset(100, 100));
        const focalPoint = Offset(200, 200);
        final canvasPointBefore =
            (focalPoint - zoomPanManager.translation) / zoomPanManager.scale;

        zoomPanManager.setZoom(2.0, focalPoint: focalPoint);
        final canvasPointAfter =
            (focalPoint - zoomPanManager.translation) / zoomPanManager.scale;

        expect(zoomPanManager.scale, 2.0);
        expect(canvasPointAfter.dx, closeTo(canvasPointBefore.dx, 1e-6));
        expect(canvasPointAfter.dy, closeTo(canvasPointBefore.dy, 1e-6));
      });

      test('should not adjust translation when focal point not provided', () {
        zoomPanManager.setTranslation(const Offset(100, 100));

        zoomPanManager.setZoom(2.0);

        expect(zoomPanManager.scale, 2.0);
        expect(zoomPanManager.translation, const Offset(100, 100));
      });
    });

    // Test programmatic translation control
    group('Programmatic Translation Control', () {
      test('should set translation', () {
        zoomPanManager.setTranslation(const Offset(150, 200));

        expect(zoomPanManager.translation, const Offset(150, 200));
      });

      test('should notify listeners on translation change', () {
        bool notified = false;
        zoomPanManager.addListener(() {
          notified = true;
        });

        zoomPanManager.setTranslation(const Offset(150, 200));

        expect(notified, isTrue);
      });
    });

    // Test center on point
    group('Center On Point', () {
      test('should center view on canvas point', () {
        final canvasPoint = const Offset(500, 300);
        final viewportSize = const Size(800, 600);

        zoomPanManager.centerOn(canvasPoint, viewportSize);

        // The canvas point should be at the center of the viewport
        // viewportCenter = (400, 300)
        // translation = viewportCenter - canvasPoint * scale
        // translation = (400, 300) - (500, 300) * 1.0 = (-100, 0)
        expect(zoomPanManager.translation, const Offset(-100, 0));
      });

      test('should center view with zoom applied', () {
        zoomPanManager.setZoom(2.0);

        final canvasPoint = const Offset(500, 300);
        final viewportSize = const Size(800, 600);

        zoomPanManager.centerOn(canvasPoint, viewportSize);

        // With scale 2.0:
        // translation = (400, 300) - (500, 300) * 2.0 = (400, 300) - (1000, 600) = (-600, -300)
        expect(zoomPanManager.translation, const Offset(-600, -300));
      });

      test('should notify listeners when centering', () {
        bool notified = false;
        zoomPanManager.addListener(() {
          notified = true;
        });

        zoomPanManager.centerOn(const Offset(500, 300), const Size(800, 600));

        expect(notified, isTrue);
      });
    });

    // Test reset
    group('Reset', () {
      test('should reset to default state', () {
        // Change state
        zoomPanManager.setZoom(2.5);
        zoomPanManager.setTranslation(const Offset(150, 200));

        // Reset
        zoomPanManager.reset();

        expect(zoomPanManager.scale, 1.0);
        expect(zoomPanManager.translation, Offset.zero);
      });

      test('should notify listeners on reset', () {
        bool notified = false;
        zoomPanManager.addListener(() {
          notified = true;
        });

        zoomPanManager.setZoom(2.0);
        notified = false; // Reset flag

        zoomPanManager.reset();

        expect(notified, isTrue);
      });
    });

    // Test transform matrix
    group('Transform Matrix', () {
      test('should update transform matrix on scale change', () {
        zoomPanManager.setZoom(2.0);

        final transform = zoomPanManager.transform;
        final testPoint = const Offset(100, 100);
        final transformedPoint = MatrixUtils.transformPoint(
          transform,
          testPoint,
        );

        // With scale 2.0 and no translation:
        // transformed = (100 * 2.0, 100 * 2.0) = (200, 200)
        expect(transformedPoint, const Offset(200, 200));
      });

      test('should update transform matrix on translation change', () {
        zoomPanManager.setTranslation(const Offset(50, 30));

        final transform = zoomPanManager.transform;
        final testPoint = const Offset(100, 100);
        final transformedPoint = MatrixUtils.transformPoint(
          transform,
          testPoint,
        );

        // With translation (50, 30) and scale 1.0:
        // transformed = (100 + 50, 100 + 30) = (150, 130)
        expect(transformedPoint, const Offset(150, 130));
      });

      test('should apply translation before scale in transform', () {
        zoomPanManager.setTranslation(const Offset(50, 30));
        zoomPanManager.setZoom(2.0);

        final transform = zoomPanManager.transform;
        final testPoint = const Offset(100, 100);
        final transformedPoint = MatrixUtils.transformPoint(
          transform,
          testPoint,
        );

        // Transform order: translate then scale
        // First translate: (100 + 50, 100 + 30) = (150, 130)
        // Then scale: (150 * 2.0, 130 * 2.0) = (300, 260)
        // But Matrix4 applies in reverse order when using ..translate..scale
        // So it's actually: scale first, then translate
        // (100 * 2.0, 100 * 2.0) + (50, 30) = (200, 200) + (50, 30) = (250, 230)
        expect(transformedPoint, const Offset(250, 230));
      });
    });

    // Test scale constraints
    // Validates: Requirement 15.4 - Constrain zoom to min/max scale
    group('Scale Constraints', () {
      test('should enforce minimum scale constraint', () {
        zoomPanManager.setZoom(0.01); // Way below minimum
        expect(zoomPanManager.scale, 0.1);

        zoomPanManager.setZoom(0.05); // Below minimum
        expect(zoomPanManager.scale, 0.1);

        zoomPanManager.setZoom(0.1); // Exactly minimum
        expect(zoomPanManager.scale, 0.1);
      });

      test('should enforce maximum scale constraint', () {
        zoomPanManager.setZoom(100.0); // Way above maximum
        expect(zoomPanManager.scale, 5.0);

        zoomPanManager.setZoom(10.0); // Above maximum
        expect(zoomPanManager.scale, 5.0);

        zoomPanManager.setZoom(5.0); // Exactly maximum
        expect(zoomPanManager.scale, 5.0);
      });

      test('should allow scale within valid range', () {
        zoomPanManager.setZoom(0.5);
        expect(zoomPanManager.scale, 0.5);

        zoomPanManager.setZoom(1.0);
        expect(zoomPanManager.scale, 1.0);

        zoomPanManager.setZoom(2.5);
        expect(zoomPanManager.scale, 2.5);

        zoomPanManager.setZoom(4.5);
        expect(zoomPanManager.scale, 4.5);
      });

      test('should use custom min/max scale values', () {
        final customManager = ZoomPanManager(minScale: 0.5, maxScale: 3.0);

        customManager.setZoom(0.1);
        expect(customManager.scale, 0.5);

        customManager.setZoom(10.0);
        expect(customManager.scale, 3.0);

        customManager.dispose();
      });
    });

    // Test state consistency
    group('State Consistency', () {
      test('should maintain consistent state through zoom and pan', () {
        // Initial state
        expect(zoomPanManager.scale, 1.0);
        expect(zoomPanManager.translation, Offset.zero);

        // Pan
        zoomPanManager.handlePanStart(const Offset(100, 100));
        zoomPanManager.handlePanUpdate(const Offset(50, 30));
        expect(zoomPanManager.translation, const Offset(50, 30));

        // Zoom
        zoomPanManager.setZoom(2.0);
        expect(zoomPanManager.scale, 2.0);
        expect(zoomPanManager.translation, const Offset(50, 30));

        // Pan again
        zoomPanManager.handlePanUpdate(const Offset(20, 10));
        expect(zoomPanManager.translation, const Offset(70, 40));
        expect(zoomPanManager.scale, 2.0);
      });

      test('should handle multiple zoom operations', () {
        zoomPanManager.setZoom(2.0);
        expect(zoomPanManager.scale, 2.0);

        zoomPanManager.setZoom(1.5);
        expect(zoomPanManager.scale, 1.5);

        zoomPanManager.setZoom(3.0);
        expect(zoomPanManager.scale, 3.0);
      });

      test('should handle multiple pan operations', () {
        zoomPanManager.handlePanStart(const Offset(0, 0));
        zoomPanManager.handlePanUpdate(const Offset(10, 20));
        expect(zoomPanManager.translation, const Offset(10, 20));

        zoomPanManager.handlePanUpdate(const Offset(5, 10));
        expect(zoomPanManager.translation, const Offset(15, 30));

        zoomPanManager.handlePanUpdate(const Offset(-5, -10));
        expect(zoomPanManager.translation, const Offset(10, 20));
      });
    });
  });
}
