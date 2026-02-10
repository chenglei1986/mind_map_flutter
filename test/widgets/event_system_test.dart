import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

void main() {
  group('Event System Tests', () {
    late MindMapController controller;
    late MindMapData testData;

    setUp(() {
      // Create test data with a simple tree structure
      final rootNode = NodeData.create(
        topic: 'Root',
        children: [
          NodeData.create(topic: 'Child 1'),
          NodeData.create(topic: 'Child 2'),
        ],
      );

      testData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );

      controller = MindMapController(
        initialData: testData,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    // ========== Stream-based Event Tests ==========
    test('should provide event stream', () {
      // Verify that the controller exposes an event stream
      expect(controller.eventStream, isA<Stream<MindMapEvent>>());
    });

    test('should emit events to stream when adding child node', () async {
      // Listen to the event stream
      final eventFuture = controller.eventStream.first;

      // Perform an operation that emits an event
      controller.addChildNode(testData.nodeData.id, topic: 'Test');

      // Wait for the event
      final event = await eventFuture;

      // Verify the event
      expect(event, isA<NodeOperationEvent>());
      final nodeEvent = event as NodeOperationEvent;
      expect(nodeEvent.operation, 'addChild');
    });

    test('should emit events to stream when adding sibling node', () async {
      // Get the first child ID
      final firstChildId = testData.nodeData.children.first.id;

      // Listen to the event stream
      final eventFuture = controller.eventStream.first;

      // Add a sibling node
      controller.addSiblingNode(firstChildId);

      // Wait for the event
      final event = await eventFuture;

      // Verify the event
      expect(event, isA<NodeOperationEvent>());
      final nodeEvent = event as NodeOperationEvent;
      expect(nodeEvent.operation, 'addSibling');
    });

    test('should emit events to stream when removing node', () async {
      // Get the first child ID
      final firstChildId = testData.nodeData.children.first.id;

      // Listen to the event stream
      final eventFuture = controller.eventStream.first;

      // Remove the node
      controller.removeNode(firstChildId);

      // Wait for the event
      final event = await eventFuture;

      // Verify the event
      expect(event, isA<NodeOperationEvent>());
      final nodeEvent = event as NodeOperationEvent;
      expect(nodeEvent.operation, 'removeNode');
    });

    test('should emit events to stream when selecting nodes', () async {
      // Get the first child ID
      final firstChildId = testData.nodeData.children.first.id;

      // Listen to the event stream
      final eventFuture = controller.eventStream.first;

      // Select a node
      controller.selectionManager.selectNode(firstChildId);

      // Wait for the event
      final event = await eventFuture;

      // Verify the event
      expect(event, isA<SelectNodesEvent>());
      final selectEvent = event as SelectNodesEvent;
      expect(selectEvent.nodeIds, contains(firstChildId));
    });

    test('should emit events to stream when moving node', () async {
      // Get node IDs
      final firstChildId = testData.nodeData.children.first.id;
      final secondChildId = testData.nodeData.children[1].id;

      // Listen to the event stream
      final eventFuture = controller.eventStream.first;

      // Move the first child to be a child of the second child
      controller.moveNode(firstChildId, secondChildId);

      // Wait for the event
      final event = await eventFuture;

      // Verify the event
      expect(event, isA<MoveNodeEvent>());
      final moveEvent = event as MoveNodeEvent;
      expect(moveEvent.nodeId, firstChildId);
      expect(moveEvent.newParentId, secondChildId);
    });

    test('should emit events to stream when expanding/collapsing node', () async {
      // Get the root node ID
      final rootId = testData.nodeData.id;

      // Listen to the event stream
      final eventFuture = controller.eventStream.first;

      // Toggle node expansion
      controller.toggleNodeExpanded(rootId);

      // Wait for the event
      final event = await eventFuture;

      // Verify the event
      expect(event, isA<ExpandNodeEvent>());
      final expandEvent = event as ExpandNodeEvent;
      expect(expandEvent.nodeId, rootId);
      expect(expandEvent.expanded, false); // Should be collapsed now
    });

    test('should emit events to stream when creating arrow', () async {
      // Get node IDs
      final firstChildId = testData.nodeData.children.first.id;
      final secondChildId = testData.nodeData.children[1].id;

      // Listen to the event stream
      final eventFuture = controller.eventStream.first;

      // Create an arrow
      controller.addArrow(
        fromNodeId: firstChildId,
        toNodeId: secondChildId,
      );

      // Wait for the event
      final event = await eventFuture;

      // Verify the event
      expect(event, isA<ArrowCreatedEvent>());
      final arrowEvent = event as ArrowCreatedEvent;
      expect(arrowEvent.fromNodeId, firstChildId);
      expect(arrowEvent.toNodeId, secondChildId);
    });

    test('should emit events to stream when creating summary', () async {
      // Get the root node ID
      final rootId = testData.nodeData.id;

      // Listen to the event stream
      final eventFuture = controller.eventStream.first;

      // Create a summary
      controller.addSummary(
        parentNodeId: rootId,
        startIndex: 0,
        endIndex: 1,
      );

      // Wait for the event
      final event = await eventFuture;

      // Verify the event
      expect(event, isA<SummaryCreatedEvent>());
      final summaryEvent = event as SummaryCreatedEvent;
      expect(summaryEvent.parentNodeId, rootId);
    });

    test('should support multiple stream listeners', () async {
      // Create multiple listeners
      final completer1 = Completer<MindMapEvent>();
      final completer2 = Completer<MindMapEvent>();
      final completer3 = Completer<MindMapEvent>();

      final subscription1 = controller.eventStream.listen((event) {
        if (!completer1.isCompleted) {
          completer1.complete(event);
        }
      });

      final subscription2 = controller.eventStream.listen((event) {
        if (!completer2.isCompleted) {
          completer2.complete(event);
        }
      });

      final subscription3 = controller.eventStream.listen((event) {
        if (!completer3.isCompleted) {
          completer3.complete(event);
        }
      });

      // Perform an operation
      controller.addChildNode(testData.nodeData.id, topic: 'Test');

      // Wait for all listeners to receive the event
      final event1 = await completer1.future;
      final event2 = await completer2.future;
      final event3 = await completer3.future;

      // Verify all listeners received the same event
      expect(event1, isA<NodeOperationEvent>());
      expect(event2, isA<NodeOperationEvent>());
      expect(event3, isA<NodeOperationEvent>());

      // Clean up
      await subscription1.cancel();
      await subscription2.cancel();
      await subscription3.cancel();
    });

    test('should emit multiple events in sequence', () async {
      // Collect events
      final events = <MindMapEvent>[];
      final subscription = controller.eventStream.listen((event) {
        events.add(event);
      });

      // Perform multiple operations
      controller.addChildNode(testData.nodeData.id, topic: 'Test');
      await Future.delayed(const Duration(milliseconds: 50));

      final firstChildId = testData.nodeData.children.first.id;
      controller.addSiblingNode(firstChildId);
      await Future.delayed(const Duration(milliseconds: 50));

      controller.selectionManager.selectNode(firstChildId);
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify we received multiple events (at least 2, since selection might not always emit)
      expect(events.length, greaterThanOrEqualTo(2));
      expect(events[0], isA<NodeOperationEvent>());
      expect(events[1], isA<NodeOperationEvent>());

      // Clean up
      await subscription.cancel();
    });

    test('should emit BeginEditEvent and FinishEditEvent', () async {
      // Collect events
      final events = <MindMapEvent>[];
      final subscription = controller.eventStream.listen((event) {
        events.add(event);
      });

      final firstChildId = testData.nodeData.children.first.id;

      // Emit begin edit event
      controller.emitEvent(BeginEditEvent(firstChildId));
      await Future.delayed(const Duration(milliseconds: 10));

      // Update node topic
      controller.updateNodeTopic(firstChildId, 'Updated Topic');
      await Future.delayed(const Duration(milliseconds: 10));

      // Emit finish edit event
      controller.emitEvent(FinishEditEvent(firstChildId, 'Updated Topic'));
      await Future.delayed(const Duration(milliseconds: 10));

      // Verify events
      expect(events.length, greaterThanOrEqualTo(2));
      expect(events.first, isA<BeginEditEvent>());
      expect(events.last, isA<FinishEditEvent>());

      // Clean up
      await subscription.cancel();
    });

    test('should not emit events after controller is disposed', () async {
      // Create a new controller for this test
      final testController = MindMapController(
        initialData: testData,
      );

      // Listen to events
      final events = <MindMapEvent>[];
      final subscription = testController.eventStream.listen((event) {
        events.add(event);
      });

      // Perform an operation
      testController.addChildNode(testData.nodeData.id, topic: 'Test');
      await Future.delayed(const Duration(milliseconds: 10));

      // Verify event was received
      expect(events.length, 1);

      // Dispose the controller
      testController.dispose();

      // Try to perform another operation (should not emit)
      // Note: This might throw an exception, which is expected
      try {
        testController.addChildNode(testData.nodeData.id, topic: 'Test');
      } catch (e) {
        // Expected - controller is disposed
      }

      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 10));

      // Verify no new events were emitted
      expect(events.length, 1);

      // Clean up
      await subscription.cancel();
    });

    // ========== Callback-based Event Tests (backward compatibility) ==========
    test('should still support callback-based events', () {
      MindMapEvent? receivedEvent;

      // Create controller with callback
      final callbackController = MindMapController(
        initialData: testData,
      );

      // Manually track the last event (simulating widget behavior)
      callbackController.addListener(() {
        receivedEvent = callbackController.lastEvent;
      });

      // Perform an operation
      callbackController.addChildNode(testData.nodeData.id, topic: 'Test');

      // Verify callback received the event
      expect(receivedEvent, isA<NodeOperationEvent>());

      // Clean up
      callbackController.dispose();
    });

    test('should emit events to both callback and stream', () async {
      MindMapEvent? callbackEvent;

      // Track callback events
      controller.addListener(() {
        callbackEvent = controller.lastEvent;
      });

      // Track stream events
      final streamEventFuture = controller.eventStream.first;

      // Perform an operation
      controller.addChildNode(testData.nodeData.id, topic: 'Test');

      // Wait for stream event
      final streamEvent = await streamEventFuture;

      // Verify both received the event
      expect(callbackEvent, isA<NodeOperationEvent>());
      expect(streamEvent, isA<NodeOperationEvent>());
      expect((callbackEvent as NodeOperationEvent).operation, 'addChild');
      expect((streamEvent as NodeOperationEvent).operation, 'addChild');
    });

    // ========== Event Type Tests ==========

    test('should emit correct event types for different operations', () async {
      final events = <MindMapEvent>[];
      final subscription = controller.eventStream.listen((event) {
        events.add(event);
      });

      final rootId = testData.nodeData.id;
      final firstChildId = testData.nodeData.children.first.id;
      final secondChildId = testData.nodeData.children[1].id;

      // Test various operations
      controller.addChildNode(rootId, topic: 'Test');
      await Future.delayed(const Duration(milliseconds: 50));

      controller.selectionManager.selectNode(firstChildId);
      await Future.delayed(const Duration(milliseconds: 50));

      controller.moveNode(firstChildId, secondChildId);
      await Future.delayed(const Duration(milliseconds: 50));

      controller.toggleNodeExpanded(rootId);
      await Future.delayed(const Duration(milliseconds: 50));

      controller.addArrow(fromNodeId: firstChildId, toNodeId: secondChildId);
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify event types (at least 4 events should be emitted)
      expect(events.length, greaterThanOrEqualTo(4));
      expect(events.any((e) => e is NodeOperationEvent), true);
      expect(events.any((e) => e is MoveNodeEvent), true);
      expect(events.any((e) => e is ExpandNodeEvent), true);
      expect(events.any((e) => e is ArrowCreatedEvent), true);

      // Clean up
      await subscription.cancel();
    });
  });
}
