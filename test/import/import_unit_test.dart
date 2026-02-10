import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

/// Unit tests for import functionality
/// 
/// This test suite verifies:
/// - Empty data handling (edge cases)
/// - Creating empty mind maps (examples)
void main() {
  group('Import Functionality Unit Tests', () {
    group('Empty Data Handling (Edge Cases)', () {
      test('should handle completely empty JSON object', () {
        // Arrange - Create completely empty JSON
        final json = <String, dynamic>{};

        // Act - Import from JSON
        final mindMapData = MindMapData.fromJson(json);

        // Assert - Verify defaults are applied
        expect(mindMapData.nodeData.topic, equals('中心主题'),
            reason: 'Should use default Chinese root topic');
        expect(mindMapData.arrows, isEmpty,
            reason: 'Should have no arrows');
        expect(mindMapData.summaries, isEmpty,
            reason: 'Should have no summaries');
        expect(mindMapData.direction, equals(LayoutDirection.side),
            reason: 'Should use default side layout direction');
        expect(mindMapData.theme, equals(MindMapTheme.light),
            reason: 'Should use default light theme');
      });

      test('should handle JSON with only nodeData', () {
        // Arrange - Create JSON with minimal nodeData
        final json = {
          'nodeData': {
            'id': 'root-1',
            'topic': 'Minimal Root',
          },
        };

        // Act - Import from JSON
        final mindMapData = MindMapData.fromJson(json);

        // Assert - Verify data is imported and defaults are applied
        expect(mindMapData.nodeData.id, equals('root-1'));
        expect(mindMapData.nodeData.topic, equals('Minimal Root'));
        expect(mindMapData.nodeData.expanded, isTrue,
            reason: 'Should default to expanded');
        expect(mindMapData.nodeData.children, isEmpty,
            reason: 'Should have no children');
        expect(mindMapData.arrows, isEmpty);
        expect(mindMapData.summaries, isEmpty);
        expect(mindMapData.direction, equals(LayoutDirection.side));
        expect(mindMapData.theme, equals(MindMapTheme.light));
      });

      test('should handle null values in JSON', () {
        // Arrange - Create JSON with explicit null values
        final json = {
          'nodeData': {
            'id': 'root-1',
            'topic': 'Root',
            'style': null,
            'hyperLink': null,
            'note': null,
          },
          'arrows': null,
          'summaries': null,
        };

        // Act - Import from JSON
        final mindMapData = MindMapData.fromJson(json);

        // Assert - Verify nulls are handled correctly
        expect(mindMapData.nodeData.id, equals('root-1'));
        expect(mindMapData.nodeData.style, isNull);
        expect(mindMapData.nodeData.hyperLink, isNull);
        expect(mindMapData.nodeData.note, isNull);
        expect(mindMapData.arrows, isEmpty,
            reason: 'Null arrows should become empty list');
        expect(mindMapData.summaries, isEmpty,
            reason: 'Null summaries should become empty list');
      });

      test('should handle empty arrays in JSON', () {
        // Arrange - Create JSON with empty arrays
        final json = {
          'nodeData': {
            'id': 'root-1',
            'topic': 'Root',
            'children': [],
            'tags': [],
            'icons': [],
          },
          'arrows': [],
          'summaries': [],
        };

        // Act - Import from JSON
        final mindMapData = MindMapData.fromJson(json);

        // Assert - Verify empty arrays are preserved
        expect(mindMapData.nodeData.children, isEmpty);
        expect(mindMapData.nodeData.tags, isEmpty);
        expect(mindMapData.nodeData.icons, isEmpty);
        expect(mindMapData.arrows, isEmpty);
        expect(mindMapData.summaries, isEmpty);
      });

      test('should handle missing optional fields in nested NodeData', () {
        // Arrange - Create JSON with nested nodes missing optional fields
        final json = {
          'nodeData': {
            'id': 'root-1',
            'topic': 'Root',
            'children': [
              {
                'id': 'child-1',
                'topic': 'Child 1',
                // Missing: expanded, style, tags, icons, etc.
              },
              {
                'id': 'child-2',
                'topic': 'Child 2',
                // Missing: expanded, style, tags, icons, etc.
              },
            ],
          },
        };

        // Act - Import from JSON
        final mindMapData = MindMapData.fromJson(json);

        // Assert - Verify defaults are applied to nested nodes
        expect(mindMapData.nodeData.children.length, equals(2));
        
        final child1 = mindMapData.nodeData.children[0];
        expect(child1.id, equals('child-1'));
        expect(child1.topic, equals('Child 1'));
        expect(child1.expanded, isTrue, reason: 'Should default to expanded');
        expect(child1.children, isEmpty);
        expect(child1.tags, isEmpty);
        expect(child1.icons, isEmpty);
        
        final child2 = mindMapData.nodeData.children[1];
        expect(child2.id, equals('child-2'));
        expect(child2.topic, equals('Child 2'));
        expect(child2.expanded, isTrue);
      });

      test('should handle invalid direction value with default', () {
        // Arrange - Create JSON with invalid direction
        final json = {
          'nodeData': {
            'id': 'root-1',
            'topic': 'Root',
          },
          'direction': 'invalid-direction',
        };

        // Act - Import from JSON
        final mindMapData = MindMapData.fromJson(json);

        // Assert - Verify default direction is used
        expect(mindMapData.direction, equals(LayoutDirection.side),
            reason: 'Invalid direction should fall back to default');
      });

      test('should handle missing theme with default light theme', () {
        // Arrange - Create JSON without theme
        final json = {
          'nodeData': {
            'id': 'root-1',
            'topic': 'Root',
          },
          'theme': null,
        };

        // Act - Import from JSON
        final mindMapData = MindMapData.fromJson(json);

        // Assert - Verify default light theme is used
        expect(mindMapData.theme, equals(MindMapTheme.light));
        expect(mindMapData.theme.name, equals('light'));
      });
    });

    group('Creating Empty Mind Maps (Examples)', () {
      test('should create empty mind map with default root topic', () {
        // Act - Create empty mind map with defaults
        final mindMapData = MindMapData.empty();

        // Assert - Verify default values
        expect(mindMapData.nodeData.topic, equals('中心主题'),
            reason: 'Should use default Chinese root topic');
        expect(mindMapData.nodeData.children, isEmpty,
            reason: 'Should have no children');
        expect(mindMapData.nodeData.expanded, isTrue,
            reason: 'Root should be expanded by default');
        expect(mindMapData.arrows, isEmpty,
            reason: 'Should have no arrows');
        expect(mindMapData.summaries, isEmpty,
            reason: 'Should have no summaries');
        expect(mindMapData.direction, equals(LayoutDirection.side),
            reason: 'Should use default side layout');
        expect(mindMapData.theme, equals(MindMapTheme.light),
            reason: 'Should use default light theme');
      });

      test('should create empty mind map with custom root topic', () {
        // Act - Create empty mind map with custom root topic
        final mindMapData = MindMapData.empty(rootTopic: 'My Project');

        // Assert - Verify custom root topic is used
        expect(mindMapData.nodeData.topic, equals('My Project'));
        expect(mindMapData.nodeData.children, isEmpty);
        expect(mindMapData.arrows, isEmpty);
        expect(mindMapData.summaries, isEmpty);
        expect(mindMapData.direction, equals(LayoutDirection.side));
        expect(mindMapData.theme, equals(MindMapTheme.light));
      });

      test('should create empty mind map with custom theme', () {
        // Act - Create empty mind map with dark theme
        final mindMapData = MindMapData.empty(
          rootTopic: 'Dark Project',
          theme: MindMapTheme.dark,
        );

        // Assert - Verify custom theme is used
        expect(mindMapData.nodeData.topic, equals('Dark Project'));
        expect(mindMapData.theme, equals(MindMapTheme.dark));
        expect(mindMapData.theme.name, equals('dark'));
      });

      test('should create empty mind map with English root topic', () {
        // Act - Create empty mind map with English root topic
        final mindMapData = MindMapData.empty(rootTopic: 'Central Idea');

        // Assert - Verify English root topic is used
        expect(mindMapData.nodeData.topic, equals('Central Idea'));
      });

      test('should create empty mind map with empty string root topic', () {
        // Act - Create empty mind map with empty string
        final mindMapData = MindMapData.empty(rootTopic: '');

        // Assert - Verify empty string is accepted
        expect(mindMapData.nodeData.topic, equals(''));
      });

      test('should create multiple independent empty mind maps', () {
        // Act - Create multiple empty mind maps
        final mindMap1 = MindMapData.empty(rootTopic: 'Project 1');
        final mindMap2 = MindMapData.empty(rootTopic: 'Project 2');
        final mindMap3 = MindMapData.empty(rootTopic: 'Project 3');

        // Assert - Verify each has unique root node ID
        expect(mindMap1.nodeData.id, isNot(equals(mindMap2.nodeData.id)),
            reason: 'Each mind map should have unique root ID');
        expect(mindMap2.nodeData.id, isNot(equals(mindMap3.nodeData.id)),
            reason: 'Each mind map should have unique root ID');
        expect(mindMap1.nodeData.id, isNot(equals(mindMap3.nodeData.id)),
            reason: 'Each mind map should have unique root ID');

        // Verify topics are different
        expect(mindMap1.nodeData.topic, equals('Project 1'));
        expect(mindMap2.nodeData.topic, equals('Project 2'));
        expect(mindMap3.nodeData.topic, equals('Project 3'));
      });

      test('should create empty mind map that can be exported to JSON', () {
        // Arrange - Create empty mind map
        final mindMapData = MindMapData.empty(rootTopic: 'Test Export');

        // Act - Export to JSON
        final json = mindMapData.toJson();

        // Assert - Verify JSON structure
        expect(json, isA<Map<String, dynamic>>());
        expect(json['nodeData'], isNotNull);
        expect(json['nodeData']['topic'], equals('Test Export'));
        expect(json['direction'], isNotNull);
        expect(json['theme'], isNotNull);
      });

      test('should create empty mind map that can be round-tripped', () {
        // Arrange - Create empty mind map
        final original = MindMapData.empty(
          rootTopic: 'Round Trip Test',
          theme: MindMapTheme.dark,
        );

        // Act - Export to JSON and import back
        final json = original.toJson();
        final imported = MindMapData.fromJson(json);

        // Assert - Verify data is preserved
        expect(imported.nodeData.topic, equals(original.nodeData.topic));
        expect(imported.theme.name, equals(original.theme.name));
        expect(imported.direction, equals(original.direction));
        expect(imported.arrows, isEmpty);
        expect(imported.summaries, isEmpty);
      });
    });

    group('Integration with Controller', () {
      test('should create controller with empty mind map', () {
        // Arrange - Create empty mind map
        final mindMapData = MindMapData.empty(rootTopic: 'Controller Test');

        // Act - Create controller with empty mind map
        final controller = MindMapController(initialData: mindMapData);

        // Assert - Verify controller is initialized correctly
        final data = controller.getData();
        expect(data.nodeData.topic, equals('Controller Test'));
        expect(data.nodeData.children, isEmpty);
      });

      test('should refresh controller with empty mind map', () {
        // Arrange - Create controller with initial data
        final initialData = MindMapData.empty(rootTopic: 'Initial');
        final controller = MindMapController(initialData: initialData);

        // Add some data
        controller.addChildNode(initialData.nodeData.id, topic: 'Child');

        // Act - Refresh with new empty mind map
        final newData = MindMapData.empty(rootTopic: 'New Empty');
        controller.refresh(newData);

        // Assert - Verify controller has new empty data
        final data = controller.getData();
        expect(data.nodeData.topic, equals('New Empty'));
        expect(data.nodeData.children, isEmpty,
            reason: 'Should have no children after refresh');
      });
    });
  });
}
