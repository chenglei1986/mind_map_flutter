import 'package:flutter/material.dart';
import '../layout/node_layout.dart';
import '../models/node_data.dart';

/// Manages node drag and drop operations
///
/// Handles:
/// - Detecting drag start on nodes
/// - Providing visual feedback during drag
/// - Highlighting valid drop targets
/// - Preventing invalid drops (circular references)
///
class DragManager extends ChangeNotifier {
  static const double _dropThreshold = 12.0;
  static const int _positionNotifyIntervalMicros = 16000; // ~60fps
  static const int _dropResolveIntervalMicros = 16000; // ~60fps
  static const double _dropResolveMinScreenDistance = 6.0;

  /// The node currently being dragged (if any)
  String? _draggedNodeId;

  /// Current position of the drag cursor
  Offset? _dragPosition;

  /// The node currently under the cursor (potential drop target)
  String? _dropTargetNodeId;

  /// Drop insert mode relative to target node:
  /// - 'before': insert as previous sibling of target
  /// - 'after': insert as next sibling of target
  /// - 'in': insert as child of target
  String? _dropInsertType;
  int _lastPositionNotifyMicros = 0;
  int _lastDropResolveMicros = 0;
  Offset? _lastResolvedScreenPosition;

  final Set<String> _draggedSubtreeNodeIds = <String>{};
  Map<String, NodeLayout>? _dropCandidateLayoutsRef;
  List<_DropCandidate> _dropCandidates = const <_DropCandidate>[];

  Matrix4? _inverseTransformSource;
  Matrix4? _cachedInverseTransform;

  /// Whether a drag operation is in progress
  bool get isDragging => _draggedNodeId != null;

  /// Get the ID of the node being dragged
  String? get draggedNodeId => _draggedNodeId;

  /// Get the current drag position
  Offset? get dragPosition => _dragPosition;

  /// Get the current drop target node ID
  String? get dropTargetNodeId => _dropTargetNodeId;

  /// Get current drop insert mode ('before' | 'after' | 'in')
  String? get dropInsertType => _dropInsertType;

  /// Start dragging a node
  void startDrag(String nodeId, Offset position) {
    _draggedNodeId = nodeId;
    _dragPosition = position;
    _dropTargetNodeId = null;
    _dropInsertType = null;
    _lastPositionNotifyMicros = DateTime.now().microsecondsSinceEpoch;
    _lastDropResolveMicros = 0;
    _lastResolvedScreenPosition = null;
    _draggedSubtreeNodeIds.clear();
    _dropCandidateLayoutsRef = null;
    _dropCandidates = const <_DropCandidate>[];
    _inverseTransformSource = null;
    _cachedInverseTransform = null;
    notifyListeners();
  }

  /// Update drag position and determine drop target
  void updateDrag(
    Offset position,
    Map<String, NodeLayout> nodeLayouts,
    Matrix4 transform,
    NodeData rootNode,
  ) {
    if (!isDragging) return;

    final previousPosition = _dragPosition;
    _dragPosition = position;

    final previousTarget = _dropTargetNodeId;
    final previousInsertType = _dropInsertType;
    final now = DateTime.now().microsecondsSinceEpoch;

    _ensureDraggedSubtreeCache(rootNode);
    _ensureDropCandidates(nodeLayouts, rootNode);

    if (_shouldResolveDropTarget(position, now)) {
      final inverseTransform = _resolveInverseTransform(transform);
      final transformedPosition = MatrixUtils.transformPoint(
        inverseTransform,
        position,
      );
      final drop = _resolveDropTarget(transformedPosition);
      _dropTargetNodeId = drop?.nodeId;
      _dropInsertType = drop?.insertType;
      _lastDropResolveMicros = now;
      _lastResolvedScreenPosition = position;
    }

    final targetChanged =
        previousTarget != _dropTargetNodeId ||
        previousInsertType != _dropInsertType;

    if (targetChanged) {
      _lastPositionNotifyMicros = now;
      notifyListeners();
      return;
    }

    // Smooth drag preview updates with frame-rate throttling.
    if (previousPosition != _dragPosition) {
      if (now - _lastPositionNotifyMicros >= _positionNotifyIntervalMicros) {
        _lastPositionNotifyMicros = now;
        notifyListeners();
      }
    }
  }

  /// Resolve drop target immediately at current drag position.
  ///
  /// Used right before drop to guarantee final target accuracy even when
  /// drag updates are throttled.
  void resolveDropTargetNow(
    Map<String, NodeLayout> nodeLayouts,
    Matrix4 transform,
    NodeData rootNode,
  ) {
    if (!isDragging || _dragPosition == null) return;

    final previousTarget = _dropTargetNodeId;
    final previousInsertType = _dropInsertType;
    final now = DateTime.now().microsecondsSinceEpoch;

    _ensureDraggedSubtreeCache(rootNode);
    _ensureDropCandidates(nodeLayouts, rootNode);

    final inverseTransform = _resolveInverseTransform(transform);
    final transformedPosition = MatrixUtils.transformPoint(
      inverseTransform,
      _dragPosition!,
    );
    final drop = _resolveDropTarget(transformedPosition);
    _dropTargetNodeId = drop?.nodeId;
    _dropInsertType = drop?.insertType;
    _lastDropResolveMicros = now;
    _lastResolvedScreenPosition = _dragPosition;

    if (previousTarget != _dropTargetNodeId ||
        previousInsertType != _dropInsertType) {
      _lastPositionNotifyMicros = now;
      notifyListeners();
    }
  }

