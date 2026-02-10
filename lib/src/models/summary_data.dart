import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'summary_style.dart';

const _uuid = Uuid();

/// Summary grouping data
@immutable
class SummaryData {
  final String id;
  final String parentNodeId;
  final int startIndex;
  final int endIndex;
  final String? label;
  final SummaryStyle? style;

  const SummaryData({
    required this.id,
    required this.parentNodeId,
    required this.startIndex,
    required this.endIndex,
    this.label,
    this.style,
  });

  /// Create a new summary with a generated UUID
  factory SummaryData.create({
    String? id,
    required String parentNodeId,
    required int startIndex,
    required int endIndex,
    String? label,
    SummaryStyle? style,
  }) {
    return SummaryData(
      id: id ?? _uuid.v4(),
      parentNodeId: parentNodeId,
      startIndex: startIndex,
      endIndex: endIndex,
      label: label,
      style: style,
    );
  }

  SummaryData copyWith({
    String? id,
    String? parentNodeId,
    int? startIndex,
    int? endIndex,
    String? label,
    SummaryStyle? style,
  }) {
    return SummaryData(
      id: id ?? this.id,
      parentNodeId: parentNodeId ?? this.parentNodeId,
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
      label: label ?? this.label,
      style: style ?? this.style,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentNodeId': parentNodeId,
      'startIndex': startIndex,
      'endIndex': endIndex,
      if (label != null) 'label': label,
      if (style != null) 'style': style!.toJson(),
    };
  }

  factory SummaryData.fromJson(Map<String, dynamic> json) {
    return SummaryData(
      id: json['id'] ?? _uuid.v4(),
      parentNodeId: json['parentNodeId'] ?? '',
      startIndex: json['startIndex'] ?? 0,
      endIndex: json['endIndex'] ?? 0,
      label: json['label'],
      style: json['style'] != null
          ? SummaryStyle.fromJson(json['style'])
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SummaryData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          parentNodeId == other.parentNodeId &&
          startIndex == other.startIndex &&
          endIndex == other.endIndex &&
          label == other.label &&
          style == other.style;

  @override
  int get hashCode =>
      id.hashCode ^
      parentNodeId.hashCode ^
      startIndex.hashCode ^
      endIndex.hashCode ^
      label.hashCode ^
      style.hashCode;
}
