import 'package:flutter/material.dart';

/// Node style properties
@immutable
class NodeStyle {
  final double? fontSize;
  final String? fontFamily;
  final Color? color;
  final Color? background;
  final FontWeight? fontWeight;
  final double? width;
  final BoxBorder? border;
  final TextDecoration? textDecoration;

  const NodeStyle({
    this.fontSize,
    this.fontFamily,
    this.color,
    this.background,
    this.fontWeight,
    this.width,
    this.border,
    this.textDecoration,
  });

  NodeStyle copyWith({
    double? fontSize,
    String? fontFamily,
    Color? color,
    Color? background,
    FontWeight? fontWeight,
    double? width,
    BoxBorder? border,
    TextDecoration? textDecoration,
  }) {
    return NodeStyle(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      color: color ?? this.color,
      background: background ?? this.background,
      fontWeight: fontWeight ?? this.fontWeight,
      width: width ?? this.width,
      border: border ?? this.border,
      textDecoration: textDecoration ?? this.textDecoration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (fontSize != null) 'fontSize': fontSize,
      if (fontFamily != null) 'fontFamily': fontFamily,
      if (color != null) 'color': color!.toARGB32(),
      if (background != null) 'background': background!.toARGB32(),
      if (fontWeight != null) 'fontWeight': fontWeight!.index,
      if (width != null) 'width': width,
      if (textDecoration != null) 'textDecoration': textDecoration!.toString(),
    };
  }

  factory NodeStyle.fromJson(Map<String, dynamic> json) {
    return NodeStyle(
      fontSize: json['fontSize']?.toDouble(),
      fontFamily: json['fontFamily'],
      color: json['color'] != null ? Color(json['color']) : null,
      background: json['background'] != null ? Color(json['background']) : null,
      fontWeight: json['fontWeight'] != null 
          ? FontWeight.values[json['fontWeight']] 
          : null,
      width: json['width']?.toDouble(),
      textDecoration: json['textDecoration'] != null
          ? _parseTextDecoration(json['textDecoration'])
          : null,
    );
  }

  static TextDecoration? _parseTextDecoration(String value) {
    if (value.contains('underline')) return TextDecoration.underline;
    if (value.contains('lineThrough')) return TextDecoration.lineThrough;
    if (value.contains('overline')) return TextDecoration.overline;
    return TextDecoration.none;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeStyle &&
          runtimeType == other.runtimeType &&
          fontSize == other.fontSize &&
          fontFamily == other.fontFamily &&
          color == other.color &&
          background == other.background &&
          fontWeight == other.fontWeight &&
          width == other.width &&
          border == other.border &&
          textDecoration == other.textDecoration;

  @override
  int get hashCode =>
      fontSize.hashCode ^
      fontFamily.hashCode ^
      color.hashCode ^
      background.hashCode ^
      fontWeight.hashCode ^
      width.hashCode ^
      border.hashCode ^
      textDecoration.hashCode;
}
