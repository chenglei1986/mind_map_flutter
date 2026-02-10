import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart'
    show
        TextPainter,
        TextSpan,
        TextStyle,
        TextDirection,
        FontWeight,
        EdgeInsets;
import '../models/node_data.dart';
import '../models/image_data.dart';
import '../models/layout_direction.dart';
import '../models/mind_map_theme.dart';
import 'node_layout.dart';

/// Layout engine for calculating node positions
class LayoutEngine {
  /// Maximum width for node text (35em ≈ 560px at 16px base font)
  /// Matches mind-elixir-core's max-width: 35em
  static const double maxWidthEm = 35.0;
  // mind-elixir-core me-parent has vertical padding: 6px 0 (top + bottom = 12px)
  // which affects effective topic-to-topic vertical spacing for depth > 1.
  static const double _nonRootParentVerticalPadding = 12.0;

  /// Calculate layout for all nodes in the mind map
  Map<String, NodeLayout> calculateLayout(
    NodeData rootNode,
    MindMapTheme theme,
    LayoutDirection direction,
  ) {
    final layouts = <String, NodeLayout>{};
    final subtreeHeights = <String, double>{};

    // Calculate root node layout at origin (will be centered by renderer)
    final rootLayout = _calculateRootLayout(rootNode, theme);
    layouts[rootNode.id] = rootLayout;

    // Precompute subtree heights to avoid node overlap
    _calculateSubtreeHeights(
      rootNode,
      theme,
      subtreeHeights,
      isRoot: true,
      depth: 0,
    );

    // Calculate children layout based on direction
    if (rootNode.children.isNotEmpty && rootNode.expanded) {
      _calculateChildrenLayout(
        rootNode,
        rootLayout,
        layouts,
        theme,
        direction,
        subtreeHeights,
        parentIsRoot: true,
        parentDepth: 0,
      );
    }

    return layouts;
  }

  /// Calculate layout for the root node
  NodeLayout _calculateRootLayout(NodeData node, MindMapTheme theme) {
    final size = _measureNodeSize(node, theme, isRoot: true, depth: 0);
    // Root node positioned at origin (0, 0)
    return NodeLayout(position: Offset.zero, size: size);
  }

  /// Calculate layout for children nodes recursively
  void _calculateChildrenLayout(
    NodeData parentNode,
    NodeLayout parentLayout,
    Map<String, NodeLayout> layouts,
    MindMapTheme theme,
    LayoutDirection direction,
    Map<String, double> subtreeHeights, {
    required bool parentIsRoot,
    int parentDepth = 0,
  }) {
    final children = parentNode.children;
    if (children.isEmpty) return;

    // Determine which children go left and which go right
    final leftChildren = <NodeData>[];
    final rightChildren = <NodeData>[];

    switch (direction) {
      case LayoutDirection.left:
        leftChildren.addAll(children);
        break;
      case LayoutDirection.right:
        rightChildren.addAll(children);
        break;
      case LayoutDirection.side:
        // Distribute children with direction hints and balance counts
        int lcount = 0;
        int rcount = 0;

        for (final child in children) {
          if (child.direction == LayoutDirection.left) {
            leftChildren.add(child);
            lcount++;
          } else if (child.direction == LayoutDirection.right) {
            rightChildren.add(child);
            rcount++;
          } else {
            // Match mind-elixir-core side distribution:
            // even-indexed root children default to right first.
            if (rcount <= lcount) {
              rightChildren.add(child);
              rcount++;
            } else {
              leftChildren.add(child);
              lcount++;
            }
          }
        }
        break;
    }

    // Calculate layout for left children
    if (leftChildren.isNotEmpty) {
      _layoutChildrenOnSide(
        leftChildren,
        parentNode,
        parentLayout,
        layouts,
        theme,
        subtreeHeights,
        isLeft: true,
        parentIsRoot: parentIsRoot,
        parentDepth: parentDepth,
      );
    }

    // Calculate layout for right children
    if (rightChildren.isNotEmpty) {
      _layoutChildrenOnSide(
        rightChildren,
        parentNode,
        parentLayout,
        layouts,
        theme,
        subtreeHeights,
        isLeft: false,
        parentIsRoot: parentIsRoot,
        parentDepth: parentDepth,
      );
    }
  }

