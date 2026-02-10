import 'package:flutter/foundation.dart';
import '../i18n/mind_map_strings.dart';

/// Configuration options for MindMapWidget
@immutable
class MindMapConfig {
  /// Whether to enable undo/redo functionality
  final bool allowUndo;

  /// Maximum number of operations to keep in history
  final int maxHistorySize;

  /// Minimum zoom scale
  final double minScale;

  /// Maximum zoom scale
  final double maxScale;

  /// Whether to enable keyboard shortcuts
  final bool enableKeyboardShortcuts;

  /// Whether to enable context menu
  final bool enableContextMenu;

  /// Whether to enable drag and drop
  final bool enableDragDrop;

  /// Locale selection for built-in labels and prompts
  final MindMapLocale locale;

  const MindMapConfig({
    this.allowUndo = true,
    this.maxHistorySize = 50,
    this.minScale = 0.1,
    this.maxScale = 5.0,
    this.enableKeyboardShortcuts = true,
    this.enableContextMenu = true,
    this.enableDragDrop = true,
    this.locale = MindMapLocale.auto,
  });

  MindMapConfig copyWith({
    bool? allowUndo,
    int? maxHistorySize,
    double? minScale,
    double? maxScale,
    bool? enableKeyboardShortcuts,
    bool? enableContextMenu,
    bool? enableDragDrop,
    MindMapLocale? locale,
  }) {
    return MindMapConfig(
      allowUndo: allowUndo ?? this.allowUndo,
      maxHistorySize: maxHistorySize ?? this.maxHistorySize,
      minScale: minScale ?? this.minScale,
      maxScale: maxScale ?? this.maxScale,
      enableKeyboardShortcuts:
          enableKeyboardShortcuts ?? this.enableKeyboardShortcuts,
      enableContextMenu: enableContextMenu ?? this.enableContextMenu,
      enableDragDrop: enableDragDrop ?? this.enableDragDrop,
      locale: locale ?? this.locale,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MindMapConfig &&
          runtimeType == other.runtimeType &&
          allowUndo == other.allowUndo &&
          maxHistorySize == other.maxHistorySize &&
          minScale == other.minScale &&
          maxScale == other.maxScale &&
          enableKeyboardShortcuts == other.enableKeyboardShortcuts &&
          enableContextMenu == other.enableContextMenu &&
          enableDragDrop == other.enableDragDrop &&
          locale == other.locale;

  @override
  int get hashCode =>
      allowUndo.hashCode ^
      maxHistorySize.hashCode ^
      minScale.hashCode ^
      maxScale.hashCode ^
      enableKeyboardShortcuts.hashCode ^
      enableContextMenu.hashCode ^
      enableDragDrop.hashCode ^
      locale.hashCode;
}
