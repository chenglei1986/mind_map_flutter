import 'dart:ui';

/// Layout information for a node
class NodeLayout {
  final Offset position;
  final Size size;
  
  /// Bounds rectangle calculated from position and size
  Rect get bounds => Rect.fromLTWH(
    position.dx,
    position.dy,
    size.width,
    size.height,
  );

  const NodeLayout({
    required this.position,
    required this.size,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeLayout &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          size == other.size;

  @override
  int get hashCode => position.hashCode ^ size.hashCode;

  @override
  String toString() => 'NodeLayout(position: $position, size: $size)';
}
