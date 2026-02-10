import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/summary_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_controller.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_widget.dart';

void main() {
  group('Summary Creation Tests - New API', () {
    late MindMapController controller;
    late MindMapData testData;

    setUp(() {
      // Create test data with a parent node that has multiple children
      final child1 = NodeData.create(topic: 'Child 1');
      final child2 = NodeData.create(topic: 'Child 2');
      final child3 = NodeData.create(topic: 'Child 3');
      final child4 = NodeData.create(topic: 'Child 4');

      final parentNode = NodeData.create(
        topic: 'Parent',
        children: [child1, child2, child3, child4],
      );

      final rootNode = NodeData.create(topic: 'Root', children: [parentNode]);

      testData = MindMapData(nodeData: rootNode, theme: MindMapTheme.light);

      controller = MindMapController(initialData: testData);
    });

    test('should start summary creation mode', () {
      expect(controller.isSummaryCreationMode, false);

      controller.startSummaryCreationMode();

      expect(controller.isSummaryCreationMode, true);
      expect(controller.summarySelectedNodeIds, isEmpty);
    });

    test('should exit summary creation mode', () {
      controller.startSummaryCreationMode();
      expect(controller.isSummaryCreationMode, true);

      controller.exitSummaryCreationMode();

      expect(controller.isSummaryCreationMode, false);
      expect(controller.summarySelectedNodeIds, isEmpty);
    });

    test('should toggle node selection for summary', () {
      controller.startSummaryCreationMode();

      final parentNode = testData.nodeData.children.first;
      final child1 = parentNode.children[0];

      // Select first child
      controller.toggleSummaryNodeSelection(child1.id);
      expect(controller.summarySelectedNodeIds, contains(child1.id));
      expect(controller.summarySelectedNodeIds.length, 1);

      // Toggle again to deselect
      controller.toggleSummaryNodeSelection(child1.id);
      expect(controller.summarySelectedNodeIds, isEmpty);
    });

    test('should select multiple nodes for summary', () {
      controller.startSummaryCreationMode();

      final parentNode = testData.nodeData.children.first;
      final child1 = parentNode.children[0];
      final child2 = parentNode.children[1];
      final child3 = parentNode.children[2];

      controller.toggleSummaryNodeSelection(child1.id);
      controller.toggleSummaryNodeSelection(child2.id);
      controller.toggleSummaryNodeSelection(child3.id);

      expect(controller.summarySelectedNodeIds.length, 3);
      expect(controller.summarySelectedNodeIds, contains(child1.id));
      expect(controller.summarySelectedNodeIds, contains(child2.id));
      expect(controller.summarySelectedNodeIds, contains(child3.id));
    });

    test('should throw error when not in summary creation mode', () {
      final parentNode = testData.nodeData.children.first;
      final child1 = parentNode.children[0];

      expect(
        () => controller.toggleSummaryNodeSelection(child1.id),
        throwsA(isA<StateError>()),
      );
    });

    test('should create summary from selected nodes with common parent', () {
      controller.startSummaryCreationMode();

      final parentNode = testData.nodeData.children.first;
      final child1 = parentNode.children[0];
      final child2 = parentNode.children[1];
      final child3 = parentNode.children[2];

      // Select children 1, 2, and 3
      controller.toggleSummaryNodeSelection(child1.id);
      controller.toggleSummaryNodeSelection(child2.id);
      controller.toggleSummaryNodeSelection(child3.id);

      // Create summary
      controller.createSummaryFromSelection(label: 'Test Summary');

      // Verify summary was created
      final data = controller.getData();
      expect(data.summaries.length, 1);

      final summary = data.summaries.first;
      expect(summary.parentNodeId, parentNode.id);
      expect(summary.startIndex, 0);
      expect(summary.endIndex, 2);
      expect(summary.label, 'Test Summary');

      // Verify mode was exited
      expect(controller.isSummaryCreationMode, false);
    });

    test('should create summary with default label when not provided', () {
      controller.startSummaryCreationMode();

      final parentNode = testData.nodeData.children.first;
      final child1 = parentNode.children[0];
      final child2 = parentNode.children[1];

      controller.toggleSummaryNodeSelection(child1.id);
      controller.toggleSummaryNodeSelection(child2.id);

      controller.createSummaryFromSelection();

      final data = controller.getData();
      expect(data.summaries.length, 1);
      expect(data.summaries.first.label, controller.defaultSummaryLabel);
    });

    test('should handle non-consecutive node selection', () {
      controller.startSummaryCreationMode();

      final parentNode = testData.nodeData.children.first;
      final child1 = parentNode.children[0];
      final child3 = parentNode.children[2];
      final child4 = parentNode.children[3];

      // Select non-consecutive children (1, 3, 4)
      controller.toggleSummaryNodeSelection(child1.id);
      controller.toggleSummaryNodeSelection(child3.id);
      controller.toggleSummaryNodeSelection(child4.id);

      controller.createSummaryFromSelection();

      final data = controller.getData();
      expect(data.summaries.length, 1);

      final summary = data.summaries.first;
      expect(summary.parentNodeId, parentNode.id);
      // Should span from first selected (index 0) to last selected (index 3)
      expect(summary.startIndex, 0);
      expect(summary.endIndex, 3);
    });

    test('should emit SummaryCreatedEvent when summary is created', () {
      controller.startSummaryCreationMode();

      final parentNode = testData.nodeData.children.first;
      final child1 = parentNode.children[0];
      final child2 = parentNode.children[1];

      controller.toggleSummaryNodeSelection(child1.id);
      controller.toggleSummaryNodeSelection(child2.id);

      controller.createSummaryFromSelection();

      final event = controller.lastEvent;
      expect(event, isA<SummaryCreatedEvent>());

      final summaryEvent = event as SummaryCreatedEvent;
      expect(summaryEvent.parentNodeId, parentNode.id);
    });

    test('should throw error when creating summary without selected nodes', () {
      controller.startSummaryCreationMode();

      expect(
        () => controller.createSummaryFromSelection(),
        throwsA(isA<StateError>()),
      );
    });

    test('should create summary with single node selection', () {
      controller.startSummaryCreationMode();

      final parentNode = testData.nodeData.children.first;
      final child1 = parentNode.children[0];

      controller.toggleSummaryNodeSelection(child1.id);

      // Should succeed with single node (start and end index are the same)
      controller.createSummaryFromSelection();

      final data = controller.getData();
      expect(data.summaries.length, 1);

      final summary = data.summaries.first;
      expect(summary.startIndex, summary.endIndex);
    });

    test('should throw error when selected nodes have no common parent', () {
      controller.startSummaryCreationMode();

      final parentNode = testData.nodeData.children.first;
      final child1 = parentNode.children[0];

      // Select nodes from different branches (root and child)
      controller.toggleSummaryNodeSelection(testData.nodeData.id);
      controller.toggleSummaryNodeSelection(child1.id);

      expect(
        () => controller.createSummaryFromSelection(),
        throwsA(isA<StateError>()),
      );
    });

    test('should add summary directly', () {
      final parentNode = testData.nodeData.children.first;

      controller.addSummary(
        parentNodeId: parentNode.id,
        startIndex: 1,
        endIndex: 3,
        label: 'Direct Summary',
      );

      final data = controller.getData();
      expect(data.summaries.length, 1);

      final summary = data.summaries.first;
      expect(summary.parentNodeId, parentNode.id);
      expect(summary.startIndex, 1);
      expect(summary.endIndex, 3);
      expect(summary.label, 'Direct Summary');
    });

    test('should throw error when adding summary with invalid parent', () {
      expect(
        () => controller.addSummary(
          parentNodeId: 'invalid-id',
          startIndex: 0,
          endIndex: 1,
        ),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should throw error when adding summary with invalid indices', () {
      final parentNode = testData.nodeData.children.first;

      // Start index greater than end index
      expect(
        () => controller.addSummary(
          parentNodeId: parentNode.id,
          startIndex: 2,
          endIndex: 1,
        ),
        throwsA(isA<StateError>()),
      );

      // Negative start index
      expect(
        () => controller.addSummary(
          parentNodeId: parentNode.id,
          startIndex: -1,
          endIndex: 1,
        ),
        throwsA(isA<StateError>()),
      );

      // End index out of bounds
      expect(
        () => controller.addSummary(
          parentNodeId: parentNode.id,
          startIndex: 0,
          endIndex: 10,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('should remove summary', () {
      final parentNode = testData.nodeData.children.first;

      controller.addSummary(
        parentNodeId: parentNode.id,
        startIndex: 0,
        endIndex: 1,
      );

      expect(controller.getData().summaries.length, 1);

      final summaryId = controller.getData().summaries.first.id;
      controller.removeSummary(summaryId);

      expect(controller.getData().summaries.length, 0);
    });

    test('should throw error when removing non-existent summary', () {
      expect(
        () => controller.removeSummary('invalid-id'),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should update summary', () {
      final parentNode = testData.nodeData.children.first;

      controller.addSummary(
        parentNodeId: parentNode.id,
        startIndex: 0,
        endIndex: 1,
        label: 'Original',
      );

      final summary = controller.getData().summaries.first;
      final updatedSummary = summary.copyWith(label: 'Updated', endIndex: 2);

      controller.updateSummary(summary.id, updatedSummary);

      final data = controller.getData();
      expect(data.summaries.first.label, 'Updated');
      expect(data.summaries.first.endIndex, 2);
    });

    test('should throw error when updating non-existent summary', () {
      final summary = SummaryData.create(
        parentNodeId: 'test',
        startIndex: 0,
        endIndex: 1,
      );

      expect(
        () => controller.updateSummary('invalid-id', summary),
        throwsA(isA<InvalidNodeIdException>()),
      );
    });

    test('should get summary by ID', () {
      final parentNode = testData.nodeData.children.first;

      controller.addSummary(
        parentNodeId: parentNode.id,
        startIndex: 0,
        endIndex: 1,
        label: 'Test',
      );

      final summaryId = controller.getData().summaries.first.id;
      final summary = controller.getSummary(summaryId);

      expect(summary, isNotNull);
      expect(summary!.label, 'Test');
    });

    test('should return null for non-existent summary', () {
      final summary = controller.getSummary('invalid-id');
      expect(summary, null);
    });

    test('should create multiple summaries for same parent', () {
      final parentNode = testData.nodeData.children.first;

      controller.addSummary(
        parentNodeId: parentNode.id,
        startIndex: 0,
        endIndex: 1,
        label: 'Summary 1',
      );

      controller.addSummary(
        parentNodeId: parentNode.id,
        startIndex: 2,
        endIndex: 3,
        label: 'Summary 2',
      );

      final data = controller.getData();
      expect(data.summaries.length, 2);
      expect(data.summaries[0].label, 'Summary 1');
      expect(data.summaries[1].label, 'Summary 2');
    });

    test('should find minimum common parent for sibling nodes', () {
      controller.startSummaryCreationMode();

      final parentNode = testData.nodeData.children.first;
      final child1 = parentNode.children[0];
      final child2 = parentNode.children[1];

      controller.toggleSummaryNodeSelection(child1.id);
      controller.toggleSummaryNodeSelection(child2.id);

      controller.createSummaryFromSelection();

      final data = controller.getData();
      final summary = data.summaries.first;

      // Should find the parent node as the common parent
      expect(summary.parentNodeId, parentNode.id);
    });

    test('should clear selection after creating summary', () {
      controller.startSummaryCreationMode();

      final parentNode = testData.nodeData.children.first;
      final child1 = parentNode.children[0];
      final child2 = parentNode.children[1];

      controller.toggleSummaryNodeSelection(child1.id);
      controller.toggleSummaryNodeSelection(child2.id);

      expect(controller.summarySelectedNodeIds.length, 2);

      controller.createSummaryFromSelection();

      expect(controller.summarySelectedNodeIds, isEmpty);
      expect(controller.isSummaryCreationMode, false);
    });
  });
}
