import 'package:flutter/material.dart';
import '../models/arrow_data.dart';
import '../models/mind_map_theme.dart';
import '../layout/node_layout.dart';
import '../utils/arrow_utils.dart';
import 'dart:math' as math;

/// Renderer for custom arrows between nodes
class ArrowRenderer {
  /// Size of the arrowhead
  static const double arrowheadSize = 10.0;
  static const List<double> _defaultDashPattern = <double>[6.0, 4.0];
  static const double _selectedHighlightStrokeWidth = 6.0;
  static const double _selectedHighlightOpacity = 0.45;
  static const double _labelFontSize = 12.0;
  static const FontWeight _labelFontWeight = FontWeight.w500;
  static const EdgeInsets _labelPadding = EdgeInsets.symmetric(
    horizontal: 6.0,
    vertical: 3.0,
  );
  static const double _labelMinTextWidth = 24.0;

  /// Draw an arrow between two nodes
  static void drawArrow(
    Canvas canvas,
    ArrowData arrow,
    Map<String, NodeLayout> nodeLayouts,
    MindMapTheme theme,
  ) {
    final geometry = _computeArrowGeometry(arrow, nodeLayouts);
    if (geometry == null) return;

    // Get arrow style
    final style = arrow.style;
    final strokeColor = style?.strokeColor ?? theme.variables.accentColor;
    final strokeWidth = style?.strokeWidth ?? 2.0;
    final opacity = style?.opacity ?? 1.0;
    final dashPattern = style?.dashPattern ?? _defaultDashPattern;

    // Create paint for the arrow
    final paint = Paint()
      ..color = strokeColor.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw the bezier curve
    _drawBezierCurve(
      canvas,
      geometry.startPoint,
      geometry.controlPoint1,
      geometry.controlPoint2,
      geometry.endPoint,
      paint,
      dashPattern,
    );

    // Draw arrowhead at the end
    _drawArrowhead(canvas, geometry.controlPoint2, geometry.endPoint, paint);

    // Draw arrowhead at the start if bidirectional
    if (arrow.bidirectional) {
      _drawArrowhead(
        canvas,
        geometry.controlPoint1,
        geometry.startPoint,
        paint,
      );
    }

    // Draw label if present
    if (arrow.label != null && arrow.label!.isNotEmpty) {
      _drawArrowLabel(
        canvas,
        arrow.label!,
        geometry.startPoint,
        geometry.controlPoint1,
        geometry.controlPoint2,
        geometry.endPoint,
        theme,
      );
    }
  }

  /// Draw selected-state highlight, mirroring mind-elixir-core:
  /// a semi-transparent thick stroke behind the selected arrow.
  static void drawSelectedArrowHighlight(
    Canvas canvas,
    ArrowData arrow,
    Map<String, NodeLayout> nodeLayouts,
    MindMapTheme theme,
  ) {
    final geometry = _computeArrowGeometry(arrow, nodeLayouts);
    if (geometry == null) return;

    final highlightPaint = Paint()
      ..color = theme.variables.selectedColor.withValues(alpha: 
        _selectedHighlightOpacity,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = _selectedHighlightStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _drawBezierCurve(
      canvas,
      geometry.startPoint,
      geometry.controlPoint1,
      geometry.controlPoint2,
      geometry.endPoint,
      highlightPaint,
      null,
    );
    _drawArrowhead(
      canvas,
      geometry.controlPoint2,
      geometry.endPoint,
      highlightPaint,
    );
    if (arrow.bidirectional) {
      _drawArrowhead(
        canvas,
        geometry.controlPoint1,
        geometry.startPoint,
        highlightPaint,
      );
    }
  }

  static (Offset, Offset) _resolveArrowDeltas(
    ArrowData arrow,
    NodeLayout fromLayout,
    NodeLayout toLayout,
  ) {
    // mind-elixir-core computes control deltas on draw when missing.
    // ArrowData uses non-null fields, so use Offset.zero as the "missing" marker.
    if (arrow.delta1 == Offset.zero && arrow.delta2 == Offset.zero) {
      return ArrowUtils.calculateDefaultDeltas(fromLayout, toLayout);
    }
    return (arrow.delta1, arrow.delta2);
  }

  /// Draw a bezier curve with optional dash pattern
  static void _drawBezierCurve(
    Canvas canvas,
    Offset start,
    Offset control1,
    Offset control2,
    Offset end,
    Paint paint,
    List<double>? dashPattern,
  ) {
    // Create path with cubic bezier curve
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        end.dx,
        end.dy,
      );

    // Draw the path with or without dashes
    if (dashPattern != null && dashPattern.isNotEmpty) {
      _drawDashedPath(canvas, path, paint, dashPattern);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  /// Draw a dashed path
  static void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    List<double> dashPattern,
  ) {
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      bool draw = true;
      int patternIndex = 0;

      while (distance < metric.length) {
        final length = dashPattern[patternIndex % dashPattern.length];

        if (draw) {
          final extractPath = metric.extractPath(
            distance,
            distance + length > metric.length
                ? metric.length
                : distance + length,
          );
          canvas.drawPath(extractPath, paint);
        }

        distance += length;
        draw = !draw;
        patternIndex++;
      }
    }
  }

