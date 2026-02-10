import 'package:flutter/material.dart';

/// Summary style properties
@immutable
class SummaryStyle {
  final Color? stroke;
  final Color? labelColor;

  const SummaryStyle({this.stroke, this.labelColor});

  SummaryStyle copyWith({Color? stroke, Color? labelColor}) {
    return SummaryStyle(
      stroke: stroke ?? this.stroke,
      labelColor: labelColor ?? this.labelColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (stroke != null) 'stroke': stroke!.toARGB32(),
      if (labelColor != null) 'labelColor': labelColor!.toARGB32(),
    };
  }

  factory SummaryStyle.fromJson(Map<String, dynamic> json) {
    return SummaryStyle(
      stroke: json['stroke'] != null ? Color(json['stroke']) : null,
      labelColor: json['labelColor'] != null ? Color(json['labelColor']) : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SummaryStyle &&
          runtimeType == other.runtimeType &&
          stroke == other.stroke &&
          labelColor == other.labelColor;

  @override
  int get hashCode => stroke.hashCode ^ labelColor.hashCode;
}
