import 'package:flutter/material.dart';
import 'theme_variables.dart';

/// Mind map theme data
@immutable
class MindMapTheme {
  final String name;
  final List<Color> palette;
  final ThemeVariables variables;

  const MindMapTheme({
    required this.name,
    required this.palette,
    required this.variables,
  });

  /// Light theme
  static final MindMapTheme light = MindMapTheme(
    name: 'light',
    palette: const [
      Color(0xFFE91E63),
      Color(0xFF9C27B0),
      Color(0xFF673AB7),
      Color(0xFF3F51B5),
      Color(0xFF2196F3),
      Color(0xFF00BCD4),
      Color(0xFF009688),
      Color(0xFF4CAF50),
      Color(0xFF8BC34A),
      Color(0xFFCDDC39),
      Color(0xFFFFEB3B),
      Color(0xFFFFC107),
      Color(0xFFFF9800),
      Color(0xFFFF5722),
    ],
    variables: const ThemeVariables(
      nodeGapX: 30.0,  // 匹配 mind-elixir-core: 30px
      nodeGapY: 10.0,  // 匹配 mind-elixir-core: 10px
      mainGapX: 65.0,  // 匹配 mind-elixir-core: 65px
      mainGapY: 45.0,  // 匹配 mind-elixir-core: 45px
      mainColor: Color(0xFF333333),
      mainBgColor: Color(0xFFFFFFFF),
      color: Color(0xFF333333),
      bgColor: Color(0xFFFFFFFF),
      selectedColor: Color(0xFF2196F3),
      accentColor: Color(0xFFFF9800),
      rootColor: Color(0xFFFFFFFF),
      rootBgColor: Color(0xFF4C4F69),
      rootBorderColor: Color(0xFF4C4F69),
      rootRadius: 16.0,
      mainRadius: 16.0,
      topicPadding: EdgeInsets.all(3.0),
      panelColor: Color(0xFF333333),
      panelBgColor: Color(0xFFFFFFFF),
      panelBorderColor: Color(0xFFE0E0E0),
      mapPadding: EdgeInsets.all(50.0),
    ),
  );

  /// Dark theme
  static final MindMapTheme dark = MindMapTheme(
    name: 'dark',
    palette: const [
      Color(0xFFE91E63),
      Color(0xFFAB47BC),
      Color(0xFF7E57C2),
      Color(0xFF5C6BC0),
      Color(0xFF42A5F5),
      Color(0xFF26C6DA),
      Color(0xFF26A69A),
      Color(0xFF66BB6A),
      Color(0xFF9CCC65),
      Color(0xFFD4E157),
      Color(0xFFFFEE58),
      Color(0xFFFFCA28),
      Color(0xFFFFA726),
      Color(0xFFFF7043),
    ],
    variables: const ThemeVariables(
      nodeGapX: 30.0,  // 匹配 mind-elixir-core: 30px
      nodeGapY: 10.0,  // 匹配 mind-elixir-core: 10px
      mainGapX: 65.0,  // 匹配 mind-elixir-core: 65px
      mainGapY: 45.0,  // 匹配 mind-elixir-core: 45px
      mainColor: Color(0xFFE0E0E0),
      mainBgColor: Color(0xFF424242),
      color: Color(0xFFE0E0E0),
      bgColor: Color(0xFF303030),
      selectedColor: Color(0xFF42A5F5),
      accentColor: Color(0xFFFFA726),
      rootColor: Color(0xFFFFFFFF),
      rootBgColor: Color(0xFF1976D2),
      rootBorderColor: Color(0xFF1565C0),
      rootRadius: 16.0,
      mainRadius: 16.0,
      topicPadding: EdgeInsets.all(3.0),
      panelColor: Color(0xFFE0E0E0),
      panelBgColor: Color(0xFF424242),
      panelBorderColor: Color(0xFF616161),
      mapPadding: EdgeInsets.all(50.0),
    ),
  );

  MindMapTheme copyWith({
    String? name,
    List<Color>? palette,
    ThemeVariables? variables,
  }) {
    return MindMapTheme(
      name: name ?? this.name,
      palette: palette ?? this.palette,
      variables: variables ?? this.variables,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'palette': palette.map((c) => c.toARGB32()).toList(),
      'variables': variables.toJson(),
    };
  }

  factory MindMapTheme.fromJson(Map<String, dynamic> json) {
    return MindMapTheme(
      name: json['name'] ?? 'custom',
      palette: json['palette'] != null
          ? (json['palette'] as List).map((c) => Color(c)).toList()
          : MindMapTheme.light.palette,
      variables: json['variables'] != null
          ? ThemeVariables.fromJson(json['variables'])
          : MindMapTheme.light.variables,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MindMapTheme &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          _listEquals(palette, other.palette) &&
          variables == other.variables;

  @override
  int get hashCode =>
      name.hashCode ^ palette.hashCode ^ variables.hashCode;

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
