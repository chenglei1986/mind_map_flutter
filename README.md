![Mind Map Demo](doc/img/mind_map.png)

# Mind Map Flutter

[![pub package](https://img.shields.io/pub/v/mind_map_flutter)](https://img.shields.io/pub/v/mind_map_flutter)

A Flutter mind map library for building interactive, editable mind maps with themes, history, and export support.

Language: **English** | [简体中文](README.zh-CN.md)

[API References](doc/API_REFERENCES.md)

## Features

- Editable tree nodes with drag-and-drop reorganization
- Rich node styling: text color, background, font, tags, icons, hyperlinks, images
- Arrows and summaries for cross-branch relationships and grouping
- Undo/redo history and clipboard copy/paste
- Focus mode, zoom/pan, fit-to-view, and center-on-node
- JSON / PNG export
- Read-only mode (keeps zoom/pan, expand/collapse, and hyperlink opening)
- Built-in light and dark themes, plus custom themes
- i18n for built-in labels (`MindMapLocale.auto/zh/en`)
- Cross-platform Flutter support (Android, iOS, Web, Windows, macOS, Linux)

## Installation

```yaml
dependencies:
  mind_map_flutter: <latest-version>
```

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

void main() {
  runApp(const MaterialApp(home: MindMapPage()));
}

class MindMapPage extends StatelessWidget {
  const MindMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mind Map')),
      body: MindMapWidget(
        initialData: MindMapData(
          nodeData: NodeData.create(
            topic: 'Central Topic',
            children: [
              NodeData.create(topic: 'Branch A'),
              NodeData.create(topic: 'Branch B'),
            ],
          ),
          theme: MindMapTheme.light,
        ),
      ),
    );
  }
}
```

## Controller Usage

```dart
late final MindMapController controller;

@override
void initState() {
  super.initState();
  controller = MindMapController(
    initialData: MindMapData(
      nodeData: NodeData.create(topic: 'Project'),
      theme: MindMapTheme.light,
    ),
    config: const MindMapConfig(
      allowUndo: true,
      enableKeyboardShortcuts: true,
      enableContextMenu: true,
      enableDragDrop: true,
      minScale: 0.1,
      maxScale: 5.0,
      maxHistorySize: 50,
      locale: MindMapLocale.auto,
    ),
  );

  controller.eventStream.listen((event) {
    if (event is FinishEditEvent) {
      debugPrint('Edited: ${event.nodeId} -> ${event.newTopic}');
    }
  });
}
```

Enable read-only mode:

```dart
const config = MindMapConfig(
  readOnly: true,
);
```

## More Examples

### Add and update nodes

```dart
final rootId = controller.getData().nodeData.id;

controller.addChildNode(rootId, topic: 'Todo');
final newNodeId = controller.getSelectedNodeIds().first;

controller.updateNodeTopic(newNodeId, 'This Week');
controller.addSiblingNode(newNodeId, topic: 'Next Week');
controller.centerOnNode(newNodeId);
```

### Export JSON and PNG

```dart
import 'dart:io';

final jsonText = controller.exportToJson();
await File('mind_map.json').writeAsString(jsonText);

final pngBytes = await controller.exportToPng(pixelRatio: 2.0);
await File('mind_map.png').writeAsBytes(pngBytes);
```

Note: `exportToPng()` should be called after `MindMapWidget` is mounted and painted.

### JSON Export/Import Format and Field Reference

```dart
import 'dart:convert';

// Export
final jsonText = controller.exportToJson();

