import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/utils/arrow_utils.dart';
import 'package:mind_map_flutter/src/layout/node_layout.dart';

void main() {
  group('ArrowUtils', () {
    group('calculateDefaultDeltas', () {
      test('should calculate horizontal deltas for horizontally aligned nodes', () {
        // Arrange: Two nodes aligned horizontally
        final fromLayout = NodeLayout(
          position: const Offset(0, 100),
          size: const Size(100, 50),
        );
        final toLayout = NodeLayout(
          position: const Offset(300, 100),
          size: const Size(100, 50),
        );
        
        // Act
        final (delta1, delta2) = ArrowUtils.calculateDefaultDeltas(fromLayout, toLayout);
        
        // Assert: Deltas should be primarily horizontal
        expect(delta1.dx.abs() > delta1.dy.abs(), true, 
            reason: 'Delta1 should be primarily horizontal');
        expect(delta2.dx.abs() > delta2.dy.abs(), true,
            reason: 'Delta2 should be primarily horizontal');
        
        // Deltas should point in opposite directions for smooth curve
        expect(delta1.dx > 0, true, reason: 'Delta1 should point right');
        expect(delta2.dx < 0, true, reason: 'Delta2 should point left');
      });
      
      test('should calculate vertical deltas for vertically aligned nodes', () {
        // Arrange: Two nodes aligned vertically
        final fromLayout = NodeLayout(
          position: const Offset(100, 0),
          size: const Size(100, 50),
        );
        final toLayout = NodeLayout(
          position: const Offset(100, 300),
          size: const Size(100, 50),
        );
        
        // Act
        final (delta1, delta2) = ArrowUtils.calculateDefaultDeltas(fromLayout, toLayout);
        
        // Assert: Deltas should be primarily vertical
        expect(delta1.dy.abs() > delta1.dx.abs(), true,
            reason: 'Delta1 should be primarily vertical');
        expect(delta2.dy.abs() > delta2.dx.abs(), true,
            reason: 'Delta2 should be primarily vertical');
        
        // Deltas should point in opposite directions for smooth curve
        expect(delta1.dy > 0, true, reason: 'Delta1 should point down');
        expect(delta2.dy < 0, true, reason: 'Delta2 should point up');
      });
      
      test('should use C-curve for close nodes', () {
        // Arrange: Two nodes very close together
        final fromLayout = NodeLayout(
          position: const Offset(0, 100),
          size: const Size(100, 50),
        );
        final toLayout = NodeLayout(
          position: const Offset(120, 100),
          size: const Size(100, 50),
        );
        
        // Act
        final (delta1, delta2) = ArrowUtils.calculateDefaultDeltas(fromLayout, toLayout);
        
        // Assert: Should use C-curve (both deltas point in same direction)
        expect(delta1.dx * delta2.dx > 0, true,
            reason: 'Both deltas should point in the same direction for C-curve');
        
        // C-curve should have large horizontal offset
        expect(delta1.dx.abs() > 100, true,
            reason: 'C-curve should have large offset');
      });
      
      test('should calculate diagonal deltas for diagonally positioned nodes', () {
        // Arrange: Two nodes positioned diagonally
        final fromLayout = NodeLayout(
          position: const Offset(0, 0),
          size: const Size(100, 50),
        );
        final toLayout = NodeLayout(
          position: const Offset(300, 300),
          size: const Size(100, 50),
        );
        
        // Act
        final (delta1, delta2) = ArrowUtils.calculateDefaultDeltas(fromLayout, toLayout);
        
        // Assert: Both deltas should have significant x and y components
        expect(delta1.dx.abs() > 10, true,
            reason: 'Delta1 should have horizontal component');
        expect(delta1.dy.abs() > 10, true,
            reason: 'Delta1 should have vertical component');
        expect(delta2.dx.abs() > 10, true,
            reason: 'Delta2 should have horizontal component');
        expect(delta2.dy.abs() > 10, true,
            reason: 'Delta2 should have vertical component');
      });
      
      test('should scale deltas based on distance', () {
        // Arrange: Two pairs of nodes at different distances
        final fromLayout1 = NodeLayout(
          position: const Offset(0, 100),
          size: const Size(100, 50),
        );
        final toLayout1 = NodeLayout(
          position: const Offset(200, 100),
          size: const Size(100, 50),
        );
        
        final fromLayout2 = NodeLayout(
          position: const Offset(0, 100),
          size: const Size(100, 50),
        );
        final toLayout2 = NodeLayout(
          position: const Offset(600, 100),
          size: const Size(100, 50),
        );
        
        // Act
        final (delta1a, delta2a) = ArrowUtils.calculateDefaultDeltas(fromLayout1, toLayout1);
        final (delta1b, delta2b) = ArrowUtils.calculateDefaultDeltas(fromLayout2, toLayout2);
        
        // Assert: Longer distance should have larger deltas (but capped at max)
        final distance1 = delta1a.distance;
        final distance2 = delta1b.distance;
        
        expect(distance2 >= distance1, true,
            reason: 'Longer node distance should result in larger or equal delta distance');
      });
    });
    
    group('calculateBezierPoint', () {
      test('should return start point at t=0', () {
        final p0 = const Offset(0, 0);
        final p1 = const Offset(100, 0);
        final p2 = const Offset(100, 100);
        final p3 = const Offset(200, 100);
        
        final result = ArrowUtils.calculateBezierPoint(p0, p1, p2, p3, 0.0);
        
        expect(result, p0);
      });
      
      test('should return end point at t=1', () {
        final p0 = const Offset(0, 0);
        final p1 = const Offset(100, 0);
        final p2 = const Offset(100, 100);
        final p3 = const Offset(200, 100);
        
        final result = ArrowUtils.calculateBezierPoint(p0, p1, p2, p3, 1.0);
        
        expect(result, p3);
      });
      
      test('should return midpoint at t=0.5', () {
        final p0 = const Offset(0, 0);
        final p1 = const Offset(100, 0);
        final p2 = const Offset(100, 100);
        final p3 = const Offset(200, 100);
        
        final result = ArrowUtils.calculateBezierPoint(p0, p1, p2, p3, 0.5);
        
        // Midpoint should be somewhere between start and end
        expect(result.dx > p0.dx && result.dx < p3.dx, true);
        expect(result.dy >= p0.dy && result.dy <= p3.dy, true);
      });
    });
    
    group('calculateBezierMidpoint', () {
      test('should calculate the midpoint of a bezier curve', () {
        final p0 = const Offset(0, 0);
        final p1 = const Offset(100, 0);
        final p2 = const Offset(100, 100);
        final p3 = const Offset(200, 100);
        
        final midpoint = ArrowUtils.calculateBezierMidpoint(p0, p1, p2, p3);
        
        // Midpoint should be between start and end
        expect(midpoint.dx > p0.dx && midpoint.dx < p3.dx, true);
        expect(midpoint.dy >= p0.dy && midpoint.dy <= p3.dy, true);
      });
    });
    
    group('isPointNearBezierCurve', () {
      test('should return true for point on the curve', () {
        final start = const Offset(0, 0);
        final control1 = const Offset(100, 0);
        final control2 = const Offset(100, 100);
        final end = const Offset(200, 100);
        
        // Calculate a point on the curve
        final pointOnCurve = ArrowUtils.calculateBezierPoint(
          start, control1, control2, end, 0.5,
        );
        
        final result = ArrowUtils.isPointNearBezierCurve(
          pointOnCurve,
          start,
          control1,
          control2,
          end,
          threshold: 5.0,
        );
        
        expect(result, true);
      });
      
      test('should return false for point far from the curve', () {
        final start = const Offset(0, 0);
        final control1 = const Offset(100, 0);
        final control2 = const Offset(100, 100);
        final end = const Offset(200, 100);
        
        // Point far from the curve
        final farPoint = const Offset(1000, 1000);
        
        final result = ArrowUtils.isPointNearBezierCurve(
          farPoint,
          start,
          control1,
          control2,
          end,
          threshold: 10.0,
        );
        
        expect(result, false);
      });
      
      test('should respect threshold parameter', () {
        final start = const Offset(0, 0);
        final control1 = const Offset(100, 0);
        final control2 = const Offset(100, 100);
        final end = const Offset(200, 100);
        
        // Point slightly off the curve
        final nearPoint = ArrowUtils.calculateBezierPoint(
          start, control1, control2, end, 0.5,
        ) + const Offset(8, 0);
        
        // Should be false with small threshold
        expect(
          ArrowUtils.isPointNearBezierCurve(
            nearPoint, start, control1, control2, end,
            threshold: 5.0,
          ),
          false,
        );
        
        // Should be true with larger threshold
        expect(
          ArrowUtils.isPointNearBezierCurve(
            nearPoint, start, control1, control2, end,
            threshold: 15.0,
          ),
          true,
        );
      });
    });
  });
}
