import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

/// Verification tests for built-in themes
void main() {
  group('Built-in Theme Verification', () {
    test('light theme should exist and be accessible', () {
      final theme = MindMapTheme.light;
      
      expect(theme, isNotNull);
      expect(theme.name, equals('light'));
    });

    test('dark theme should exist and be accessible', () {
      final theme = MindMapTheme.dark;
      
      expect(theme, isNotNull);
      expect(theme.name, equals('dark'));
    });

    test('light theme should have complete palette', () {
      final theme = MindMapTheme.light;
      
      // Should have at least 10 colors for variety
      expect(theme.palette.length, greaterThanOrEqualTo(10));
      
      // All colors should be valid
      for (final color in theme.palette) {
        expect(color, isA<Color>());
        expect(color.a, greaterThan(0));
      }
    });

    test('dark theme should have complete palette', () {
      final theme = MindMapTheme.dark;
      
      // Should have at least 10 colors for variety
      expect(theme.palette.length, greaterThanOrEqualTo(10));
      
      // All colors should be valid
      for (final color in theme.palette) {
        expect(color, isA<Color>());
        expect(color.a, greaterThan(0));
      }
    });

    test('light theme should have light background', () {
      final theme = MindMapTheme.light;
      
      // Light theme should have a light background (high luminance)
      expect(theme.variables.bgColor, equals(const Color(0xFFFFFFFF)));
      expect(theme.variables.mainBgColor, equals(const Color(0xFFFFFFFF)));
    });

    test('dark theme should have dark background', () {
      final theme = MindMapTheme.dark;
      
      // Dark theme should have a dark background (low luminance)
      expect(theme.variables.bgColor, equals(const Color(0xFF303030)));
      expect(theme.variables.mainBgColor, equals(const Color(0xFF424242)));
    });

    test('light theme should have all required theme variables', () {
      final theme = MindMapTheme.light;
      final vars = theme.variables;
      
      // Spacing variables
      expect(vars.nodeGapX, greaterThan(0));
      expect(vars.nodeGapY, greaterThan(0));
      expect(vars.mainGapX, greaterThan(0));
      expect(vars.mainGapY, greaterThan(0));
      
      // Color variables
      expect(vars.mainColor, isA<Color>());
      expect(vars.mainBgColor, isA<Color>());
      expect(vars.color, isA<Color>());
      expect(vars.bgColor, isA<Color>());
      expect(vars.selectedColor, isA<Color>());
      expect(vars.accentColor, isA<Color>());
      expect(vars.rootColor, isA<Color>());
      expect(vars.rootBgColor, isA<Color>());
      expect(vars.rootBorderColor, isA<Color>());
      expect(vars.panelColor, isA<Color>());
      expect(vars.panelBgColor, isA<Color>());
      expect(vars.panelBorderColor, isA<Color>());
      
      // Radius variables
      expect(vars.rootRadius, greaterThanOrEqualTo(0));
      expect(vars.mainRadius, greaterThanOrEqualTo(0));
      
      // Padding variables
      expect(vars.topicPadding, isA<EdgeInsets>());
      expect(vars.mapPadding, isA<EdgeInsets>());
    });

    test('dark theme should have all required theme variables', () {
      final theme = MindMapTheme.dark;
      final vars = theme.variables;
      
      // Spacing variables
      expect(vars.nodeGapX, greaterThan(0));
      expect(vars.nodeGapY, greaterThan(0));
      expect(vars.mainGapX, greaterThan(0));
      expect(vars.mainGapY, greaterThan(0));
      
      // Color variables
      expect(vars.mainColor, isA<Color>());
      expect(vars.mainBgColor, isA<Color>());
      expect(vars.color, isA<Color>());
      expect(vars.bgColor, isA<Color>());
      expect(vars.selectedColor, isA<Color>());
      expect(vars.accentColor, isA<Color>());
      expect(vars.rootColor, isA<Color>());
      expect(vars.rootBgColor, isA<Color>());
      expect(vars.rootBorderColor, isA<Color>());
      expect(vars.panelColor, isA<Color>());
      expect(vars.panelBgColor, isA<Color>());
      expect(vars.panelBorderColor, isA<Color>());
      
      // Radius variables
      expect(vars.rootRadius, greaterThanOrEqualTo(0));
      expect(vars.mainRadius, greaterThanOrEqualTo(0));
      
      // Padding variables
      expect(vars.topicPadding, isA<EdgeInsets>());
      expect(vars.mapPadding, isA<EdgeInsets>());
    });

    test('light and dark themes should have different colors', () {
      final lightTheme = MindMapTheme.light;
      final darkTheme = MindMapTheme.dark;
      
      // Background colors should be different
      expect(lightTheme.variables.bgColor, isNot(equals(darkTheme.variables.bgColor)));
      expect(lightTheme.variables.mainBgColor, isNot(equals(darkTheme.variables.mainBgColor)));
      
      // Text colors should be different
      expect(lightTheme.variables.color, isNot(equals(darkTheme.variables.color)));
      expect(lightTheme.variables.mainColor, isNot(equals(darkTheme.variables.mainColor)));
    });

    test('themes should be usable in MindMapData', () {
      final rootNode = NodeData.create(topic: 'Root');
      
      // Should be able to create MindMapData with light theme
      final lightData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.light,
      );
      expect(lightData.theme, equals(MindMapTheme.light));
      
      // Should be able to create MindMapData with dark theme
      final darkData = MindMapData(
        nodeData: rootNode,
        theme: MindMapTheme.dark,
      );
      expect(darkData.theme, equals(MindMapTheme.dark));
    });

    test('themes should support JSON serialization', () {
      final lightTheme = MindMapTheme.light;
      final darkTheme = MindMapTheme.dark;
      
      // Should be able to serialize to JSON
      final lightJson = lightTheme.toJson();
      final darkJson = darkTheme.toJson();
      
      expect(lightJson, isA<Map<String, dynamic>>());
      expect(darkJson, isA<Map<String, dynamic>>());
      
      expect(lightJson['name'], equals('light'));
      expect(darkJson['name'], equals('dark'));
      
      // Should be able to deserialize from JSON
      final lightFromJson = MindMapTheme.fromJson(lightJson);
      final darkFromJson = MindMapTheme.fromJson(darkJson);
      
      expect(lightFromJson.name, equals('light'));
      expect(darkFromJson.name, equals('dark'));
    });

    test('themes should have consistent palette sizes', () {
      final lightTheme = MindMapTheme.light;
      final darkTheme = MindMapTheme.dark;
      
      // Both themes should have the same number of palette colors
      expect(lightTheme.palette.length, equals(darkTheme.palette.length));
    });

    test('theme palettes should provide good color variety', () {
      final lightTheme = MindMapTheme.light;
      final darkTheme = MindMapTheme.dark;
      
      // Check that palette colors are distinct (not all the same)
      final lightColors = lightTheme.palette.toSet();
      final darkColors = darkTheme.palette.toSet();
      
      // Should have at least 10 unique colors
      expect(lightColors.length, greaterThanOrEqualTo(10));
      expect(darkColors.length, greaterThanOrEqualTo(10));
    });
  });
}
