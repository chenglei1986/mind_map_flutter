import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/node_data.dart';
import '../models/image_data.dart';
import '../models/mind_map_theme.dart';
import '../models/layout_direction.dart';
import '../layout/node_layout.dart';

/// Renderer for individual nodes
class NodeRenderer {
  /// Size of the expand/collapse indicator
  static const double indicatorSize = 18.0;

  /// Padding between node and indicator
  /// Kept for backward-compatible tests that call old APIs.
  static const double indicatorPadding = 8.0;
  static const double _mainIndicatorOffset = 10.0; // core: left/right = -10px
  static const double _subIndicatorInset = 5.0; // core: left/right = 5px
  static const double _subParentPaddingY = 6.0; // core: me-parent padding-y
  static const double _hyperlinkTailGap = 4.0;

  /// Maximum width multiplier for node text (35em)
  /// Matches mind-elixir-core's max-width: 35em
  static const double maxWidthEm = 35.0;

  /// Draw a node on the canvas
  static void drawNode(
    Canvas canvas,
    NodeData node,
    NodeLayout layout,
    MindMapTheme theme,
    bool isSelected,
    bool isRoot, {
    bool showExpandIndicator = true,
    bool showCollapseIndicator = true,
    int depth = 0,
    bool? isLeftSideOverride,
    Map<String, ui.Image>? imageCache,
  }) {
    final bounds = layout.bounds;

    // Draw node background and border
    _drawNodeBackground(canvas, node, bounds, theme, isRoot, depth);

    // Draw selection indicator if selected
    if (isSelected) {
      _drawSelectionIndicator(canvas, bounds, theme);
    }

    // Draw node content (image, text, hyperlink, icons, tags)
    _drawNodeContent(
      canvas,
      node,
      bounds,
      theme,
      depth,
      isLeftSideOverride: isLeftSideOverride,
      imageCache: imageCache,
    );

    // Draw expand/collapse indicator if node has children
    // Expand button (+): show if showExpandIndicator is true
    // Collapse button (-): show if showCollapseIndicator is true
    if (node.children.isNotEmpty) {
      final shouldShow = node.expanded
          ? showCollapseIndicator
          : showExpandIndicator;
      if (shouldShow) {
        _drawExpandIndicator(
          canvas,
          node,
          bounds,
          theme,
          depth,
          isLeftSideOverride: isLeftSideOverride,
        );
      }
    }
  }

  /// Draw the node background with rounded corners
  /// Implements three-tier styling based on node depth:
  /// - depth 0 (root): 25px font, 10px 30px padding, 2px border, root-radius, root background
  /// - depth 1 (main): 16px font, 8px 25px padding, 2px border, main-radius, main background
  /// - depth 2+ (child): 14px font, 3px padding, 3px radius, no border, transparent background
  static void _drawNodeBackground(
    Canvas canvas,
    NodeData node,
    Rect bounds,
    MindMapTheme theme,
    bool isRoot,
    int depth,
  ) {
    final style = node.style;
    final variables = theme.variables;

    // Determine background color based on depth
    // Child nodes (depth 2+) have transparent background by default
    final backgroundColor =
        style?.background ??
        (depth == 0
            ? variables.rootBgColor
            : depth == 1
            ? variables.mainBgColor
            : Colors.transparent);

    // Determine border radius based on depth
    // Root: rootRadius, Main: mainRadius, Child: 3px
    final radius = depth == 0
        ? variables.rootRadius
        : (depth == 1 ? variables.mainRadius : 3.0);

    // Create rounded rectangle
    final rrect = RRect.fromRectAndRadius(bounds, Radius.circular(radius));

    // Draw background only if not transparent
    if (backgroundColor != Colors.transparent) {
      final backgroundPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, backgroundPaint);
    }

    // Draw border
    // Root: rootBorderColor 2px, Main: mainColor 2px, Child: no border
    final mainBorderColor = node.branchColor ?? variables.mainColor;
    final borderColor = style?.border != null
        ? (style!.border as Border?)?.top.color ??
              (depth == 0
                  ? variables.rootBorderColor
                  : depth == 1
                  ? mainBorderColor
                  : Colors.transparent)
        : (depth == 0
              ? variables.rootBorderColor
              : depth == 1
              ? mainBorderColor
              : Colors.transparent);

    final borderWidth = style?.border != null
        ? (style!.border as Border?)?.top.width ?? 1.0
        : (depth <= 1 ? 2.0 : 0.0);

