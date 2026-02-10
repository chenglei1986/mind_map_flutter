import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';
import '../helpers/generators.dart';

void main() {
  group('Data Model Property Tests', () {
    const iterations = 100;

    // Feature: mind-map-flutter, Property 1: UUID uniqueness
    test('Property 1: UUID uniqueness - all node IDs should be unique', () {
      for (int i = 0; i < iterations; i++) {
        final mindMapData = generateRandomMindMapData(
          maxDepth: 3,
          maxChildren: 4,
        );

        // Collect all node IDs
        final allIds = collectAllNodeIds(mindMapData.nodeData);

        // Check that all IDs are unique (set size equals list size)
        final idList = allIds.toList();
        expect(
          allIds.length,
          equals(idList.length),
          reason: 'All node IDs should be unique',
        );

        // Verify each ID is a valid UUID format (basic check)
        for (final id in allIds) {
          expect(
            id.length,
            greaterThan(0),
            reason: 'Node ID should not be empty',
          );
          // UUID v4 format check (8-4-4-4-12 characters)
          final uuidPattern = RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          );
          expect(
            uuidPattern.hasMatch(id),
            isTrue,
            reason: 'Node ID should be a valid UUID: $id',
          );
        }
      }
    });

    // Feature: mind-map-flutter, Property 27: Data export completeness
    test('Property 27: Data export completeness - exported JSON should contain all data', () {
      for (int i = 0; i < iterations; i++) {
        final mindMapData = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 3,
          maxArrows: 2,
          maxSummaries: 2,
        );

        final json = mindMapData.toJson();

        // Verify all required fields are present
        expect(json.containsKey('nodeData'), isTrue,
            reason: 'Exported JSON should contain nodeData');
        expect(json.containsKey('direction'), isTrue,
            reason: 'Exported JSON should contain direction');
        expect(json.containsKey('theme'), isTrue,
            reason: 'Exported JSON should contain theme');

        // Verify arrows are included if present
        if (mindMapData.arrows.isNotEmpty) {
          expect(json.containsKey('arrows'), isTrue,
              reason: 'Exported JSON should contain arrows when present');
          expect(json['arrows'], hasLength(mindMapData.arrows.length),
              reason: 'All arrows should be exported');
        }

        // Verify summaries are included if present
        if (mindMapData.summaries.isNotEmpty) {
          expect(json.containsKey('summaries'), isTrue,
              reason: 'Exported JSON should contain summaries when present');
          expect(json['summaries'], hasLength(mindMapData.summaries.length),
              reason: 'All summaries should be exported');
        }

        // Verify node data structure
        final nodeDataJson = json['nodeData'] as Map<String, dynamic>;
        expect(nodeDataJson.containsKey('id'), isTrue,
            reason: 'Node data should contain id');
        expect(nodeDataJson.containsKey('topic'), isTrue,
            reason: 'Node data should contain topic');
        expect(nodeDataJson.containsKey('expanded'), isTrue,
            reason: 'Node data should contain expanded state');
      }
    });

    test('Property 28: Data import round trip - export then import should produce equivalent data', () {
      for (int i = 0; i < iterations; i++) {
        final original = generateRandomMindMapData(
          maxDepth: 2,
          maxChildren: 3,
          maxArrows: 2,
          maxSummaries: 1,
        );

        // Export to JSON
        final json = original.toJson();

        // Import from JSON
        final imported = MindMapData.fromJson(json);

        // Verify equivalence
        expect(imported.nodeData.id, equals(original.nodeData.id),
            reason: 'Root node ID should be preserved');
        expect(imported.nodeData.topic, equals(original.nodeData.topic),
            reason: 'Root node topic should be preserved');
        expect(imported.direction, equals(original.direction),
            reason: 'Direction should be preserved');
        expect(imported.arrows.length, equals(original.arrows.length),
            reason: 'Arrow count should be preserved');
        expect(imported.summaries.length, equals(original.summaries.length),
            reason: 'Summary count should be preserved');

        // Verify all node IDs are preserved
        final originalIds = collectAllNodeIds(original.nodeData);
        final importedIds = collectAllNodeIds(imported.nodeData);
        expect(importedIds, equals(originalIds),
            reason: 'All node IDs should be preserved in round trip');

        // Verify arrow IDs are preserved
        final originalArrowIds = original.arrows.map((a) => a.id).toSet();
        final importedArrowIds = imported.arrows.map((a) => a.id).toSet();
        expect(importedArrowIds, equals(originalArrowIds),
            reason: 'All arrow IDs should be preserved in round trip');

        // Verify summary IDs are preserved
        final originalSummaryIds = original.summaries.map((s) => s.id).toSet();
        final importedSummaryIds = imported.summaries.map((s) => s.id).toSet();
        expect(importedSummaryIds, equals(originalSummaryIds),
            reason: 'All summary IDs should be preserved in round trip');
      }
    });
  });
}
