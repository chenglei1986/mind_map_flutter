import 'package:flutter/material.dart';

/// Theme variables for mind map styling
@immutable
class ThemeVariables {
  final double nodeGapX;
  final double nodeGapY;
  final double mainGapX;
  final double mainGapY;
  final Color mainColor;
  final Color mainBgColor;
  final Color color;
  final Color bgColor;
  final Color selectedColor;
  final Color accentColor;
  final Color rootColor;
  final Color rootBgColor;
  final Color rootBorderColor;
  final double rootRadius;
  final double mainRadius;
  final EdgeInsets topicPadding;
  final Color panelColor;
  final Color panelBgColor;
  final Color panelBorderColor;
  final EdgeInsets mapPadding;

  const ThemeVariables({
    required this.nodeGapX,
    required this.nodeGapY,
    required this.mainGapX,
    required this.mainGapY,
    required this.mainColor,
    required this.mainBgColor,
    required this.color,
    required this.bgColor,
    required this.selectedColor,
    required this.accentColor,
    required this.rootColor,
    required this.rootBgColor,
    required this.rootBorderColor,
    required this.rootRadius,
    required this.mainRadius,
    required this.topicPadding,
    required this.panelColor,
    required this.panelBgColor,
    required this.panelBorderColor,
    required this.mapPadding,
  });

  ThemeVariables copyWith({
    double? nodeGapX,
    double? nodeGapY,
    double? mainGapX,
    double? mainGapY,
    Color? mainColor,
    Color? mainBgColor,
    Color? color,
    Color? bgColor,
    Color? selectedColor,
    Color? accentColor,
    Color? rootColor,
    Color? rootBgColor,
    Color? rootBorderColor,
    double? rootRadius,
    double? mainRadius,
    EdgeInsets? topicPadding,
    Color? panelColor,
    Color? panelBgColor,
    Color? panelBorderColor,
    EdgeInsets? mapPadding,
  }) {
    return ThemeVariables(
      nodeGapX: nodeGapX ?? this.nodeGapX,
      nodeGapY: nodeGapY ?? this.nodeGapY,
      mainGapX: mainGapX ?? this.mainGapX,
      mainGapY: mainGapY ?? this.mainGapY,
      mainColor: mainColor ?? this.mainColor,
      mainBgColor: mainBgColor ?? this.mainBgColor,
      color: color ?? this.color,
      bgColor: bgColor ?? this.bgColor,
      selectedColor: selectedColor ?? this.selectedColor,
      accentColor: accentColor ?? this.accentColor,
      rootColor: rootColor ?? this.rootColor,
      rootBgColor: rootBgColor ?? this.rootBgColor,
      rootBorderColor: rootBorderColor ?? this.rootBorderColor,
      rootRadius: rootRadius ?? this.rootRadius,
      mainRadius: mainRadius ?? this.mainRadius,
      topicPadding: topicPadding ?? this.topicPadding,
      panelColor: panelColor ?? this.panelColor,
      panelBgColor: panelBgColor ?? this.panelBgColor,
      panelBorderColor: panelBorderColor ?? this.panelBorderColor,
      mapPadding: mapPadding ?? this.mapPadding,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nodeGapX': nodeGapX,
      'nodeGapY': nodeGapY,
      'mainGapX': mainGapX,
      'mainGapY': mainGapY,
      'mainColor': mainColor.toARGB32(),
      'mainBgColor': mainBgColor.toARGB32(),
      'color': color.toARGB32(),
      'bgColor': bgColor.toARGB32(),
      'selectedColor': selectedColor.toARGB32(),
      'accentColor': accentColor.toARGB32(),
      'rootColor': rootColor.toARGB32(),
      'rootBgColor': rootBgColor.toARGB32(),
      'rootBorderColor': rootBorderColor.toARGB32(),
      'rootRadius': rootRadius,
      'mainRadius': mainRadius,
      'topicPadding': {
        'left': topicPadding.left,
        'top': topicPadding.top,
        'right': topicPadding.right,
        'bottom': topicPadding.bottom,
      },
      'panelColor': panelColor.toARGB32(),
      'panelBgColor': panelBgColor.toARGB32(),
      'panelBorderColor': panelBorderColor.toARGB32(),
      'mapPadding': {
        'left': mapPadding.left,
        'top': mapPadding.top,
        'right': mapPadding.right,
        'bottom': mapPadding.bottom,
      },
    };
  }