    if (borderWidth > 0) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  /// Draw selection indicator around the node
  static void _drawSelectionIndicator(
    Canvas canvas,
    Rect bounds,
    MindMapTheme theme,
  ) {
    final selectionPadding = 4.0;
    final selectionBounds = bounds.inflate(selectionPadding);
    final selectionRRect = RRect.fromRectAndRadius(
      selectionBounds,
      Radius.circular(theme.variables.mainRadius + selectionPadding),
    );

    final selectionPaint = Paint()
      ..color = theme.variables.selectedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(selectionRRect, selectionPaint);
  }

  /// Draw the node text content
  /// Implements three-tier font sizing:
  /// - depth 0 (root): 25px
  /// - depth 1 (main): 16px
  /// - depth 2+ (child): 14px
  ///
  /// Text width follows content with max-width constraint (35em),
  /// matching mind-elixir-core's CSS: max-width: 35em; white-space: pre-wrap;
  /// Text wraps when exceeding max width (white-space: pre-wrap behavior)
  static void _drawNodeContent(
    Canvas canvas,
    NodeData node,
    Rect bounds,
    MindMapTheme theme,
    int depth, {
    bool? isLeftSideOverride,
    Map<String, ui.Image>? imageCache,
  }) {
    final style = node.style;
    final variables = theme.variables;

    // Determine text color based on depth
    // Root: rootColor, Main: mainColor, Child: color
    final textColor =
        style?.color ??
        (depth == 0
            ? variables.rootColor
            : depth == 1
            ? variables.mainColor
            : variables.color);

    // Determine font size based on depth
    // Root: 25px, Main: 16px, Child: 14px
    final fontSize =
        style?.fontSize ?? (depth == 0 ? 25.0 : (depth == 1 ? 16.0 : 14.0));

    // Determine font weight
    final fontWeight =
        style?.fontWeight ?? (depth == 0 ? FontWeight.bold : FontWeight.normal);

    // Determine font family
    final fontFamily = style?.fontFamily;

    // Create text style
    final textStyle = TextStyle(
      color: textColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: fontFamily,
      decoration: style?.textDecoration,
    );

    // Determine padding based on depth
    final EdgeInsets padding = depth == 0
        ? const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0)
        : (depth == 1
              ? const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0)
              : variables.topicPadding);

    final contentLeft = bounds.left + padding.left;
    final contentTop = bounds.top + padding.top;
    final contentWidth = math.max(0.0, bounds.width - padding.horizontal);
    double cursorY = contentTop;

    // Calculate max box width (35em relative to font size, per CSS)
    final maxBoxWidth = fontSize * maxWidthEm;
    final maxTextWidth = math.max(0.0, maxBoxWidth - padding.horizontal);

    // Create text painter with wrapping support
    final textPainter = TextPainter(
      text: TextSpan(text: node.topic, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    // Layout with max width constraint to enable wrapping
    // This matches mind-elixir-core's white-space: pre-wrap behavior
    textPainter.layout(maxWidth: math.min(maxTextWidth, contentWidth));

    final imageFlow = _layoutImages(
      node.effectiveImages,
      maxWidth: contentWidth,
      gap: 8.0,
      bottomMargin: 8.0,
    );
    for (var i = 0; i < imageFlow.rects.length; i++) {
      final image = node.effectiveImages[i];
      final imageRect = imageFlow.rects[i].shift(Offset(contentLeft, cursorY));
      final decoded = imageCache?[image.url];
      if (decoded != null) {
        final srcRect = Rect.fromLTWH(
          0.0,
          0.0,
          decoded.width.toDouble(),
          decoded.height.toDouble(),
        );
        final fitted = applyBoxFit(image.fit, srcRect.size, imageRect.size);
        final inputRect = Alignment.center.inscribe(fitted.source, srcRect);
        final outputRect = Alignment.center.inscribe(
          fitted.destination,
          imageRect,
        );

        canvas.save();
        canvas.clipRect(imageRect);
        final imagePaint = Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.medium;
        canvas.drawImageRect(decoded, inputRect, outputRect, imagePaint);
        canvas.restore();
      } else {
        final placeholderPaint = Paint()
          ..color = theme.variables.bgColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawRect(imageRect, placeholderPaint);

        final imgTextStyle = TextStyle(
          fontSize: 12.0,
          color: theme.variables.mainColor.withValues(alpha: 0.5),
          fontWeight: FontWeight.w500,
        );
        final imgTextPainter = TextPainter(
          text: TextSpan(text: 'IMG', style: imgTextStyle),
          textDirection: TextDirection.ltr,
        );
        imgTextPainter.layout();
        final imgTextOffset = Offset(
          imageRect.left + (imageRect.width - imgTextPainter.width) / 2,
          imageRect.top + (imageRect.height - imgTextPainter.height) / 2,
        );
        imgTextPainter.paint(canvas, imgTextOffset);
      }

      final borderPaint = Paint()
        ..color = theme.variables.mainColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(imageRect, borderPaint);
    }
    cursorY += imageFlow.totalHeight;

    // Draw text
    textPainter.paint(canvas, Offset(contentLeft, cursorY));

    final lineMetrics = textPainter.computeLineMetrics();
    final lastLine = lineMetrics.isNotEmpty ? lineMetrics.last : null;
    final lastLineTop = lastLine != null
        ? cursorY + (textPainter.height - lastLine.height)
        : cursorY;
    final lastLineWidth = lastLine?.width ?? 0.0;

    double extrasX = contentLeft + lastLineWidth;
    double extrasY = lastLineTop;
    bool extrasWrapped = false;

    if (node.icons.isNotEmpty) {
      extrasX += 5.0; // icons margin-left
      final iconsPainter = TextPainter(
        text: TextSpan(
          text: node.icons.join(''),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      iconsPainter.layout();
      if (extrasX + iconsPainter.width > contentLeft + contentWidth &&
          contentWidth > 0) {
        extrasWrapped = true;
        extrasX = contentLeft;
        extrasY = cursorY + textPainter.height;
      }
      iconsPainter.paint(canvas, Offset(extrasX, extrasY));
      extrasX += iconsPainter.width;
    }

    if (node.hyperLink != null && node.hyperLink!.isNotEmpty) {
      final linkPainter = TextPainter(
        text: TextSpan(
          text: '🔗',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            fontFamily: fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final isLeftSide =
          isLeftSideOverride ?? (node.direction == LayoutDirection.left);
      final linkBounds = _computeHyperlinkTailBounds(
        bounds,
        linkPainter,
        isLeftSide: isLeftSide,
      );
      linkPainter.paint(canvas, linkBounds.topLeft);
    }

    cursorY +=
        textPainter.height + (extrasWrapped ? (lastLine?.height ?? 0.0) : 0.0);

    if (node.tags.isEmpty) return;
    cursorY += 2.0; // margin-top for tags

    const tagFontSize = 12.0;
    const tagPaddingH = 8.0;
    const tagPaddingV = 4.0;
    const tagMarginRight = 4.0;
    const tagRadius = 3.0;
    final tagLineHeight = tagFontSize * 1.3 + tagPaddingV;

    double x = contentLeft;
    double y = cursorY;

    for (final tag in node.tags) {
      final tagStyle =
          tag.style ??
          const TextStyle(fontSize: tagFontSize, color: Color(0xFF276F86));
      final tagTextPainter = TextPainter(
        text: TextSpan(text: tag.text, style: tagStyle),
        textDirection: TextDirection.ltr,
      );
      tagTextPainter.layout();

      final tagWidth = tagTextPainter.width + tagPaddingH;
      if (x > contentLeft &&
          x + tagWidth > contentLeft + contentWidth &&
          contentWidth > 0) {
        x = contentLeft;
        y += tagLineHeight + 2.0;
      }

      final tagBounds = Rect.fromLTWH(x, y, tagWidth, tagLineHeight);
      final tagRRect = RRect.fromRectAndRadius(
        tagBounds,
        const Radius.circular(tagRadius),
      );

      final tagPaint = Paint()
        ..color = const Color(0xFFD6F0F8)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(tagRRect, tagPaint);

      final textOffset = Offset(
        x + tagPaddingH / 2,
        y + (tagLineHeight - tagTextPainter.height) / 2,
      );
      tagTextPainter.paint(canvas, textOffset);

      x += tagWidth + tagMarginRight;
    }
  }

  /// Draw the expand/collapse indicator for nodes with children
  static void _drawExpandIndicator(
    Canvas canvas,
    NodeData node,
    Rect bounds,
    MindMapTheme theme,
    int depth, {
    bool? isLeftSideOverride,
  }) {
    final indicatorCenter = _computeExpandIndicatorCenter(
      node: node,
      bounds: bounds,
      theme: theme,
      depth: depth,
      isLeftSideOverride: isLeftSideOverride,
    );

    // mind-elixir-core visual style: add/minus circle icon with ~0.8 opacity.
    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(indicatorCenter, indicatorSize / 2, backgroundPaint);

    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(indicatorCenter, indicatorSize / 2, borderPaint);

    final symbolPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final symbolSize = indicatorSize * 0.33;

    if (node.expanded) {
      // Draw minus sign (-)
      canvas.drawLine(
        Offset(indicatorCenter.dx - symbolSize, indicatorCenter.dy),
        Offset(indicatorCenter.dx + symbolSize, indicatorCenter.dy),
        symbolPaint,
      );
    } else {
      // Draw collapsed branch count text instead of plus sign.
      final hiddenBranches = node.children.length;
      final label = hiddenBranches > 99 ? '99+' : '$hiddenBranches';
      final fontSize = hiddenBranches >= 10 ? 8.0 : 9.5;

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.85),
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final textOffset = Offset(
        indicatorCenter.dx - textPainter.width / 2,
        indicatorCenter.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  /// Get the bounds of the expand/collapse indicator for a node
  /// Returns null if the node has no children
  static Rect? getExpandIndicatorBounds(
    NodeData node,
    NodeLayout layout, [
    MindMapTheme? theme,
    int depth = 2,
    bool? isLeftSideOverride,
  ]) {
    if (node.children.isEmpty) return null;
    if (theme != null && depth == 0) return null;

    // Backward-compatible behavior for older callers/tests (2-arg signature).
    if (theme == null) {
      final isLeftSide =
          isLeftSideOverride ?? (node.direction == LayoutDirection.left);
      final indicatorCenter = isLeftSide
          ? Offset(
              layout.bounds.left - indicatorPadding - indicatorSize / 2,
              layout.bounds.center.dy,
            )
          : Offset(
              layout.bounds.right + indicatorPadding + indicatorSize / 2,
              layout.bounds.center.dy,
            );
      return Rect.fromCenter(
        center: indicatorCenter,
        width: indicatorSize,
        height: indicatorSize,
      );
    }

    final indicatorCenter = _computeExpandIndicatorCenter(
      node: node,
      bounds: layout.bounds,
      theme: theme,
      depth: depth,
      isLeftSideOverride: isLeftSideOverride,
    );

    return Rect.fromCenter(
      center: indicatorCenter,
      width: indicatorSize,
      height: indicatorSize,
    );
  }

  static Offset _computeExpandIndicatorCenter({
    required NodeData node,
    required Rect bounds,
    required MindMapTheme theme,
    required int depth,
    bool? isLeftSideOverride,
  }) {
    final isLeftSide =
        isLeftSideOverride ?? (node.direction == LayoutDirection.left);
    final half = indicatorSize / 2;
    final dxMain = _mainIndicatorOffset - half; // -10px css offset
    if (depth == 1) {
      // mind-elixir-core main node:
      // me-main > me-wrapper > me-parent { padding: 0; margin: 10px; }
      // me-epd is anchored to the me-parent box, which matches topic bounds.
      return Offset(
        isLeftSide ? bounds.left - dxMain : bounds.right + dxMain,
        bounds.center.dy,
      );
    }

    final gap = theme.variables.nodeGapX;
    final virtualParent = Rect.fromLTWH(
      bounds.left - gap,
      bounds.top - _subParentPaddingY,
      bounds.width + gap * 2,
      bounds.height + _subParentPaddingY * 2,
    );
    final dxSub = _subIndicatorInset + half; // 5px css inset
    return Offset(
      isLeftSide ? virtualParent.left + dxSub : virtualParent.right - dxSub,
      virtualParent.bottom,
    );
  }

  /// Get the bounds of the hyperlink icon for a node.
  /// In themed mode the icon is rendered outside node tail:
  /// left-side nodes place it at the left, right-side nodes at the right.
  /// Returns null if the node has no hyperlink
  static Rect? getHyperlinkIndicatorBounds(
    NodeData node,
    NodeLayout layout, [
    MindMapTheme? theme,
    int depth = 2,
    bool? isLeftSideOverride,
  ]) {
    if (node.hyperLink == null || node.hyperLink!.isEmpty) return null;

    // Backward-compatible behavior for older 2-arg callers/tests:
    // return a fixed 14x14 indicator near the bottom-right corner.
    if (theme == null) {
      final b = layout.bounds;
      return Rect.fromLTWH(b.right - 18.0, b.bottom - 18.0, 14.0, 14.0);
    }

    final fontSize =
        node.style?.fontSize ??
        (depth == 0 ? 25.0 : (depth == 1 ? 16.0 : 14.0));
    final fontWeight =
        node.style?.fontWeight ??
        (depth == 0 ? FontWeight.bold : FontWeight.normal);
    final fontFamily = node.style?.fontFamily;
    final linkPainter = TextPainter(
      text: TextSpan(
        text: '🔗',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final isLeftSide =
        isLeftSideOverride ?? (node.direction == LayoutDirection.left);
    return _computeHyperlinkTailBounds(
      layout.bounds,
      linkPainter,
      isLeftSide: isLeftSide,
    );
  }

  /// Measure the size needed for a node
  /// Implements three-tier sizing based on node depth:
  /// - depth 0 (root): 25px font, 10px 30px padding
  /// - depth 1 (main): 16px font, 8px 25px padding
  /// - depth 2+ (child): 14px font, 3px padding (all sides)
  ///
  /// Node width follows text content with max-width constraint (35em),
  /// matching mind-elixir-core's CSS: max-width: 35em; white-space: pre-wrap;
  static Size measureNodeSize(
    NodeData node,
    MindMapTheme theme,
    bool isRoot,
    int depth,
  ) {
    final style = node.style;
    final variables = theme.variables;

    // Determine font size based on depth
    final fontSize =
        style?.fontSize ?? (depth == 0 ? 25.0 : (depth == 1 ? 16.0 : 14.0));

    // Determine font weight
    final fontWeight =
        style?.fontWeight ?? (depth == 0 ? FontWeight.bold : FontWeight.normal);

    // Determine font family
    final fontFamily = style?.fontFamily;

    // Create text style
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: fontFamily,
    );

    // Determine padding based on depth
    // Root: 10px 30px, Main: 8px 25px, Child: var(--topic-padding)
    final EdgeInsets padding = depth == 0
        ? const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0)
        : (depth == 1
              ? const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0)
              : variables.topicPadding);

    // Calculate max box width (35em relative to font size, per CSS)
    final maxBoxWidth = fontSize * maxWidthEm;
    final maxContentWidth = math.max(0.0, maxBoxWidth - padding.horizontal);

    // Create text painter with wrapping support
    final textPainter = TextPainter(
      text: TextSpan(text: node.topic, style: textStyle),
      textDirection: TextDirection.ltr,
    );

    // Layout with max width constraint to enable wrapping
    textPainter.layout(maxWidth: maxContentWidth);
    final lineMetrics = textPainter.computeLineMetrics();
    final maxTextLineWidth = _maxLineWidth(lineMetrics);
    final lastLineWidth = _lastLineWidth(lineMetrics);
    final lastLineHeight = lineMetrics.isNotEmpty
        ? lineMetrics.last.height
        : 0.0;

    // Inline extras after text: icons only.
    // Hyperlink icon is rendered at node tail and does not affect node size.
    double extrasWidth = 0.0;
    if (node.icons.isNotEmpty) {
      extrasWidth += 5.0; // icons container margin-left
      extrasWidth += _measureTextWidth(
        node.icons.join(''),
        TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: fontFamily,
        ),
      );
    }

    double inlineWidth = maxTextLineWidth;
    bool extrasWrapped = false;
    if (extrasWidth > 0.0) {
      if (lastLineWidth + extrasWidth <= maxContentWidth) {
        inlineWidth = math.max(maxTextLineWidth, lastLineWidth + extrasWidth);
      } else {
        inlineWidth = math.max(
          maxTextLineWidth,
          math.min(extrasWidth, maxContentWidth),
        );
        extrasWrapped = true;
      }
    }

    // Tags layout (inline-block spans with wrapping)
    double maxTagsLineWidth = 0.0;
    int tagLines = 0;
    if (node.tags.isNotEmpty) {
      const tagFontSize = 12.0;
      const tagPaddingH = 8.0;
      const tagMarginRight = 4.0;
      double currentLineWidth = 0.0;

      for (final tag in node.tags) {
        final tagStyle = tag.style ?? const TextStyle(fontSize: tagFontSize);
        final tagTextWidth = _measureTextWidth(tag.text, tagStyle);
        final tagWidth = tagTextWidth + tagPaddingH;
        final tagWidthWithMargin = tagWidth + tagMarginRight;

        if (currentLineWidth > 0 &&
            currentLineWidth + tagWidthWithMargin > maxContentWidth) {
          maxTagsLineWidth = math.max(
            maxTagsLineWidth,
            currentLineWidth - tagMarginRight,
          );
          currentLineWidth = 0.0;
          tagLines += 1;
        }

        currentLineWidth += tagWidthWithMargin;
      }

      if (currentLineWidth > 0) {
        maxTagsLineWidth = math.max(
          maxTagsLineWidth,
          currentLineWidth - tagMarginRight,
        );
        tagLines += 1;
      }

      if (maxContentWidth > 0) {
        maxTagsLineWidth = math.min(maxTagsLineWidth, maxContentWidth);
      }
    }

    final imageFlow = _layoutImages(
      node.effectiveImages,
      maxWidth: maxContentWidth,
      gap: 8.0,
      bottomMargin: 8.0,
    );
    final imageWidth = imageFlow.maxRowWidth;
    final contentMaxWidth = maxContentWidth > 0
        ? math.min(
            maxContentWidth,
            math.max(inlineWidth, math.max(maxTagsLineWidth, imageWidth)),
          )
        : math.max(inlineWidth, math.max(maxTagsLineWidth, imageWidth));

    double width = contentMaxWidth + padding.horizontal;
    if (maxBoxWidth > 0) {
      width = math.min(width, maxBoxWidth);
    }

    double contentHeight =
        textPainter.height + (extrasWrapped ? lastLineHeight : 0.0);
    contentHeight += imageFlow.totalHeight;
    if (tagLines > 0) {
      const tagFontSize = 12.0;
      const tagPaddingV = 4.0;
      const tagMarginTop = 2.0;
      final tagLineHeight = tagFontSize * 1.3 + tagPaddingV;
      contentHeight += tagLines * (tagLineHeight + tagMarginTop);
    }

    double height = contentHeight + padding.vertical;

    if (style?.width != null) {
      width = style!.width!;
      if (maxBoxWidth > 0) {
        width = math.min(width, maxBoxWidth);
      }
    }

    return Size(width, height);
  }

  static double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    return painter.width;
  }

  static double _maxLineWidth(List<LineMetrics> lines) {
    if (lines.isEmpty) return 0.0;
    double maxWidth = 0.0;
    for (final line in lines) {
      maxWidth = math.max(maxWidth, line.width);
    }
    return maxWidth;
  }

  static double _lastLineWidth(List<LineMetrics> lines) {
    if (lines.isEmpty) return 0.0;
    return lines.last.width;
  }

  static Rect _computeHyperlinkTailBounds(
    Rect bounds,
    TextPainter linkPainter, {
    required bool isLeftSide,
  }) {
    final x = isLeftSide
        ? bounds.left - _hyperlinkTailGap - linkPainter.width
        : bounds.right + _hyperlinkTailGap;
    final y = bounds.center.dy - linkPainter.height / 2;
    return Rect.fromLTWH(x, y, linkPainter.width, linkPainter.height);
  }

  static _ImageFlowLayout _layoutImages(
    List<ImageData> images, {
    required double maxWidth,
    required double gap,
    required double bottomMargin,
  }) {
    if (images.isEmpty) {
      return const _ImageFlowLayout(
        rects: <Rect>[],
        maxRowWidth: 0.0,
        totalHeight: 0.0,
      );
    }

    final rects = <Rect>[];
    double x = 0.0;
    double y = 0.0;
    double rowHeight = 0.0;
    double maxRowWidth = 0.0;
    final canWrap = maxWidth > 0.0;

    for (final image in images) {
      if (canWrap && x > 0.0 && x + image.width > maxWidth) {
        maxRowWidth = math.max(maxRowWidth, x - gap);
        x = 0.0;
        y += rowHeight + gap;
        rowHeight = 0.0;
      }

      rects.add(Rect.fromLTWH(x, y, image.width, image.height));
      x += image.width + gap;
      rowHeight = math.max(rowHeight, image.height);
    }

    if (x > 0.0) {
      maxRowWidth = math.max(maxRowWidth, x - gap);
    }

    final totalHeight = y + rowHeight + bottomMargin;
    return _ImageFlowLayout(
      rects: rects,
      maxRowWidth: maxRowWidth,
      totalHeight: totalHeight,
    );
  }
}

class _ImageFlowLayout {
  final List<Rect> rects;
  final double maxRowWidth;
  final double totalHeight;

  const _ImageFlowLayout({
    required this.rects,
    required this.maxRowWidth,
    required this.totalHeight,
  });
}
