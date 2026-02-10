import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Manages zoom and pan transformations for the mind map canvas
///
/// Handles:
/// - Managing the transformation matrix
/// - Processing pan gestures (dragging the canvas)
/// - Processing zoom gestures (pinch-to-zoom, mouse wheel)
/// - Constraining zoom to min/max scale limits
///
class ZoomPanManager extends ChangeNotifier {
  /// The current transformation matrix
  Matrix4 _transform = Matrix4.identity();

  /// Minimum allowed scale
  final double minScale;

  /// Maximum allowed scale
  final double maxScale;

  /// Current scale factor
  double _scale = 1.0;

  /// Current translation offset
  Offset _translation = Offset.zero;

  /// Initial scale at the start of a scale gesture
  double? _initialScale;

  /// Initial focal point at the start of a scale gesture
  Offset? _initialFocalPoint;

  /// Initial translation at the start of a scale gesture
  Offset? _initialTranslation;

  ZoomPanManager({this.minScale = 0.1, this.maxScale = 5.0}) {
    _updateTransform();
  }

  /// Get the current transformation matrix
  Matrix4 get transform => _transform;

  /// Get the current scale factor
  double get scale => _scale;

  /// Get the current translation offset
  Offset get translation => _translation;

  /// Handle pan start (for canvas dragging)
  void handlePanStart(Offset position) {
    // Store initial state for pan gesture
    _initialTranslation = _translation;
  }

  /// Handle pan update (for canvas dragging)
  void handlePanUpdate(Offset delta) {
    if (delta.dx == 0.0 && delta.dy == 0.0) {
      return;
    }
    if (_initialTranslation == null) {
      _initialTranslation = _translation;
    }

    // Update translation by the delta
    _translation = _translation + delta;
    _updateTransform();
    notifyListeners();
  }

  /// Handle pan end (for canvas dragging)
  void handlePanEnd() {
    _initialTranslation = null;
  }

  /// Handle scale start (for pinch-to-zoom)
  void handleScaleStart(ScaleStartDetails details) {
    _initialScale = _scale;
    _initialFocalPoint = details.localFocalPoint;
    _initialTranslation = _translation;
  }

  /// Handle scale update (for pinch-to-zoom)
  void handleScaleUpdate(ScaleUpdateDetails details) {
    if (_initialScale == null ||
        _initialFocalPoint == null ||
        _initialTranslation == null) {
      return;
    }

    // Calculate new scale, constrained to min/max
    final newScale = (_initialScale! * details.scale).clamp(minScale, maxScale);

    // Keep the current focal point fixed in screen coordinates
    final focalCanvasBefore = _screenToCanvas(
      _initialFocalPoint!,
      _initialScale!,
      _initialTranslation!,
    );

    final newTranslation =
        details.localFocalPoint - (focalCanvasBefore * newScale);

    if (_scale == newScale && _translation == newTranslation) {
      return;
    }

    _scale = newScale;
    _translation = newTranslation;

    _updateTransform();
    notifyListeners();
  }

  /// Handle scale end (for pinch-to-zoom)
  void handleScaleEnd(ScaleEndDetails details) {
    _initialScale = null;
    _initialFocalPoint = null;
    _initialTranslation = null;
  }

  /// Handle mouse wheel scroll (for zoom)
  void handleMouseWheel(PointerScrollEvent event, Offset pointerPosition) {
    // Calculate zoom delta from scroll delta
    // Negative scrollDelta.dy means scroll up (zoom in)
    final zoomDelta = -event.scrollDelta.dy / 500.0;

    final targetScale = _scale * (1.0 + zoomDelta);
    _setScaleAtFocalPoint(targetScale, pointerPosition);
  }

  /// Set the zoom level programmatically
  ///
  /// [scale] - The new scale factor
  /// [focalPoint] - Optional focal point to zoom around (defaults to center)
  void setZoom(double scale, {Offset? focalPoint}) {
    if (focalPoint != null) {
      _setScaleAtFocalPoint(scale, focalPoint);
      return;
    }

    final newScale = scale.clamp(minScale, maxScale).toDouble();
    if (_scale == newScale) {
      return;
    }

    _scale = newScale;
    _updateTransform();
    notifyListeners();
  }

  /// Set the translation offset programmatically
  void setTranslation(Offset translation) {
    _translation = translation;
    _updateTransform();
    notifyListeners();
  }

  /// Center the view on a specific point in canvas coordinates
  ///
  /// [canvasPoint] - The point in canvas coordinates to center on
  /// [viewportSize] - The size of the viewport
  void centerOn(Offset canvasPoint, Size viewportSize) {
    // Calculate the translation needed to center the point
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );
    final scaledCanvasPoint = canvasPoint * _scale;
    _translation = viewportCenter - scaledCanvasPoint;

    _updateTransform();
    notifyListeners();
  }

  /// Reset zoom and pan to default state
  void reset() {
    _scale = 1.0;
    _translation = Offset.zero;
    _updateTransform();
    notifyListeners();
  }

  /// Update the transformation matrix based on current scale and translation
  void _updateTransform() {
    _transform = Matrix4.identity()
      ..translateByDouble(_translation.dx, _translation.dy, 0.0, 1.0)
      ..scaleByDouble(_scale, _scale, 1.0, 1.0);
  }

  /// Convert screen coordinates to canvas coordinates
  Offset _screenToCanvas(Offset screenPoint, double scale, Offset translation) {
    return (screenPoint - translation) / scale;
  }

  /// Update scale around a specific screen-space focal point.
  ///
  /// Keeps the canvas point under [focalPoint] visually fixed after zoom.
  void _setScaleAtFocalPoint(double targetScale, Offset focalPoint) {
    final newScale = targetScale.clamp(minScale, maxScale).toDouble();
    if (_scale == newScale) {
      return;
    }

    final focalCanvasBefore = _screenToCanvas(focalPoint, _scale, _translation);
    _scale = newScale;
    _translation = focalPoint - (focalCanvasBefore * _scale);

    _updateTransform();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
