import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

void main() {
  group('JSON Export Tests', () {
    test('exportToJson should return valid JSON string', () {
      // Create a simple mind map
      final rootNode = NodeData.create(topic: 'Root');
      final child1 = NodeData.create(topic: 'Child 1');
      final child2 = NodeData.create(topic: 'Child 2');
      final rootWithChildren = rootNode.copyWith(
        children: [child1, child2],
      );
      
      final mindMapData = MindMapData(
        nodeData: rootWithChildren,
        theme: MindMapTheme.light,
      );
      
      final controller = MindMapController(
        initialData: mindMapData,
      );
      
      // Export to JSON
      final jsonString = controller.exportToJson();
      
      // Verify it's a valid JSON string
      expect(jsonString, isNotEmpty);
      
      // Parse the JSON to verify it's valid
      final parsed = jsonDecode(jsonString);
      expect(parsed, isA<Map<String, dynamic>>());
      
      // Verify required fields are present
      expect(parsed['nodeData'], isNotNull);
      expect(parsed['direction'], isNotNull);
      expect(parsed['theme'], isNotNull);
    });
    
    test('exportToJson should include all data - nodes, arrows, summaries', () {
      // Create a mind map with all features
      final rootNode = NodeData.create(topic: 'Root');
      final child1 = NodeData.create(topic: 'Child 1');
      final child2 = NodeData.create(topic: 'Child 2');
      final child3 = NodeData.create(topic: 'Child 3');
      
      final rootWithChildren = rootNode.copyWith(
        children: [child1, child2, child3],
      );
      
      // Create an arrow
      final arrow = ArrowData.create(
        fromNodeId: child1.id,
        toNodeId: child2.id,
        label: 'Test Arrow',
      );
      
      // Create a summary
      final summary = SummaryData.create(
        parentNodeId: rootNode.id,
        startIndex: 0,
        endIndex: 1,
        label: 'Test Summary',
      );
      
      final mindMapData = MindMapData(
        nodeData: rootWithChildren,
        arrows: [arrow],
        summaries: [summary],
        direction: LayoutDirection.side,
        theme: MindMapTheme.dark,
      );
      
      final controller = MindMapController(
        initialData: mindMapData,
      );
      
      // Export to JSON
      final jsonString = controller.exportToJson();
      final parsed = jsonDecode(jsonString);
      
      // Verify all data is included
      expect(parsed['nodeData'], isNotNull);
      expect(parsed['nodeData']['topic'], equals('Root'));
      expect(parsed['nodeData']['children'], isNotNull);
      expect(parsed['nodeData']['children'], hasLength(3));
      
      // Verify arrows are included
      expect(parsed['arrows'], isNotNull);
      expect(parsed['arrows'], hasLength(1));
      expect(parsed['arrows'][0]['label'], equals('Test Arrow'));
      
      // Verify summaries are included
      expect(parsed['summaries'], isNotNull);
      expect(parsed['summaries'], hasLength(1));
      expect(parsed['summaries'][0]['label'], equals('Test Summary'));
      
      // Verify direction and theme
      expect(parsed['direction'], equals('side'));
      expect(parsed['theme'], isNotNull);
      expect(parsed['theme']['name'], equals('dark'));
    });
    
    test('exportToJson should produce JSON that can be imported back', () {
      // Create a complex mind map
      final rootNode = NodeData.create(topic: 'Root');
      final child1 = NodeData.create(topic: 'Child 1');
      final child2 = NodeData.create(topic: 'Child 2');
      
      final rootWithChildren = rootNode.copyWith(
        children: [child1, child2],
      );
      
      final arrow = ArrowData.create(
        fromNodeId: child1.id,
        toNodeId: child2.id,
      );
      
      final originalData = MindMapData(
        nodeData: rootWithChildren,
        arrows: [arrow],
        direction: LayoutDirection.left,
        theme: MindMapTheme.light,
      );
      
      final controller = MindMapController(
        initialData: originalData,
      );
      
      // Export to JSON
      final jsonString = controller.exportToJson();
      
      // Import back from JSON
      final parsed = jsonDecode(jsonString);
      final importedData = MindMapData.fromJson(parsed);
      
      // Verify the imported data matches the original
      expect(importedData.nodeData.topic, equals(originalData.nodeData.topic));
      expect(importedData.nodeData.children.length, 
             equals(originalData.nodeData.children.length));
      expect(importedData.arrows.length, equals(originalData.arrows.length));
      expect(importedData.direction, equals(originalData.direction));
      expect(importedData.theme.name, equals(originalData.theme.name));
    });
    
    test('exportToJson should handle empty arrows and summaries', () {
      // Create a simple mind map without arrows or summaries
      final rootNode = NodeData.create(topic: 'Root');
      
      final mindMapData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
      
      final controller = MindMapController(
        initialData: mindMapData,
      );
      
      // Export to JSON
      final jsonString = controller.exportToJson();
      final parsed = jsonDecode(jsonString);
      
      // Verify structure is correct
      expect(parsed['nodeData'], isNotNull);
      expect(parsed['direction'], isNotNull);
      expect(parsed['theme'], isNotNull);
      
      // Empty arrays should not be included (as per toJson implementation)
      // or should be empty arrays
      if (parsed.containsKey('arrows')) {
        expect(parsed['arrows'], isEmpty);
      }
      if (parsed.containsKey('summaries')) {
        expect(parsed['summaries'], isEmpty);
      }
    });
    
    test('exportToJson should format JSON with indentation', () {
      // Create a simple mind map
      final rootNode = NodeData.create(topic: 'Root');
      
      final mindMapData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
      
      final controller = MindMapController(
        initialData: mindMapData,
      );
      
      // Export to JSON
      final jsonString = controller.exportToJson();
      
      // Verify the JSON is formatted with indentation (pretty printed)
      expect(jsonString.contains('\n'), isTrue);
      expect(jsonString.contains('  '), isTrue);
    });
  });
}
