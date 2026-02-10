import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

void main() {
  group('DragManager Unit Tests', () {
    late DragManager dragManager;
    late NodeData rootNode;
    late Map<String, NodeLayout> nodeLayouts;
    late Matrix4 transform;

    setUp(() {
      dragManager = DragManager();
      
      // Create a simple tree structure for testing
      // Root
      //   ├─ Child1
      //   │   └─ Grandchild1
      //   └─ Child2
      rootNode = NodeData.create(
        id: 'root',
        topic: 'Root',
        children: [
          NodeData.create(
            id: 'child1',
            topic: 'Child 1',
            children: [
              NodeData.create(
                id: 'grandchild1',
                topic: 'Grandchild 1',
              ),
            ],
          ),
          NodeData.create(
            id: 'child2',
            topic: 'Child 2',
          ),
        ],
      );
      
      // Create mock layouts
      nodeLayouts = {
        'root': NodeLayout(
          position: const Offset(100, 100),
          size: const Size(100, 40),
        ),
        'child1': NodeLayout(
          position: const Offset(50, 200),
          size: const Size(80, 30),
        ),
        'child2': NodeLayout(
          position: const Offset(150, 200),
          size: const Size(80, 30),
        ),
        'grandchild1': NodeLayout(
          position: const Offset(30, 300),
          size: const Size(70, 30),
        ),
      };
      
      transform = Matrix4.identity();
    });

    tearDown(() {
      dragManager.dispose();
    });

    // Test drag start
    // Validates: Requirement 5.1 - Handle node drag start
    test('should start dragging a node', () {
      expect(dragManager.isDragging, isFalse);
      expect(dragManager.draggedNodeId, isNull);
      
      dragManager.startDrag('child1', const Offset(50, 200));
      
      expect(dragManager.isDragging, isTrue);
      expect(dragManager.draggedNodeId, 'child1');
      expect(dragManager.dragPosition, const Offset(50, 200));
      expect(dragManager.dropTargetNodeId, isNull);
    });

    test('should notify listeners when drag starts', () {
      bool notified = false;
      dragManager.addListener(() {
        notified = true;
      });
      
      dragManager.startDrag('child1', const Offset(50, 200));
      expect(notified, isTrue);
    });

    test('should clear drop target when starting new drag', () {
      dragManager.startDrag('child1', const Offset(50, 200));
      dragManager.updateDrag(
        const Offset(150, 200),
        nodeLayouts,
        transform,
        rootNode,
      );
      expect(dragManager.dropTargetNodeId, 'child2');
      
      // Start a new drag
      dragManager.startDrag('child2', const Offset(150, 200));
      expect(dragManager.dropTargetNodeId, isNull);
    });

    // Test drag update and drop target detection
    // Validates: Requirement 5.2 - Highlight drop targets
    test('should update drag position', () {
      dragManager.startDrag('child1', const Offset(50, 200));
      
      dragManager.updateDrag(
        const Offset(60, 210),
        nodeLayouts,
        transform,
        rootNode,
      );
      
      expect(dragManager.dragPosition, const Offset(60, 210));
    });

    test('should detect valid drop target when hovering over node', () {
      dragManager.startDrag('child1', const Offset(50, 200));
      
      // Move over child2
      dragManager.updateDrag(
        const Offset(180, 215), // Inside child2 bounds
        nodeLayouts,
        transform,
        rootNode,
      );
      
      expect(dragManager.dropTargetNodeId, 'child2');
    });

    test('should clear drop target when not hovering over any node', () {
      dragManager.startDrag('child1', const Offset(50, 200));
      
      // Move over child2
      dragManager.updateDrag(
        const Offset(180, 215),
        nodeLayouts,
        transform,
        rootNode,
      );
      expect(dragManager.dropTargetNodeId, 'child2');
      
      // Move to empty space
      dragManager.updateDrag(
        const Offset(500, 500),
        nodeLayouts,
        transform,
        rootNode,
      );
      expect(dragManager.dropTargetNodeId, isNull);
    });

    test('should not set dragged node as drop target', () {
      dragManager.startDrag('child1', const Offset(50, 200));
      
      // Move over the dragged node itself
      dragManager.updateDrag(
        const Offset(80, 215), // Inside child1 bounds
        nodeLayouts,
        transform,
        rootNode,
      );
      
      expect(dragManager.dropTargetNodeId, isNull);
    });

    test('should notify listeners when drop target changes', () {
      int notificationCount = 0;
      dragManager.addListener(() {
        notificationCount++;
      });
      
      dragManager.startDrag('child1', const Offset(50, 200));
      notificationCount = 0; // Reset after start
      
      // Move over child2
      dragManager.updateDrag(
        const Offset(180, 215),
        nodeLayouts,
        transform,
        rootNode,
      );
      expect(notificationCount, 1);
      
      // Move over same target (should not notify)
      dragManager.updateDrag(
        const Offset(185, 220),
        nodeLayouts,
        transform,
        rootNode,
      );
      expect(notificationCount, 1); // Still 1, no new notification
      
      // Move to empty space
      dragManager.updateDrag(
        const Offset(500, 500),
        nodeLayouts,
        transform,
        rootNode,
      );
      expect(notificationCount, 2);
    });

    test('should not update drag if not dragging', () {
      expect(dragManager.isDragging, isFalse);
      
      dragManager.updateDrag(
        const Offset(100, 100),
        nodeLayouts,
        transform,
        rootNode,
      );
      
      expect(dragManager.dragPosition, isNull);
      expect(dragManager.dropTargetNodeId, isNull);
    });

    // Test drag end
    test('should end drag and return drop target', () {
      dragManager.startDrag('child1', const Offset(50, 200));
      dragManager.updateDrag(
        const Offset(180, 215),
        nodeLayouts,
        transform,
        rootNode,
      );
      
      final dropTarget = dragManager.endDrag();
      
      expect(dropTarget, 'child2');
      expect(dragManager.isDragging, isFalse);
      expect(dragManager.draggedNodeId, isNull);
      expect(dragManager.dragPosition, isNull);
      expect(dragManager.dropTargetNodeId, isNull);
    });

    test('should end drag without drop target', () {
      dragManager.startDrag('child1', const Offset(50, 200));
      dragManager.updateDrag(
        const Offset(500, 500), // Empty space
        nodeLayouts,
        transform,
        rootNode,
      );
      
      final dropTarget = dragManager.endDrag();
      
      expect(dropTarget, isNull);
      expect(dragManager.isDragging, isFalse);
    });

    test('should return null when ending drag without starting', () {
      expect(dragManager.isDragging, isFalse);
      
      final dropTarget = dragManager.endDrag();
      
      expect(dropTarget, isNull);
    });

    test('should notify listeners when drag ends', () {
      bool notified = false;
      dragManager.addListener(() {
        notified = true;
      });
      
      dragManager.startDrag('child1', const Offset(50, 200));
      notified = false; // Reset after start
      
      dragManager.endDrag();
      expect(notified, isTrue);
    });

    // Test drag cancel
    test('should cancel drag operation', () {
      dragManager.startDrag('child1', const Offset(50, 200));
      dragManager.updateDrag(
        const Offset(180, 215),
        nodeLayouts,
        transform,
        rootNode,
      );
      
      dragManager.cancelDrag();
      
      expect(dragManager.isDragging, isFalse);
      expect(dragManager.draggedNodeId, isNull);
      expect(dragManager.dragPosition, isNull);
      expect(dragManager.dropTargetNodeId, isNull);
    });

    test('should notify listeners when drag is cancelled', () {
      bool notified = false;
      dragManager.addListener(() {
        notified = true;
      });
      
      dragManager.startDrag('child1', const Offset(50, 200));
      notified = false; // Reset after start
      
      dragManager.cancelDrag();
      expect(notified, isTrue);
    });

    test('should handle cancel when not dragging', () {
      expect(dragManager.isDragging, isFalse);
      
      // Should not throw
      dragManager.cancelDrag();
      
      expect(dragManager.isDragging, isFalse);
    });

    // Test circular reference prevention
    // Validates: Requirement 5.5 - Prevent circular references
    test('should prevent dropping node onto itself', () {
      dragManager.startDrag('child1', const Offset(50, 200));
      
      // Try to drop onto itself
      dragManager.updateDrag(
        const Offset(80, 215), // Inside child1 bounds
        nodeLayouts,
        transform,
        rootNode,
      );
      
      expect(dragManager.dropTargetNodeId, isNull);
    });

    test('should prevent dropping node onto its descendant', () {
      dragManager.startDrag('child1', const Offset(50, 200));
      
      // Try to drop onto grandchild1 (descendant of child1)
      dragManager.updateDrag(
        const Offset(60, 315), // Inside grandchild1 bounds
        nodeLayouts,
        transform,
        rootNode,
      );
      
      expect(dragManager.dropTargetNodeId, isNull);
    });

    test('should allow dropping node onto sibling', () {
      dragManager.startDrag('child1', const Offset(50, 200));
      
      // Drop onto child2 (sibling)
      dragManager.updateDrag(
        const Offset(180, 215), // Inside child2 bounds
        nodeLayouts,
        transform,
        rootNode,
      );
      
      expect(dragManager.dropTargetNodeId, 'child2');
    });

    test('should allow dropping node onto parent', () {
      dragManager.startDrag('child1', const Offset(50, 200));
      
      // Drop onto root (parent)
      dragManager.updateDrag(
        const Offset(130, 115), // Inside root bounds
        nodeLayouts,
        transform,
        rootNode,
      );
      
      expect(dragManager.dropTargetNodeId, 'root');
    });

    test('should allow dropping grandchild onto root', () {
      dragManager.startDrag('grandchild1', const Offset(30, 300));
      
      // Drop onto root (ancestor but not parent)
      dragManager.updateDrag(
        const Offset(130, 115), // Inside root bounds
        nodeLayouts,
        transform,
        rootNode,
      );
      
      expect(dragManager.dropTargetNodeId, 'root');
    });

    // Test with transform
    test('should handle transformed coordinates', () {
      // Apply a scale transform
      transform = Matrix4.identity()..scaleByDouble(2.0, 2.0, 1.0, 1.0);
      
      dragManager.startDrag('child1', const Offset(100, 400));
      
      // The position in screen coordinates needs to be transformed
      // to canvas coordinates for hit testing
      dragManager.updateDrag(
        const Offset(300, 430), // Screen coordinates
        nodeLayouts,
        transform,
        rootNode,
      );
      
      // After inverse transform: (300/2, 430/2) = (150, 215)
      // This should be inside child2 bounds
      expect(dragManager.dropTargetNodeId, 'child2');
    });

    // Test state consistency
    test('should maintain consistent state through drag lifecycle', () {
      // Initial state
      expect(dragManager.isDragging, isFalse);
      expect(dragManager.draggedNodeId, isNull);
      
      // Start drag
      dragManager.startDrag('child1', const Offset(50, 200));
      expect(dragManager.isDragging, isTrue);
      expect(dragManager.draggedNodeId, 'child1');
      
      // Update drag
      dragManager.updateDrag(
        const Offset(180, 215),
        nodeLayouts,
        transform,
        rootNode,
      );
      expect(dragManager.isDragging, isTrue);
      expect(dragManager.dropTargetNodeId, 'child2');
      
      // End drag
      dragManager.endDrag();
      expect(dragManager.isDragging, isFalse);
      expect(dragManager.draggedNodeId, isNull);
      expect(dragManager.dropTargetNodeId, isNull);
    });

    test('should handle multiple drag operations sequentially', () {
      // First drag
      dragManager.startDrag('child1', const Offset(50, 200));
      dragManager.updateDrag(
        const Offset(180, 215),
        nodeLayouts,
        transform,
        rootNode,
      );
      final firstTarget = dragManager.endDrag();
      expect(firstTarget, 'child2');
      
      // Second drag
      dragManager.startDrag('child2', const Offset(150, 200));
      dragManager.updateDrag(
        const Offset(80, 215),
        nodeLayouts,
        transform,
        rootNode,
      );
      final secondTarget = dragManager.endDrag();
      expect(secondTarget, 'child1');
    });
  });
}
