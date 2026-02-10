import 'package:flutter/material.dart';
import 'node_data.dart';
import 'arrow_data.dart';
import 'summary_data.dart';
import 'layout_direction.dart';
import 'mind_map_theme.dart';

/// Complete mind map data structure
@immutable
class MindMapData {
  final NodeData nodeData;
  final List<ArrowData> arrows;
  final List<SummaryData> summaries;
  final LayoutDirection direction;
  final MindMapTheme theme;

  const MindMapData({
    required this.nodeData,
    this.arrows = const [],
    this.summaries = const [],
    this.direction = LayoutDirection.side,
    required this.theme,
  });

  /// Create an empty mind map with a root node
  factory MindMapData.empty({String rootTopic = '中心主题', MindMapTheme? theme}) {
    return MindMapData(
      nodeData: NodeData.create(topic: rootTopic),
      theme: theme ?? MindMapTheme.light,
    );
  }

  MindMapData copyWith({
    NodeData? nodeData,
    List<ArrowData>? arrows,
    List<SummaryData>? summaries,
    LayoutDirection? direction,
    MindMapTheme? theme,
  }) {
    return MindMapData(
      nodeData: nodeData ?? this.nodeData,
      arrows: arrows ?? this.arrows,
      summaries: summaries ?? this.summaries,
      direction: direction ?? this.direction,
      theme: theme ?? this.theme,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nodeData': nodeData.toJson(),
      if (arrows.isNotEmpty) 'arrows': arrows.map((a) => a.toJson()).toList(),
      if (summaries.isNotEmpty)
        'summaries': summaries.map((s) => s.toJson()).toList(),
      'direction': direction.toJson(),
      'theme': theme.toJson(),
    };
  }

  factory MindMapData.fromJson(Map<String, dynamic> json) {
    return MindMapData(
      nodeData: json['nodeData'] != null
          ? NodeData.fromJson(json['nodeData'])
          : NodeData.create(topic: '中心主题'),
      arrows: json['arrows'] != null
          ? (json['arrows'] as List).map((a) => ArrowData.fromJson(a)).toList()
          : [],
      summaries: json['summaries'] != null
          ? (json['summaries'] as List)
                .map((s) => SummaryData.fromJson(s))
                .toList()
          : [],
      direction: json['direction'] != null
          ? LayoutDirectionExtension.fromJson(json['direction'])
          : LayoutDirection.side,
      theme: json['theme'] != null
          ? MindMapTheme.fromJson(json['theme'])
          : MindMapTheme.light,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MindMapData &&
          runtimeType == other.runtimeType &&
          nodeData == other.nodeData &&
          _listEquals(arrows, other.arrows) &&
          _listEquals(summaries, other.summaries) &&
          direction == other.direction &&
          theme == other.theme;

  @override
  int get hashCode =>
      nodeData.hashCode ^
      arrows.hashCode ^
      summaries.hashCode ^
      direction.hashCode ^
      theme.hashCode;

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