  /// Draw an arrowhead at the end of the arrow
  static void _drawArrowhead(
    Canvas canvas,
    Offset controlPoint,
    Offset endPoint,
    Paint paint,
  ) {
    final wingPoints = _calculateArrowWingPoints(controlPoint, endPoint);
    if (wingPoints == null) return;

    // Match mind-elixir-core: render an open "V" arrowhead using strokes.
    final arrowPath = Path()
      ..moveTo(wingPoints.$1.dx, wingPoints.$1.dy)
      ..lineTo(endPoint.dx, endPoint.dy)
      ..lineTo(wingPoints.$2.dx, wingPoints.$2.dy);

    final arrowPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = paint.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(arrowPath, arrowPaint);
  }

  static (Offset, Offset)? _calculateArrowWingPoints(
    Offset controlPoint,
    Offset endPoint,
  ) {
    final deltaX = endPoint.dx - controlPoint.dx;
    final deltaY = endPoint.dy - controlPoint.dy;

    if (deltaX.abs() < 1e-6 && deltaY.abs() < 1e-6) {
      return null;
    }

    final angleRad = math.atan2(deltaY, deltaX);
    const wingAngle = math.pi / 6; // 30deg
    const wingLength = arrowheadSize * 1.2;

    final wing1 = Offset(
      endPoint.dx + math.cos(angleRad + math.pi - wingAngle) * wingLength,
      endPoint.dy + math.sin(angleRad + math.pi - wingAngle) * wingLength,
    );
    final wing2 = Offset(
      endPoint.dx + math.cos(angleRad + math.pi + wingAngle) * wingLength,
      endPoint.dy + math.sin(angleRad + math.pi + wingAngle) * wingLength,
    );

    return (wing1, wing2);
  }

  /// Calculate where a ray from node center toward control point
  /// intersects the node rectangle boundary.
  /// Mirrors mind-elixir-core `calcP` behavior for rectangular topics.
  static Offset _calculateEdgePoint(Rect bounds, Offset controlPoint) {
    final w = bounds.width;
    final h = bounds.height;
    final cx = bounds.center.dx;
    final cy = bounds.center.dy;
    final ctrlX = controlPoint.dx;
    final ctrlY = controlPoint.dy;

    final dx = ctrlX - cx;
    final dy = cy - ctrlY;

    // Vertical direction: avoid division by zero.
    if (dx.abs() < 1e-6) {
      return Offset(cx, ctrlY < cy ? cy + h / 2 : cy - h / 2);
    }

    final k = dy / dx;
    final slopeLimit = h / w;

    if (k > slopeLimit || k < -slopeLimit) {
      if (dy < 0) {
        return Offset(cx - h / 2 / k, cy + h / 2);
      }
      return Offset(cx + h / 2 / k, cy - h / 2);
    }

    if (cx - ctrlX < 0) {
      return Offset(cx + w / 2, cy - (w * k) / 2);
    }
    return Offset(cx - w / 2, cy + (w * k) / 2);
  }

