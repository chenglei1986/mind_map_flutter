import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

void main() {
  group('Data Model Unit Tests', () {
    group('NodeData', () {
      test('copyWith should update only specified fields', () {
        final original = NodeData.create(
          topic: 'Original',
          expanded: true,
        );

        final updated = original.copyWith(
          topic: 'Updated',
        );

        expect(updated.topic, equals('Updated'));
        expect(updated.expanded, equals(true));
        expect(updated.id, equals(original.id));
      });

      test('copyWith should preserve children when not specified', () {
        final child1 = NodeData.create(topic: 'Child 1');
        final child2 = NodeData.create(topic: 'Child 2');
        final parent = NodeData.create(
          topic: 'Parent',
          children: [child1, child2],
        );

        final updated = parent.copyWith(topic: 'Updated Parent');

        expect(updated.children.length, equals(2));
        expect(updated.children[0].id, equals(child1.id));
        expect(updated.children[1].id, equals(child2.id));
      });

      test('addChild should add a child to the node', () {
        final parent = NodeData.create(topic: 'Parent');
        final child = NodeData.create(topic: 'Child');

        final updated = parent.addChild(child);

        expect(updated.children.length, equals(1));
        expect(updated.children[0].id, equals(child.id));
      });

      test('removeChild should remove a child by ID', () {
        final child1 = NodeData.create(topic: 'Child 1');
        final child2 = NodeData.create(topic: 'Child 2');
        final parent = NodeData.create(
          topic: 'Parent',
          children: [child1, child2],
        );

        final updated = parent.removeChild(child1.id);

        expect(updated.children.length, equals(1));
        expect(updated.children[0].id, equals(child2.id));
      });

      test('updateChild should update a specific child', () {
        final child1 = NodeData.create(topic: 'Child 1');
        final child2 = NodeData.create(topic: 'Child 2');
        final parent = NodeData.create(
          topic: 'Parent',
          children: [child1, child2],
        );

        final updatedChild1 = child1.copyWith(topic: 'Updated Child 1');
        final updated = parent.updateChild(child1.id, updatedChild1);

        expect(updated.children.length, equals(2));
        expect(updated.children[0].topic, equals('Updated Child 1'));
        expect(updated.children[1].topic, equals('Child 2'));
      });
    });

    group('JSON Serialization Round Trip', () {
      test('NodeData should serialize and deserialize correctly', () {
        final original = NodeData.create(
          topic: 'Test Node',
          expanded: false,
          tags: [TagData(text: 'tag1'), TagData(text: 'tag2')],
          icons: ['🎯', '⭐'],
          hyperLink: 'https://example.com',
          branchColor: Colors.blue,
          note: 'Test note',
        );

        final json = original.toJson();
        final deserialized = NodeData.fromJson(json);

        expect(deserialized.id, equals(original.id));
        expect(deserialized.topic, equals(original.topic));
        expect(deserialized.expanded, equals(original.expanded));
        expect(deserialized.tags.length, equals(2));
        expect(deserialized.icons.length, equals(2));
        expect(deserialized.hyperLink, equals(original.hyperLink));
        expect(deserialized.note, equals(original.note));
      });

      test('ArrowData should serialize and deserialize correctly', () {
        final original = ArrowData.create(
          fromNodeId: 'node1',
          toNodeId: 'node2',
          label: 'Test Arrow',
          bidirectional: true,
          delta1: const Offset(10, 20),
          delta2: const Offset(30, 40),
        );

        final json = original.toJson();
        final deserialized = ArrowData.fromJson(json);

        expect(deserialized.id, equals(original.id));
        expect(deserialized.fromNodeId, equals(original.fromNodeId));
        expect(deserialized.toNodeId, equals(original.toNodeId));
        expect(deserialized.label, equals(original.label));
        expect(deserialized.bidirectional, equals(original.bidirectional));
        expect(deserialized.delta1, equals(original.delta1));
        expect(deserialized.delta2, equals(original.delta2));
      });

      test('SummaryData should serialize and deserialize correctly', () {
        final original = SummaryData.create(
          parentNodeId: 'parent1',
          startIndex: 0,
          endIndex: 3,
          label: 'Test Summary',
        );

        final json = original.toJson();
        final deserialized = SummaryData.fromJson(json);

        expect(deserialized.id, equals(original.id));
        expect(deserialized.parentNodeId, equals(original.parentNodeId));
        expect(deserialized.startIndex, equals(original.startIndex));
        expect(deserialized.endIndex, equals(original.endIndex));
        expect(deserialized.label, equals(original.label));
      });

      test('MindMapData should serialize and deserialize correctly', () {
        final child1 = NodeData.create(topic: 'Child 1');
        final child2 = NodeData.create(topic: 'Child 2');
        final root = NodeData.create(
          topic: 'Root',
          children: [child1, child2],
        );

        final arrow = ArrowData.create(
          fromNodeId: root.id,
          toNodeId: child1.id,
        );

        final summary = SummaryData.create(
          parentNodeId: root.id,
          startIndex: 0,
          endIndex: 1,
        );

        final original = MindMapData(
          nodeData: root,
          arrows: [arrow],
          summaries: [summary],
          direction: LayoutDirection.left,
          theme: MindMapTheme.dark,
        );

        final json = original.toJson();
        final deserialized = MindMapData.fromJson(json);

        expect(deserialized.nodeData.id, equals(original.nodeData.id));
        expect(deserialized.arrows.length, equals(1));
        expect(deserialized.summaries.length, equals(1));
        expect(deserialized.direction, equals(LayoutDirection.left));
      });
    });

    group('Edge Cases', () {
      test('should handle empty data when importing', () {
        final json = <String, dynamic>{};
        final mindMapData = MindMapData.fromJson(json);

        expect(mindMapData.nodeData.topic, equals('中心主题'));
        expect(mindMapData.arrows, isEmpty);
        expect(mindMapData.summaries, isEmpty);
        expect(mindMapData.direction, equals(LayoutDirection.side));
      });

      test('should handle missing optional fields in NodeData', () {
        final json = {
          'id': 'test-id',
          'topic': 'Test',
        };

        final node = NodeData.fromJson(json);

        expect(node.id, equals('test-id'));
        expect(node.topic, equals('Test'));
        expect(node.expanded, isTrue); // default value
        expect(node.children, isEmpty);
        expect(node.tags, isEmpty);
        expect(node.icons, isEmpty);
        expect(node.hyperLink, isNull);
        expect(node.style, isNull);
      });

      test('should handle missing optional fields in ArrowData', () {
        final json = {
          'id': 'arrow-id',
          'fromNodeId': 'node1',
          'toNodeId': 'node2',
        };

        final arrow = ArrowData.fromJson(json);

        expect(arrow.id, equals('arrow-id'));
        expect(arrow.fromNodeId, equals('node1'));
        expect(arrow.toNodeId, equals('node2'));
        expect(arrow.label, isNull);
        expect(arrow.bidirectional, isFalse); // default value
        expect(arrow.delta1, equals(Offset.zero)); // default value
        expect(arrow.delta2, equals(Offset.zero)); // default value
      });

      test('should handle missing optional fields in SummaryData', () {
        final json = {
          'id': 'summary-id',
          'parentNodeId': 'parent1',
          'startIndex': 0,
          'endIndex': 2,
        };

        final summary = SummaryData.fromJson(json);

        expect(summary.id, equals('summary-id'));
        expect(summary.parentNodeId, equals('parent1'));
        expect(summary.startIndex, equals(0));
        expect(summary.endIndex, equals(2));
        expect(summary.label, isNull);
        expect(summary.style, isNull);
      });

      test('should create empty mind map with default root topic', () {
        final mindMapData = MindMapData.empty();

        expect(mindMapData.nodeData.topic, equals('中心主题'));
        expect(mindMapData.arrows, isEmpty);
        expect(mindMapData.summaries, isEmpty);
        expect(mindMapData.direction, equals(LayoutDirection.side));
        expect(mindMapData.theme, equals(MindMapTheme.light));
      });

      test('should create empty mind map with custom root topic', () {
        final mindMapData = MindMapData.empty(rootTopic: 'Custom Root');

        expect(mindMapData.nodeData.topic, equals('Custom Root'));
      });

      test('should create empty mind map with custom theme', () {
        final mindMapData = MindMapData.empty(theme: MindMapTheme.dark);

        expect(mindMapData.theme, equals(MindMapTheme.dark));
      });
    });

    group('Theme Tests', () {
      test('light theme should have correct properties', () {
        final theme = MindMapTheme.light;

        expect(theme.name, equals('light'));
        expect(theme.palette.length, greaterThan(0));
        expect(theme.variables.bgColor, equals(const Color(0xFFFFFFFF)));
      });

      test('dark theme should have correct properties', () {
        final theme = MindMapTheme.dark;

        expect(theme.name, equals('dark'));
        expect(theme.palette.length, greaterThan(0));
        expect(theme.variables.bgColor, equals(const Color(0xFF303030)));
      });
    });
  });
}
