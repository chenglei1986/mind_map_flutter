import 'dart:ui' show Rect;

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/interaction/gesture_handler.dart';
import 'package:mind_map_flutter/src/layout/layout_engine.dart';
import 'package:mind_map_flutter/src/layout/node_layout.dart';
import 'package:mind_map_flutter/src/models/layout_direction.dart';
import 'package:mind_map_flutter/src/models/mind_map_data.dart';
import 'package:mind_map_flutter/src/models/mind_map_theme.dart';
import 'package:mind_map_flutter/src/models/node_data.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_controller.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_widget.dart';

void main() {
  group('Read-only mode interactions', () {
    late MindMapController controller;
    late Map<String, dynamic> fixture;

    setUp(() {
      final root = NodeData.create(
        id: 'root',
        topic: 'Root',
        children: [
          NodeData.create(
            id: 'expand-node',
            topic: 'Expand Node',
            expanded: true,
            children: [NodeData.create(id: 'leaf', topic: 'Leaf')],
          ),
          NodeData.create(
            id: 'link-node',
            topic: 'Link Node',
            hyperLink: 'https://example.com',
          ),
        ],
      );

      final data = MindMapData(
        nodeData: root,
        theme: MindMapTheme.light,
        direction: LayoutDirection.side,
      );
      controller = MindMapController(initialData: data);
      final layouts = LayoutEngine().calculateLayout(
        data.nodeData,
        data.theme,
        data.direction,
      );

      fixture = {'data': data, 'root': root, 'layouts': layouts};
    });

    tearDown(() {
      controller.dispose();
    });

    test(
      'read-only blocks node selection and edit entry on tap/double tap',
      () {
        bool beginEditCalled = false;
        final layouts = fixture['layouts'] as Map<String, NodeLayout>;
        final handler = GestureHandler(
          controller: controller,
          nodeLayouts: layouts,
          transform: Matrix4.identity(),
          isReadOnly: true,
          onBeginEdit: (_) => beginEditCalled = true,
        );

        final nodeCenter = layouts['expand-node']!.bounds.center;
        final tap = TapUpDetails(
          kind: PointerDeviceKind.mouse,
          localPosition: nodeCenter,
          globalPosition: nodeCenter,
        );

        handler.handleTapUp(tap);
        handler.handleTapUp(tap); // double-tap path should still be blocked

        expect(controller.getSelectedNodeIds(), isEmpty);
        expect(beginEditCalled, isFalse);
        expect(controller.lastEvent, isNull);
      },
    );

    test('read-only keeps expand/collapse interaction available', () {
      final layouts = fixture['layouts'] as Map<String, NodeLayout>;

      final handler = GestureHandler(
        controller: controller,
        nodeLayouts: layouts,
        transform: Matrix4.identity(),
        isReadOnly: true,
      );

      final expandNode = _findNode(
        controller.getData().nodeData,
        'expand-node',
      );
      expect(expandNode, isNotNull);
      final expandLayout = layouts['expand-node']!;
      final indicatorPoint = _findHitPoint(
        expandLayout.bounds.inflate(80),
        (point) => handler.hitTestExpandIndicator(point) == 'expand-node',
      );
      expect(indicatorPoint, isNotNull);

      final tap = TapUpDetails(
        kind: PointerDeviceKind.mouse,
        localPosition: indicatorPoint!,
        globalPosition: indicatorPoint,
      );
      handler.handleTapUp(tap);

      final updatedNode = _findNode(
        controller.getData().nodeData,
        'expand-node',
      )!;
      expect(updatedNode.expanded, isFalse);
    });

    test('read-only keeps hyperlink opening interaction available', () {
      final layouts = fixture['layouts'] as Map<String, NodeLayout>;

      final handler = GestureHandler(
        controller: controller,
        nodeLayouts: layouts,
        transform: Matrix4.identity(),
        isReadOnly: true,
      );

      final linkNode = _findNode(controller.getData().nodeData, 'link-node');
      expect(linkNode, isNotNull);
      final nonNullLinkNode = linkNode!;
      final linkLayout = layouts['link-node']!;
      final indicatorPoint = _findHitPoint(
        linkLayout.bounds.inflate(80),
        (point) => handler.hitTestHyperlinkIndicator(point) == 'link-node',
      );
      expect(indicatorPoint, isNotNull);

      final tap = TapUpDetails(
        kind: PointerDeviceKind.mouse,
        localPosition: indicatorPoint!,
        globalPosition: indicatorPoint,
      );
      handler.handleTapUp(tap);

      expect(controller.lastEvent, isA<HyperlinkClickEvent>());
      final event = controller.lastEvent as HyperlinkClickEvent;
      expect(event.nodeId, 'link-node');
      expect(event.url, nonNullLinkNode.hyperLink);
    });
  });
}

NodeData? _findNode(NodeData node, String id) {
  if (node.id == id) return node;
  for (final child in node.children) {
    final found = _findNode(child, id);
    if (found != null) return found;
  }
  return null;
}

Offset? _findHitPoint(Rect area, bool Function(Offset point) matcher) {
  for (double y = area.top; y <= area.bottom; y += 2) {
    for (double x = area.left; x <= area.right; x += 2) {
      final point = Offset(x, y);
      if (matcher(point)) {
        return point;
      }
    }
  }
  return null;
}
