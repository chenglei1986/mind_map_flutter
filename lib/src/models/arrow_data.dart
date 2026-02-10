import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'arrow_style.dart';

const _uuid = Uuid();

/// Arrow connection data
@immutable
class ArrowData {
  final String id;
  final String fromNodeId;
  final String toNodeId;
  final String? label;
  final Offset delta1;
  final Offset delta2;
  final bool bidirectional;
  final ArrowStyle? style;

  const ArrowData({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    this.label,
    this.delta1 = Offset.zero,
    this.delta2 = Offset.zero,
    this.bidirectional = false,
    this.style,
  });

  /// Create a new arrow with a generated UUID
  factory ArrowData.create({
    String? id,
    required String fromNodeId,
    required String toNodeId,
    String? label,
    Offset delta1 = Offset.zero,
    Offset delta2 = Offset.zero,
    bool bidirectional = false,
    ArrowStyle? style,
  }) {
    return ArrowData(
      id: id ?? _uuid.v4(),
      fromNodeId: fromNodeId,
      toNodeId: toNodeId,
      label: label,
      delta1: delta1,
      delta2: delta2,
      bidirectional: bidirectional,
      style: style,
    );
  }

  ArrowData copyWith({
    String? id,
    String? fromNodeId,
    String? toNodeId,
    String? label,
    Offset? delta1,
    Offset? delta2,
    bool? bidirectional,
    ArrowStyle? style,
  }) {
    return ArrowData(
      id: id ?? this.id,
      fromNodeId: fromNodeId ?? this.fromNodeId,
      toNodeId: toNodeId ?? this.toNodeId,
      label: label ?? this.label,
      delta1: delta1 ?? this.delta1,
      delta2: delta2 ?? this.delta2,
      bidirectional: bidirectional ?? this.bidirectional,
      style: style ?? this.style,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      if (label != null) 'label': label,
      'delta1': {'dx': delta1.dx, 'dy': delta1.dy},
      'delta2': {'dx': delta2.dx, 'dy': delta2.dy},
      'bidirectional': bidirectional,
      if (style != null) 'style': style!.toJson(),
    };
  }

  factory ArrowData.fromJson(Map<String, dynamic> json) {
    return ArrowData(
      id: json['id'] ?? _uuid.v4(),
      fromNodeId: json['fromNodeId'] ?? '',
      toNodeId: json['toNodeId'] ?? '',
      label: json['label'],
      delta1: json['delta1'] != null
          ? Offset(
              json['delta1']['dx']?.toDouble() ?? 0.0,
              json['delta1']['dy']?.toDouble() ?? 0.0,
            )
          : Offset.zero,
      delta2: json['delta2'] != null
          ? Offset(
              json['delta2']['dx']?.toDouble() ?? 0.0,
              json['delta2']['dy']?.toDouble() ?? 0.0,
            )
          : Offset.zero,
      bidirectional: json['bidirectional'] ?? false,
      style: json['style'] != null
          ? ArrowStyle.fromJson(json['style'])
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArrowData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fromNodeId == other.fromNodeId &&
          toNodeId == other.toNodeId &&
          label == other.label &&
          delta1 == other.delta1 &&
          delta2 == other.delta2 &&
          bidirectional == other.bidirectional &&
          style == other.style;

  @override
  int get hashCode =>
      id.hashCode ^
      fromNodeId.hashCode ^
      toNodeId.hashCode ^
      label.hashCode ^
      delta1.hashCode ^
      delta2.hashCode ^
      bidirectional.hashCode ^
      style.hashCode;
}
