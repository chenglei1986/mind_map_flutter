import 'package:flutter/foundation.dart';
import '../models/node_data.dart';
import '../widgets/mind_map_widget.dart';

/// Manages node selection state
/// 
/// Supports:
/// - Single selection (clicking a node)
/// - Multi-selection (Ctrl/Cmd + click)
/// - Drag selection (selecting multiple nodes with a rectangle)
/// - Clipboard operations (copy/paste)
/// 
class SelectionManager extends ChangeNotifier {
  final List<String> _selectedNodeIds = [];
  final void Function(SelectNodesEvent)? _onSelectionChanged;
  NodeData? _clipboard;

  SelectionManager({
    void Function(SelectNodesEvent)? onSelectionChanged,
  }) : _onSelectionChanged = onSelectionChanged;

  /// Get the list of currently selected node IDs
  List<String> get selectedNodeIds => List.unmodifiable(_selectedNodeIds);

  /// Check if a node is selected
  bool isSelected(String nodeId) => _selectedNodeIds.contains(nodeId);
  
  /// Copy a node to the clipboard
  void copyToClipboard(NodeData node) {
    _clipboard = node;
  }
  
  /// Get the node from the clipboard
  NodeData? getFromClipboard() {
    return _clipboard;
  }
  
  /// Check if the clipboard has content
  bool get hasClipboardContent => _clipboard != null;

  /// Select a single node (clears previous selection)
  void selectNode(String nodeId) {
    if (_selectedNodeIds.length == 1 && _selectedNodeIds.first == nodeId) {
      // Already selected, no change needed
      return;
    }

    _selectedNodeIds.clear();
    _selectedNodeIds.add(nodeId);
    _emitSelectionEvent();
  }

  /// Add a node to the current selection (multi-select)
  void addToSelection(String nodeId) {
    if (_selectedNodeIds.contains(nodeId)) {
      // Already in selection, no change needed
      return;
    }

    _selectedNodeIds.add(nodeId);
    _emitSelectionEvent();
  }

  /// Remove a node from the current selection
  void removeFromSelection(String nodeId) {
    if (_selectedNodeIds.remove(nodeId)) {
      _emitSelectionEvent();
    }
  }

  /// Toggle a node's selection state (for Ctrl/Cmd + click)
  /// If the node is selected, deselect it. Otherwise, add it to selection.
  void toggleSelection(String nodeId) {
    if (_selectedNodeIds.contains(nodeId)) {
      _selectedNodeIds.remove(nodeId);
    } else {
      _selectedNodeIds.add(nodeId);
    }
    _emitSelectionEvent();
  }

  /// Select multiple nodes at once (for drag selection)
  void selectNodes(List<String> nodeIds) {
    if (_areListsEqual(_selectedNodeIds, nodeIds)) {
      // Same selection, no change needed
      return;
    }

    _selectedNodeIds.clear();
    _selectedNodeIds.addAll(nodeIds);
    _emitSelectionEvent();
  }

  /// Clear all selections
  void clearSelection() {
    if (_selectedNodeIds.isEmpty) {
      // Already empty, no change needed
      return;
    }

    _selectedNodeIds.clear();
    _emitSelectionEvent();
  }

  /// Emit a selectNodes event
  void _emitSelectionEvent() {
    final event = SelectNodesEvent(List.from(_selectedNodeIds));
    _onSelectionChanged?.call(event);
    notifyListeners();
  }

  /// Helper to compare two lists for equality
  bool _areListsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _selectedNodeIds.clear();
    _clipboard = null;
    super.dispose();
  }
}