  /// Layout children on one side (left or right)
  void _layoutChildrenOnSide(
    List<NodeData> children,
    NodeData parentNode,
    NodeLayout parentLayout,
    Map<String, NodeLayout> layouts,
    MindMapTheme theme,
    Map<String, double> subtreeHeights, {
    required bool isLeft,
    required bool parentIsRoot,
    int parentDepth = 0,
  }) {
    final vars = theme.variables;
    // Match mind-elixir-core box model:
    // - main nodes use --main-gap-*
    // - deeper nodes include me-parent horizontal paddings on both sides
    //   (topic-to-topic distance ~= 2 * --node-gap-x)
    // - deeper nodes include me-parent vertical paddings (6px top/bottom)
    //   in addition to margin-top (--node-gap-y)
    final gapX = parentIsRoot ? vars.mainGapX : vars.nodeGapX * 2;
    final gapY = parentIsRoot
        ? vars.mainGapY
        : vars.nodeGapY + _nonRootParentVerticalPadding;
    final childDepth = parentDepth + 1;

    // Calculate total height needed for all children
    double totalHeight = 0;
    final childSizes = <Size>[];
    final childSubtreeHeights = <double>[];

    for (final child in children) {
      final size = _measureNodeSize(
        child,
        theme,
        isRoot: false,
        depth: childDepth,
      );
      childSizes.add(size);
      final subtreeHeight = subtreeHeights[child.id] ?? size.height;
      childSubtreeHeights.add(subtreeHeight);
      totalHeight += subtreeHeight;
    }

    // Add gaps between children
    totalHeight += gapY * (children.length - 1);

    // Start position (centered vertically relative to parent)
    final parentCenterY =
        parentLayout.position.dy + parentLayout.size.height / 2;
    double currentY = parentCenterY - totalHeight / 2;

    // Position each child
    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      final size = childSizes[i];
      final subtreeHeight = childSubtreeHeights[i];

      // Calculate X position based on side
      final double x;
      if (isLeft) {
        x = parentLayout.position.dx - gapX - size.width;
      } else {
        x = parentLayout.position.dx + parentLayout.size.width + gapX;
      }

      // Center the node vertically within its subtree segment
      final nodeY = currentY + (subtreeHeight - size.height) / 2;

      // Create layout for this child
      final childLayout = NodeLayout(position: Offset(x, nodeY), size: size);
      layouts[child.id] = childLayout;

      // Recursively layout this child's children
      if (child.children.isNotEmpty && child.expanded) {
        _calculateChildrenLayout(
          child,
          childLayout,
          layouts,
          theme,
          isLeft ? LayoutDirection.left : LayoutDirection.right,
          subtreeHeights,
          parentIsRoot: false,
          parentDepth: childDepth,
        );
      }

      // Move to next child position
      currentY += subtreeHeight + gapY;
    }
  }

  double _calculateSubtreeHeights(
    NodeData node,
    MindMapTheme theme,
    Map<String, double> subtreeHeights, {
    required bool isRoot,
    int depth = 0,
  }) {
    final vars = theme.variables;
    final nodeSize = _measureNodeSize(
      node,
      theme,
      isRoot: isRoot,
      depth: depth,
    );
    double height = nodeSize.height;

    if (node.children.isNotEmpty && node.expanded) {
      final gapY = isRoot
          ? vars.mainGapY
          : vars.nodeGapY + _nonRootParentVerticalPadding;
      double total = 0;

      for (final child in node.children) {
        total += _calculateSubtreeHeights(
          child,
          theme,
          subtreeHeights,
          isRoot: false,
          depth: depth + 1,
        );
      }

      total += gapY * (node.children.length - 1);
      if (total > height) {
        height = total;
      }
    }

    subtreeHeights[node.id] = height;
    return height;
  }

  /// Measure the size of a node
  /// Implements three-tier sizing based on node depth:
  /// - depth 0 (root): 25px font, 10px 30px padding
  /// - depth 1 (main): 16px font, 8px 25px padding
  /// - depth 2+ (child): 14px font, 3px padding (all sides)
  ///
  /// Node width follows text content with max-width constraint (35em),
  /// matching mind-elixir-core's CSS: max-width: 35em; white-space: pre-wrap;
  Size _measureNodeSize(
    NodeData node,
    MindMapTheme theme, {
    required bool isRoot,
    int depth = 0,
  }) {
    final vars = theme.variables;

    // Determine padding based on depth
    // Root: 10px 30px, Main: 8px 25px, Child: var(--topic-padding)
    final EdgeInsets padding = depth == 0
        ? const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0)
        : (depth == 1
              ? const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0)
              : vars.topicPadding);

    // Get font size from node style or use defaults based on depth
    final fontSize =
        node.style?.fontSize ??
        (depth == 0 ? 25.0 : (depth == 1 ? 16.0 : 14.0));
    final fontWeight =
        node.style?.fontWeight ??
        (depth == 0 ? FontWeight.bold : FontWeight.normal);

    // Calculate max box width (35em relative to font size, per CSS)
    final maxBoxWidth = fontSize * maxWidthEm;
    final maxContentWidth = math.max(0.0, maxBoxWidth - padding.horizontal);

    // Measure text size with max width constraint for wrapping
    // This matches mind-elixir-core's white-space: pre-wrap behavior
    final textPainter = TextPainter(
      text: TextSpan(
        text: node.topic,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: node.style?.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    // Layout with max width constraint to enable wrapping (pre-wrap)
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
      // icons container margin-left: 5px
      extrasWidth += 5.0;
      extrasWidth += _measureTextWidth(
        node.icons.join(''),
        TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: node.style?.fontFamily,
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
      const tagPaddingH = 8.0; // 4px left + 4px right
      const tagMarginRight = 4.0;
      double currentLineWidth = 0.0;

      for (final tag in node.tags) {
        final tagText = tag.text;
        final tagStyle = tag.style ?? const TextStyle(fontSize: tagFontSize);
        final tagTextWidth = _measureTextWidth(tagText, tagStyle);
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

    // Height calculation
    double contentHeight =
        textPainter.height + (extrasWrapped ? lastLineHeight : 0.0);
    contentHeight += imageFlow.totalHeight;
    if (tagLines > 0) {
      const tagFontSize = 12.0;
      const tagPaddingV = 4.0; // 2px top + 2px bottom
      const tagMarginTop = 2.0;
      final tagLineHeight = tagFontSize * 1.3 + tagPaddingV;
      contentHeight += tagLines * (tagLineHeight + tagMarginTop);
    }

    double height = contentHeight + padding.vertical;

    // Apply custom width if specified (respects max-width)
    if (node.style?.width != null) {
      width = node.style!.width!;
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

  static _ImageFlowLayout _layoutImages(
    List<ImageData> images, {
    required double maxWidth,
    required double gap,
    required double bottomMargin,
  }) {
    if (images.isEmpty) {
      return const _ImageFlowLayout(maxRowWidth: 0.0, totalHeight: 0.0);
    }

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

      x += image.width + gap;
      rowHeight = math.max(rowHeight, image.height);
    }

    if (x > 0.0) {
      maxRowWidth = math.max(maxRowWidth, x - gap);
    }

    final totalHeight = y + rowHeight + bottomMargin;
    return _ImageFlowLayout(maxRowWidth: maxRowWidth, totalHeight: totalHeight);
  }
}

class _ImageFlowLayout {
  final double maxRowWidth;
  final double totalHeight;

  const _ImageFlowLayout({
    required this.maxRowWidth,
    required this.totalHeight,
  });
}
