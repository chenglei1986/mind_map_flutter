import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

void main() {
  group('Export API Tests', () {
    late MindMapController controller;
    late MindMapData testData;

    setUp(() {
      final rootNode = NodeData.create(
        topic: 'Root',
        children: [
          NodeData.create(topic: 'Child 1'),
          NodeData.create(topic: 'Child 2'),
        ],
      );

      testData = MindMapData(nodeData: rootNode, theme: MindMapTheme.light);

      controller = MindMapController(initialData: testData);
    });

    group('Export API Existence', () {
      test('exportToJson method should exist and be callable', () {
        expect(() => controller.exportToJson(), returnsNormally);

        final result = controller.exportToJson();
        expect(result, isA<String>());
        expect(result, isNotEmpty);
        expect(() => jsonDecode(result), returnsNormally);
      });

      test('exportToPng method should exist and be callable', () {
        expect(controller.exportToPng, isA<Function>());

        expect(() => controller.exportToPng(), throwsException);
      });

      test('export methods should be accessible from controller', () {
        expect(controller, isA<MindMapController>());
        expect(controller.exportToJson, isA<String Function()>());
        expect(controller.exportToPng, isA<Function>());
      });
    });

    group('Image Size Options', () {
      test('exportToPng should support size parameter', () {
        expect(
          () => controller.exportToPng(size: Size(800, 600)),
          throwsException,
        );
      });

      test('exportToPng should support pixelRatio parameter', () {
        expect(() => controller.exportToPng(pixelRatio: 2.0), throwsException);
        expect(() => controller.exportToPng(pixelRatio: 1.0), throwsException);
        expect(() => controller.exportToPng(pixelRatio: 3.0), throwsException);
      });

      test(
        'exportToPng should support both size and pixelRatio parameters',
        () {
          expect(
            () =>
                controller.exportToPng(size: Size(1024, 768), pixelRatio: 2.0),
            throwsException,
          );
        },
      );
    });

    group('Export API with Complex Data', () {
      test('exportToJson should work with complex mind map', () {
        final complexRoot = NodeData.create(
          topic: 'Complex Root',
          children: [
            NodeData.create(
              topic: 'Branch 1',
              children: [
                NodeData.create(topic: 'Leaf 1'),
                NodeData.create(topic: 'Leaf 2'),
              ],
            ),
            NodeData.create(topic: 'Branch 2'),
          ],
        );

        final arrow = ArrowData.create(
          fromNodeId: complexRoot.children[0].id,
          toNodeId: complexRoot.children[1].id,
          label: 'Connection',
        );

        final summary = SummaryData.create(
          parentNodeId: complexRoot.id,
          startIndex: 0,
          endIndex: 1,
          label: 'Summary',
        );

        final complexData = MindMapData(
          nodeData: complexRoot,
          arrows: [arrow],
          summaries: [summary],
          theme: MindMapTheme.dark,
        );

        final complexController = MindMapController(initialData: complexData);

        final json = complexController.exportToJson();
        expect(json, isNotEmpty);

        final parsed = jsonDecode(json);
        expect(parsed['nodeData'], isNotNull);
        expect(parsed['arrows'], isNotNull);
        expect(parsed['summaries'], isNotNull);
      });
    });

    group('Export API Error Handling', () {
      test('exportToJson should handle empty mind map', () {
        final minimalData = MindMapData(
          nodeData: NodeData.create(topic: 'Root'),
          theme: MindMapTheme.light,
        );

        final minimalController = MindMapController(initialData: minimalData);

        final json = minimalController.exportToJson();
        expect(json, isNotEmpty);

        final parsed = jsonDecode(json);
        expect(parsed['nodeData'], isNotNull);
        expect(parsed['nodeData']['topic'], equals('Root'));
      });

      test(
        'exportToPng should throw exception when widget not initialized',
        () {
          expect(() => controller.exportToPng(), throwsException);
        },
      );
    });
  });
}
