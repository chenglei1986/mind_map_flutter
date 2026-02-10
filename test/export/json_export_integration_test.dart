import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

/// Integration test demonstrating the complete JSON export workflow
/// 
/// This test validates Requirements 12.1 and 12.2:
/// - The system SHALL provide a method to export the complete mind map as JSON
/// - The exported data SHALL include node data, arrows, summaries, direction, and theme
void main() {
  group('JSON Export Integration Tests', () {
    test('Complete workflow: create mind map, modify it, and export to JSON', () {
      // Step 1: Create a new mind map
      final controller = MindMapController(
        initialData: MindMapData.empty(rootTopic: 'My Project'),
      );
      
      // Step 2: Build a mind map structure
      final rootId = controller.getData().nodeData.id;
      
      // Add main branches
      controller.addChildNode(rootId, topic: 'Planning');
      controller.addChildNode(rootId, topic: 'Development');
      controller.addChildNode(rootId, topic: 'Testing');
      
      final rootNode = controller.getData().nodeData;
      final planningId = rootNode.children[0].id;
      final developmentId = rootNode.children[1].id;
      
      // Add sub-tasks under Planning
      controller.addChildNode(planningId, topic: 'Requirements');
      controller.addChildNode(planningId, topic: 'Design');
      
      // Add sub-tasks under Development
      controller.addChildNode(developmentId, topic: 'Frontend');
      controller.addChildNode(developmentId, topic: 'Backend');
      
      // Step 3: Add an arrow to show relationship
      controller.addArrow(
        fromNodeId: planningId,
        toNodeId: developmentId,
        label: 'Leads to',
      );
      
      // Step 4: Add a summary
      controller.addSummary(
        parentNodeId: rootId,
        startIndex: 0,
        endIndex: 2,
        label: 'Project Phases',
      );
      
      // Step 5: Export to JSON
      final jsonString = controller.exportToJson();
      
      // Step 6: Verify the export
      expect(jsonString, isNotEmpty);
      
      // Parse and validate structure
      final parsed = jsonDecode(jsonString);
      
      // Verify root node
      expect(parsed['nodeData']['topic'], equals('My Project'));
      expect(parsed['nodeData']['children'], hasLength(3));
      
      // Verify main branches
      final children = parsed['nodeData']['children'];
      expect(children[0]['topic'], equals('Planning'));
      expect(children[1]['topic'], equals('Development'));
      expect(children[2]['topic'], equals('Testing'));
      
      // Verify sub-tasks
      expect(children[0]['children'], hasLength(2));
      expect(children[0]['children'][0]['topic'], equals('Requirements'));
      expect(children[0]['children'][1]['topic'], equals('Design'));
      
      expect(children[1]['children'], hasLength(2));
      expect(children[1]['children'][0]['topic'], equals('Frontend'));
      expect(children[1]['children'][1]['topic'], equals('Backend'));
      
      // Verify arrow
      expect(parsed['arrows'], hasLength(1));
      expect(parsed['arrows'][0]['label'], equals('Leads to'));
      
      // Verify summary
      expect(parsed['summaries'], hasLength(1));
      expect(parsed['summaries'][0]['label'], equals('Project Phases'));
      expect(parsed['summaries'][0]['startIndex'], equals(0));
      expect(parsed['summaries'][0]['endIndex'], equals(2));
      
      // Verify theme and direction
      expect(parsed['theme'], isNotNull);
      expect(parsed['direction'], isNotNull);
      
      controller.dispose();
    });
    
    test('Export after undo/redo operations preserves correct state', () {
      // Create a mind map
      final controller = MindMapController(
        initialData: MindMapData.empty(rootTopic: 'Root'),
        config: MindMapConfig(allowUndo: true),
      );
      
      final rootId = controller.getData().nodeData.id;
      
      // Add a child
      controller.addChildNode(rootId, topic: 'Child 1');
      
      // Export state 1
      final json1 = controller.exportToJson();
      final parsed1 = jsonDecode(json1);
      expect(parsed1['nodeData']['children'], hasLength(1));
      
      // Add another child
      controller.addChildNode(rootId, topic: 'Child 2');
      
      // Export state 2
      final json2 = controller.exportToJson();
      final parsed2 = jsonDecode(json2);
      expect(parsed2['nodeData']['children'], hasLength(2));
      
      // Undo the last addition
      controller.undo();
      
      // Export after undo - should match state 1
      final json3 = controller.exportToJson();
      final parsed3 = jsonDecode(json3);
      expect(parsed3['nodeData']['children'], hasLength(1));
      
      // Redo
      controller.redo();
      
      // Export after redo - should match state 2
      final json4 = controller.exportToJson();
      final parsed4 = jsonDecode(json4);
      expect(parsed4['nodeData']['children'], hasLength(2));
      
      controller.dispose();
    });
    
    test('Export with theme changes preserves theme data', () {
      // Create a mind map with light theme
      final controller = MindMapController(
        initialData: MindMapData.empty(
          rootTopic: 'Root',
          theme: MindMapTheme.light,
        ),
      );
      
      // Export with light theme
      final json1 = controller.exportToJson();
      final parsed1 = jsonDecode(json1);
      expect(parsed1['theme']['name'], equals('light'));
      
      // Switch to dark theme
      controller.setTheme(MindMapTheme.dark);
      
      // Export with dark theme
      final json2 = controller.exportToJson();
      final parsed2 = jsonDecode(json2);
      expect(parsed2['theme']['name'], equals('dark'));
      
      controller.dispose();
    });
    
    test('Exported JSON can be saved and loaded back', () {
      // Create and populate a mind map
      final originalController = MindMapController(
        initialData: MindMapData.empty(rootTopic: 'Original'),
      );
      
      final rootId = originalController.getData().nodeData.id;
      originalController.addChildNode(rootId, topic: 'Child A');
      originalController.addChildNode(rootId, topic: 'Child B');
      
      // Export to JSON string (simulating save to file)
      final savedJson = originalController.exportToJson();
      
      // Simulate loading from file
      final parsed = jsonDecode(savedJson);
      final loadedData = MindMapData.fromJson(parsed);
      
      // Create a new controller with loaded data
      final loadedController = MindMapController(
        initialData: loadedData,
      );
      
      // Verify the loaded data matches the original
      final originalData = originalController.getData();
      final loadedDataFromController = loadedController.getData();
      
      expect(
        loadedDataFromController.nodeData.topic,
        equals(originalData.nodeData.topic),
      );
      expect(
        loadedDataFromController.nodeData.children.length,
        equals(originalData.nodeData.children.length),
      );
      expect(
        loadedDataFromController.nodeData.children[0].topic,
        equals(originalData.nodeData.children[0].topic),
      );
      expect(
        loadedDataFromController.nodeData.children[1].topic,
        equals(originalData.nodeData.children[1].topic),
      );
      
      originalController.dispose();
      loadedController.dispose();
    });
  });
}
