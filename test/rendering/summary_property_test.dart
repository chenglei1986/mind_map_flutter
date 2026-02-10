import 'dart:ui' show PictureRecorder, Canvas;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';
import 'dart:math';

// Feature: mind-map-flutter, Property 22: 摘要渲染和持久化
// Feature: mind-map-flutter, Property 23: 摘要样式应用

void main() {
  group('Summary Property Tests', () {
    const iterations = 100;

    // For any summary, it should render a bracket encompassing the specified
    // range of sibling nodes, and the data should contain parent node ID,
    // start/end indices, label, and style
    test('Property 22: Summary rendering and persistence', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data with a parent node that has multiple children
        final random = Random(i);
        
        // Create a parent node with at least 2 children for summary
        final childCount = 2 + random.nextInt(6); // 2-7 children
        final children = List.generate(
          childCount,
          (index) => NodeData.create(topic: 'Child ${index + 1}'),
        );
        
        final parentNode = NodeData.create(
          topic: 'Parent',
          children: children,
        );
        
        final rootNode = NodeData.create(
          topic: 'Root',
          children: [parentNode],
        );

        final initialData = MindMapData(
          nodeData: rootNode,
          theme: random.nextBool() ? MindMapTheme.light : MindMapTheme.dark,
          direction: LayoutDirection.values[random.nextInt(3)],
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Generate random summary properties
        final maxIndex = childCount - 1;
        final startIndex = random.nextInt(maxIndex);
        final endIndex = startIndex + random.nextInt(maxIndex - startIndex + 1);
        final label = random.nextBool() ? 'Summary $i' : null;
        final labelColor = random.nextBool()
            ? Color(0xFF000000 + random.nextInt(0xFFFFFF))
            : null;
        final style = labelColor != null
            ? SummaryStyle(labelColor: labelColor)
            : null;

        // Capture initial summary count
        final initialSummaryCount = controller.getData().summaries.length;

        // Create summary (Requirement 10.1, 10.6)
        controller.addSummary(
          parentNodeId: parentNode.id,
          startIndex: startIndex,
          endIndex: endIndex,
          label: label,
          style: style,
        );

        // Verify summary was added to data (Requirement 10.6)
        final data = controller.getData();
        expect(data.summaries.length, initialSummaryCount + 1,
            reason: 'Summary should be added to data');

        // Get the created summary
        final summary = data.summaries.last;

        // Verify summary data persistence (Requirement 10.6)
        expect(summary.parentNodeId, parentNode.id,
            reason: 'Summary should persist parent node ID');
        expect(summary.startIndex, startIndex,
            reason: 'Summary should persist start index');
        expect(summary.endIndex, endIndex,
            reason: 'Summary should persist end index');
        expect(summary.label, label,
            reason: 'Summary should persist label');
        
        // Verify style persistence
        if (style != null) {
          expect(summary.style, isNotNull,
              reason: 'Summary should persist style when provided');
          expect(summary.style!.labelColor, labelColor,
              reason: 'Summary should persist label color');
        }

        // Verify summary has unique ID
        expect(summary.id, isNotEmpty,
            reason: 'Summary should have a unique ID');

        // Verify summary can be retrieved
        final retrievedSummary = controller.getSummary(summary.id);
        expect(retrievedSummary, isNotNull,
            reason: 'Summary should be retrievable by ID');
        expect(retrievedSummary!.id, summary.id,
            reason: 'Retrieved summary should match created summary');

        // Calculate layout for rendering verification
        final layoutEngine = LayoutEngine();
        final nodeLayouts = layoutEngine.calculateLayout(
          data.nodeData,
          data.theme,
          data.direction,
        );

        // Verify parent and child nodes are in layout
        expect(nodeLayouts.containsKey(parentNode.id), true,
            reason: 'Parent node should be in layout');
        
        // Verify at least some children are in layout (may be collapsed)
        final childrenInLayout = children
            .where((child) => nodeLayouts.containsKey(child.id))
            .length;
        
        // If parent is expanded, children should be in layout
        if (parentNode.expanded) {
          expect(childrenInLayout, greaterThan(0),
              reason: 'Children should be in layout when parent is expanded');
        }

        // Verify summary can be rendered (Requirement 10.2, 10.5)
        expect(
          () {
            final recorder = PictureRecorder();
            final canvas = Canvas(recorder);
            SummaryRenderer.drawSummary(
              canvas,
              summary,
              parentNode,
              nodeLayouts,
              data.theme,
            );
          },
          returnsNormally,
          reason: 'Summary should render without errors',
        );

        // Verify summary bounds can be calculated (for hit testing)
        final summaryBounds = SummaryRenderer.getSummaryBounds(
          summary,
          parentNode,
          nodeLayouts,
        );

        // Bounds may be null if children are not in layout (e.g., collapsed)
        if (parentNode.expanded && childrenInLayout > 0) {
          expect(summaryBounds, isNotNull,
              reason: 'Summary bounds should be calculable when children are visible');
          
          if (summaryBounds != null) {
            // Verify bounds have valid dimensions
            expect(summaryBounds.width, greaterThan(0),
                reason: 'Summary bounds should have positive width');
            expect(summaryBounds.height, greaterThan(0),
                reason: 'Summary bounds should have positive height');
            
            // Verify bounds encompass the child nodes in the range
            final firstChildLayout = nodeLayouts[children[startIndex].id];
            final lastChildLayout = nodeLayouts[children[endIndex].id];
            
            if (firstChildLayout != null && lastChildLayout != null) {
              // Summary should encompass the vertical range of children
              expect(summaryBounds.top, lessThanOrEqualTo(firstChildLayout.bounds.top + 10.5),
                  reason: 'Summary should encompass first child vertically');
              expect(summaryBounds.bottom, greaterThanOrEqualTo(lastChildLayout.bounds.bottom - 10.5),
                  reason: 'Summary should encompass last child vertically');
            }
          }
        }

        controller.dispose();
      }
    });

    // For any summary with custom label color, rendering should apply that color
    test('Property 23: Summary style application', () {
      for (int i = 0; i < iterations; i++) {
        // Generate random initial data
        final random = Random(i);
        
        // Create a parent node with multiple children
        final childCount = 2 + random.nextInt(6);
        final children = List.generate(
          childCount,
          (index) => NodeData.create(topic: 'Child ${index + 1}'),
        );
        
        final parentNode = NodeData.create(
          topic: 'Parent',
          children: children,
        );
        
        final rootNode = NodeData.create(
          topic: 'Root',
          children: [parentNode],
        );

        final initialData = MindMapData(
          nodeData: rootNode,
          theme: random.nextBool() ? MindMapTheme.light : MindMapTheme.dark,
          direction: LayoutDirection.values[random.nextInt(3)],
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Generate random summary with custom label color (Requirement 10.4)
        final maxIndex = childCount - 1;
        final startIndex = random.nextInt(maxIndex);
        final endIndex = startIndex + random.nextInt(maxIndex - startIndex + 1);
        final label = 'Styled Summary $i';
        
        // Generate random custom label color
        final labelColor = Color(0xFF000000 + random.nextInt(0xFFFFFF));
        final style = SummaryStyle(labelColor: labelColor);

        // Create summary with custom style
        controller.addSummary(
          parentNodeId: parentNode.id,
          startIndex: startIndex,
          endIndex: endIndex,
          label: label,
          style: style,
        );

        final summary = controller.getData().summaries.last;

        // Verify style is persisted correctly
        expect(summary.style, isNotNull,
            reason: 'Summary should have style');
        expect(summary.style!.labelColor, labelColor,
            reason: 'Summary should persist label color');

        // Verify label color is a valid color
        expect(summary.style!.labelColor!.a, greaterThan(0),
            reason: 'Label color should have non-zero alpha');

        // Calculate layout
        final layoutEngine = LayoutEngine();
        final nodeLayouts = layoutEngine.calculateLayout(
          controller.getData().nodeData,
          controller.getData().theme,
          controller.getData().direction,
        );

        // Verify summary with custom style can be rendered (Requirement 10.4)
        expect(
          () {
            final recorder = PictureRecorder();
            final canvas = Canvas(recorder);
            SummaryRenderer.drawSummary(
              canvas,
              summary,
              parentNode,
              nodeLayouts,
              controller.getData().theme,
            );
          },
          returnsNormally,
          reason: 'Summary with custom style should render without errors',
        );

        // Test updating summary style
        final newLabelColor = Color(0xFF000000 + random.nextInt(0xFFFFFF));
        final newStyle = SummaryStyle(labelColor: newLabelColor);
        final updatedSummary = summary.copyWith(style: newStyle);

        controller.updateSummary(summary.id, updatedSummary);

        final retrievedSummary = controller.getSummary(summary.id);
        expect(retrievedSummary, isNotNull);
        expect(retrievedSummary!.style, isNotNull);
        expect(retrievedSummary.style!.labelColor, newLabelColor,
            reason: 'Updated label color should be persisted');

        // Verify updated summary can still be rendered
        expect(
          () {
            final recorder = PictureRecorder();
            final canvas = Canvas(recorder);
            SummaryRenderer.drawSummary(
              canvas,
              retrievedSummary,
              parentNode,
              nodeLayouts,
              controller.getData().theme,
            );
          },
          returnsNormally,
          reason: 'Summary should render after style update',
        );

        controller.dispose();
      }
    });

    // Additional property test: Summary without label
    test('Property 22 (Extended): Summary without label', () {
      for (int i = 0; i < iterations; i++) {
        final random = Random(i);
        
        final childCount = 2 + random.nextInt(6);
        final children = List.generate(
          childCount,
          (index) => NodeData.create(topic: 'Child ${index + 1}'),
        );
        
        final parentNode = NodeData.create(
          topic: 'Parent',
          children: children,
        );
        
        final rootNode = NodeData.create(
          topic: 'Root',
          children: [parentNode],
        );

        final initialData = MindMapData(
          nodeData: rootNode,
          theme: MindMapTheme.light,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        final maxIndex = childCount - 1;
        final startIndex = random.nextInt(maxIndex);
        final endIndex = startIndex + random.nextInt(maxIndex - startIndex + 1);

        // Create summary without label
        controller.addSummary(
          parentNodeId: parentNode.id,
          startIndex: startIndex,
          endIndex: endIndex,
        );

        final summary = controller.getData().summaries.last;

        // Verify label is null
        expect(summary.label, isNull,
            reason: 'Summary should have no label when not provided');

        // Calculate layout
        final layoutEngine = LayoutEngine();
        final nodeLayouts = layoutEngine.calculateLayout(
          controller.getData().nodeData,
          controller.getData().theme,
          controller.getData().direction,
        );

        // Verify summary without label can be rendered
        expect(
          () {
            final recorder = PictureRecorder();
            final canvas = Canvas(recorder);
            SummaryRenderer.drawSummary(
              canvas,
              summary,
              parentNode,
              nodeLayouts,
              controller.getData().theme,
            );
          },
          returnsNormally,
          reason: 'Summary without label should render without errors',
        );

        controller.dispose();
      }
    });

    // Additional property test: Multiple summaries for same parent
    test('Property 22 (Extended): Multiple summaries persistence', () {
      for (int i = 0; i < iterations; i++) {
        final random = Random(i);
        
        // Create parent with enough children for multiple summaries
        final childCount = 4 + random.nextInt(4); // 4-7 children
        final children = List.generate(
          childCount,
          (index) => NodeData.create(topic: 'Child ${index + 1}'),
        );
        
        final parentNode = NodeData.create(
          topic: 'Parent',
          children: children,
        );
        
        final rootNode = NodeData.create(
          topic: 'Root',
          children: [parentNode],
        );

        final initialData = MindMapData(
          nodeData: rootNode,
          theme: MindMapTheme.light,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Create multiple non-overlapping summaries (2-3)
        final summaryCount = 2 + random.nextInt(2);
        final createdSummaryIds = <String>[];
        
        // Divide children into ranges for summaries
        final rangeSize = childCount ~/ summaryCount;
        
        for (int j = 0; j < summaryCount; j++) {
          final startIndex = j * rangeSize;
          final endIndex = (j == summaryCount - 1) 
              ? childCount - 1 
              : (j + 1) * rangeSize - 1;
          
          if (startIndex <= endIndex) {
            controller.addSummary(
              parentNodeId: parentNode.id,
              startIndex: startIndex,
              endIndex: endIndex,
              label: 'Summary $j',
            );

            createdSummaryIds.add(controller.getData().summaries.last.id);
          }
        }

        // Verify all summaries are persisted
        final data = controller.getData();
        expect(data.summaries.length, greaterThanOrEqualTo(summaryCount),
            reason: 'All created summaries should be persisted');

        // Verify each summary can be retrieved
        for (final summaryId in createdSummaryIds) {
          final summary = controller.getSummary(summaryId);
          expect(summary, isNotNull,
              reason: 'Each summary should be retrievable by ID');
          expect(summary!.parentNodeId, parentNode.id,
              reason: 'All summaries should reference the same parent');
        }

        // Calculate layout
        final layoutEngine = LayoutEngine();
        final nodeLayouts = layoutEngine.calculateLayout(
          data.nodeData,
          data.theme,
          data.direction,
        );

        // Verify all summaries can be rendered
        expect(
          () {
            final recorder = PictureRecorder();
            final canvas = Canvas(recorder);
            SummaryRenderer.drawAllSummaries(
              canvas,
              data.summaries,
              rootNode,
              nodeLayouts,
              data.theme,
            );
          },
          returnsNormally,
          reason: 'All summaries should render without errors',
        );

        controller.dispose();
      }
    });

    // Additional property test: Summary removal
    test('Property 22 (Extended): Summary removal', () {
      for (int i = 0; i < iterations; i++) {
        final random = Random(i);
        
        final childCount = 2 + random.nextInt(6);
        final children = List.generate(
          childCount,
          (index) => NodeData.create(topic: 'Child ${index + 1}'),
        );
        
        final parentNode = NodeData.create(
          topic: 'Parent',
          children: children,
        );
        
        final rootNode = NodeData.create(
          topic: 'Root',
          children: [parentNode],
        );

        final initialData = MindMapData(
          nodeData: rootNode,
          theme: MindMapTheme.light,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        final maxIndex = childCount - 1;
        final startIndex = random.nextInt(maxIndex);
        final endIndex = startIndex + random.nextInt(maxIndex - startIndex + 1);

        // Create summary
        controller.addSummary(
          parentNodeId: parentNode.id,
          startIndex: startIndex,
          endIndex: endIndex,
          label: 'Test Summary',
        );

        final summaryId = controller.getData().summaries.last.id;
        final summaryCountBefore = controller.getData().summaries.length;

        // Remove summary
        controller.removeSummary(summaryId);

        // Verify summary is removed
        final data = controller.getData();
        expect(data.summaries.length, summaryCountBefore - 1,
            reason: 'Summary should be removed from data');

        // Verify summary cannot be retrieved
        final summary = controller.getSummary(summaryId);
        expect(summary, isNull,
            reason: 'Removed summary should not be retrievable');

        controller.dispose();
      }
    });

    // Additional property test: Summary update
    test('Property 22 (Extended): Summary update', () {
      for (int i = 0; i < iterations; i++) {
        final random = Random(i);
        
        final childCount = 3 + random.nextInt(5); // At least 3 children
        final children = List.generate(
          childCount,
          (index) => NodeData.create(topic: 'Child ${index + 1}'),
        );
        
        final parentNode = NodeData.create(
          topic: 'Parent',
          children: children,
        );
        
        final rootNode = NodeData.create(
          topic: 'Root',
          children: [parentNode],
        );

        final initialData = MindMapData(
          nodeData: rootNode,
          theme: MindMapTheme.light,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        // Create initial summary
        controller.addSummary(
          parentNodeId: parentNode.id,
          startIndex: 0,
          endIndex: 1,
          label: 'Original',
        );

        final summary = controller.getData().summaries.last;

        // Update summary with new range and label
        final newEndIndex = 2;
        final newLabel = 'Updated';
        final updatedSummary = summary.copyWith(
          endIndex: newEndIndex,
          label: newLabel,
        );

        controller.updateSummary(summary.id, updatedSummary);

        // Verify updates are persisted
        final retrievedSummary = controller.getSummary(summary.id);
        expect(retrievedSummary, isNotNull);
        expect(retrievedSummary!.endIndex, newEndIndex,
            reason: 'Updated end index should be persisted');
        expect(retrievedSummary.label, newLabel,
            reason: 'Updated label should be persisted');

        // Calculate layout
        final layoutEngine = LayoutEngine();
        final nodeLayouts = layoutEngine.calculateLayout(
          controller.getData().nodeData,
          controller.getData().theme,
          controller.getData().direction,
        );

        // Verify updated summary can be rendered
        expect(
          () {
            final recorder = PictureRecorder();
            final canvas = Canvas(recorder);
            SummaryRenderer.drawSummary(
              canvas,
              retrievedSummary,
              parentNode,
              nodeLayouts,
              controller.getData().theme,
            );
          },
          returnsNormally,
          reason: 'Updated summary should render without errors',
        );

        controller.dispose();
      }
    });

    // Additional property test: Summary with collapsed parent
    test('Property 22 (Extended): Summary with collapsed parent', () {
      for (int i = 0; i < iterations; i++) {
        final random = Random(i);
        
        final childCount = 2 + random.nextInt(6);
        final children = List.generate(
          childCount,
          (index) => NodeData.create(topic: 'Child ${index + 1}'),
        );
        
        // Create parent node that is collapsed
        final parentNode = NodeData.create(
          topic: 'Parent',
          children: children,
          expanded: false, // Collapsed
        );
        
        final rootNode = NodeData.create(
          topic: 'Root',
          children: [parentNode],
        );

        final initialData = MindMapData(
          nodeData: rootNode,
          theme: MindMapTheme.light,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        final maxIndex = childCount - 1;
        final startIndex = random.nextInt(maxIndex);
        final endIndex = startIndex + random.nextInt(maxIndex - startIndex + 1);

        // Create summary for collapsed parent
        controller.addSummary(
          parentNodeId: parentNode.id,
          startIndex: startIndex,
          endIndex: endIndex,
          label: 'Hidden Summary',
        );

        final summary = controller.getData().summaries.last;

        // Verify summary is persisted even though parent is collapsed
        expect(summary.parentNodeId, parentNode.id,
            reason: 'Summary should be persisted for collapsed parent');

        // Calculate layout
        final layoutEngine = LayoutEngine();
        final nodeLayouts = layoutEngine.calculateLayout(
          controller.getData().nodeData,
          controller.getData().theme,
          controller.getData().direction,
        );

        // Verify children are not in layout when parent is collapsed
        final childrenInLayout = children
            .where((child) => nodeLayouts.containsKey(child.id))
            .length;
        expect(childrenInLayout, 0,
            reason: 'Children should not be in layout when parent is collapsed');

        // Verify summary rendering handles collapsed parent gracefully
        expect(
          () {
            final recorder = PictureRecorder();
            final canvas = Canvas(recorder);
            SummaryRenderer.drawSummary(
              canvas,
              summary,
              parentNode,
              nodeLayouts,
              controller.getData().theme,
            );
          },
          returnsNormally,
          reason: 'Summary should handle collapsed parent gracefully',
        );

        // Verify summary bounds are null when children are not visible
        final summaryBounds = SummaryRenderer.getSummaryBounds(
          summary,
          parentNode,
          nodeLayouts,
        );
        expect(summaryBounds, isNull,
            reason: 'Summary bounds should be null when children are not visible');

        controller.dispose();
      }
    });

    // Additional property test: Summary with different directions
    test('Property 22 (Extended): Summary with different layout directions', () {
      for (int i = 0; i < iterations; i++) {
        final random = Random(i);
        
        final childCount = 2 + random.nextInt(6);
        final children = List.generate(
          childCount,
          (index) => NodeData.create(topic: 'Child ${index + 1}'),
        );
        
        final parentNode = NodeData.create(
          topic: 'Parent',
          children: children,
        );
        
        final rootNode = NodeData.create(
          topic: 'Root',
          children: [parentNode],
        );

        // Test with each layout direction
        final direction = LayoutDirection.values[i % 3];

        final initialData = MindMapData(
          nodeData: rootNode,
          theme: MindMapTheme.light,
          direction: direction,
        );

        final controller = MindMapController(
          initialData: initialData,
        );

        final maxIndex = childCount - 1;
        final startIndex = random.nextInt(maxIndex);
        final endIndex = startIndex + random.nextInt(maxIndex - startIndex + 1);

        // Create summary
        controller.addSummary(
          parentNodeId: parentNode.id,
          startIndex: startIndex,
          endIndex: endIndex,
          label: 'Directional Summary',
        );

        final summary = controller.getData().summaries.last;

        // Calculate layout with specific direction
        final layoutEngine = LayoutEngine();
        final nodeLayouts = layoutEngine.calculateLayout(
          controller.getData().nodeData,
          controller.getData().theme,
          direction,
        );

        // Verify summary can be rendered with any layout direction
        expect(
          () {
            final recorder = PictureRecorder();
            final canvas = Canvas(recorder);
            SummaryRenderer.drawSummary(
              canvas,
              summary,
              parentNode,
              nodeLayouts,
              controller.getData().theme,
            );
          },
          returnsNormally,
          reason: 'Summary should render correctly with $direction layout',
        );

        controller.dispose();
      }
    });
  });
}
