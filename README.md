![Mind Map Demo](doc/img/mind_map.png)

# Mind Map Flutter

[![pub package](https://img.shields.io/pub/v/mind_map_flutter)](https://img.shields.io/pub/v/mind_map_flutter)

A Flutter mind map library for building interactive, editable mind maps with themes, history, and export support.

Language: **English** | [简体中文](README.zh-CN.md)

## Features

- Editable tree nodes with drag-and-drop reorganization
- Rich node styling: text color, background, font, tags, icons, hyperlinks, images
- Arrows and summaries for cross-branch relationships and grouping
- Undo/redo history and clipboard copy/paste
- Focus mode, zoom/pan, fit-to-view, and center-on-node
- JSON / PNG export
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

## Acknowledgements

This project was written entirely with AI assistance.

Special thanks to:

- Codex
- Kiro
- Claude Code
- Mind Elixir
