import 'package:flutter/material.dart';

/// Tag data for nodes
@immutable
class TagData {
  final String text;
  final TextStyle? style;
  final String? className;

  const TagData({
    required this.text,
    this.style,
    this.className,
  });

  TagData copyWith({
    String? text,
    TextStyle? style,
    String? className,
  }) {
    return TagData(
      text: text ?? this.text,
      style: style ?? this.style,
      className: className ?? this.className,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      if (className != null) 'className': className,
    };
  }

  factory TagData.fromJson(Map<String, dynamic> json) {
    return TagData(
      text: json['text'] ?? '',
      className: json['className'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagData &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          style == other.style &&
          className == other.className;

  @override
  int get hashCode => text.hashCode ^ style.hashCode ^ className.hashCode;
}