  factory ThemeVariables.fromJson(Map<String, dynamic> json) {
    return ThemeVariables(
      nodeGapX: json['nodeGapX']?.toDouble() ?? 50.0,
      nodeGapY: json['nodeGapY']?.toDouble() ?? 20.0,
      mainGapX: json['mainGapX']?.toDouble() ?? 80.0,
      mainGapY: json['mainGapY']?.toDouble() ?? 30.0,
      mainColor: Color(json['mainColor'] ?? 0xFF000000),
      mainBgColor: Color(json['mainBgColor'] ?? 0xFFFFFFFF),
      color: Color(json['color'] ?? 0xFF000000),
      bgColor: Color(json['bgColor'] ?? 0xFFFFFFFF),
      selectedColor: Color(json['selectedColor'] ?? 0xFF2196F3),
      accentColor: Color(json['accentColor'] ?? 0xFFFF9800),
      rootColor: Color(json['rootColor'] ?? 0xFFFFFFFF),
      rootBgColor: Color(json['rootBgColor'] ?? 0xFF2196F3),
      rootBorderColor: Color(json['rootBorderColor'] ?? 0xFF1976D2),
      rootRadius: json['rootRadius']?.toDouble() ?? 8.0,
      mainRadius: json['mainRadius']?.toDouble() ?? 4.0,
      topicPadding: json['topicPadding'] != null
          ? EdgeInsets.only(
              left: json['topicPadding']['left']?.toDouble() ?? 3.0,
              top: json['topicPadding']['top']?.toDouble() ?? 3.0,
              right: json['topicPadding']['right']?.toDouble() ?? 3.0,
              bottom: json['topicPadding']['bottom']?.toDouble() ?? 3.0,
            )
          : const EdgeInsets.all(3.0),
      panelColor: Color(json['panelColor'] ?? 0xFF000000),
      panelBgColor: Color(json['panelBgColor'] ?? 0xFFFFFFFF),
      panelBorderColor: Color(json['panelBorderColor'] ?? 0xFFE0E0E0),
      mapPadding: json['mapPadding'] != null
          ? EdgeInsets.only(
              left: json['mapPadding']['left']?.toDouble() ?? 50.0,
              top: json['mapPadding']['top']?.toDouble() ?? 50.0,
              right: json['mapPadding']['right']?.toDouble() ?? 50.0,
              bottom: json['mapPadding']['bottom']?.toDouble() ?? 50.0,
            )
          : const EdgeInsets.all(50.0),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeVariables &&
          runtimeType == other.runtimeType &&
          nodeGapX == other.nodeGapX &&
          nodeGapY == other.nodeGapY &&
          mainGapX == other.mainGapX &&
          mainGapY == other.mainGapY &&
          mainColor == other.mainColor &&
          mainBgColor == other.mainBgColor &&
          color == other.color &&
          bgColor == other.bgColor &&
          selectedColor == other.selectedColor &&
          accentColor == other.accentColor &&
          rootColor == other.rootColor &&
          rootBgColor == other.rootBgColor &&
          rootBorderColor == other.rootBorderColor &&
          rootRadius == other.rootRadius &&
          mainRadius == other.mainRadius &&
          topicPadding == other.topicPadding &&
          panelColor == other.panelColor &&
          panelBgColor == other.panelBgColor &&
          panelBorderColor == other.panelBorderColor &&
          mapPadding == other.mapPadding;

  @override
  int get hashCode =>
      nodeGapX.hashCode ^
      nodeGapY.hashCode ^
      mainGapX.hashCode ^
      mainGapY.hashCode ^
      mainColor.hashCode ^
      mainBgColor.hashCode ^
      color.hashCode ^
      bgColor.hashCode ^
      selectedColor.hashCode ^
      accentColor.hashCode ^
      rootColor.hashCode ^
      rootBgColor.hashCode ^
      rootBorderColor.hashCode ^
      rootRadius.hashCode ^
      mainRadius.hashCode ^
      topicPadding.hashCode ^
      panelColor.hashCode ^
      panelBgColor.hashCode ^
      panelBorderColor.hashCode ^
      mapPadding.hashCode;
}
