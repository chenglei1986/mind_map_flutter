import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/history/history_manager.dart';
import 'package:mind_map_flutter/src/history/operation.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';

/// Mock operation for testing
class MockOperation implements Operation {
  final String _description;
  final MindMapData _executeResult;
  final MindMapData _undoResult;
  
  MockOperation(this._description, this._executeResult, this._undoResult);
  
  @override
  String get description => _description;
  
  @override
  MindMapData execute(MindMapData currentData) => _executeResult;
  
  @override
  MindMapData undo(MindMapData currentData) => _undoResult;
}

void main() {
  group('HistoryManager', () {
    late HistoryManager historyManager;
    late MindMapData testData1;
    late MindMapData testData2;
    late MindMapData testData3;
    
    setUp(() {
      historyManager = HistoryManager();
      
      // Create test data
      final node1 = NodeData.create(topic: 'Root 1');
      final node2 = NodeData.create(topic: 'Root 2');
      final node3 = NodeData.create(topic: 'Root 3');
      
      testData1 = MindMapData(
        nodeData: node1,
        theme: MindMapTheme.light,
      );
      
      testData2 = MindMapData(
        nodeData: node2,
        theme: MindMapTheme.light,
      );
      
      testData3 = MindMapData(
        nodeData: node3,
        theme: MindMapTheme.light,
      );
    });
    
    test('should initialize with empty stacks', () {
      expect(historyManager.canUndo, false);
      expect(historyManager.canRedo, false);
      expect(historyManager.undoCount, 0);
      expect(historyManager.redoCount, 0);
    });
    
    test('should record operations in undo stack', () {
      final operation = MockOperation('test', testData2, testData1);
      
      historyManager.recordOperation(operation);
      
      expect(historyManager.canUndo, true);
      expect(historyManager.canRedo, false);
      expect(historyManager.undoCount, 1);
      expect(historyManager.redoCount, 0);
    });
    
    test('should clear redo stack when recording new operation', () {
      final op1 = MockOperation('op1', testData2, testData1);
      final op2 = MockOperation('op2', testData3, testData2);
      
      // Record and undo an operation
      historyManager.recordOperation(op1);
      historyManager.undo();
      
      expect(historyManager.canRedo, true);
      expect(historyManager.redoCount, 1);
      
      // Record a new operation - should clear redo stack
      historyManager.recordOperation(op2);
      
      expect(historyManager.canRedo, false);
      expect(historyManager.redoCount, 0);
      expect(historyManager.undoCount, 1);
    });
    
    test('should undo operation and move to redo stack', () {
      final operation = MockOperation('test', testData2, testData1);
      
      historyManager.recordOperation(operation);
      final undoneEntry = historyManager.undo();
      
      expect(undoneEntry?.operation, operation);
      expect(historyManager.canUndo, false);
      expect(historyManager.canRedo, true);
      expect(historyManager.undoCount, 0);
      expect(historyManager.redoCount, 1);
    });
    
    test('should return null when undoing with empty stack', () {
      final result = historyManager.undo();
      
      expect(result, null);
      expect(historyManager.canUndo, false);
    });
    
    test('should redo operation and move back to undo stack', () {
      final operation = MockOperation('test', testData2, testData1);
      
      historyManager.recordOperation(operation);
      historyManager.undo();
      final redoneEntry = historyManager.redo();
      
      expect(redoneEntry?.operation, operation);
      expect(historyManager.canUndo, true);
      expect(historyManager.canRedo, false);
      expect(historyManager.undoCount, 1);
      expect(historyManager.redoCount, 0);
    });
    
    test('should return null when redoing with empty stack', () {
      final result = historyManager.redo();
      
      expect(result, null);
      expect(historyManager.canRedo, false);
    });
    
    test('should support multiple undo/redo operations', () {
      final op1 = MockOperation('op1', testData2, testData1);
      final op2 = MockOperation('op2', testData3, testData2);
      
      historyManager.recordOperation(op1);
      historyManager.recordOperation(op2);
      
      expect(historyManager.undoCount, 2);
      
      // Undo both
      final undone1 = historyManager.undo();
      final undone2 = historyManager.undo();
      
      expect(undone1?.operation, op2);
      expect(undone2?.operation, op1);
      expect(historyManager.undoCount, 0);
      expect(historyManager.redoCount, 2);
      
      // Redo both
      final redone1 = historyManager.redo();
      final redone2 = historyManager.redo();
      
      expect(redone1?.operation, op1);
      expect(redone2?.operation, op2);
      expect(historyManager.undoCount, 2);
      expect(historyManager.redoCount, 0);
    });
    
    test('should clear all history', () {
      final op1 = MockOperation('op1', testData2, testData1);
      final op2 = MockOperation('op2', testData3, testData2);
      
      historyManager.recordOperation(op1);
      historyManager.recordOperation(op2);
      historyManager.undo();
      
      expect(historyManager.undoCount, 1);
      expect(historyManager.redoCount, 1);
      
      historyManager.clear();
      
      expect(historyManager.canUndo, false);
      expect(historyManager.canRedo, false);
      expect(historyManager.undoCount, 0);
      expect(historyManager.redoCount, 0);
    });
    
    test('should enforce history size limit', () {
      final manager = HistoryManager(maxHistorySize: 3);
      
      final op1 = MockOperation('op1', testData1, testData1);
      final op2 = MockOperation('op2', testData2, testData2);
      final op3 = MockOperation('op3', testData3, testData3);
      final op4 = MockOperation('op4', testData1, testData1);
      
      manager.recordOperation(op1);
      manager.recordOperation(op2);
      manager.recordOperation(op3);
      
      expect(manager.undoCount, 3);
      
      // Adding a 4th operation should remove the oldest (op1)
      manager.recordOperation(op4);
      
      expect(manager.undoCount, 3);
      
      // Verify the oldest operation was removed by undoing all
      final undone1 = manager.undo();
      final undone2 = manager.undo();
      final undone3 = manager.undo();
      
      expect(undone1?.operation, op4);
      expect(undone2?.operation, op3);
      expect(undone3?.operation, op2);
      expect(manager.canUndo, false);
    });
    
    test('should allow unlimited history when maxHistorySize is 0', () {
      final manager = HistoryManager(maxHistorySize: 0);
      
      // Add many operations
      for (int i = 0; i < 200; i++) {
        manager.recordOperation(MockOperation('op$i', testData1, testData1));
      }
      
      expect(manager.undoCount, 200);
    });
    
    test('should allow unlimited history when maxHistorySize is negative', () {
      final manager = HistoryManager(maxHistorySize: -1);
      
      // Add many operations
      for (int i = 0; i < 150; i++) {
        manager.recordOperation(MockOperation('op$i', testData1, testData1));
      }
      
      expect(manager.undoCount, 150);
    });
    
    test('should handle undo/redo roundtrip correctly', () {
      final operation = MockOperation('test', testData2, testData1);
      
      historyManager.recordOperation(operation);
      
      // Undo
      final undoneEntry = historyManager.undo();
      expect(undoneEntry?.operation, operation);
      expect(historyManager.canUndo, false);
      expect(historyManager.canRedo, true);
      
      // Redo
      final redoneEntry = historyManager.redo();
      expect(redoneEntry?.operation, operation);
      expect(historyManager.canUndo, true);
      expect(historyManager.canRedo, false);
      
      // Should be back to original state
      expect(historyManager.undoCount, 1);
      expect(historyManager.redoCount, 0);
    });
    
    test('should store selection snapshots with history entries', () {
      final operation = MockOperation('test', testData2, testData1);
      
      historyManager.recordOperation(
        operation,
        selectionBefore: ['a', 'b'],
        selectionAfter: ['c'],
      );
      
      final entry = historyManager.undo();
      expect(entry, isNotNull);
      expect(entry?.operation, operation);
      expect(entry?.selectionBefore, ['a', 'b']);
      expect(entry?.selectionAfter, ['c']);
    });
  });
}