  /// End the drag operation
  ///
  /// Returns the drop target node ID if the drop is valid, null otherwise
  String? endDrag() {
    if (!isDragging) return null;

    final targetNodeId = _dropTargetNodeId;

    // Clear drag state
    _draggedNodeId = null;
    _dragPosition = null;
    _dropTargetNodeId = null;
    _dropInsertType = null;
    _lastPositionNotifyMicros = 0;
    _lastDropResolveMicros = 0;
    _lastResolvedScreenPosition = null;
    _draggedSubtreeNodeIds.clear();
    _dropCandidateLayoutsRef = null;
    _dropCandidates = const <_DropCandidate>[];
    _inverseTransformSource = null;
    _cachedInverseTransform = null;
    notifyListeners();

    return targetNodeId;
  }

  /// Cancel the drag operation without dropping
  void cancelDrag() {
    if (!isDragging) return;

    _draggedNodeId = null;
    _dragPosition = null;
    _dropTargetNodeId = null;
    _dropInsertType = null;
    _lastPositionNotifyMicros = 0;
    _lastDropResolveMicros = 0;
    _lastResolvedScreenPosition = null;
    _draggedSubtreeNodeIds.clear();
    _dropCandidateLayoutsRef = null;
    _dropCandidates = const <_DropCandidate>[];
    _inverseTransformSource = null;
    _cachedInverseTransform = null;
    notifyListeners();
  }

  bool _shouldResolveDropTarget(Offset screenPosition, int nowMicros) {
    if (_lastResolvedScreenPosition == null) {
      return true;
    }
    if (nowMicros - _lastDropResolveMicros >= _dropResolveIntervalMicros) {
      return true;
    }
    return (screenPosition - _lastResolvedScreenPosition!).distance >=
        _dropResolveMinScreenDistance;
  }

  Matrix4 _resolveInverseTransform(Matrix4 transform) {
    if (identical(_inverseTransformSource, transform) &&
        _cachedInverseTransform != null) {
      return _cachedInverseTransform!;
    }
    _inverseTransformSource = transform;
    _cachedInverseTransform = Matrix4.inverted(transform);
    return _cachedInverseTransform!;
  }

  void _ensureDraggedSubtreeCache(NodeData rootNode) {
    if (_draggedNodeId == null || _draggedSubtreeNodeIds.isNotEmpty) {
      return;
    }
    final draggedNode = _findNode(rootNode, _draggedNodeId!);
    if (draggedNode == null) return;
    _collectSubtreeNodeIds(draggedNode, _draggedSubtreeNodeIds);
  }

  void _ensureDropCandidates(
    Map<String, NodeLayout> nodeLayouts,
    NodeData rootNode,
  ) {
    if (identical(_dropCandidateLayoutsRef, nodeLayouts)) {
      return;
    }

    _dropCandidateLayoutsRef = nodeLayouts;
    final candidates = <_DropCandidate>[];
    for (final entry in nodeLayouts.entries) {
      final nodeId = entry.key;
      if (_draggedSubtreeNodeIds.contains(nodeId)) continue;
      candidates.add(_DropCandidate(nodeId: nodeId, bounds: entry.value.bounds));
    }
    _dropCandidates = candidates;
  }

  _DropTarget? _resolveDropTarget(Offset position) {
    if (_draggedNodeId == null) return null;

    _DropTarget? best;
    double bestDistance = double.infinity;

    for (final candidate in _dropCandidates) {
      final nodeId = candidate.nodeId;
      final bounds = candidate.bounds;

      // X must be over topic bounds; Y allows small extension for before/after.
      if (position.dx < bounds.left || position.dx > bounds.right) {
        continue;
      }
      if (position.dy < bounds.top - _dropThreshold ||
          position.dy > bounds.bottom + _dropThreshold) {
        continue;
      }

      final String insertType;
      final double distance;
      if (position.dy < bounds.top) {
        insertType = 'before';
        distance = bounds.top - position.dy;
      } else if (position.dy > bounds.bottom) {
        insertType = 'after';
        distance = position.dy - bounds.bottom;
      } else {
        insertType = 'in';
        distance = 0.0;
      }

      if (distance < bestDistance) {
        bestDistance = distance;
        best = _DropTarget(nodeId: nodeId, insertType: insertType);
      }
    }

    return best;
  }

  void _collectSubtreeNodeIds(NodeData node, Set<String> ids) {
    ids.add(node.id);
    for (final child in node.children) {
      _collectSubtreeNodeIds(child, ids);
    }
  }

  /// Find a node in the tree by ID
  NodeData? _findNode(NodeData node, String nodeId) {
    if (node.id == nodeId) return node;

    for (final child in node.children) {
      final found = _findNode(child, nodeId);
      if (found != null) return found;
    }

    return null;
  }

  @override
  void dispose() {
    _draggedNodeId = null;
    _dragPosition = null;
    _dropTargetNodeId = null;
    _dropInsertType = null;
    _lastPositionNotifyMicros = 0;
    _lastDropResolveMicros = 0;
    _lastResolvedScreenPosition = null;
    _draggedSubtreeNodeIds.clear();
    _dropCandidateLayoutsRef = null;
    _dropCandidates = const <_DropCandidate>[];
    _inverseTransformSource = null;
    _cachedInverseTransform = null;
    super.dispose();
  }
}

class _DropTarget {
  final String nodeId;
  final String insertType;

  const _DropTarget({required this.nodeId, required this.insertType});
}

class _DropCandidate {
  final String nodeId;
  final Rect bounds;

  const _DropCandidate({required this.nodeId, required this.bounds});
}
