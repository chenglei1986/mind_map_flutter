import 'package:flutter/material.dart';

/// Arrow style properties
@immutable
class ArrowStyle {
  final Color? strokeColor;
  final double? strokeWidth;
  final List<double>? dashPattern;
  final double? opacity;

  const ArrowStyle({
    this.strokeColor,
    this.strokeWidth,
    this.dashPattern,
    this.opacity,
  });

  ArrowStyle copyWith({
    Color? strokeColor,
    double? strokeWidth,
    List<double>? dashPattern,
    double? opacity,
  }) {
    return ArrowStyle(
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      dashPattern: dashPattern ?? this.dashPattern,
      opacity: opacity ?? this.opacity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (strokeColor != null) 'strokeColor': strokeColor!.toARGB32(),
      if (strokeWidth != null) 'strokeWidth': strokeWidth,
      if (dashPattern != null) 'dashPattern': dashPattern,
      if (opacity != null) 'opacity': opacity,
    };
  }

  factory ArrowStyle.fromJson(Map<String, dynamic> json) {
    return ArrowStyle(
      strokeColor: json['strokeColor'] != null 
          ? Color(json['strokeColor']) 
          : null,
      strokeWidth: json['strokeWidth']?.toDouble(),
      dashPattern: json['dashPattern'] != null
          ? List<double>.from(json['dashPattern'])
          : null,
      opacity: json['opacity']?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArrowStyle &&
          runtimeType == other.runtimeType &&
          strokeColor == other.strokeColor &&
          strokeWidth == other.strokeWidth &&
          _listEquals(dashPattern, other.dashPattern) &&
          opacity == other.opacity;

  @override
  int get hashCode =>
      strokeColor.hashCode ^
      strokeWidth.hashCode ^
      dashPattern.hashCode ^
      opacity.hashCode;

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
