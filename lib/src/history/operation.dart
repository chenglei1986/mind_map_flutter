import '../models/mind_map_data.dart';

/// Abstract interface for operations that can be undone and redone
/// 
/// Each operation represents a single user action that modifies the mind map.
/// Operations must be able to execute themselves and undo their changes.
/// 
abstract class Operation {
  /// Execute this operation, applying changes to the mind map data
  /// 
  /// Returns the new mind map data after the operation is applied.
  MindMapData execute(MindMapData currentData);
  
  /// Undo this operation, reverting changes to the mind map data
  /// 
  /// Returns the mind map data before the operation was applied.
  MindMapData undo(MindMapData currentData);
  
  /// A description of this operation for debugging purposes
  String get description;
}
