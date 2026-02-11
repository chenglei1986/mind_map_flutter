![Mind Map Demo](doc/img/mind_map.png)

# Mind Map Flutter

一个用于 Flutter 的思维导图库，支持交互编辑、主题定制、历史记录与多格式导出。

语言: [English](README.md) | **简体中文**

[API 文档](doc/API_REFERENCES.zh-CN.md)

## 功能概览

- 可编辑节点树，支持拖拽重组
- 节点样式定制：文字、背景、字体、标签、图标、链接、图片
- 支持箭头与摘要（Summary）
- 撤销/重做与复制/粘贴
- 聚焦模式、缩放/平移、居中与自适应视图
- JSON / PNG 导出
- 只读模式（保留缩放/平移、展开/折叠、打开链接）
- 内置明暗主题，支持自定义主题
- 内置文案支持 `MindMapLocale.auto/zh/en`
- 支持 Android、iOS、Web、Windows、macOS、Linux

## 安装

```yaml
dependencies:
  mind_map_flutter: <latest-version>
```

```bash
flutter pub get
```

## 快速开始

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
            topic: '中心主题',
            children: [
              NodeData.create(topic: '分支 A'),
              NodeData.create(topic: '分支 B'),
            ],
          ),
          theme: MindMapTheme.light,
        ),
      ),
    );
  }
}
```

## Controller 用法

```dart
late final MindMapController controller;

@override
void initState() {
  super.initState();
  controller = MindMapController(
    initialData: MindMapData(
      nodeData: NodeData.create(topic: '项目规划'),
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
      debugPrint('已编辑: ${event.nodeId} -> ${event.newTopic}');
    }
  });
}
```

启用只读模式：

```dart
const config = MindMapConfig(
  readOnly: true,
);
```

## 更多示例

### 新增并更新节点

```dart
final rootId = controller.getData().nodeData.id;

controller.addChildNode(rootId, topic: '待办');
final newNodeId = controller.getSelectedNodeIds().first;

controller.updateNodeTopic(newNodeId, '本周计划');
controller.addSiblingNode(newNodeId, topic: '下周计划');
controller.centerOnNode(newNodeId);
```

### 导出 JSON 与 PNG

```dart
import 'dart:io';

final jsonText = controller.exportToJson();
await File('mind_map.json').writeAsString(jsonText);

final pngBytes = await controller.exportToPng(pixelRatio: 2.0);
await File('mind_map.png').writeAsBytes(pngBytes);
```

说明：`exportToPng()` 需要在 `MindMapWidget` 完成挂载并绘制后调用。

### JSON 导出/导入格式与字段说明

```dart
import 'dart:convert';

// 导出
final jsonText = controller.exportToJson();

// 导入
final map = jsonDecode(jsonText) as Map<String, dynamic>;
final data = MindMapData.fromJson(map);
controller.refresh(data);
```

#### 顶层字段

| 字段 | 类型 | 是否必填 | 含义 |
| --- | --- | --- | --- |
| `nodeData` | `Map<String, dynamic>` | 是 | 根节点（递归包含整棵树） |
| `arrows` | `List<Map>` | 否 | 节点之间的箭头关系 |
| `summaries` | `List<Map>` | 否 | 同级节点分组摘要 |
| `direction` | `String` | 否 | 布局方向：`left` / `right` / `side`（默认 `side`） |
| `theme` | `Map<String, dynamic>` | 否 | 主题配置（默认 `MindMapTheme.light`） |

#### `nodeData` 常用字段

| 字段 | 类型 | 含义 |
| --- | --- | --- |
| `id` | `String` | 节点唯一 ID（缺失时自动生成） |
| `topic` | `String` | 节点文本 |
| `children` | `List<Map>` | 子节点列表 |
| `style` | `Map` | 节点样式（如字体、颜色、背景、宽度） |
| `tags` | `List<Map>` | 标签列表（`text` / `className`） |
| `icons` | `List<String>` | 图标（通常用 emoji） |
| `hyperLink` | `String` | 超链接地址 |
| `expanded` | `bool` | 是否展开 |
| `direction` | `String` | 节点方向：`left` / `right` / `side` |
| `image` | `Map` | 旧版单图字段（兼容） |
| `images` | `List<Map>` | 推荐图片字段（支持多图） |
| `branchColor` | `int` | 分支颜色 |
| `note` | `String` | 备注文本 |

#### `arrows` / `summaries` / `theme` 关键字段

| 字段路径 | 类型 | 含义 |
| --- | --- | --- |
| `arrows[].fromNodeId` / `toNodeId` | `String` | 箭头起止节点 ID |
| `arrows[].delta1` / `delta2` | `Map(dx,dy)` | 箭头贝塞尔控制点偏移 |
| `arrows[].bidirectional` | `bool` | 是否双向箭头 |
| `arrows[].style` | `Map` | 箭头样式（颜色、线宽、虚线、透明度） |
| `summaries[].parentNodeId` | `String` | 父节点 ID（被分组节点的父节点） |
| `summaries[].startIndex` / `endIndex` | `int` | 在父节点 `children` 里的起止索引（闭区间） |
| `summaries[].label` | `String` | 摘要文字 |
| `summaries[].style` | `Map` | 摘要样式（线条/文字颜色） |
| `theme.name` | `String` | 主题名 |
| `theme.palette` | `List<int>` | 调色板颜色 |
| `theme.variables` | `Map` | 主题变量（间距、颜色、圆角、内边距等） |

说明：
- 颜色字段是 `Color.toARGB32()` 的十进制整数。
- `fontWeight` 使用 `FontWeight.values[index]`（例如 `w700` 常见是 `6`）。
- `image` 为兼容旧格式保留，推荐使用 `images`。
- `NodeStyle.border`、`TagData.style` 当前不参与 JSON 序列化。
- `summary` 建议只分组同一侧的连续兄弟节点（避免跨左右两侧分组）。

#### JSON 示例

```json
{
  "nodeData": {
    "id": "root",
    "topic": "版本发布",
    "children": [
      {
        "id": "n-plan",
        "topic": "规划",
        "style": {
          "fontSize": 16,
          "fontWeight": 6
        },
        "children": [
          {
            "id": "n-plan-scope",
            "topic": "范围确认",
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
        "topic": "开发",
        "icons": ["💻"],
        "hyperLink": "https://example.com/spec",
        "expanded": true,
        "direction": "right",
        "note": "实现与自测"
      },
      {
        "id": "n-qa",
        "topic": "测试",
        "icons": ["✅"],
        "expanded": true,
        "direction": "right"
      },
      {
        "id": "n-release",
        "topic": "发布",
        "icons": [
          "🚀"
        ],
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
      "label": "通过后发布",
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
      "label": "执行阶段"
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

## 致谢

本项目完全由 AI 协助编写。

特别感谢：

- Codex
- Kiro
- Claude Code
- Mind Elixir
