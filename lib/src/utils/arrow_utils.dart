import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../layout/node_layout.dart';

/// Utility functions for arrow calculations
/// 
/// This class provides intelligent control point calculation for arrows,
/// similar to mind-elixir-core's implementation.
class ArrowUtils {
  /// Calculate default delta values for arrow control points based on node positions
  /// 
  /// This algorithm intelligently determines the best control points for a bezier curve
  /// connecting two nodes, considering:
  /// - Distance between nodes
  /// - Relative positions (horizontal, vertical, diagonal)
  /// - Node sizes
  /// - Visual aesthetics
  /// 
  /// Returns a tuple of (delta1, delta2) where:
  /// - delta1: offset from source node center to first control point
  /// - delta2: offset from target node center to second control point
  /// 
  static (Offset, Offset) calculateDefaultDeltas(
    NodeLayout fromLayout,
    NodeLayout toLayout,
  ) {
    // Calculate center positions of both nodes
    final fromCenter = fromLayout.bounds.center;
    final toCenter = toLayout.bounds.center;
    
    // Calculate the vector between nodes
    final dx = toCenter.dx - fromCenter.dx;
    final dy = toCenter.dy - fromCenter.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    
    // Calculate recommended offset based on distance and direction
    // Use 30% of the distance as base offset, with min 50 and max 200
    final baseOffset = math.max(50.0, math.min(200.0, distance * 0.3));
    
    // Determine the primary direction and calculate deltas accordingly
    final absDx = dx.abs();
    final absDy = dy.abs();
    
    Offset delta1;
    Offset delta2;
    
    // Use C-type curve when nodes are close together to avoid overlapping
    final isCloseDistance = distance < 150;
    
    if (isCloseDistance) {
      // For close nodes, use a C-shaped curve that goes outward
      // Determine which side to curve based on relative position
      final xMul = dx >= 0 ? 1.0 : -1.0;
      delta1 = Offset(200.0 * xMul, 0.0);
      delta2 = Offset(200.0 * xMul, 0.0);
    } else if (absDx > absDy * 1.5) {
      // Primarily horizontal arrangement
      // Calculate offset from the edge of the node, not the center
      final fromEdgeOffsetX = dx > 0 
          ? fromLayout.bounds.width / 2
          : -fromLayout.bounds.width / 2;
      final toEdgeOffsetX = dx > 0 
          ? -toLayout.bounds.width / 2
          : toLayout.bounds.width / 2;
      
      delta1 = Offset(
        fromEdgeOffsetX + (dx > 0 ? baseOffset : -baseOffset),
        0.0,
      );
      delta2 = Offset(
        toEdgeOffsetX + (dx > 0 ? -baseOffset : baseOffset),
        0.0,
      );
    } else if (absDy > absDx * 1.5) {
      // Primarily vertical arrangement
      // Calculate offset from the edge of the node, not the center
      final fromEdgeOffsetY = dy > 0 
          ? fromLayout.bounds.height / 2 
          : -fromLayout.bounds.height / 2;
      final toEdgeOffsetY = dy > 0 
          ? -toLayout.bounds.height / 2 
          : toLayout.bounds.height / 2;
      
      // Use straight vertical line for longer distances
      delta1 = Offset(
        0.0,
        fromEdgeOffsetY + (dy > 0 ? baseOffset : -baseOffset),
      );
      delta2 = Offset(
        0.0,
        toEdgeOffsetY + (dy > 0 ? -baseOffset : baseOffset),
      );
    } else {
      // Diagonal arrangement
      // Calculate offset from the edge of the node, not the center
      final angle = math.atan2(dy, dx);
      
      // Calculate which edge point the arrow exits/enters from
      final fromEdgeOffsetX = (fromLayout.bounds.width / 2) * math.cos(angle);
      final fromEdgeOffsetY = (fromLayout.bounds.height / 2) * math.sin(angle);
      final toEdgeOffsetX = -(toLayout.bounds.width / 2) * math.cos(angle);
      final toEdgeOffsetY = -(toLayout.bounds.height / 2) * math.sin(angle);
      
      // Add the control point offset from the edge
      final offsetX = baseOffset * 0.7 * (dx > 0 ? 1 : -1);
      final offsetY = baseOffset * 0.7 * (dy > 0 ? 1 : -1);
      
      delta1 = Offset(
        fromEdgeOffsetX + offsetX,
        fromEdgeOffsetY + offsetY,
      );
      delta2 = Offset(
        toEdgeOffsetX - offsetX,
        toEdgeOffsetY - offsetY,
      );
    }
    
    return (delta1, delta2);
  }
  
  /// Calculate a point on a cubic bezier curve at parameter t (0 to 1)
  static Offset calculateBezierPoint(
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
  
  /// Calculate the midpoint of a bezier curve
  static Offset calculateBezierMidpoint(
    Offset p0,
    Offset p1,
    Offset p2,
    Offset p3,
  ) {
    return calculateBezierPoint(p0, p1, p2, p3, 0.5);
  }
  
  /// Check if a point is near a bezier curve (for hit testing)
  /// 
  /// [point] - The point to test
  /// [start] - Start point of the curve
  /// [control1] - First control point
  /// [control2] - Second control point
  /// [end] - End point of the curve
  /// [threshold] - Maximum distance in pixels to consider a "hit"
  /// [samples] - Number of points to sample along the curve
  static bool isPointNearBezierCurve(
    Offset point,
    Offset start,
    Offset control1,
    Offset control2,
    Offset end, {
    double threshold = 10.0,
    int samples = 20,
  }) {
    for (int i = 0; i <= samples; i++) {
      final t = i / samples;
      final curvePoint = calculateBezierPoint(start, control1, control2, end, t);
      final distance = (curvePoint - point).distance;
      
      if (distance < threshold) {
        return true;
      }
    }
    
    return false;
  }
}
