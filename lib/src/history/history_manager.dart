import 'operation.dart';

/// Manages operation history for undo/redo functionality
/// 
/// The HistoryManager maintains two stacks:
/// - Undo stack: operations that can be undone
/// - Redo stack: operations that can be redone
/// 
/// When a new operation is recorded, it's added to the undo stack and the redo
/// stack is cleared. When an operation is undone, it's moved from the undo stack
/// to the redo stack. When an operation is redone, it's moved back to the undo stack.
/// 
/// The history size can be limited to prevent excessive memory usage.
/// 
class HistoryManager {
  final List<HistoryEntry> _undoStack = [];
  final List<HistoryEntry> _redoStack = [];
  final int maxHistorySize;
  
  /// Creates a new HistoryManager
  /// 
  /// [maxHistorySize] limits the number of operations stored in the undo stack.
  /// When the limit is reached, the oldest operations are removed.
  /// A value of 0 or negative means unlimited history.
  HistoryManager({this.maxHistorySize = 100});
  
  /// Record a new operation in the history
  /// 
  /// This adds the operation to the undo stack and clears the redo stack,
  /// as performing a new action invalidates any previously undone operations.
  /// 
  /// If the undo stack exceeds [maxHistorySize], the oldest operation is removed.
  /// 
  void recordOperation(
    Operation operation, {
    List<String>? selectionBefore,
    List<String>? selectionAfter,
  }) {
    _undoStack.add(HistoryEntry(
      operation: operation,
      selectionBefore: selectionBefore ?? const [],
      selectionAfter: selectionAfter ?? const [],
    ));
    _redoStack.clear();
    
    // Enforce history size limit
    if (maxHistorySize > 0 && _undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }
  }
  
  /// Undo the most recent operation
  /// 
  /// Returns the operation that was undone, or null if there's nothing to undo.
  /// The undone operation is moved to the redo stack.
  /// 
  HistoryEntry? undo() {
    if (_undoStack.isEmpty) {
      return null;
    }
    
    final entry = _undoStack.removeLast();
    _redoStack.add(entry);
    return entry;
  }
  
  /// Redo the most recently undone operation
  /// 
  /// Returns the operation that was redone, or null if there's nothing to redo.
  /// The redone operation is moved back to the undo stack.
  /// 
  HistoryEntry? redo() {
    if (_redoStack.isEmpty) {
      return null;
    }
    
    final entry = _redoStack.removeLast();
    _undoStack.add(entry);
    return entry;
  }
  
  /// Clear all history
  /// 
  /// Removes all operations from both the undo and redo stacks.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
  
  /// Whether there are operations that can be undone
  bool get canUndo => _undoStack.isNotEmpty;
  
  /// Whether there are operations that can be redone
  bool get canRedo => _redoStack.isNotEmpty;
  
  /// The number of operations in the undo stack
  int get undoCount => _undoStack.length;
  
  /// The number of operations in the redo stack
  int get redoCount => _redoStack.length;
}

class HistoryEntry {
  final Operation operation;
  final List<String> selectionBefore;
  final List<String> selectionAfter;
  
  HistoryEntry({
    required this.operation,
    required List<String> selectionBefore,
    required List<String> selectionAfter,
  })  : selectionBefore = List.unmodifiable(selectionBefore),
        selectionAfter = List.unmodifiable(selectionAfter);
}
