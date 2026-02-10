import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';
import 'dart:math';

/// Property-based tests for zoom and pan operations
/// 
/// Feature: mind-map-flutter
void main() {
  group('Zoom and Pan Property Tests', () {
    const iterations = 100;

    // For any zoom operation, the zoom value should be constrained to
    // the configured minimum and maximum range
    test('Property 31: Zoom range constraints', () {
      for (int i = 0; i < iterations; i++) {
        final random = Random(i);
        
        // Generate random min/max scale values
        final minScale = 0.05 + random.nextDouble() * 0.45; // 0.05 to 0.5
        final maxScale = 2.0 + random.nextDouble() * 8.0; // 2.0 to 10.0
        
        final zoomPanManager = ZoomPanManager(
          minScale: minScale,
          maxScale: maxScale,
        );
        
        // Test various zoom values
        final testScales = [
          0.01, // Way below minimum
          minScale * 0.5, // Below minimum
          minScale, // Exactly minimum
          minScale + (maxScale - minScale) * 0.25, // 25% of range
          minScale + (maxScale - minScale) * 0.5, // Middle of range
          minScale + (maxScale - minScale) * 0.75, // 75% of range
          maxScale, // Exactly maximum
          maxScale * 1.5, // Above maximum
          maxScale * 10.0, // Way above maximum
        ];
        
        for (final testScale in testScales) {
          zoomPanManager.setZoom(testScale);
          
          // Verify scale is constrained to min/max range
          expect(
            zoomPanManager.scale,
            greaterThanOrEqualTo(minScale),
            reason: 'Scale should not be less than minScale ($minScale) for input $testScale',
          );
          expect(
            zoomPanManager.scale,
            lessThanOrEqualTo(maxScale),
            reason: 'Scale should not be greater than maxScale ($maxScale) for input $testScale',
          );
          
          // Verify the actual constrained value
          final expectedScale = testScale.clamp(minScale, maxScale);
          expect(
            zoomPanManager.scale,
            expectedScale,
            reason: 'Scale should be clamped to $expectedScale for input $testScale',
          );
        }
        
        zoomPanManager.dispose();
      }
    });

    // Property 31 (Extended): Zoom constraints with pinch gesture
    test('Property 31: Zoom constraints with pinch gesture', () {
      for (int i = 0; i < iterations; i++) {
        final random = Random(i);
        
        final minScale = 0.1 + random.nextDouble() * 0.4; // 0.1 to 0.5
        final maxScale = 2.0 + random.nextDouble() * 3.0; // 2.0 to 5.0
        
        final zoomPanManager = ZoomPanManager(
          minScale: minScale,
          maxScale: maxScale,
        );
        
        // Generate random pinch scale factors
        final pinchScales = [
          0.1, // Pinch in a lot (zoom out)
          0.5, // Pinch in
          1.0, // No change
          2.0, // Pinch out
          5.0, // Pinch out a lot (zoom in)
          10.0, // Extreme pinch out
        ];
        
        for (final pinchScale in pinchScales) {
          // Reset to middle of range
          final midScale = (minScale + maxScale) / 2;
          zoomPanManager.setZoom(midScale);
          
          // Perform pinch gesture
          final startDetails = ScaleStartDetails(
            focalPoint: Offset(
              100.0 + random.nextDouble() * 200.0,
              100.0 + random.nextDouble() * 200.0,
            ),
          );
          
          zoomPanManager.handleScaleStart(startDetails);
          
          final updateDetails = ScaleUpdateDetails(
            focalPoint: startDetails.focalPoint,
            scale: pinchScale,
          );
          
          zoomPanManager.handleScaleUpdate(updateDetails);
          
          // Verify scale is constrained
          expect(
            zoomPanManager.scale,
            greaterThanOrEqualTo(minScale),
            reason: 'Pinch gesture should not result in scale below minScale',
          );
          expect(
            zoomPanManager.scale,
            lessThanOrEqualTo(maxScale),
            reason: 'Pinch gesture should not result in scale above maxScale',
          );
          
          zoomPanManager.handleScaleEnd(ScaleEndDetails());
        }
        
        zoomPanManager.dispose();
      }
    });


    // Property 31 (Extended): Zoom constraints with mouse wheel
    test('Property 31: Zoom constraints with mouse wheel', () {
      for (int i = 0; i < iterations; i++) {
        final random = Random(i);
        
        final minScale = 0.1 + random.nextDouble() * 0.4;
        final maxScale = 2.0 + random.nextDouble() * 3.0;
        
        final zoomPanManager = ZoomPanManager(
          minScale: minScale,
          maxScale: maxScale,
        );
        
        // Test zooming in until hitting max constraint
        zoomPanManager.setZoom((minScale + maxScale) / 2);
        
        for (int j = 0; j < 50; j++) {
          final event = PointerScrollEvent(
            scrollDelta: Offset(0, -100.0 - random.nextDouble() * 400.0), // Zoom in
          );
          
          zoomPanManager.handleMouseWheel(
            event,
            Offset(
              100.0 + random.nextDouble() * 200.0,
              100.0 + random.nextDouble() * 200.0,
            ),
          );
          
          // Should never exceed maxScale
          expect(
            zoomPanManager.scale,
            lessThanOrEqualTo(maxScale),
            reason: 'Mouse wheel zoom in should not exceed maxScale',
          );
        }
        
        // Test zooming out until hitting min constraint
        zoomPanManager.setZoom((minScale + maxScale) / 2);
        
        for (int j = 0; j < 50; j++) {
          final event = PointerScrollEvent(
            scrollDelta: Offset(0, 100.0 + random.nextDouble() * 400.0), // Zoom out
          );
          
          zoomPanManager.handleMouseWheel(
            event,
            Offset(
              100.0 + random.nextDouble() * 200.0,
              100.0 + random.nextDouble() * 200.0,
            ),
          );
          
          // Should never go below minScale
          expect(
            zoomPanManager.scale,
            greaterThanOrEqualTo(minScale),
            reason: 'Mouse wheel zoom out should not go below minScale',
          );
        }
        
        zoomPanManager.dispose();
      }
    });


    // For any supported gesture (drag, pinch, mouse wheel), the system should
    // correctly respond and execute the corresponding operation
    test('Property 30: Gesture response consistency - Pan gestures', () {
      // Feature: mind-map-flutter, Property 30: Gesture response consistency
      for (int i = 0; i < iterations; i++) {
        final random = Random(i);
        
        final zoomPanManager = ZoomPanManager(
          minScale: 0.1,
          maxScale: 5.0,
        );
        
        // Generate random pan deltas
        final panDeltas = List.generate(
          3 + random.nextInt(5), // 3-7 pan updates
          (index) => Offset(
            -200.0 + random.nextDouble() * 400.0, // -200 to 200
            -200.0 + random.nextDouble() * 400.0,
          ),
        );
        
        // Start pan gesture
        final startPosition = Offset(
          random.nextDouble() * 800.0,
          random.nextDouble() * 600.0,
        );
        
        zoomPanManager.handlePanStart(startPosition);
        
        // Track expected translation
        Offset expectedTranslation = Offset.zero;
        
        // Apply pan updates
        for (final delta in panDeltas) {
          zoomPanManager.handlePanUpdate(delta);
          expectedTranslation += delta;
          
          // Verify translation is updated correctly
          expect(
            zoomPanManager.translation.dx,
            closeTo(expectedTranslation.dx, 0.001),
            reason: 'Pan gesture should update translation X correctly',
          );
          expect(
            zoomPanManager.translation.dy,
            closeTo(expectedTranslation.dy, 0.001),
            reason: 'Pan gesture should update translation Y correctly',
          );
        }
        
        // End pan gesture
        zoomPanManager.handlePanEnd();
        
        // Translation should remain after pan end
        expect(
          zoomPanManager.translation.dx,
          closeTo(expectedTranslation.dx, 0.001),
          reason: 'Translation should persist after pan end',
        );
        
        zoomPanManager.dispose();
      }
    });


    test('Property 30: Gesture response consistency - Pinch zoom gestures', () {
      // Feature: mind-map-flutter, Property 30: Gesture response consistency
      for (int i = 0; i < iterations; i++) {
        final random = Random(i);
        
        final zoomPanManager = ZoomPanManager(
          minScale: 0.1,
          maxScale: 5.0,
        );
        
        // Generate random pinch gesture
        final focalPoint = Offset(
          100.0 + random.nextDouble() * 600.0,
          100.0 + random.nextDouble() * 400.0,
        );
        
        final initialScale = 0.5 + random.nextDouble() * 2.0; // 0.5 to 2.5
        zoomPanManager.setZoom(initialScale);
        
        final pinchScale = 0.5 + random.nextDouble() * 3.0; // 0.5 to 3.5
        
        // Start pinch gesture
        final startDetails = ScaleStartDetails(focalPoint: focalPoint);
        zoomPanManager.handleScaleStart(startDetails);
        
        // Update pinch gesture
        final updateDetails = ScaleUpdateDetails(
          focalPoint: focalPoint,
          scale: pinchScale,
        );
        zoomPanManager.handleScaleUpdate(updateDetails);
        
        // Verify scale is updated (within constraints)
        final expectedScale = (initialScale * pinchScale).clamp(0.1, 5.0);
        expect(
          zoomPanManager.scale,
          closeTo(expectedScale, 0.001),
          reason: 'Pinch gesture should update scale correctly',
        );
        
        // End pinch gesture
        zoomPanManager.handleScaleEnd(ScaleEndDetails());
        
        // Scale should remain after gesture end
        expect(
          zoomPanManager.scale,
          closeTo(expectedScale, 0.001),
          reason: 'Scale should persist after pinch end',
        );
        
        zoomPanManager.dispose();
      }
    });


    test('Property 30: Gesture response consistency - Mouse wheel zoom', () {
      // Feature: mind-map-flutter, Property 30: Gesture response consistency
      for (int i = 0; i < iterations; i++) {
        final random = Random(i);
        
        final zoomPanManager = ZoomPanManager(
          minScale: 0.1,
          maxScale: 5.0,
        );
        
        // Set initial scale
        final initialScale = 0.5 + random.nextDouble() * 2.0;
        zoomPanManager.setZoom(initialScale);
        
        final pointerPosition = Offset(
          100.0 + random.nextDouble() * 600.0,
          100.0 + random.nextDouble() * 400.0,
        );
        
        // Test zoom in (negative scroll delta)
        final zoomInEvent = PointerScrollEvent(
          scrollDelta: Offset(0, -100.0 - random.nextDouble() * 200.0),
        );
        
        final scaleBeforeZoomIn = zoomPanManager.scale;
        zoomPanManager.handleMouseWheel(zoomInEvent, pointerPosition);
        
        // Scale should increase (or stay at max)
        expect(
          zoomPanManager.scale,
          greaterThanOrEqualTo(scaleBeforeZoomIn),
          reason: 'Mouse wheel scroll up should zoom in (increase scale)',
        );
        
        // Test zoom out (positive scroll delta)
        final zoomOutEvent = PointerScrollEvent(
          scrollDelta: Offset(0, 100.0 + random.nextDouble() * 200.0),
        );
        
        final scaleBeforeZoomOut = zoomPanManager.scale;
        zoomPanManager.handleMouseWheel(zoomOutEvent, pointerPosition);
        
        // Scale should decrease (or stay at min)
        expect(
          zoomPanManager.scale,
          lessThanOrEqualTo(scaleBeforeZoomOut),
          reason: 'Mouse wheel scroll down should zoom out (decrease scale)',
        );
        
        zoomPanManager.dispose();
      }
    });


    // Additional property: Pan and zoom independence
    test('Property: Pan and zoom operations are independent', () {
      for (int i = 0; i < iterations; i++) {
        final random = Random(i);
        
        final zoomPanManager = ZoomPanManager(
          minScale: 0.1,
          maxScale: 5.0,
        );
        
        // Set initial state
        final initialScale = 0.5 + random.nextDouble() * 2.0;
        final initialTranslation = Offset(
          -100.0 + random.nextDouble() * 200.0,
          -100.0 + random.nextDouble() * 200.0,
        );
        
        zoomPanManager.setZoom(initialScale);
        zoomPanManager.setTranslation(initialTranslation);
        
        // Pan should not affect scale
        final panDelta = Offset(
          -50.0 + random.nextDouble() * 100.0,
          -50.0 + random.nextDouble() * 100.0,
        );
        
        zoomPanManager.handlePanStart(Offset.zero);
        zoomPanManager.handlePanUpdate(panDelta);
        
        expect(
          zoomPanManager.scale,
          closeTo(initialScale, 0.001),
          reason: 'Pan operation should not change scale',
        );
        
        zoomPanManager.handlePanEnd();
        
        // Zoom should not affect translation (when no focal point)
        final newScale = 0.5 + random.nextDouble() * 2.0;
        final translationBeforeZoom = zoomPanManager.translation;
        
        zoomPanManager.setZoom(newScale);
        
        expect(
          zoomPanManager.translation,
          translationBeforeZoom,
          reason: 'Zoom without focal point should not change translation',
        );
        
        zoomPanManager.dispose();
      }
    });


    // Additional property: Transform matrix consistency
    test('Property: Transform matrix reflects scale and translation', () {
      for (int i = 0; i < iterations; i++) {
        final random = Random(i);
        
        final zoomPanManager = ZoomPanManager(
          minScale: 0.1,
          maxScale: 5.0,
        );
        
        // Generate random scale and translation
        final scale = 0.2 + random.nextDouble() * 4.5; // 0.2 to 4.7
        final translation = Offset(
          -200.0 + random.nextDouble() * 400.0,
          -200.0 + random.nextDouble() * 400.0,
        );
        
        zoomPanManager.setZoom(scale);
        zoomPanManager.setTranslation(translation);
        
        // Test transform matrix with random points
        for (int j = 0; j < 5; j++) {
          final testPoint = Offset(
            random.nextDouble() * 500.0,
            random.nextDouble() * 500.0,
          );
          
          final transformedPoint = MatrixUtils.transformPoint(
            zoomPanManager.transform,
            testPoint,
          );
          
          // Expected transformation: translate then scale
          // Matrix4 applies: scale first, then translate
          // So: (point * scale) + translation
          final expectedPoint = Offset(
            testPoint.dx * scale + translation.dx,
            testPoint.dy * scale + translation.dy,
          );
          
          expect(
            transformedPoint.dx,
            closeTo(expectedPoint.dx, 0.001),
            reason: 'Transform matrix should correctly transform X coordinate',
          );
          expect(
            transformedPoint.dy,
            closeTo(expectedPoint.dy, 0.001),
            reason: 'Transform matrix should correctly transform Y coordinate',
          );
        }
        
        zoomPanManager.dispose();
      }
    });


    // Additional property: Zoom around focal point adjusts translation
    test('Property: Zoom with focal point adjusts translation appropriately', () {
      for (int i = 0; i < iterations; i++) {
        final random = Random(i);
        
        final zoomPanManager = ZoomPanManager(
          minScale: 0.1,
          maxScale: 5.0,
        );
        
        // Set initial state
        final initialScale = 0.5 + random.nextDouble() * 2.0;
        final initialTranslation = Offset(
          -100.0 + random.nextDouble() * 200.0,
          -100.0 + random.nextDouble() * 200.0,
        );
        
        zoomPanManager.setZoom(initialScale);
        zoomPanManager.setTranslation(initialTranslation);
        
        // Choose a focal point in screen coordinates
        final focalPoint = Offset(
          100.0 + random.nextDouble() * 600.0,
          100.0 + random.nextDouble() * 400.0,
        );
        
        // Zoom around focal point
        final newScale = 0.2 + random.nextDouble() * 4.5;
        final constrainedNewScale = newScale.clamp(0.1, 5.0);
        
        // Skip if scale doesn't actually change
        if ((constrainedNewScale - initialScale).abs() < 0.001) {
          zoomPanManager.dispose();
          continue;
        }
        
        zoomPanManager.setZoom(newScale, focalPoint: focalPoint);
        
        // When zooming with a focal point, translation should be adjusted
        // (unless we're at the exact same scale, which we've already filtered out)
        expect(
          zoomPanManager.translation,
          isNot(initialTranslation),
          reason: 'Zoom with focal point should adjust translation',
        );
        
        // Scale should be updated (within constraints)
        expect(
          zoomPanManager.scale,
          closeTo(constrainedNewScale, 0.001),
          reason: 'Scale should be updated to new value (within constraints)',
        );
        
        zoomPanManager.dispose();
      }
    });


    // Additional property: Center on point calculation
    test('Property: Center on point positions point at viewport center', () {
      for (int i = 0; i < iterations; i++) {
        final random = Random(i);
        
        final zoomPanManager = ZoomPanManager(
          minScale: 0.1,
          maxScale: 5.0,
        );
        
        // Set random scale
        final scale = 0.2 + random.nextDouble() * 4.5;
        zoomPanManager.setZoom(scale);
        
        // Generate random canvas point and viewport size
        final canvasPoint = Offset(
          -500.0 + random.nextDouble() * 1000.0,
          -500.0 + random.nextDouble() * 1000.0,
        );
        
        final viewportSize = Size(
          400.0 + random.nextDouble() * 800.0, // 400 to 1200
          300.0 + random.nextDouble() * 600.0, // 300 to 900
        );
        
        // Center on the canvas point
        zoomPanManager.centerOn(canvasPoint, viewportSize);
        
        // Calculate where the canvas point appears in screen coordinates
        final screenPoint = Offset(
          canvasPoint.dx * scale + zoomPanManager.translation.dx,
          canvasPoint.dy * scale + zoomPanManager.translation.dy,
        );
        
        // Should be at the center of the viewport
        final viewportCenter = Offset(
          viewportSize.width / 2,
          viewportSize.height / 2,
        );
        
        expect(
          screenPoint.dx,
          closeTo(viewportCenter.dx, 0.1),
          reason: 'Canvas point should be at viewport center X',
        );
        expect(
          screenPoint.dy,
          closeTo(viewportCenter.dy, 0.1),
          reason: 'Canvas point should be at viewport center Y',
        );
        
        zoomPanManager.dispose();
      }
    });


    // Additional property: Reset restores initial state
    test('Property: Reset restores default scale and translation', () {
      for (int i = 0; i < iterations; i++) {
        final random = Random(i);
        
        final zoomPanManager = ZoomPanManager(
          minScale: 0.1,
          maxScale: 5.0,
        );
        
        // Modify state randomly
        final scale = 0.2 + random.nextDouble() * 4.5;
        final translation = Offset(
          -200.0 + random.nextDouble() * 400.0,
          -200.0 + random.nextDouble() * 400.0,
        );
        
        zoomPanManager.setZoom(scale);
        zoomPanManager.setTranslation(translation);
        
        // Verify state is modified
        expect(zoomPanManager.scale, isNot(1.0));
        expect(zoomPanManager.translation, isNot(Offset.zero));
        
        // Reset
        zoomPanManager.reset();
        
        // Verify state is restored to defaults
        expect(
          zoomPanManager.scale,
          1.0,
          reason: 'Reset should restore scale to 1.0',
        );
        expect(
          zoomPanManager.translation,
          Offset.zero,
          reason: 'Reset should restore translation to zero',
        );
        
        zoomPanManager.dispose();
      }
    });

    // Additional property: Listener notification consistency
    test('Property: Listeners are notified on state changes', () {
      for (int i = 0; i < iterations; i++) {
        final random = Random(i);
        
        final zoomPanManager = ZoomPanManager(
          minScale: 0.1,
          maxScale: 5.0,
        );
        
        int notificationCount = 0;
        zoomPanManager.addListener(() {
          notificationCount++;
        });
        
        // Test various operations that should notify listeners
        final operations = [
          () => zoomPanManager.setZoom(0.5 + random.nextDouble() * 2.0),
          () => zoomPanManager.setTranslation(Offset(
            random.nextDouble() * 100.0,
            random.nextDouble() * 100.0,
          )),
          () {
            zoomPanManager.handlePanStart(Offset.zero);
            zoomPanManager.handlePanUpdate(Offset(10.0, 10.0));
          },
          () => zoomPanManager.reset(),
        ];
        
        for (final operation in operations) {
          final countBefore = notificationCount;
          operation();
          
          expect(
            notificationCount,
            greaterThan(countBefore),
            reason: 'Operation should notify listeners',
          );
        }
        
        zoomPanManager.dispose();
      }
    });
  });
}