  /// Draw the arrow label at the midpoint of the curve
  static void _drawArrowLabel(
    Canvas canvas,
    String label,
    Offset start,
    Offset control1,
    Offset control2,
    Offset end,
    MindMapTheme theme,
  ) {
    final textStyle = _createLabelTextStyle(theme);
    final textPainter = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();

    final labelBounds = _calculateArrowLabelBounds(
      start: start,
      control1: control1,
      control2: control2,
      end: end,
      textWidth: textPainter.width,
      textHeight: textPainter.height,
      minTextWidth: 0.0,
    );

    final backgroundPaint = Paint()
      ..color = theme.variables.bgColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = theme.variables.mainColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final labelRRect = RRect.fromRectAndRadius(
      labelBounds,
      Radius.circular(4.0),
    );

    canvas.drawRRect(labelRRect, backgroundPaint);
    canvas.drawRRect(labelRRect, borderPaint);

    // Draw text
    final textOffset = Offset(
      labelBounds.center.dx - textPainter.width / 2,
      labelBounds.center.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  /// Get arrow label bounds for hit testing/edit overlay alignment.
  ///
  /// Returns bounds even when label is empty so editing can start on double tap.
  static Rect? getArrowLabelBounds(
    ArrowData arrow,
    Map<String, NodeLayout> nodeLayouts,
    MindMapTheme theme, {
    String? overrideLabel,
  }) {
    final geometry = _computeArrowGeometry(arrow, nodeLayouts);
    if (geometry == null) return null;

    final label = overrideLabel ?? arrow.label ?? '';
    final measureText = label.isEmpty ? ' ' : label;
    final textPainter = TextPainter(
      text: TextSpan(text: measureText, style: _createLabelTextStyle(theme)),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();

    return _calculateArrowLabelBounds(
      start: geometry.startPoint,
      control1: geometry.controlPoint1,
      control2: geometry.controlPoint2,
      end: geometry.endPoint,
      textWidth: textPainter.width,
      textHeight: textPainter.height,
      minTextWidth: label.isEmpty ? _labelMinTextWidth : 0.0,
    );
  }

  static TextStyle _createLabelTextStyle(MindMapTheme theme) {
    return TextStyle(
      color: theme.variables.mainColor,
      fontSize: _labelFontSize,
      fontWeight: _labelFontWeight,
      backgroundColor: theme.variables.bgColor.withValues(alpha: 0.9),
    );
  }

  static Rect _calculateArrowLabelBounds({
    required Offset start,
    required Offset control1,
    required Offset control2,
    required Offset end,
    required double textWidth,
    required double textHeight,
    required double minTextWidth,
  }) {
    final midPoint = _calculateBezierPoint(start, control1, control2, end, 0.5);
    final width = math.max(textWidth, minTextWidth) + _labelPadding.horizontal;
    final height = textHeight + _labelPadding.vertical;
    return Rect.fromCenter(
      center: midPoint,
      width: width,
      height: height,
    );
  }

  /// Calculate a point on a cubic bezier curve at parameter t (0 to 1)
  static Offset _calculateBezierPoint(
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

  /// Draw all arrows in the mind map
  static void drawAllArrows(
    Canvas canvas,
    List<ArrowData> arrows,
    Map<String, NodeLayout> nodeLayouts,
    MindMapTheme theme, [
    String? selectedArrowId,
  ]
  ) {
    ArrowData? selectedArrow;
    for (final arrow in arrows) {
      if (selectedArrowId != null && arrow.id == selectedArrowId) {
        selectedArrow = arrow;
        continue;
      }
      drawArrow(canvas, arrow, nodeLayouts, theme);
    }

    // Draw selected arrow last with highlight to match mind-elixir-core UX.
    if (selectedArrow != null) {
      drawSelectedArrowHighlight(canvas, selectedArrow, nodeLayouts, theme);
      drawArrow(canvas, selectedArrow, nodeLayouts, theme);
    }
  }

  /// Draw control points for an arrow (used when arrow is selected)
  static void drawControlPoints(
    Canvas canvas,
    ArrowData arrow,
    Map<String, NodeLayout> nodeLayouts,
    MindMapTheme theme,
  ) {
    // Get source and target node layouts
    final fromLayout = nodeLayouts[arrow.fromNodeId];
    final toLayout = nodeLayouts[arrow.toNodeId];

    if (fromLayout == null || toLayout == null) return;

    final (effectiveDelta1, effectiveDelta2) = _resolveArrowDeltas(
      arrow,
      fromLayout,
      toLayout,
    );

    // Calculate control points
    final startPoint = fromLayout.bounds.center;
    final endPoint = toLayout.bounds.center;
    final controlPoint1 = startPoint + effectiveDelta1;
    final controlPoint2 = endPoint + effectiveDelta2;
    final startEdgePoint = _calculateEdgePoint(fromLayout.bounds, controlPoint1);
    final endEdgePoint = _calculateEdgePoint(toLayout.bounds, controlPoint2);

    // Draw control point handles
    final handlePaint = Paint()
      ..color = theme.variables.accentColor
      ..style = PaintingStyle.fill;

    final handleBorderPaint = Paint()
      ..color = theme.variables.mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const handleRadius = 6.0;

    // Draw control point 1
    canvas.drawCircle(controlPoint1, handleRadius, handlePaint);
    canvas.drawCircle(controlPoint1, handleRadius, handleBorderPaint);

    // Draw control point 2
    canvas.drawCircle(controlPoint2, handleRadius, handlePaint);
    canvas.drawCircle(controlPoint2, handleRadius, handleBorderPaint);

    // Draw helper lines from node edge to control points.
    // This keeps the part inside node bounds hidden for a cleaner look.
    final linePaint = Paint()
      ..color = theme.variables.mainColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(startEdgePoint, controlPoint1, linePaint);
    canvas.drawLine(endEdgePoint, controlPoint2, linePaint);
  }

  static _ArrowGeometry? _computeArrowGeometry(
    ArrowData arrow,
    Map<String, NodeLayout> nodeLayouts,
  ) {
    final fromLayout = nodeLayouts[arrow.fromNodeId];
    final toLayout = nodeLayouts[arrow.toNodeId];
    if (fromLayout == null || toLayout == null) return null;

    final (effectiveDelta1, effectiveDelta2) = _resolveArrowDeltas(
      arrow,
      fromLayout,
      toLayout,
    );
    final fromCenter = fromLayout.bounds.center;
    final toCenter = toLayout.bounds.center;
    final controlPoint1 = fromCenter + effectiveDelta1;
    final controlPoint2 = toCenter + effectiveDelta2;
    final startPoint = _calculateEdgePoint(fromLayout.bounds, controlPoint1);
    final endPoint = _calculateEdgePoint(toLayout.bounds, controlPoint2);

    return _ArrowGeometry(
      startPoint: startPoint,
      endPoint: endPoint,
      controlPoint1: controlPoint1,
      controlPoint2: controlPoint2,
    );
  }

  /// Get the visual bounds of an arrow, including curve, arrowheads and label.
  static Rect? getArrowBounds(
    ArrowData arrow,
    Map<String, NodeLayout> nodeLayouts,
    MindMapTheme theme,
  ) {
    final geometry = _computeArrowGeometry(arrow, nodeLayouts);
    if (geometry == null) return null;

    final path = Path()
      ..moveTo(geometry.startPoint.dx, geometry.startPoint.dy)
      ..cubicTo(
        geometry.controlPoint1.dx,
        geometry.controlPoint1.dy,
        geometry.controlPoint2.dx,
        geometry.controlPoint2.dy,
        geometry.endPoint.dx,
        geometry.endPoint.dy,
      );

    final strokeWidth = arrow.style?.strokeWidth ?? 2.0;
    // Include stroke and arrowhead wings.
    final edgePadding = math.max(strokeWidth * 0.5 + 2.0, arrowheadSize * 1.4);
    Rect bounds = path.getBounds().inflate(edgePadding);

    if (arrow.label != null && arrow.label!.isNotEmpty) {
      final labelBounds = getArrowLabelBounds(arrow, nodeLayouts, theme);
      if (labelBounds != null) {
        bounds = bounds.expandToInclude(labelBounds.inflate(2.0));
      }
    }

    return bounds;
  }

  /// Get the bounds of a control point for hit testing
  static Rect? getControlPointBounds(
    ArrowData arrow,
    Map<String, NodeLayout> nodeLayouts,
    int controlPointIndex,
  ) {
    final fromLayout = nodeLayouts[arrow.fromNodeId];
    final toLayout = nodeLayouts[arrow.toNodeId];

    if (fromLayout == null || toLayout == null) return null;

    final startPoint = fromLayout.bounds.center;
    final endPoint = toLayout.bounds.center;
    final (effectiveDelta1, effectiveDelta2) = _resolveArrowDeltas(
      arrow,
      fromLayout,
      toLayout,
    );

    final controlPoint = controlPointIndex == 0
        ? startPoint + effectiveDelta1
        : endPoint + effectiveDelta2;

    const handleRadius = 6.0;
    return Rect.fromCenter(
      center: controlPoint,
      width: handleRadius * 2,
      height: handleRadius * 2,
    );
  }
}

class _ArrowGeometry {
  final Offset startPoint;
  final Offset endPoint;
  final Offset controlPoint1;
  final Offset controlPoint2;

  const _ArrowGeometry({
    required this.startPoint,
    required this.endPoint,
    required this.controlPoint1,
    required this.controlPoint2,
  });
}
