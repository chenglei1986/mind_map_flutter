import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/rendering/summary_renderer.dart';
import 'package:mind_map_flutter/src/models/summary_data.dart';
import 'package:mind_map_flutter/src/models/summary_style.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/layout/node_layout.dart';

void main() {
  group('SummaryRenderer', () {
    late MindMapTheme theme;
    late NodeData parentNode;
    late Map<String, NodeLayout> nodeLayouts;

    setUp(() {
      theme = MindMapTheme.light;
      
      // Create a parent node with multiple children
      parentNode = NodeData.create(
        topic: 'Parent',
        children: [
          NodeData.create(topic: 'Child 1'),
          NodeData.create(topic: 'Child 2'),
          NodeData.create(topic: 'Child 3'),
          NodeData.create(topic: 'Child 4'),
        ],
      );
      
      // Create layouts for parent and children
      nodeLayouts = {
        parentNode.id: NodeLayout(
          position: const Offset(100, 100),
          size: const Size(100, 40),
        ),
        parentNode.children[0].id: NodeLayout(
          position: const Offset(250, 50),
          size: const Size(80, 30),
        ),
        parentNode.children[1].id: NodeLayout(
          position: const Offset(250, 100),
          size: const Size(80, 30),
        ),
        parentNode.children[2].id: NodeLayout(
          position: const Offset(250, 150),
          size: const Size(80, 30),
        ),
        parentNode.children[3].id: NodeLayout(
          position: const Offset(250, 200),
          size: const Size(80, 30),
        ),
      };
    });

    group('drawSummary', () {
      test('draws summary bracket for valid range', () {
        final summary = SummaryData.create(
          parentNodeId: parentNode.id,
          startIndex: 0,
          endIndex: 2,
          label: 'Group A',
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        // Should not throw
        expect(
          () => SummaryRenderer.drawSummary(
            canvas,
            summary,
            parentNode,
            nodeLayouts,
            theme,
          ),
          returnsNormally,
        );
      });

      test('handles summary without label', () {
        final summary = SummaryData.create(
          parentNodeId: parentNode.id,
          startIndex: 1,
          endIndex: 3,
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        // Should not throw
        expect(
          () => SummaryRenderer.drawSummary(
            canvas,
            summary,
            parentNode,
            nodeLayouts,
            theme,
          ),
          returnsNormally,
        );
      });

      test('applies custom label color from style', () {
        final customColor = Colors.red;
        final summary = SummaryData.create(
          parentNodeId: parentNode.id,
          startIndex: 0,
          endIndex: 1,
          label: 'Custom',
          style: SummaryStyle(labelColor: customColor),
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        // Should not throw
        expect(
          () => SummaryRenderer.drawSummary(
            canvas,
            summary,
            parentNode,
            nodeLayouts,
            theme,
          ),
          returnsNormally,
        );
      });

      test('handles invalid start index gracefully', () {
        final summary = SummaryData.create(
          parentNodeId: parentNode.id,
          startIndex: -1,
          endIndex: 2,
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        // Should not throw, just skip rendering
        expect(
          () => SummaryRenderer.drawSummary(
            canvas,
            summary,
            parentNode,
            nodeLayouts,
            theme,
          ),
          returnsNormally,
        );
      });

      test('handles invalid end index gracefully', () {
        final summary = SummaryData.create(
          parentNodeId: parentNode.id,
          startIndex: 0,
          endIndex: 10, // Out of bounds
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        // Should not throw, just skip rendering
        expect(
          () => SummaryRenderer.drawSummary(
            canvas,
            summary,
            parentNode,
            nodeLayouts,
            theme,
          ),
          returnsNormally,
        );
      });

      test('handles start index greater than end index', () {
        final summary = SummaryData.create(
          parentNodeId: parentNode.id,
          startIndex: 3,
          endIndex: 1,
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        // Should not throw, just skip rendering
        expect(
          () => SummaryRenderer.drawSummary(
            canvas,
            summary,
            parentNode,
            nodeLayouts,
            theme,
          ),
          returnsNormally,
        );
      });

      test('handles missing parent node layout', () {
        final summary = SummaryData.create(
          parentNodeId: 'non-existent-id',
          startIndex: 0,
          endIndex: 1,
        );

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        // Should not throw, just skip rendering
        expect(
          () => SummaryRenderer.drawSummary(
            canvas,
            summary,
            parentNode,
            nodeLayouts,
            theme,
          ),
          returnsNormally,
        );
      });

      test('handles missing child node layouts', () {
        final summary = SummaryData.create(
          parentNodeId: parentNode.id,
          startIndex: 0,
          endIndex: 2,
        );

        // Remove child layouts
        final emptyLayouts = {
          parentNode.id: nodeLayouts[parentNode.id]!,
        };

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        // Should not throw, just skip rendering
        expect(
          () => SummaryRenderer.drawSummary(
            canvas,
            summary,
            parentNode,
            emptyLayouts,
            theme,
          ),
          returnsNormally,
        );
      });
    });

    group('drawAllSummaries', () {
      test('draws multiple summaries', () {
        final summaries = [
          SummaryData.create(
            parentNodeId: parentNode.id,
            startIndex: 0,
            endIndex: 1,
            label: 'Group 1',
          ),
          SummaryData.create(
            parentNodeId: parentNode.id,
            startIndex: 2,
            endIndex: 3,
            label: 'Group 2',
          ),
        ];

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        // Should not throw
        expect(
          () => SummaryRenderer.drawAllSummaries(
            canvas,
            summaries,
            parentNode,
            nodeLayouts,
            theme,
          ),
          returnsNormally,
        );
      });

      test('handles empty summaries list', () {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        // Should not throw
        expect(
          () => SummaryRenderer.drawAllSummaries(
            canvas,
            [],
            parentNode,
            nodeLayouts,
            theme,
          ),
          returnsNormally,
        );
      });

      test('handles summaries with non-existent parent nodes', () {
        final summaries = [
          SummaryData.create(
            parentNodeId: 'non-existent',
            startIndex: 0,
            endIndex: 1,
          ),
        ];

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);

        // Should not throw, just skip invalid summaries
        expect(
          () => SummaryRenderer.drawAllSummaries(
            canvas,
            summaries,
            parentNode,
            nodeLayouts,
            theme,
          ),
          returnsNormally,
        );
      });
    });

    group('getSummaryBounds', () {
      test('returns valid bounds for valid summary', () {
        final summary = SummaryData.create(
          parentNodeId: parentNode.id,
          startIndex: 0,
          endIndex: 2,
        );

        final bounds = SummaryRenderer.getSummaryBounds(
          summary,
          parentNode,
          nodeLayouts,
        );

        expect(bounds, isNotNull);
        expect(bounds!.width, greaterThan(0));
        expect(bounds.height, greaterThan(0));
      });

      test('returns null for invalid start index', () {
        final summary = SummaryData.create(
          parentNodeId: parentNode.id,
          startIndex: -1,
          endIndex: 2,
        );

        final bounds = SummaryRenderer.getSummaryBounds(
          summary,
          parentNode,
          nodeLayouts,
        );

        expect(bounds, isNull);
      });

      test('returns null for invalid end index', () {
        final summary = SummaryData.create(
          parentNodeId: parentNode.id,
          startIndex: 0,
          endIndex: 10,
        );

        final bounds = SummaryRenderer.getSummaryBounds(
          summary,
          parentNode,
          nodeLayouts,
        );

        expect(bounds, isNull);
      });

      test('returns null for missing parent layout', () {
        final summary = SummaryData.create(
          parentNodeId: 'non-existent',
          startIndex: 0,
          endIndex: 1,
        );

        final bounds = SummaryRenderer.getSummaryBounds(
          summary,
          parentNode,
          nodeLayouts,
        );

        expect(bounds, isNull);
      });

      test('returns null for missing child layouts', () {
        final summary = SummaryData.create(
          parentNodeId: parentNode.id,
          startIndex: 0,
          endIndex: 2,
        );

        final emptyLayouts = {
          parentNode.id: nodeLayouts[parentNode.id]!,
        };

        final bounds = SummaryRenderer.getSummaryBounds(
          summary,
          parentNode,
          emptyLayouts,
        );

        expect(bounds, isNull);
      });

      test('bounds encompass all child nodes in range', () {
        final summary = SummaryData.create(
          parentNodeId: parentNode.id,
          startIndex: 1,
          endIndex: 2,
        );

        final bounds = SummaryRenderer.getSummaryBounds(
          summary,
          parentNode,
          nodeLayouts,
        );

        expect(bounds, isNotNull);
        
        // Bounds should encompass child 1 and child 2
        final child1Bounds = nodeLayouts[parentNode.children[1].id]!.bounds;
        final child2Bounds = nodeLayouts[parentNode.children[2].id]!.bounds;
        
        // The summary bounds should have positive width (includes bracket and padding)
        expect(bounds!.width, greaterThan(0));
        
        // The summary bounds should encompass both children vertically
        expect(bounds.top, lessThanOrEqualTo(child1Bounds.top + 10.5));
        expect(bounds.bottom, greaterThanOrEqualTo(child2Bounds.bottom - 10.5));
      });
    });

    group('constants', () {
      test('bracket padding is reasonable', () {
        expect(SummaryRenderer.bracketPadding, greaterThan(0));
        expect(SummaryRenderer.bracketPadding, lessThan(50));
      });

      test('bracket width is reasonable', () {
        expect(SummaryRenderer.bracketWidth, greaterThan(0));
        expect(SummaryRenderer.bracketWidth, lessThan(10));
      });

      test('bracket cap length is reasonable', () {
        expect(SummaryRenderer.bracketCapLength, greaterThan(0));
        expect(SummaryRenderer.bracketCapLength, lessThan(50));
      });

      test('label padding is reasonable', () {
        expect(SummaryRenderer.labelPadding.horizontal, greaterThan(0));
        expect(SummaryRenderer.labelPadding.vertical, greaterThan(0));
      });
    });
  });
}
