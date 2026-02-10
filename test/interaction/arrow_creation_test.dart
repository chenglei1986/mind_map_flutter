import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../lib/src/models/mind_map_data.dart';
import '../../lib/src/models/node_data.dart';
import '../../lib/src/models/mind_map_theme.dart';
import '../../lib/src/widgets/mind_map_controller.dart';
import '../../lib/src/widgets/mind_map_widget.dart';

void main() {
  group('Arrow Creation and Editing', () {
    late MindMapController controller;
    late MindMapData testData;

    setUp(() {
      // Create test data with a simple tree
      final root = NodeData.create(
        id: 'root',
        topic: 'Root',
        children: [
          NodeData.create(id: 'child1', topic: 'Child 1'),
          NodeData.create(id: 'child2', topic: 'Child 2'),
          NodeData.create(id: 'child3', topic: 'Child 3'),
        ],
      );

      testData = MindMapData(
        nodeData: root,
        theme: MindMapTheme.light,
      );

      controller = MindMapController(initialData: testData);
    });

    tearDown(() {
      controller.dispose();
    });

    group('Example Tests', () {
      test('arrow creation flow: start mode -> select source -> select target -> create arrow', () {
        // Example Test #7: Arrow Creation Flow
        // Initial state: no arrows, not in arrow creation mode
        expect(controller.getData().arrows.length, 0);
        expect(controller.isArrowCreationMode, false);
        expect(controller.arrowSourceNodeId, null);
        
        // Step 1: Start arrow creation mode
        controller.startArrowCreationMode();
        expect(controller.isArrowCreationMode, true);
        expect(controller.arrowSourceNodeId, null);
        
        // Step 2: Select source node
        controller.selectArrowSourceNode('child1');
        expect(controller.isArrowCreationMode, true);
        expect(controller.arrowSourceNodeId, 'child1');
        
        // Step 3: Select target node
        controller.selectArrowTargetNode('child2');
        
        // Step 4: Verify arrow was created
        final data = controller.getData();
        expect(data.arrows.length, 1);
        expect(data.arrows.first.fromNodeId, 'child1');
        expect(data.arrows.first.toNodeId, 'child2');
        
        // Verify mode was exited
        expect(controller.isArrowCreationMode, false);
        expect(controller.arrowSourceNodeId, null);
        
        // Verify event was emitted
        expect(controller.lastEvent, isA<ArrowCreatedEvent>());
        final event = controller.lastEvent as ArrowCreatedEvent;
        expect(event.fromNodeId, 'child1');
        expect(event.toNodeId, 'child2');
      });
    });

    group('Arrow Creation Mode', () {
      test('should start arrow creation mode', () {
        expect(controller.isArrowCreationMode, false);
        expect(controller.arrowSourceNodeId, null);

        controller.startArrowCreationMode();

        expect(controller.isArrowCreationMode, true);
        expect(controller.arrowSourceNodeId, null);
      });

      test('should exit arrow creation mode', () {
        controller.startArrowCreationMode();
        expect(controller.isArrowCreationMode, true);

        controller.exitArrowCreationMode();

        expect(controller.isArrowCreationMode, false);
        expect(controller.arrowSourceNodeId, null);
      });

      test('should select source node in arrow creation mode', () {
        controller.startArrowCreationMode();

        controller.selectArrowSourceNode('child1');

        expect(controller.arrowSourceNodeId, 'child1');
        expect(controller.isArrowCreationMode, true);
      });

      test('should throw error when selecting source node outside arrow creation mode', () {
        expect(
          () => controller.selectArrowSourceNode('child1'),
          throwsStateError,
        );
      });

      test('should create arrow when selecting target node', () {
        controller.startArrowCreationMode();
        controller.selectArrowSourceNode('child1');

        final initialArrowCount = controller.getData().arrows.length;

        controller.selectArrowTargetNode('child2');

        final data = controller.getData();
        expect(data.arrows.length, initialArrowCount + 1);
        expect(data.arrows.last.fromNodeId, 'child1');
        expect(data.arrows.last.toNodeId, 'child2');
        expect(controller.isArrowCreationMode, false);
        expect(controller.arrowSourceNodeId, null);
      });

      test('should create arrow with label', () {
        controller.startArrowCreationMode();
        controller.selectArrowSourceNode('child1');

        controller.selectArrowTargetNode('child2', label: 'Test Label');

        final data = controller.getData();
        expect(data.arrows.last.label, 'Test Label');
      });

      test('should create bidirectional arrow', () {
        controller.startArrowCreationMode();
        controller.selectArrowSourceNode('child1');

        controller.selectArrowTargetNode('child2', bidirectional: true);

        final data = controller.getData();
        expect(data.arrows.last.bidirectional, true);
      });

      test('should emit ArrowCreatedEvent when arrow is created', () {
        controller.startArrowCreationMode();
        controller.selectArrowSourceNode('child1');

        controller.selectArrowTargetNode('child2');

        expect(controller.lastEvent, isA<ArrowCreatedEvent>());
        final event = controller.lastEvent as ArrowCreatedEvent;
        expect(event.fromNodeId, 'child1');
        expect(event.toNodeId, 'child2');
      });

      test('should throw error when selecting target without source', () {
        controller.startArrowCreationMode();

        expect(
          () => controller.selectArrowTargetNode('child2'),
          throwsStateError,
        );
      });
    });

    group('Arrow Management', () {
      test('should add arrow directly', () {
        final initialArrowCount = controller.getData().arrows.length;

        controller.addArrow(
          fromNodeId: 'child1',
          toNodeId: 'child2',
          label: 'Direct Arrow',
        );

        final data = controller.getData();
        expect(data.arrows.length, initialArrowCount + 1);
        expect(data.arrows.last.fromNodeId, 'child1');
        expect(data.arrows.last.toNodeId, 'child2');
        expect(data.arrows.last.label, 'Direct Arrow');
      });

      test('should throw error when adding arrow with invalid node IDs', () {
        expect(
          () => controller.addArrow(
            fromNodeId: 'invalid',
            toNodeId: 'child2',
          ),
          throwsA(isA<InvalidNodeIdException>()),
        );

        expect(
          () => controller.addArrow(
            fromNodeId: 'child1',
            toNodeId: 'invalid',
          ),
          throwsA(isA<InvalidNodeIdException>()),
        );
      });

      test('should remove arrow', () {
        controller.addArrow(fromNodeId: 'child1', toNodeId: 'child2');
        final arrowId = controller.getData().arrows.last.id;
        final initialArrowCount = controller.getData().arrows.length;

        controller.removeArrow(arrowId);

        expect(controller.getData().arrows.length, initialArrowCount - 1);
      });

      test('should throw error when removing non-existent arrow', () {
        expect(
          () => controller.removeArrow('invalid-id'),
          throwsA(isA<InvalidNodeIdException>()),
        );
      });

      test('should update arrow properties', () {
        controller.addArrow(fromNodeId: 'child1', toNodeId: 'child2');
        final arrow = controller.getData().arrows.last;

        final updatedArrow = arrow.copyWith(
          label: 'Updated Label',
          bidirectional: true,
        );

        controller.updateArrow(arrow.id, updatedArrow);

        final data = controller.getData();
        final resultArrow = data.arrows.firstWhere((a) => a.id == arrow.id);
        expect(resultArrow.label, 'Updated Label');
        expect(resultArrow.bidirectional, true);
      });
    });

    group('Arrow Selection and Control Points', () {
      test('should select arrow', () {
        controller.addArrow(fromNodeId: 'child1', toNodeId: 'child2');
        final arrowId = controller.getData().arrows.last.id;

        expect(controller.selectedArrowId, null);

        controller.selectArrow(arrowId);

        expect(controller.selectedArrowId, arrowId);
      });

      test('should deselect arrow', () {
        controller.addArrow(fromNodeId: 'child1', toNodeId: 'child2');
        final arrowId = controller.getData().arrows.last.id;
        controller.selectArrow(arrowId);

        controller.deselectArrow();

        expect(controller.selectedArrowId, null);
      });

      test('should throw error when selecting non-existent arrow', () {
        expect(
          () => controller.selectArrow('invalid-id'),
          throwsA(isA<InvalidNodeIdException>()),
        );
      });

      test('should update arrow control points', () {
        controller.addArrow(fromNodeId: 'child1', toNodeId: 'child2');
        final arrow = controller.getData().arrows.last;

        const newDelta1 = Offset(10, 20);
        const newDelta2 = Offset(30, 40);

        controller.updateArrowControlPoints(arrow.id, newDelta1, newDelta2);

        final data = controller.getData();
        final updatedArrow = data.arrows.firstWhere((a) => a.id == arrow.id);
        expect(updatedArrow.delta1, newDelta1);
        expect(updatedArrow.delta2, newDelta2);
      });

      test('should get arrow by ID', () {
        controller.addArrow(fromNodeId: 'child1', toNodeId: 'child2');
        final arrowId = controller.getData().arrows.last.id;

        final arrow = controller.getArrow(arrowId);

        expect(arrow, isNotNull);
        expect(arrow!.id, arrowId);
      });

      test('should return null for non-existent arrow ID', () {
        final arrow = controller.getArrow('invalid-id');

        expect(arrow, null);
      });

      test('should clear selected arrow when removing it', () {
        controller.addArrow(fromNodeId: 'child1', toNodeId: 'child2');
        final arrowId = controller.getData().arrows.last.id;
        controller.selectArrow(arrowId);

        controller.removeArrow(arrowId);

        expect(controller.selectedArrowId, null);
      });
    });

    group('Arrow Data Persistence', () {
      test('should persist arrow data in mind map', () {
        controller.addArrow(
          fromNodeId: 'child1',
          toNodeId: 'child2',
          label: 'Test Arrow',
        );

        final data = controller.getData();
        final arrow = data.arrows.last;

        expect(arrow.fromNodeId, 'child1');
        expect(arrow.toNodeId, 'child2');
        expect(arrow.label, 'Test Arrow');
        // Note: delta1 and delta2 are now automatically calculated based on node positions
        // They will not be Offset.zero unless explicitly set
        expect(arrow.delta1, isNot(Offset.zero));
        expect(arrow.delta2, isNot(Offset.zero));
        expect(arrow.bidirectional, false);
      });

      test('should persist control point deltas', () {
        controller.addArrow(fromNodeId: 'child1', toNodeId: 'child2');
        final arrowId = controller.getData().arrows.last.id;

        const delta1 = Offset(15, 25);
        const delta2 = Offset(35, 45);
        controller.updateArrowControlPoints(arrowId, delta1, delta2);

        final data = controller.getData();
        final arrow = data.arrows.firstWhere((a) => a.id == arrowId);

        expect(arrow.delta1, delta1);
        expect(arrow.delta2, delta2);
      });
      
      test('should allow manual control point specification', () {
        // Users can still manually specify control points if desired
        const manualDelta1 = Offset(50, 0);
        const manualDelta2 = Offset(-50, 0);
        
        controller.addArrow(
          fromNodeId: 'child1',
          toNodeId: 'child2',
          label: 'Manual Arrow',
          delta1: manualDelta1,
          delta2: manualDelta2,
        );

        final data = controller.getData();
        final arrow = data.arrows.last;

        expect(arrow.fromNodeId, 'child1');
        expect(arrow.toNodeId, 'child2');
        expect(arrow.label, 'Manual Arrow');
        expect(arrow.delta1, manualDelta1);
        expect(arrow.delta2, manualDelta2);
      });
    });
  });
}
