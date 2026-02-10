import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/widgets/mind_map_widget.dart';

void main() {
  group('Edit Overlay Wrap Logic', () {
    const baseStyle = TextStyle(
      inherit: false,
      fontSize: 16,
      fontWeight: FontWeight.normal,
      letterSpacing: 0,
      wordSpacing: 0,
      textBaseline: TextBaseline.alphabetic,
    );

    test('should wrap when text contains explicit newline', () {
      final shouldWrap = MindMapState.shouldWrapEditText(
        text: 'line1\nline2',
        style: baseStyle,
        contentWidth: 1000,
      );

      expect(shouldWrap, isTrue);
    });

    test('should not wrap when single-line text has enough width', () {
      final shouldWrap = MindMapState.shouldWrapEditText(
        text: 'Single line text',
        style: baseStyle,
        contentWidth: 1000,
      );

      expect(shouldWrap, isFalse);
    });

    test('should wrap when width is too narrow for single-line text', () {
      final shouldWrap = MindMapState.shouldWrapEditText(
        text: 'Single line text that is too long',
        style: baseStyle,
        contentWidth: 20,
      );

      expect(shouldWrap, isTrue);
    });

    test('should wrap when content width is non-positive', () {
      final shouldWrap = MindMapState.shouldWrapEditText(
        text: 'text',
        style: baseStyle,
        contentWidth: 0,
      );

      expect(shouldWrap, isTrue);
    });

    test('should not wrap at near-boundary width tolerance', () {
      const text = 'BoundaryText';
      final painter = TextPainter(
        text: const TextSpan(text: text, style: baseStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

      final shouldWrap = MindMapState.shouldWrapEditText(
        text: text,
        style: baseStyle,
        contentWidth: painter.width + 0.25,
      );

      expect(shouldWrap, isFalse);
    });
  });
}
