import 'package:flutter/material.dart';
import '../i18n/mind_map_strings.dart';

/// Represents a single menu item in the context menu
///
class ContextMenuItem {
  /// The label text displayed for this menu item
  final String label;

  /// The icon displayed next to the label (optional)
  final IconData? icon;

  /// Callback invoked when this menu item is tapped
  final VoidCallback onTap;

  /// Whether this menu item is enabled (default: true)
  final bool enabled;

  /// Whether to show a divider after this item (default: false)
  final bool showDivider;

  const ContextMenuItem({
    required this.label,
    this.icon,
    required this.onTap,
    this.enabled = true,
    this.showDivider = false,
  });
}

/// A context menu popup widget that displays menu items
///
/// This widget is shown when the user right-clicks or long-presses on a node.
/// It provides quick access to common node operations.
///
class ContextMenuPopup extends StatelessWidget {
  /// The position where the menu should be displayed
  final Offset position;

  /// The list of menu items to display
  final List<ContextMenuItem> items;

  /// Callback invoked when the menu is dismissed
  final VoidCallback onDismiss;

  /// The theme colors to use for the menu
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final Color hoverColor;
  final Color dividerColor;

  const ContextMenuPopup({
    Key? key,
    required this.position,
    required this.items,
    required this.onDismiss,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black87,
    this.iconColor = Colors.black54,
    this.hoverColor = const Color(0xFFF5F5F5),
    this.dividerColor = const Color(0xFFE0E0E0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate menu size to ensure it fits on screen
    const double menuWidth = 220.0;
    final screenSize = MediaQuery.of(context).size;

    // Adjust position to keep menu on screen
    double left = position.dx;
    double top = position.dy;

    // Estimate menu height (each item is ~48px, dividers are ~1px)
    final estimatedHeight = items.fold<double>(
      0.0,
      (sum, item) => sum + 48.0 + (item.showDivider ? 1.0 : 0.0),
    );

    // Adjust horizontal position if menu would go off screen
    if (left + menuWidth > screenSize.width) {
      left = screenSize.width - menuWidth - 8;
    }

    // Adjust vertical position if menu would go off screen
    if (top + estimatedHeight > screenSize.height) {
      top = screenSize.height - estimatedHeight - 8;
    }

    // Ensure menu doesn't go off the left or top edge
    left = left.clamp(8.0, screenSize.width - menuWidth - 8);
    top = top.clamp(8.0, screenSize.height - estimatedHeight - 8);

    return Stack(
      children: [
        // Transparent overlay to detect clicks outside the menu
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),

        // The actual menu
        Positioned(
          left: left,
          top: top,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(4),
            color: backgroundColor,
            child: Container(
              width: menuWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: dividerColor, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildMenuItems(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build the list of menu item widgets
  List<Widget> _buildMenuItems() {
    final widgets = <Widget>[];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      // Add the menu item
      widgets.add(
        _ContextMenuItemWidget(
          item: item,
          textColor: textColor,
          iconColor: iconColor,
          hoverColor: hoverColor,
          onDismiss: onDismiss,
        ),
      );

      // Add divider if requested
      if (item.showDivider && i < items.length - 1) {
        widgets.add(Divider(height: 1, thickness: 1, color: dividerColor));
      }
    }

    return widgets;
  }
}

/// Internal widget for rendering a single menu item
class _ContextMenuItemWidget extends StatefulWidget {
  final ContextMenuItem item;
  final Color textColor;
  final Color iconColor;
  final Color hoverColor;
  final VoidCallback onDismiss;

  const _ContextMenuItemWidget({
    Key? key,
    required this.item,
    required this.textColor,
    required this.iconColor,
    required this.hoverColor,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<_ContextMenuItemWidget> createState() => _ContextMenuItemWidgetState();
}

class _ContextMenuItemWidgetState extends State<_ContextMenuItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final opacity = widget.item.enabled ? 1.0 : 0.4;

    return MouseRegion(
      cursor: widget.item.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        if (widget.item.enabled) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTap: widget.item.enabled
            ? () {
                widget.item.onTap();
                widget.onDismiss();
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: _isHovered ? widget.hoverColor : Colors.transparent,
          child: Row(
            children: [
              // Icon (if provided)
              if (widget.item.icon != null) ...[
                Icon(
                  widget.item.icon,
                  size: 20,
                  color: widget.iconColor.withValues(alpha: opacity),
                ),
                const SizedBox(width: 12),
              ],

              // Label
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.textColor.withValues(alpha: opacity),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Builder function type for creating custom context menu items
typedef ContextMenuItemBuilder = List<ContextMenuItem> Function(String nodeId);

/// Default context menu items for a node
///
/// This provides the standard set of menu items as specified in the requirements.
///
class DefaultContextMenuItems {
  /// Create the default context menu items for a node
  ///
  /// [nodeId] - The ID of the node the menu is for
  /// [onAddChild] - Callback to add a child node
  /// [onAddSibling] - Callback to add a sibling node
  /// [onAddParent] - Callback to add a parent node
  /// [onDelete] - Callback to delete the node
  /// [onEditProperties] - Callback to edit node properties
  /// [onCreateArrow] - Callback to create an arrow from this node
  /// [onCreateSummary] - Callback to create a summary
  /// [onFocusMode] - Callback to enter focus mode on this node
  /// [onInsertImage] - Callback to insert/update image
  /// [onRemoveImage] - Callback to remove image
  /// [onSetHyperlink] - Callback to set/update hyperlink
  /// [onRemoveHyperlink] - Callback to remove hyperlink
  /// [onAddTag] - Callback to add tag
  /// [onAddIcon] - Callback to add icon
  /// [onToggleExpanded] - Callback to toggle expanded/collapsed state
  /// [strings] - Localized labels
  /// [isRootNode] - Whether this is the root node (affects available operations)
  static List<ContextMenuItem> build({
    required String nodeId,
    required VoidCallback onAddChild,
    required VoidCallback onAddSibling,
    required VoidCallback onAddParent,
    required VoidCallback onDelete,
    required VoidCallback onEditProperties,
    required VoidCallback onCreateArrow,
    required VoidCallback onCreateSummary,
    required VoidCallback onFocusMode,
    required MindMapStrings strings,
    VoidCallback? onInsertImage,
    VoidCallback? onRemoveImage,
    VoidCallback? onSetHyperlink,
    VoidCallback? onRemoveHyperlink,
    VoidCallback? onAddTag,
    VoidCallback? onAddIcon,
    VoidCallback? onToggleExpanded,
    bool hasImage = false,
    bool hasHyperlink = false,
    bool canToggleExpanded = false,
    bool isExpanded = true,
    bool isRootNode = false,
  }) {
    final items = <ContextMenuItem>[
      // Add child node
      ContextMenuItem(
        label: strings.menuAddChild,
        icon: Icons.subdirectory_arrow_right,
        onTap: onAddChild,
      ),

      // Add sibling node (not available for root)
      if (!isRootNode)
        ContextMenuItem(
          label: strings.menuAddSibling,
          icon: Icons.add,
          onTap: onAddSibling,
        ),

      // Add parent node (not available for root)
      if (!isRootNode)
        ContextMenuItem(
          label: strings.menuAddParent,
          icon: Icons.arrow_upward,
          onTap: onAddParent,
          showDivider: true,
        ),

      // Delete node (not available for root)
      if (!isRootNode)
        ContextMenuItem(
          label: strings.menuDeleteNode,
          icon: Icons.delete,
          onTap: onDelete,
          showDivider: true,
        ),

      // Edit properties
      ContextMenuItem(
        label: strings.menuEditProperties,
        icon: Icons.edit,
        onTap: onEditProperties,
      ),

      if (onInsertImage != null)
        ContextMenuItem(
          label: strings.menuInsertImage,
          icon: Icons.image,
          onTap: onInsertImage,
        ),

      if (hasImage && onRemoveImage != null)
        ContextMenuItem(
          label: strings.menuRemoveImage,
          icon: Icons.hide_image,
          onTap: onRemoveImage,
        ),

      if (onSetHyperlink != null)
        ContextMenuItem(
          label: strings.menuSetHyperlink,
          icon: Icons.link,
          onTap: onSetHyperlink,
        ),

      if (hasHyperlink && onRemoveHyperlink != null)
        ContextMenuItem(
          label: strings.menuRemoveHyperlink,
          icon: Icons.link_off,
          onTap: onRemoveHyperlink,
        ),

      if (onAddTag != null)
        ContextMenuItem(
          label: strings.menuAddTag,
          icon: Icons.sell,
          onTap: onAddTag,
        ),

      if (onAddIcon != null)
        ContextMenuItem(
          label: strings.menuAddIcon,
          icon: Icons.emoji_emotions,
          onTap: onAddIcon,
          showDivider: true,
        ),

      // Create arrow
      ContextMenuItem(
        label: strings.menuCreateArrow,
        icon: Icons.arrow_forward,
        onTap: onCreateArrow,
      ),

      // Create summary
      ContextMenuItem(
        label: strings.menuCreateSummary,
        icon: Icons.format_list_bulleted,
        onTap: onCreateSummary,
        showDivider: true,
      ),

      if (canToggleExpanded && onToggleExpanded != null)
        ContextMenuItem(
          label: isExpanded ? strings.menuCollapseNode : strings.menuExpandNode,
          icon: isExpanded ? Icons.unfold_less : Icons.unfold_more,
          onTap: onToggleExpanded,
          showDivider: true,
        ),

      // Focus mode
      ContextMenuItem(
        label: strings.menuFocusMode,
        icon: Icons.center_focus_strong,
        onTap: onFocusMode,
      ),
    ];

    return items;
  }
}