// Import
final map = jsonDecode(jsonText) as Map<String, dynamic>;
final data = MindMapData.fromJson(map);
controller.refresh(data);
```

#### Top-level fields

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `nodeData` | `Map<String, dynamic>` | Yes | Root node (recursively contains the full tree) |
| `arrows` | `List<Map>` | No | Arrow connections between nodes |
| `summaries` | `List<Map>` | No | Summary groups for sibling ranges |
| `direction` | `String` | No | Layout direction: `left` / `right` / `side` (default: `side`) |
| `theme` | `Map<String, dynamic>` | No | Theme config (default: `MindMapTheme.light`) |

#### Common `nodeData` fields

| Field | Type | Description |
| --- | --- | --- |
| `id` | `String` | Unique node ID (auto-generated if missing) |
| `topic` | `String` | Node text |
| `children` | `List<Map>` | Child nodes |
| `style` | `Map` | Node style (font, colors, width, etc.) |
| `tags` | `List<Map>` | Tag list (`text` / `className`) |
| `icons` | `List<String>` | Icon list (usually emojis) |
| `hyperLink` | `String` | Hyperlink URL |
| `expanded` | `bool` | Expand/collapse state |
| `direction` | `String` | Node side: `left` / `right` / `side` |
| `image` | `Map` | Legacy single-image field (compatibility) |
| `images` | `List<Map>` | Preferred image field (supports multi-image) |
| `branchColor` | `int` | Branch color |
| `note` | `String` | Node note |

#### Key `arrows` / `summaries` / `theme` fields

| Field path | Type | Description |
| --- | --- | --- |
| `arrows[].fromNodeId` / `toNodeId` | `String` | Arrow source/target node IDs |
| `arrows[].delta1` / `delta2` | `Map(dx,dy)` | Bezier control point offsets |
| `arrows[].bidirectional` | `bool` | Whether arrow is bidirectional |
| `arrows[].style` | `Map` | Arrow style (color, width, dash, opacity) |
| `summaries[].parentNodeId` | `String` | Parent node ID of grouped siblings |
| `summaries[].startIndex` / `endIndex` | `int` | Child index range in parent `children` (inclusive) |
| `summaries[].label` | `String` | Summary label |
| `summaries[].style` | `Map` | Summary style (stroke/label color) |
| `theme.name` | `String` | Theme name |
| `theme.palette` | `List<int>` | Theme palette colors |
| `theme.variables` | `Map` | Theme variables (spacing, colors, radius, paddings) |

Notes:
- Color fields are decimal ints from `Color.toARGB32()`.
- `fontWeight` uses `FontWeight.values[index]` (for example, `w700` is commonly `6`).
- `image` is kept for backward compatibility; prefer `images`.
- `NodeStyle.border` and `TagData.style` are not serialized to JSON currently.
- `summary` should group contiguous siblings on the same side (avoid mixing left/right branches).

#### JSON example

```json
{
  "nodeData": {
    "id": "root",
    "topic": "Release Plan",
    "children": [
      {
        "id": "n-plan",
        "topic": "Planning",
        "style": {
          "fontSize": 16,
          "fontWeight": 6
        },
        "children": [
          {
            "id": "n-plan-scope",
            "topic": "Scope",
            "expanded": true
          }
        ],
        "tags": [{"text": "P1"}],
        "icons": ["📝"],
        "expanded": true,
        "direction": "right"
      },
      {
        "id": "n-dev",
        "topic": "Development",
        "icons": ["💻"],
        "hyperLink": "https://example.com/spec",
        "expanded": true,
        "direction": "right",
        "note": "Implementation and self-test"
      },
      {
        "id": "n-qa",
        "topic": "QA",
        "icons": ["✅"],
        "expanded": true,
        "direction": "right"
      },
      {
        "id": "n-release",
        "topic": "Release",
        "icons": ["🚀"],
        "expanded": true,
        "direction": "right"
      }
    ],
    "expanded": true
  },
  "arrows": [
    {
      "id": "a-qa-release",
      "fromNodeId": "n-qa",
      "toNodeId": "n-release",
      "label": "Release gate",
      "delta1": {
        "dx": 134.28137003841232,
        "dy": 15.201664532650454
      },
      "delta2": {
        "dx": 118.07762483994884,
        "dy": -8.633402688860485
      },
      "bidirectional": false
    }
  ],
  "summaries": [
    {
      "id": "s-exec",
      "parentNodeId": "root",
      "startIndex": 1,
      "endIndex": 3,
      "label": "Execution"
    }
  ],
  "direction": "right",
  "theme": {
    "name": "light",
    "palette": [
      4293467747,
      4288423856,
      4284955319,
      4282339765,
      4280391411,
      4278238420,
      4278228616,
      4283215696,
      4287349578,
      4291681337,
      4294961979,
      4294951175,
      4294940672,
      4294924066
    ],
    "variables": {
      "nodeGapX": 30,
      "nodeGapY": 10,
      "mainGapX": 65,
      "mainGapY": 45,
      "mainColor": 4281545523,
      "mainBgColor": 4294967295,
      "color": 4281545523,
      "bgColor": 4294967295,
      "selectedColor": 4280391411,
      "accentColor": 4294940672,
      "rootColor": 4294967295,
      "rootBgColor": 4283191145,
      "rootBorderColor": 4283191145,
      "rootRadius": 16,
      "mainRadius": 16,
      "topicPadding": {
        "left": 3,
        "top": 3,
        "right": 3,
        "bottom": 3
      },
      "panelColor": 4281545523,
      "panelBgColor": 4294967295,
      "panelBorderColor": 4292927712,
      "mapPadding": {
        "left": 50,
        "top": 50,
        "right": 50,
        "bottom": 50
      }
    }
  }
}
```

## Acknowledgements

This project was written entirely with AI assistance.

Special thanks to:

- Codex
- Kiro
- Claude Code
- Mind Elixir
