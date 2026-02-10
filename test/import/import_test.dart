import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

/// Tests for import functionality
/// 
/// This test suite verifies that the system can import mind map data
/// from JSON-compatible structures using:
/// - MindMapData.fromJson() factory constructor
/// - MindMapController.refresh() method
void main() {
  group('Import Functionality Tests', () {
    group('MindMapData.fromJson()', () {
      test('should import complete mind map from JSON', () {
        // Arrange - Create JSON data
        final json = {
          'nodeData': {
            'id': 'root-1',
            'topic': 'Imported Root',
            'expanded': true,
            'children': [
              {
                'id': 'child-1',
                'topic': 'Child 1',
                'expanded': true,
              },
              {
                'id': 'child-2',
                'topic': 'Child 2',
                'expanded': true,
              },
            ],
          },
          'direction': 'side',
          'theme': {
            'name': 'light',
            'palette': [
              4294198070,
              4294945600,
              4293467747,
              4291681337,
              4290190364,
            ],
            'variables': {
              'nodeGapX': 50.0,
              'nodeGapY': 20.0,
              'mainGapX': 100.0,
              'mainGapY': 30.0,
              'mainColor': 4278190080,
              'mainBgColor': 4294967295,
              'color': 4278190080,
              'bgColor': 4294967295,
              'selectedColor': 4280391411,
              'accentColor': 4280391411,
              'rootColor': 4278190080,
              'rootBgColor': 4294967295,
              'rootBorderColor': 4280391411,
              'rootRadius': 8.0,
              'mainRadius': 4.0,
              'topicPaddingTop': 8.0,
              'topicPaddingRight': 12.0,
              'topicPaddingBottom': 8.0,
              'topicPaddingLeft': 12.0,
              'panelColor': 4278190080,
              'panelBgColor': 4294967295,
              'panelBorderColor': 4292730333,
              'mapPaddingTop': 20.0,
              'mapPaddingRight': 20.0,
              'mapPaddingBottom': 20.0,
              'mapPaddingLeft': 20.0,
            },
          },
        };

        // Act - Import from JSON
        final mindMapData = MindMapData.fromJson(json);

        // Assert - Verify imported data
        expect(mindMapData.nodeData.id, equals('root-1'));
        expect(mindMapData.nodeData.topic, equals('Imported Root'));
        expect(mindMapData.nodeData.children.length, equals(2));
        expect(mindMapData.nodeData.children[0].topic, equals('Child 1'));
        expect(mindMapData.nodeData.children[1].topic, equals('Child 2'));
        expect(mindMapData.direction, equals(LayoutDirection.side));
        expect(mindMapData.theme.name, equals('light'));
      });

      test('should import mind map with arrows from JSON', () {
        // Arrange - Create JSON data with arrows
        final json = {
          'nodeData': {
            'id': 'root-1',
            'topic': 'Root',
            'expanded': true,
            'children': [
              {'id': 'child-1', 'topic': 'Child 1', 'expanded': true},
              {'id': 'child-2', 'topic': 'Child 2', 'expanded': true},
            ],
          },
          'arrows': [
            {
              'id': 'arrow-1',
              'fromNodeId': 'child-1',
              'toNodeId': 'child-2',
              'label': 'Connection',
              'bidirectional': false,
              'delta1': {'dx': 0.0, 'dy': 0.0},
              'delta2': {'dx': 0.0, 'dy': 0.0},
            },
          ],
          'direction': 'side',
          'theme': {
            'name': 'light',
            'palette': [4294198070],
            'variables': {
              'nodeGapX': 50.0,
              'nodeGapY': 20.0,
              'mainGapX': 100.0,
              'mainGapY': 30.0,
              'mainColor': 4278190080,
              'mainBgColor': 4294967295,
              'color': 4278190080,
              'bgColor': 4294967295,
              'selectedColor': 4280391411,
              'accentColor': 4280391411,
              'rootColor': 4278190080,
              'rootBgColor': 4294967295,
              'rootBorderColor': 4280391411,
              'rootRadius': 8.0,
              'mainRadius': 4.0,
              'topicPaddingTop': 8.0,
              'topicPaddingRight': 12.0,
              'topicPaddingBottom': 8.0,
              'topicPaddingLeft': 12.0,
              'panelColor': 4278190080,
              'panelBgColor': 4294967295,
              'panelBorderColor': 4292730333,
              'mapPaddingTop': 20.0,
              'mapPaddingRight': 20.0,
              'mapPaddingBottom': 20.0,
              'mapPaddingLeft': 20.0,
            },
          },
        };

        // Act - Import from JSON
        final mindMapData = MindMapData.fromJson(json);

        // Assert - Verify arrows are imported
        expect(mindMapData.arrows.length, equals(1));
        expect(mindMapData.arrows[0].id, equals('arrow-1'));
        expect(mindMapData.arrows[0].fromNodeId, equals('child-1'));
        expect(mindMapData.arrows[0].toNodeId, equals('child-2'));
        expect(mindMapData.arrows[0].label, equals('Connection'));
      });

      test('should import mind map with summaries from JSON', () {
        // Arrange - Create JSON data with summaries
        final json = {
          'nodeData': {
            'id': 'root-1',
            'topic': 'Root',
            'expanded': true,
            'children': [
              {'id': 'child-1', 'topic': 'Child 1', 'expanded': true},
              {'id': 'child-2', 'topic': 'Child 2', 'expanded': true},
              {'id': 'child-3', 'topic': 'Child 3', 'expanded': true},
            ],
          },
          'summaries': [
            {
              'id': 'summary-1',
              'parentNodeId': 'root-1',
              'startIndex': 0,
              'endIndex': 1,
              'label': 'Group 1',
            },
          ],
          'direction': 'side',
          'theme': {
            'name': 'light',
            'palette': [4294198070],
            'variables': {
              'nodeGapX': 50.0,
              'nodeGapY': 20.0,
              'mainGapX': 100.0,
              'mainGapY': 30.0,
              'mainColor': 4278190080,
              'mainBgColor': 4294967295,
              'color': 4278190080,
              'bgColor': 4294967295,
              'selectedColor': 4280391411,
              'accentColor': 4280391411,
              'rootColor': 4278190080,
              'rootBgColor': 4294967295,
              'rootBorderColor': 4280391411,
              'rootRadius': 8.0,
              'mainRadius': 4.0,
              'topicPaddingTop': 8.0,
              'topicPaddingRight': 12.0,
              'topicPaddingBottom': 8.0,
              'topicPaddingLeft': 12.0,
              'panelColor': 4278190080,
              'panelBgColor': 4294967295,
              'panelBorderColor': 4292730333,
              'mapPaddingTop': 20.0,
              'mapPaddingRight': 20.0,
              'mapPaddingBottom': 20.0,
              'mapPaddingLeft': 20.0,
            },
          },
        };

        // Act - Import from JSON
        final mindMapData = MindMapData.fromJson(json);

        // Assert - Verify summaries are imported
        expect(mindMapData.summaries.length, equals(1));
        expect(mindMapData.summaries[0].id, equals('summary-1'));
        expect(mindMapData.summaries[0].parentNodeId, equals('root-1'));
        expect(mindMapData.summaries[0].startIndex, equals(0));
        expect(mindMapData.summaries[0].endIndex, equals(1));
        expect(mindMapData.summaries[0].label, equals('Group 1'));
      });

      test('should handle missing optional fields with defaults', () {
        // Arrange - Create minimal JSON data
        final json = {
          'nodeData': {
            'id': 'root-1',
            'topic': 'Root',
          },
        };

        // Act - Import from JSON
        final mindMapData = MindMapData.fromJson(json);

        // Assert - Verify defaults are applied
        expect(mindMapData.nodeData.id, equals('root-1'));
        expect(mindMapData.nodeData.topic, equals('Root'));
        expect(mindMapData.arrows, isEmpty);
        expect(mindMapData.summaries, isEmpty);
        expect(mindMapData.direction, equals(LayoutDirection.side));
        expect(mindMapData.theme, equals(MindMapTheme.light));
      });

      test('should handle completely empty JSON with defaults', () {
        // Arrange - Create empty JSON
        final json = <String, dynamic>{};

        // Act - Import from JSON
        final mindMapData = MindMapData.fromJson(json);

        // Assert - Verify defaults are applied
        expect(mindMapData.nodeData.topic, equals('中心主题'));
        expect(mindMapData.arrows, isEmpty);
        expect(mindMapData.summaries, isEmpty);
        expect(mindMapData.direction, equals(LayoutDirection.side));
        expect(mindMapData.theme, equals(MindMapTheme.light));
      });

      test('should import and export round-trip correctly', () {
        // Arrange - Create original data
        final originalNode = NodeData.create(topic: 'Original Root');
        final child1 = NodeData.create(topic: 'Child 1');
        final child2 = NodeData.create(topic: 'Child 2');
        final nodeWithChildren = originalNode.copyWith(
          children: [child1, child2],
        );

        final arrow = ArrowData.create(
          fromNodeId: child1.id,
          toNodeId: child2.id,
          label: 'Test Arrow',
        );

        final originalData = MindMapData(
          nodeData: nodeWithChildren,
          arrows: [arrow],
          direction: LayoutDirection.left,
          theme: MindMapTheme.dark,
        );

        // Act - Export to JSON and import back
        final json = originalData.toJson();
        final importedData = MindMapData.fromJson(json);

        // Assert - Verify data is preserved
        expect(importedData.nodeData.topic, equals(originalData.nodeData.topic));
        expect(importedData.nodeData.children.length,
            equals(originalData.nodeData.children.length));
        expect(importedData.arrows.length, equals(originalData.arrows.length));
        expect(importedData.arrows[0].label, equals(originalData.arrows[0].label));
        expect(importedData.direction, equals(originalData.direction));
        expect(importedData.theme.name, equals(originalData.theme.name));
      });
    });

    group('MindMapController.refresh()', () {
      test('should refresh controller with new data', () {
        // Arrange - Create initial controller
        final initialData = MindMapData.empty(rootTopic: 'Initial Root');
        final controller = MindMapController(initialData: initialData);

        // Create new data to import
        final newNode = NodeData.create(topic: 'New Root');
        final child = NodeData.create(topic: 'New Child');
        final newNodeWithChild = newNode.copyWith(children: [child]);
        final newData = MindMapData(
          nodeData: newNodeWithChild,
          theme: MindMapTheme.dark,
        );

        // Act - Refresh with new data
        controller.refresh(newData);

        // Assert - Verify controller has new data
        final currentData = controller.getData();
        expect(currentData.nodeData.topic, equals('New Root'));
        expect(currentData.nodeData.children.length, equals(1));
        expect(currentData.nodeData.children[0].topic, equals('New Child'));
        expect(currentData.theme.name, equals('dark'));
      });

      test('should clear selection when refreshing', () {
        // Arrange - Create controller with data
        final rootNode = NodeData.create(topic: 'Root');
        final child = NodeData.create(topic: 'Child');
        final nodeWithChild = rootNode.copyWith(children: [child]);
        final initialData = MindMapData(
          nodeData: nodeWithChild,
          theme: MindMapTheme.light,
        );
        final controller = MindMapController(initialData: initialData);

        // Select a node
        controller.selectionManager.selectNode(child.id);
        expect(controller.getSelectedNodeIds(), isNotEmpty);

        // Act - Refresh with new data
        final newData = MindMapData.empty(rootTopic: 'New Root');
        controller.refresh(newData);

        // Assert - Selection should be cleared
        expect(controller.getSelectedNodeIds(), isEmpty);
      });

      test('should clear history when refreshing', () {
        // Arrange - Create controller with undo enabled
        final initialData = MindMapData.empty(rootTopic: 'Root');
        final controller = MindMapController(
          initialData: initialData,
          config: MindMapConfig(allowUndo: true),
        );

        // Perform an operation to create history
        controller.addChildNode(initialData.nodeData.id, topic: 'Child');
        expect(controller.canUndo(), isTrue);

        // Act - Refresh with new data
        final newData = MindMapData.empty(rootTopic: 'New Root');
        controller.refresh(newData);

        // Assert - History should be cleared
        expect(controller.canUndo(), isFalse);
        expect(controller.canRedo(), isFalse);
      });

      test('should clear last event when refreshing', () {
        // Arrange - Create controller
        final initialData = MindMapData.empty(rootTopic: 'Root');
        final controller = MindMapController(initialData: initialData);

        // Perform an operation to create an event
        controller.addChildNode(initialData.nodeData.id, topic: 'Child');
        expect(controller.lastEvent, isNotNull);

        // Act - Refresh with new data
        final newData = MindMapData.empty(rootTopic: 'New Root');
        controller.refresh(newData);

        // Assert - Last event should be cleared
        expect(controller.lastEvent, isNull);
      });

      test('should import from JSON string and refresh controller', () {
        // Arrange - Create controller
        final initialData = MindMapData.empty(rootTopic: 'Initial');
        final controller = MindMapController(initialData: initialData);

        // Create JSON string (simulating loading from file)
        final jsonString = '''
        {
          "nodeData": {
            "id": "imported-root",
            "topic": "Imported Root",
            "expanded": true,
            "children": [
              {
                "id": "imported-child",
                "topic": "Imported Child",
                "expanded": true
              }
            ]
          },
          "direction": "side",
          "theme": {
            "name": "dark",
            "palette": [4294198070],
            "variables": {
              "nodeGapX": 50.0,
              "nodeGapY": 20.0,
              "mainGapX": 100.0,
              "mainGapY": 30.0,
              "mainColor": 4294967295,
              "mainBgColor": 4278190080,
              "color": 4294967295,
              "bgColor": 4278190080,
              "selectedColor": 4280391411,
              "accentColor": 4280391411,
              "rootColor": 4294967295,
              "rootBgColor": 4278190080,
              "rootBorderColor": 4280391411,
              "rootRadius": 8.0,
              "mainRadius": 4.0,
              "topicPaddingTop": 8.0,
              "topicPaddingRight": 12.0,
              "topicPaddingBottom": 8.0,
              "topicPaddingLeft": 12.0,
              "panelColor": 4294967295,
              "panelBgColor": 4278190080,
              "panelBorderColor": 4292730333,
              "mapPaddingTop": 20.0,
              "mapPaddingRight": 20.0,
              "mapPaddingBottom": 20.0,
              "mapPaddingLeft": 20.0
            }
          }
        }
        ''';

        // Act - Parse JSON and refresh controller
        final json = jsonDecode(jsonString);
        final importedData = MindMapData.fromJson(json);
        controller.refresh(importedData);

        // Assert - Verify controller has imported data
        final currentData = controller.getData();
        expect(currentData.nodeData.id, equals('imported-root'));
        expect(currentData.nodeData.topic, equals('Imported Root'));
        expect(currentData.nodeData.children.length, equals(1));
        expect(currentData.nodeData.children[0].topic, equals('Imported Child'));
        expect(currentData.theme.name, equals('dark'));
      });
    });
  });
}
