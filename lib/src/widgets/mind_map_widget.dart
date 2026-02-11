import 'dart:math' as math;
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import '../models/mind_map_data.dart';
import '../models/mind_map_theme.dart';
import '../models/node_data.dart';
import '../models/image_data.dart';
import '../models/tag_data.dart';
import '../models/summary_data.dart';
import '../models/arrow_data.dart';
import '../models/layout_direction.dart';
import '../layout/layout_engine.dart';
import '../layout/node_layout.dart';
import '../rendering/mind_map_painter.dart';
import '../rendering/node_renderer.dart';
import '../rendering/arrow_renderer.dart';
import '../rendering/summary_renderer.dart';
import '../interaction/gesture_handler.dart';
import '../interaction/drag_manager.dart';
import '../interaction/keyboard_handler.dart';
import '../utils/context_menu_suppressor.dart';
import '../utils/local_image_picker.dart';
import '../i18n/mind_map_strings.dart';
import 'mind_map_controller.dart';
import 'mind_map_config.dart';
import 'context_menu.dart';

/// Main Flutter widget for the mind map
class MindMapWidget extends StatefulWidget {
  final MindMapData initialData;
  final MindMapConfig config;
  final ValueChanged<MindMapEvent>? onEvent;
  final MindMapController? controller;

  const MindMapWidget({
    super.key,
    required this.initialData,
    this.config = const MindMapConfig(),
    this.onEvent,
    this.controller,
  });

  @override
  State<MindMapWidget> createState() => MindMapState();
}

class MindMapState extends State<MindMapWidget> {
  late MindMapController _controller;
  late LayoutEngine _layoutEngine;
  late DragManager _dragManager;
  late KeyboardHandler _keyboardHandler;
  Map<String, NodeLayout> _nodeLayouts = {};
  Matrix4 _transform = Matrix4.identity();
  late GestureHandler _gestureHandler;
  bool _gestureHandlerInitialized = false;

  // Cache keys for layout/image synchronization optimization
  NodeData? _lastLayoutNodeDataRef;
  MindMapTheme? _lastLayoutThemeRef;
  LayoutDirection? _lastLayoutDirection;
  bool _lastLayoutFocusMode = false;
  String? _lastLayoutFocusedNodeId;
  NodeData? _lastImageSyncRootRef;

  // RepaintBoundary key for PNG export
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  // Edit mode state
  String? _editingNodeId;
  final TextEditingController _editController = TextEditingController();
  final FocusNode _editFocusNode = FocusNode();
  final FocusNode _widgetFocusNode = FocusNode();
  String? _originalTopic;
  int? _editingNodeDepth;
  String? _editingSummaryId;
  final TextEditingController _summaryEditController = TextEditingController();
  final FocusNode _summaryEditFocusNode = FocusNode();
  String? _originalSummaryLabel;
  String? _editingArrowId;
  final TextEditingController _arrowEditController = TextEditingController();
  final FocusNode _arrowEditFocusNode = FocusNode();
  String? _originalArrowLabel;

  // Modifier key state
  bool _isCtrlPressed = false;
  bool _isSpacePressed = false;

  // Selection rectangle state
  Rect? _selectionRect;

  // Right mouse button pan state
  bool _isSecondaryPanning = false;
  Offset? _secondaryPanLastPosition;
  bool _isRightMouseButtonDown = false;

  // Hover state for expand indicators
  String? _hoveredExpandNodeId;
  MouseCursor _canvasMouseCursor = SystemMouseCursors.basic;

  // Context menu state
  String? _contextMenuNodeId;
  Offset? _contextMenuPosition;

  // Custom context menu item builder
  ContextMenuItemBuilder? _customContextMenuBuilder;
  MindMapEvent? _lastDispatchedEvent;

  // Decoded node images cache (keyed by ImageData.url)
  final Map<String, ui.Image> _decodedNodeImages = <String, ui.Image>{};
  final Set<String> _failedNodeImageUrls = <String>{};
  final Map<String, _PendingImageLoad> _pendingNodeImageLoads =
      <String, _PendingImageLoad>{};

  // Expose for testing
  @visibleForTesting
  Map<String, NodeLayout> get nodeLayouts => _nodeLayouts;

  @visibleForTesting
  Matrix4 get transform => _transform;

  @visibleForTesting
  DragManager get dragManager => _dragManager;

  // Expose repaint boundary key for PNG export
  GlobalKey get repaintBoundaryKey => _repaintBoundaryKey;

  @override
  void initState() {
    super.initState();

    // Initialize layout engine
    _layoutEngine = LayoutEngine();

    // Initialize drag manager
    _dragManager = DragManager();

    // Initialize or use provided controller
    _controller =
        widget.controller ??
        MindMapController(
          initialData: widget.initialData,
          config: widget.config,
        );

    // Set the repaint boundary key for PNG export
    _controller.setRepaintBoundaryKey(_repaintBoundaryKey);
    _publishExportImageCache();

    // Disable browser context menu while widget is mounted (web only)
    disableBrowserContextMenu();

    // Set up view compensation callbacks for expand/collapse
    _controller.setNodePositionCallback(_getNodeScreenPosition);
    _controller.setViewCompensationCallback(_compensateViewDrift);

    // Initialize keyboard handler
    _keyboardHandler = KeyboardHandler(
      controller: _controller,
      onCenterView: () => _controller.centerView(),
      onBeginEdit: () {
        final selectedNodeIds = _controller.getSelectedNodeIds();
        if (selectedNodeIds.isNotEmpty) {
          _beginEdit(selectedNodeIds.first);
        }
      },
    );

    // Listen to edit focus node changes
    _editFocusNode.addListener(_onEditFocusChanged);
    _summaryEditFocusNode.addListener(_onSummaryEditFocusChanged);
    _arrowEditFocusNode.addListener(_onArrowEditFocusChanged);

    // Listen to controller changes
    _controller.addListener(_onControllerChanged);

    // Calculate initial layout
    _calculateLayout();

    // Ensure initial interactive layout is applied after first frame
    // and update viewport size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Update viewport size first
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        _controller.setViewportSize(renderBox.size);
      }

      // Then recalculate layout with updated transform
      setState(() {
        // Update transform from zoom/pan manager
        _transform = _controller.zoomPanManager.transform;
        _calculateLayout();
        _syncNodeImages();
      });

      // Request focus for keyboard shortcuts
      _widgetFocusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(MindMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Optimized hot reload support
    // Update controller if config changed
    if (widget.config != oldWidget.config) {
      _controller.updateConfig(widget.config);
    }

    // Recalculate layout only if data structure changed (not just reference)
    // This supports hot reload by avoiding unnecessary recalculations
    if (widget.initialData != oldWidget.initialData) {
      // Check if it's a meaningful change or just hot reload
      if (widget.initialData.nodeData.id != oldWidget.initialData.nodeData.id ||
          widget.initialData.nodeData.children.length !=
              oldWidget.initialData.nodeData.children.length) {
        _calculateLayout();
      }
    }

    // Update controller reference if it changed (hot reload scenario)
    if (widget.controller != oldWidget.controller &&
        widget.controller != null) {
      // Remove listener from old controller
      if (oldWidget.controller == null) {
        _controller.removeListener(_onControllerChanged);
      }

      // Use new controller
      _controller = widget.controller!;
      _controller.addListener(_onControllerChanged);
      _calculateLayout();
      _syncNodeImages();
    }
  }

  @override
  void dispose() {
    _clearPendingImageLoads();
    _controller.setExportImageCache(const <String, ui.Image>{});
    _controller.removeListener(_onControllerChanged);
    _editFocusNode.removeListener(_onEditFocusChanged);
    _summaryEditFocusNode.removeListener(_onSummaryEditFocusChanged);
    _arrowEditFocusNode.removeListener(_onArrowEditFocusChanged);
    _dragManager.dispose();
    _editController.dispose();
    _editFocusNode.dispose();
    _summaryEditController.dispose();
    _summaryEditFocusNode.dispose();
    _arrowEditController.dispose();
    _arrowEditFocusNode.dispose();
    _widgetFocusNode.dispose();
    enableBrowserContextMenu();
    // Only dispose controller if we created it
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;

    final data = _controller.getData();
    final needsLayoutRebuild = _isLayoutStructureDirty(data);
    final arrowEditInvalid =
        _editingArrowId != null &&
        _controller.getArrow(_editingArrowId!) == null;
    if (arrowEditInvalid) {
      _arrowEditFocusNode.unfocus();
    }

    setState(() {
      _transform = _controller.zoomPanManager.transform;
      if (arrowEditInvalid) {
        _editingArrowId = null;
        _originalArrowLabel = null;
      }
      if (needsLayoutRebuild) {
        _calculateLayout();
        _syncNodeImages();
      } else if (_gestureHandlerInitialized) {
        _gestureHandler.updateContext(
          nodeLayouts: _nodeLayouts,
          transform: _transform,
          isReadOnly: widget.config.readOnly,
        );
      }
    });

    // Emit events if callback provided
    if (widget.onEvent != null && _controller.lastEvent != null) {
      final event = _controller.lastEvent!;
      if (!identical(event, _lastDispatchedEvent)) {
        _lastDispatchedEvent = event;
        widget.onEvent!(event);
      }
    }
  }

  void _onEditFocusChanged() {
    // When edit focus is lost, finish editing
    // This matches mind-elixir-core's behavior where clicking outside
    // the input box triggers blur event and finishes editing
    if (!_editFocusNode.hasFocus && _editingNodeId != null) {
      // Use post frame callback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _editingNodeId != null) {
          _finishEdit();
        }
      });
    }
  }

  void _onSummaryEditFocusChanged() {
    if (!_summaryEditFocusNode.hasFocus && _editingSummaryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _editingSummaryId != null) {
          _finishSummaryEdit();
        }
      });
    }
  }

  void _onArrowEditFocusChanged() {
    if (!_arrowEditFocusNode.hasFocus && _editingArrowId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _editingArrowId != null) {
          _finishArrowEdit();
        }
      });
    }
  }

  void _handleTapEmptySpace() {
    // When user taps on empty space, finish editing if in edit mode
    // This matches mind-elixir-core's behavior
    if (_editingNodeId != null) {
      // Unfocus the edit field, which will trigger _onEditFocusChanged
      _editFocusNode.unfocus();
    }
    if (_editingSummaryId != null) {
      _summaryEditFocusNode.unfocus();
    }
    if (_editingArrowId != null) {
      _arrowEditFocusNode.unfocus();
    }
  }

  void _calculateLayout() {
    final data = _controller.getData();

    // Fast path for high-frequency notifications (zoom/pan/selection).
    if (_gestureHandlerInitialized &&
        !_isLayoutStructureDirty(data) &&
        _nodeLayouts.isNotEmpty) {
      _gestureHandler.updateContext(
        nodeLayouts: _nodeLayouts,
        transform: _transform,
        isReadOnly: widget.config.readOnly,
      );
      return;
    }

    // In focus mode, calculate layout for the focused node as if it were the root
    NodeData layoutRoot = data.nodeData;
    if (_controller.isFocusMode && _controller.focusedNodeId != null) {
      final focusedNode = _findNode(data.nodeData, _controller.focusedNodeId!);
      if (focusedNode != null) {
        layoutRoot = focusedNode;
      }
    }

    _nodeLayouts = _layoutEngine.calculateLayout(
      layoutRoot,
      data.theme,
      data.direction,
    );

    // Update gesture handler with new layouts
    _gestureHandler = GestureHandler(
      controller: _controller,
      nodeLayouts: _nodeLayouts,
      transform: _transform,
      isReadOnly: widget.config.readOnly,
      onBeginEdit: _beginEdit,
      onBeginEditSummary: _beginSummaryEdit,
      onBeginEditArrow: _beginArrowEdit,
      onSelectionRectChanged: (rect) {
        if (mounted) {
          setState(() {
            _selectionRect = rect;
          });
        }
      },
      onShowContextMenu: _showContextMenu,
      onTapEmptySpace: _handleTapEmptySpace,
      dragManager: _dragManager,
    );
    _gestureHandlerInitialized = true;
    _lastLayoutNodeDataRef = data.nodeData;
    _lastLayoutThemeRef = data.theme;
    _lastLayoutDirection = data.direction;
    _lastLayoutFocusMode = _controller.isFocusMode;
    _lastLayoutFocusedNodeId = _controller.focusedNodeId;
  }

  void _syncNodeImages() {
    final data = _controller.getData();
    if (identical(_lastImageSyncRootRef, data.nodeData)) {
      return;
    }
    _lastImageSyncRootRef = data.nodeData;

    final urls = <String>{};
    _collectNodeImageUrls(data.nodeData, urls);

    final staleDecoded = _decodedNodeImages.keys
        .where((url) => !urls.contains(url))
        .toList();
    for (final url in staleDecoded) {
      _decodedNodeImages.remove(url);
    }

    _failedNodeImageUrls.removeWhere((url) => !urls.contains(url));

    final stalePending = _pendingNodeImageLoads.keys
        .where((url) => !urls.contains(url))
        .toList();
    for (final url in stalePending) {
      final pending = _pendingNodeImageLoads.remove(url);
      if (pending != null) {
        pending.stream.removeListener(pending.listener);
      }
    }

    for (final url in urls) {
      if (url.trim().isEmpty) continue;
      if (_decodedNodeImages.containsKey(url)) continue;
      if (_failedNodeImageUrls.contains(url)) continue;
      if (_pendingNodeImageLoads.containsKey(url)) continue;
      _loadNodeImage(url);
    }

    _publishExportImageCache();
  }

  void _publishExportImageCache() {
    _controller.setExportImageCache(
      Map<String, ui.Image>.unmodifiable(_decodedNodeImages),
    );
  }

  bool _isLayoutStructureDirty(MindMapData data) {
    if (!identical(_lastLayoutNodeDataRef, data.nodeData)) {
      return true;
    }
    if (!identical(_lastLayoutThemeRef, data.theme)) {
      return true;
    }
    if (_lastLayoutDirection != data.direction) {
      return true;
    }
    if (_lastLayoutFocusMode != _controller.isFocusMode) {
      return true;
    }
    if (_lastLayoutFocusedNodeId != _controller.focusedNodeId) {
      return true;
    }
    return false;
  }

  void _collectNodeImageUrls(NodeData node, Set<String> urls) {
    for (final image in node.effectiveImages) {
      final imageUrl = image.url;
      if (imageUrl.trim().isNotEmpty) {
        urls.add(imageUrl);
      }
    }
    for (final child in node.children) {
      _collectNodeImageUrls(child, urls);
    }
  }

  ImageProvider<Object> _resolveImageProvider(String imageUrl) {
    final lower = imageUrl.toLowerCase();
    if (lower.startsWith('data:image/')) {
      final bytes = _tryDecodeDataUri(imageUrl);
      if (bytes != null) {
        return MemoryImage(bytes);
      }
    }
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return NetworkImage(imageUrl);
    }
    return AssetImage(imageUrl);
  }

  Uint8List? _tryDecodeDataUri(String uri) {
    final commaIndex = uri.indexOf(',');
    if (commaIndex <= 0 || commaIndex >= uri.length - 1) {
      return null;
    }
    final meta = uri.substring(0, commaIndex).toLowerCase();
    if (!meta.contains(';base64')) {
      return null;
    }
    final payload = uri.substring(commaIndex + 1);
    try {
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }

  void _loadNodeImage(String imageUrl) {
    late final ImageStreamListener listener;
    final provider = _resolveImageProvider(imageUrl);
    final stream = provider.resolve(createLocalImageConfiguration(context));

    listener = ImageStreamListener(
      (ImageInfo imageInfo, bool synchronousCall) {
        stream.removeListener(listener);
        _pendingNodeImageLoads.remove(imageUrl);
        _failedNodeImageUrls.remove(imageUrl);
        _decodedNodeImages[imageUrl] = imageInfo.image;
        _publishExportImageCache();
        if (mounted) {
          setState(() {});
        }
      },
      onError: (Object error, StackTrace? stackTrace) {
        stream.removeListener(listener);
        _pendingNodeImageLoads.remove(imageUrl);
        _failedNodeImageUrls.add(imageUrl);
      },
    );

    _pendingNodeImageLoads[imageUrl] = _PendingImageLoad(
      stream: stream,
      listener: listener,
    );
    stream.addListener(listener);
  }

  void _clearPendingImageLoads() {
    for (final pending in _pendingNodeImageLoads.values) {
      pending.stream.removeListener(pending.listener);
    }
    _pendingNodeImageLoads.clear();
  }

  /// Begin editing a node
  void _beginEdit(String nodeId) {
    if (widget.config.readOnly) return;

    final node = _findNode(_controller.getData().nodeData, nodeId);
    if (node == null) return;

    if (_editingSummaryId != null) {
      _cancelSummaryEdit();
    }
    if (_editingArrowId != null) {
      _cancelArrowEdit();
    }

    setState(() {
      _editingNodeId = nodeId;
      _originalTopic = node.topic;
      final depth = _findNodeDepth(_controller.getData().nodeData, nodeId);
      _editingNodeDepth = depth < 0 ? 0 : depth;
      _editController.text = node.topic;
    });

    // Emit begin edit event
    _controller.emitEvent(BeginEditEvent(nodeId));

    // Focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocusNode.requestFocus();
      _editController.selection = TextSelection(
        baseOffset: node.topic.length,
        extentOffset: 0,
      );
    });
  }

  void _beginSummaryEdit(String summaryId) {
    if (widget.config.readOnly) return;

    final summary = _controller.getSummary(summaryId);
    if (summary == null) return;
    _controller.selectSummary(summaryId);

    if (_editingNodeId != null) {
      _cancelEdit();
    }
    if (_editingArrowId != null) {
      _cancelArrowEdit();
    }

    setState(() {
      _editingSummaryId = summaryId;
      _originalSummaryLabel = summary.label ?? '';
      _summaryEditController.text = summary.label ?? '';
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _summaryEditFocusNode.requestFocus();
      _summaryEditController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _summaryEditController.text.length,
      );
    });
  }

  /// Finish editing and save changes
  void _finishEdit() {
    if (_editingNodeId == null) return;

    final newTopic = _editController.text.trim();
    final nodeId = _editingNodeId!;
    final originalTopic = _originalTopic ?? '';

    // Match mind-elixir-core: ignore empty or unchanged edits
    if (newTopic.isEmpty || newTopic == originalTopic) {
      _cancelEdit();
      return;
    }

    // Commit edit as a single operation
    _controller.commitNodeTopicEdit(nodeId, originalTopic, newTopic);

    // Emit finish edit event
    _controller.emitEvent(FinishEditEvent(nodeId, newTopic));

    setState(() {
      _editingNodeId = null;
      _originalTopic = null;
      _editingNodeDepth = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _editingNodeId == null &&
          _editingSummaryId == null &&
          _editingArrowId == null) {
        _widgetFocusNode.requestFocus();
      }
    });
  }

  void _onEditChanged(String value) {
    if (_editingNodeId == null) return;
    final nodeId = _editingNodeId!;
    final node = _findNode(_controller.getData().nodeData, nodeId);
    if (node == null) return;
    if (node.topic == value) return;
    _controller.updateNode(nodeId, node.copyWith(topic: value));
  }

  /// Cancel editing and restore original text
  void _cancelEdit() {
    if (_editingNodeId == null) return;
    final nodeId = _editingNodeId!;
    final originalTopic = _originalTopic;
    if (originalTopic != null) {
      final node = _findNode(_controller.getData().nodeData, nodeId);
      if (node != null && node.topic != originalTopic) {
        _controller.updateNode(nodeId, node.copyWith(topic: originalTopic));
      }
    }

    setState(() {
      _editingNodeId = null;
      _originalTopic = null;
      _editingNodeDepth = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _editingNodeId == null &&
          _editingSummaryId == null &&
          _editingArrowId == null) {
        _widgetFocusNode.requestFocus();
      }
    });
  }

  void _finishSummaryEdit() {
    if (_editingSummaryId == null) return;

    final summaryId = _editingSummaryId!;
    final summary = _controller.getSummary(summaryId);
    if (summary == null) {
      _cancelSummaryEdit();
      return;
    }

    final newLabel = _summaryEditController.text.trim();
    final originalLabel = _originalSummaryLabel ?? '';
    if (newLabel != originalLabel) {
      _controller.updateSummary(summaryId, summary.copyWith(label: newLabel));
    }

    _cancelSummaryEdit();
  }

  void _cancelSummaryEdit() {
    setState(() {
      _editingSummaryId = null;
      _originalSummaryLabel = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _editingSummaryId == null &&
          _editingNodeId == null &&
          _editingArrowId == null) {
        _widgetFocusNode.requestFocus();
      }
    });
  }

  void _beginArrowEdit(String arrowId) {
    if (widget.config.readOnly) return;

    final arrow = _controller.getArrow(arrowId);
    if (arrow == null) return;

    _controller.selectArrow(arrowId);

    if (_editingNodeId != null) {
      _cancelEdit();
    }
    if (_editingSummaryId != null) {
      _cancelSummaryEdit();
    }

    setState(() {
      _editingArrowId = arrowId;
      _originalArrowLabel = arrow.label ?? '';
      _arrowEditController.text = arrow.label ?? '';
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _arrowEditFocusNode.requestFocus();
      _arrowEditController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _arrowEditController.text.length,
      );
    });
  }

  void _finishArrowEdit() {
    if (_editingArrowId == null) return;

    final arrowId = _editingArrowId!;
    final arrow = _controller.getArrow(arrowId);
    if (arrow == null) {
      _cancelArrowEdit();
      return;
    }

    final newLabel = _arrowEditController.text.trim();
    final originalLabel = _originalArrowLabel ?? '';
    if (newLabel != originalLabel) {
      _controller.updateArrow(
        arrowId,
        arrow.copyWith(label: newLabel.isEmpty ? null : newLabel),
      );
    }

    _cancelArrowEdit();
  }

  void _cancelArrowEdit() {
    setState(() {
      _editingArrowId = null;
      _originalArrowLabel = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _editingArrowId == null &&
          _editingSummaryId == null &&
          _editingNodeId == null) {
        _widgetFocusNode.requestFocus();
      }
    });
  }

  /// Show context menu for a node
  ///
  void _showContextMenu(String nodeId, Offset position) {
    // Only show context menu if enabled in config
    if (!widget.config.enableContextMenu || widget.config.readOnly) {
      return;
    }

    setState(() {
      _contextMenuNodeId = nodeId;
      _contextMenuPosition = position;
    });
  }

  /// Dismiss the context menu
  void _dismissContextMenu() {
    setState(() {
      _contextMenuNodeId = null;
      _contextMenuPosition = null;
    });
  }

  /// Build context menu items for a node
  ///
  List<ContextMenuItem> _buildContextMenuItems(String nodeId) {
    final strings = _resolveStrings();

    // Check if there's a custom builder
    if (_customContextMenuBuilder != null) {
      return _customContextMenuBuilder!(nodeId);
    }

    // Use default menu items
    final node = _findNode(_controller.getData().nodeData, nodeId);
    final isRootNode = nodeId == _controller.getData().nodeData.id;

    return DefaultContextMenuItems.build(
      nodeId: nodeId,
      isRootNode: isRootNode,

      // Add child node
      onAddChild: () {
        _controller.addChildNode(nodeId);
      },

      // Add sibling node
      onAddSibling: () {
        _controller.addSiblingNode(nodeId);
      },

      // Add parent node
      onAddParent: () {
        _controller.addParentNode(nodeId);
      },

      // Delete node
      onDelete: () {
        try {
          _controller.removeNode(nodeId);
        } catch (e) {
          // Handle errors (e.g., trying to delete root)
          debugPrint('Failed to delete node: $e');
        }
      },

      // Edit properties (enter edit mode)
      onEditProperties: () {
        _beginEdit(nodeId);
      },

      onInsertImage: () {
        _pickAndSetImage(nodeId);
      },
      onRemoveImage: () {
        _controller.clearNodeImages(nodeId);
      },
      onSetHyperlink: () {
        _showSetHyperlinkDialog(nodeId);
      },
      onRemoveHyperlink: () {
        _controller.setNodeHyperLink(nodeId, null);
      },
      onAddTag: () {
        _showAddTagDialog(nodeId);
      },
      onAddIcon: () {
        _showAddIconDialog(nodeId);
      },
      hasImage: node?.effectiveImages.isNotEmpty ?? false,
      hasHyperlink:
          node?.hyperLink != null &&
          (node?.hyperLink?.trim().isNotEmpty ?? false),

      // Create arrow
      onCreateArrow: () {
        _controller.startArrowCreationMode();
        _controller.selectArrowSourceNode(nodeId);
      },

      // Create summary
      onCreateSummary: () {
        _controller.startSummaryCreationMode();
        // Select the node to start building the summary
        _controller.toggleSummaryNodeSelection(nodeId);
      },

      // Focus mode
      onFocusMode: () {
        _controller.focusNode(nodeId);
      },
      canToggleExpanded: (node?.children.isNotEmpty ?? false),
      isExpanded: node?.expanded ?? true,
      onToggleExpanded: () {
        _controller.toggleNodeExpanded(nodeId);
      },
      strings: strings,
    );
  }

  Future<void> _showSetHyperlinkDialog(String nodeId) async {
    final strings = _resolveStrings();
    final node = _findNode(_controller.getData().nodeData, nodeId);
    if (node == null) return;

    final url = await _showSingleInputDialog(
      title: strings.dialogTitleSetHyperlink,
      label: strings.fieldHyperlink,
      initialValue: node.hyperLink ?? '',
    );
    if (url == null) return;
    _controller.setNodeHyperLink(nodeId, url.trim());
  }

  Future<void> _showAddTagDialog(String nodeId) async {
    final strings = _resolveStrings();
    final text = await _showSingleInputDialog(
      title: strings.dialogTitleAddTag,
      label: strings.fieldTag,
    );
    if (text == null) return;
    final value = text.trim();
    if (value.isEmpty) return;
    _controller.addNodeTag(nodeId, TagData(text: value));
  }

  Future<void> _showAddIconDialog(String nodeId) async {
    final strings = _resolveStrings();
    final text = await _showSingleInputDialog(
      title: strings.dialogTitleAddIcon,
      label: strings.fieldIcon,
    );
    if (text == null) return;
    final value = text.trim();
    if (value.isEmpty) return;
    _controller.addNodeIcon(nodeId, value);
  }

  Future<void> _pickAndSetImage(String nodeId) async {
    final pickedFiles = await pickLocalImages();
    if (pickedFiles.isEmpty) return;

    try {
      for (final picked in pickedFiles) {
        final bytes = picked.bytes;
        if (bytes.isEmpty) continue;

        final mimeType = _inferImageMimeType(picked.name, bytes);
        final dataUri = 'data:$mimeType;base64,${base64Encode(bytes)}';
        final (preferredWidth, preferredHeight) =
            await _computeImageDisplaySize(bytes);

        _controller.addNodeImage(
          nodeId,
          ImageData(
            url: dataUri,
            width: preferredWidth,
            height: preferredHeight,
            fit: BoxFit.contain,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to pick image: $e');
    }
  }

  String _inferImageMimeType(String fileName, Uint8List bytes) {
    if (bytes.length >= 12) {
      // PNG
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'image/png';
      }
      // JPEG
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
        return 'image/jpeg';
      }
      // GIF
      if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
        return 'image/gif';
      }
      // WEBP: RIFF....WEBP
      if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        return 'image/webp';
      }
      // BMP
      if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
        return 'image/bmp';
      }
    }

    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    return 'image/png';
  }

  Future<(double, double)> _computeImageDisplaySize(Uint8List bytes) async {
    const fallbackWidth = 132.0;
    const fallbackHeight = 64.0;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final rawWidth = image.width.toDouble();
      final rawHeight = image.height.toDouble();
      image.dispose();
      codec.dispose();

      if (rawWidth <= 0 || rawHeight <= 0) {
        return (fallbackWidth, fallbackHeight);
      }

      // Keep mind map readable: preserve aspect ratio under a moderate cap.
      const maxWidth = 220.0;
      const maxHeight = 140.0;
      final scale = math.min(
        1.0,
        math.min(maxWidth / rawWidth, maxHeight / rawHeight),
      );
      final width = rawWidth * scale;
      final height = rawHeight * scale;
      return (width, height);
    } catch (_) {
      return (fallbackWidth, fallbackHeight);
    }
  }

  Future<String?> _showSingleInputDialog({
    required String title,
    required String label,
    String initialValue = '',
  }) async {
    final strings = _resolveStrings();
    var inputValue = initialValue;
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextFormField(
            initialValue: initialValue,
            autofocus: true,
            decoration: InputDecoration(labelText: label),
            onChanged: (v) => inputValue = v,
            onFieldSubmitted: (v) => Navigator.of(dialogContext).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(strings.actionCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(inputValue),
              child: Text(strings.actionConfirm),
            ),
          ],
        );
      },
    );
    return value;
  }

  MindMapStrings _resolveStrings() {
    return MindMapStrings.resolve(
      widget.config.locale,
      Localizations.maybeLocaleOf(context),
    );
  }

  /// Set a custom context menu item builder
  ///
  /// This allows applications to customize the context menu items.
  ///
  void setCustomContextMenuBuilder(ContextMenuItemBuilder? builder) {
    setState(() {
      _customContextMenuBuilder = builder;
    });
  }

  /// Find a node in the tree
  NodeData? _findNode(NodeData node, String nodeId) {
    if (node.id == nodeId) return node;

    for (final child in node.children) {
      final found = _findNode(child, nodeId);
      if (found != null) return found;
    }

    return null;
  }

  /// Get the screen position of a node
  ///
  /// This calculates the node's position in screen coordinates,
  /// taking into account the current transform.
  Offset? _getNodeScreenPosition(String nodeId) {
    final layout = _nodeLayouts[nodeId];
    if (layout == null) return null;

    // Get the node's center in canvas coordinates
    final canvasPosition = layout.bounds.center;

    // Transform to screen coordinates
    final screenPosition = MatrixUtils.transformPoint(
      _transform,
      canvasPosition,
    );

    return screenPosition;
  }

  /// Compensate for view drift after expand/collapse
  ///
  /// This method adjusts the view transform to keep the node at the same
  /// screen position after its expanded state changes, preventing jarring
  /// jumps in the user's view.
  ///
  /// Similar to mind-elixir-core's drift compensation logic.
  void _compensateViewDrift(String nodeId, Offset beforePosition) {
    // Schedule compensation after the next frame when layout is recalculated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Get the new position after layout recalculation
      final afterPosition = _getNodeScreenPosition(nodeId);
      if (afterPosition == null) return;

      // Calculate the drift
      final driftX = beforePosition.dx - afterPosition.dx;
      final driftY = beforePosition.dy - afterPosition.dy;

      // Only compensate if there's significant drift (> 1 pixel)
      if (driftX.abs() > 1.0 || driftY.abs() > 1.0) {
        // Apply the compensation by adjusting the translation
        final currentTranslation = _controller.zoomPanManager.translation;
        final newTranslation = Offset(
          currentTranslation.dx + driftX,
          currentTranslation.dy + driftY,
        );

        _controller.zoomPanManager.setTranslation(newTranslation);

        // Trigger a rebuild to apply the new transform
        setState(() {
          _transform = _controller.zoomPanManager.transform;
        });
      }
    });
  }

  /// Update the hovered expand indicator based on mouse position
  ///
  /// This checks if the mouse is hovering near any node with children
  /// and updates the state accordingly. On desktop platforms, expand indicators
  /// are hidden by default and only shown when the mouse is near the node.
  ///
  /// Similar to mind-elixir-core's behavior where hovering over the parent node
  /// shows the expand/collapse button.
  void _updateHoveredExpandIndicator(Offset screenPosition) {
    // Transform screen position to canvas coordinates
    final inverseTransform = Matrix4.inverted(_transform);
    final canvasPosition = MatrixUtils.transformPoint(
      inverseTransform,
      screenPosition,
    );
    final data = _controller.getData();
    final renderRootId =
        _controller.isFocusMode && _controller.focusedNodeId != null
        ? _controller.focusedNodeId!
        : data.nodeData.id;
    final renderRootLayout = _nodeLayouts[renderRootId];

    // Check each node to see if the mouse is near it
    String? newHoveredNodeId;

    void checkNode(NodeData node, int depth) {
      if (node.children.isEmpty) return;

      final layout = _nodeLayouts[node.id];
      if (layout == null) return;

      // Check if mouse is hovering over the node itself or near the expand indicator area
      final nodeBounds = layout.bounds;
      final indicatorBounds = NodeRenderer.getExpandIndicatorBounds(
        node,
        layout,
        data.theme,
        depth,
        renderRootLayout != null
            ? layout.bounds.center.dx < renderRootLayout.bounds.center.dx
            : null,
      );

      if (indicatorBounds != null) {
        // Use the real union of node bounds and indicator bounds.
        // This matches both:
        // - depth 1 indicator (left/right of node center)
        // - depth >1 indicator (below node at parent edge)
        final extendedBounds = Rect.fromLTRB(
          math.min(nodeBounds.left, indicatorBounds.left) - 8.0,
          math.min(nodeBounds.top, indicatorBounds.top) - 8.0,
          math.max(nodeBounds.right, indicatorBounds.right) + 8.0,
          math.max(nodeBounds.bottom, indicatorBounds.bottom) + 8.0,
        );

        if (extendedBounds.contains(canvasPosition)) {
          newHoveredNodeId = node.id;
          return;
        }
      }

      // Check children recursively
      for (final child in node.children) {
        checkNode(child, depth + 1);
        if (newHoveredNodeId != null) return;
      }
    }

    checkNode(data.nodeData, 0);

    // Update state if changed
    if (newHoveredNodeId != _hoveredExpandNodeId) {
      setState(() {
        _hoveredExpandNodeId = newHoveredNodeId;
      });
    }
  }

  MouseCursor _resolveCanvasCursor(Offset screenPosition) {
    if (!_gestureHandlerInitialized ||
        _editingNodeId != null ||
        _editingSummaryId != null ||
        _editingArrowId != null) {
      return SystemMouseCursors.basic;
    }

    final hasLinkOrExpandHit =
        _gestureHandler.hitTestHyperlinkIndicator(screenPosition) != null ||
        _gestureHandler.hitTestExpandIndicator(screenPosition) != null;
    if (widget.config.readOnly) {
      return hasLinkOrExpandHit
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic;
    }

    if (hasLinkOrExpandHit ||
        _gestureHandler.hitTestSummary(screenPosition) != null ||
        _gestureHandler.hitTestArrowControlPoint(screenPosition) != null ||
        _gestureHandler.hitTestArrow(screenPosition) != null ||
        _gestureHandler.hitTestNode(screenPosition) != null) {
      return SystemMouseCursors.click;
    }

    return SystemMouseCursors.basic;
  }

  void _updateCanvasHoverFeedback(Offset screenPosition) {
    _updateHoveredExpandIndicator(screenPosition);

    final newCursor = _resolveCanvasCursor(screenPosition);
    if (newCursor != _canvasMouseCursor) {
      setState(() {
        _canvasMouseCursor = newCursor;
      });
    }
  }

  void _clearCanvasHoverFeedback() {
    if (_hoveredExpandNodeId == null &&
        _canvasMouseCursor == SystemMouseCursors.basic) {
      return;
    }

    setState(() {
      _hoveredExpandNodeId = null;
      _canvasMouseCursor = SystemMouseCursors.basic;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _controller.getData();
    final strings = _resolveStrings();

    return Container(
      color: data.theme.variables.bgColor,
      child: KeyboardListener(
        focusNode: _widgetFocusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (widget.config.readOnly) {
            return;
          }

          // Only handle keyboard shortcuts if enabled in config
          if (!widget.config.enableKeyboardShortcuts) {
            return;
          }

          // While editing, suppress global shortcuts (handled by edit overlays)
          if (_editingNodeId != null ||
              _editingSummaryId != null ||
              _editingArrowId != null) {
            return;
          }

          // Track Ctrl/Cmd key state for multi-selection
          if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
              event.logicalKey == LogicalKeyboardKey.controlRight ||
              event.logicalKey == LogicalKeyboardKey.metaLeft ||
              event.logicalKey == LogicalKeyboardKey.metaRight) {
            setState(() {
              _isCtrlPressed = event is KeyDownEvent || event is KeyRepeatEvent;
            });
          }

          // Track Space key state for canvas panning
          if (event.logicalKey == LogicalKeyboardKey.space) {
            setState(() {
              _isSpacePressed =
                  event is KeyDownEvent || event is KeyRepeatEvent;
            });
          }

          // Handle keyboard shortcuts
          _keyboardHandler.handleKeyEvent(event);
        },
        child: Listener(
          // Handle mouse wheel for zoom
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              final renderBox = context.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                _controller.setViewportSize(renderBox.size);
                _controller.zoomPanManager.handleMouseWheel(
                  event,
                  event.localPosition,
                );
              }
            }
          },
          onPointerDown: (event) {
            if (_editingNodeId == null &&
                _editingSummaryId == null &&
                _editingArrowId == null) {
              _widgetFocusNode.requestFocus();
            }
            if (event.kind == PointerDeviceKind.mouse &&
                (event.buttons & kSecondaryMouseButton) != 0) {
              _clearCanvasHoverFeedback();
              _isSecondaryPanning = true;
              _isRightMouseButtonDown = true;
              _secondaryPanLastPosition = event.localPosition;
              _controller.zoomPanManager.handlePanStart(event.localPosition);
            }
          },
          onPointerMove: (event) {
            if (_isSecondaryPanning && _secondaryPanLastPosition != null) {
              final delta = event.localPosition - _secondaryPanLastPosition!;
              _secondaryPanLastPosition = event.localPosition;
              _controller.zoomPanManager.handlePanUpdate(delta);
            }

            // Avoid expensive hover hit-testing while dragging/panning.
            if (event.kind == PointerDeviceKind.mouse &&
                event.buttons == 0 &&
                !_isSecondaryPanning &&
                !_dragManager.isDragging &&
                _selectionRect == null) {
              _updateCanvasHoverFeedback(event.localPosition);
            }
          },
          onPointerHover: (event) {
            _updateCanvasHoverFeedback(event.localPosition);
          },
          onPointerUp: (event) {
            if (_isSecondaryPanning) {
              _isSecondaryPanning = false;
              _isRightMouseButtonDown = false;
              _secondaryPanLastPosition = null;
              _controller.zoomPanManager.handlePanEnd();
            }
          },
          onPointerCancel: (_) {
            if (_isSecondaryPanning) {
              _isSecondaryPanning = false;
              _isRightMouseButtonDown = false;
              _secondaryPanLastPosition = null;
              _controller.zoomPanManager.handlePanEnd();
            }
          },
          child: Stack(
            children: [
              // Main mind map canvas
              RepaintBoundary(
                key: _repaintBoundaryKey,
                child: MouseRegion(
                  cursor: _canvasMouseCursor,
                  onExit: (_) => _clearCanvasHoverFeedback(),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: _gestureHandler.handleTapDown,
                    onTapUp: (details) => _gestureHandler.handleTapUp(
                      details,
                      isCtrlPressed: _isCtrlPressed,
                      isEditMode:
                          _editingNodeId != null ||
                          _editingSummaryId != null ||
                          _editingArrowId != null,
                    ),
                    onScaleStart: (details) => _gestureHandler.handleScaleStart(
                      details,
                      isRightMouseButton: _isRightMouseButtonDown,
                      isSpacePressed: _isSpacePressed,
                      isEditMode:
                          _editingNodeId != null ||
                          _editingSummaryId != null ||
                          _editingArrowId != null,
                    ),
                    onScaleUpdate: (details) =>
                        _gestureHandler.handleScaleUpdate(
                          details,
                          isRightMouseButton: _isRightMouseButtonDown,
                          isSpacePressed: _isSpacePressed,
                        ),
                    onScaleEnd: _gestureHandler.handleScaleEnd,
                    onSecondaryTapUp: (details) =>
                        _gestureHandler.handleSecondaryTapUp(
                          details,
                          isEditMode:
                              _editingNodeId != null ||
                              _editingSummaryId != null ||
                              _editingArrowId != null,
                        ),
                    onLongPressStart: (details) =>
                        _gestureHandler.handleLongPress(
                          details.localPosition,
                          isEditMode:
                              _editingNodeId != null ||
                              _editingSummaryId != null ||
                              _editingArrowId != null,
                        ),
                    child: AnimatedBuilder(
                      animation: _dragManager,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: MindMapPainter(
                            data: data,
                            nodeLayouts: _nodeLayouts,
                            imageCache: Map<String, ui.Image>.unmodifiable(
                              _decodedNodeImages,
                            ),
                            selectedNodeIds: _controller
                                .getSelectedNodeIds()
                                .toSet(),
                            transform: _transform,
                            selectionRect: _selectionRect,
                            draggedNodeId: _dragManager.draggedNodeId,
                            dragPosition: _dragManager.dragPosition,
                            dropTargetNodeId: _dragManager.dropTargetNodeId,
                            dropInsertType: _dragManager.dropInsertType,
                            selectedArrowId: _controller.selectedArrowId,
                            selectedSummaryId: _controller.selectedSummaryId,
                            arrowSourceNodeId: _controller.arrowSourceNodeId,
                            isFocusMode: _controller.isFocusMode,
                            focusedNodeId: _controller.focusedNodeId,
                            hoveredExpandNodeId: _hoveredExpandNodeId,
                            strings: strings,
                          ),
                          child: const SizedBox.expand(),
                        );
                      },
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SelectionRectPainter(
                      rect: _selectionRect,
                      fillColor: Colors.blueAccent.withValues(alpha: 0.25),
                      borderColor: Colors.blueAccent.withValues(alpha: 0.9),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),

              // Edit mode overlay
              if (_editingNodeId != null) _buildEditOverlay(),
              if (_editingSummaryId != null) _buildSummaryEditOverlay(),
              if (_editingArrowId != null) _buildArrowEditOverlay(),

              // Context menu overlay
              if (_contextMenuNodeId != null && _contextMenuPosition != null)
                _buildContextMenu(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the edit mode overlay
  Widget _buildEditOverlay() {
    if (_editingNodeId == null) return const SizedBox.shrink();

    final layout = _nodeLayouts[_editingNodeId];
    if (layout == null) return const SizedBox.shrink();

    final data = _controller.getData();
    final theme = data.theme.variables;
    final node = _findNode(data.nodeData, _editingNodeId!);
    if (node == null) return const SizedBox.shrink();
    final depthValue =
        _editingNodeDepth ?? _findNodeDepth(data.nodeData, _editingNodeId!);
    final depth = depthValue < 0 ? 0 : depthValue;
    final fontSize =
        node.style?.fontSize ??
        (depth == 0 ? 25.0 : (depth == 1 ? 16.0 : 14.0));
    final fontWeight =
        node.style?.fontWeight ??
        (depth == 0 ? FontWeight.bold : FontWeight.normal);
    final fontFamily = node.style?.fontFamily;
    final textColor =
        node.style?.color ??
        (depth == 0
            ? theme.rootColor
            : depth == 1
            ? theme.mainColor
            : theme.color);
    final backgroundColor =
        node.style?.background ??
        (depth == 0
            ? theme.rootBgColor
            : depth == 1
            ? theme.mainBgColor
            : Colors.transparent);

    // 根据背景颜色亮度决定光标颜色
    // 深色背景使用白色光标，浅色背景使用深灰色光标
    final backgroundLuminance = backgroundColor == Colors.transparent
        ? 1.0 // 透明背景视为浅色
        : backgroundColor.computeLuminance();
    final cursorColor = backgroundLuminance > 0.5
        ? (Colors.grey[700] ?? Colors.grey) // 浅色背景用深灰色
        : Colors.white; // 深色背景用白色

    final padding = depth == 0
        ? const EdgeInsets.symmetric(horizontal: 30.0, vertical: 10.0)
        : (depth == 1
              ? const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0)
              : theme.topicPadding);
    final borderRadius = depth == 0
        ? theme.rootRadius
        : depth == 1
        ? theme.mainRadius
        : 3.0;
    final measureTextStyle = TextStyle(
      inherit: false,
      color: textColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: fontFamily,
      decoration: node.style?.textDecoration,
      letterSpacing: 0.0,
      wordSpacing: 0.0,
      textBaseline: TextBaseline.alphabetic,
    );
    final editTextPainter = TextPainter(
      text: TextSpan(text: _editController.text, style: measureTextStyle),
      textDirection: TextDirection.ltr,
    );
    editTextPainter.layout();
    const caretReserve = 4.0;
    final unconstrainedTextWidth = editTextPainter.width;
    final contentWidth = math.max(0.0, layout.size.width - padding.horizontal);
    final shouldWrap = MindMapState.shouldWrapEditText(
      text: _editController.text,
      style: measureTextStyle,
      contentWidth: contentWidth,
    );
    final renderedTextWidth = shouldWrap
        ? contentWidth
        : math.min(unconstrainedTextWidth, contentWidth);

    final transformedBounds = MatrixUtils.transformRect(
      _transform,
      layout.bounds,
    );
    final left = transformedBounds.left;
    final top = transformedBounds.top;
    final scaledWidth = transformedBounds.width;
    final scaledHeight = transformedBounds.height;
    final scaleX = layout.size.width == 0
        ? 1.0
        : scaledWidth / layout.size.width;
    final scaleY = layout.size.height == 0
        ? 1.0
        : scaledHeight / layout.size.height;
    final scale = (scaleX + scaleY) / 2.0;
    final scaledPadding = EdgeInsets.fromLTRB(
      padding.left * scaleX,
      padding.top * scaleY,
      padding.right * scaleX,
      padding.bottom * scaleY,
    );
    final scaledBorderRadius = borderRadius * scale;
    final scaledFontSize = fontSize * scale;
    final scaledRenderedTextWidth = renderedTextWidth * scale;
    final scaledCaretReserve = caretReserve * scaleX;
    final editFieldPadding = EdgeInsets.fromLTRB(
      scaledPadding.left,
      scaledPadding.top,
      math.max(0.0, scaledPadding.right - scaledCaretReserve),
      scaledPadding.bottom,
    );

    void setCaretToStart() {
      _editController.selection = const TextSelection.collapsed(offset: 0);
    }

    void setCaretToEnd() {
      _editController.selection = TextSelection.collapsed(
        offset: _editController.text.length,
      );
    }

    return Positioned(
      left: left,
      top: top,
      child: TextFieldTapRegion(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            _editFocusNode.requestFocus();
            if (shouldWrap) return;
            final tapX = details.localPosition.dx;
            final contentLeft = scaledPadding.left;
            final contentRight = scaledWidth - scaledPadding.right;
            final textRight =
                (contentLeft + scaledRenderedTextWidth + scaledCaretReserve)
                    .clamp(contentLeft, contentRight);
            if (tapX <= contentLeft) {
              setCaretToStart();
              return;
            }
            if (tapX >= textRight) {
              setCaretToEnd();
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.text,
            child: Stack(
              children: [
                KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent || event is KeyRepeatEvent) {
                      // Cancel on ESC key
                      if (event.logicalKey == LogicalKeyboardKey.escape) {
                        _cancelEdit();
                      }
                      // Finish on Enter or Tab (allow Shift+Enter for newline)
                      if ((event.logicalKey == LogicalKeyboardKey.enter ||
                              event.logicalKey == LogicalKeyboardKey.tab) &&
                          !HardwareKeyboard.instance.isShiftPressed) {
                        _finishEdit();
                      }
                    }
                  },
                  child: Container(
                    width: scaledWidth,
                    height: scaledHeight,
                    decoration: ShapeDecoration(
                      color: backgroundColor == Colors.transparent
                          ? null
                          : backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(scaledBorderRadius),
                      ),
                    ),
                    child: Padding(
                      padding: editFieldPadding,
                      child: TextField(
                        controller: _editController,
                        focusNode: _editFocusNode,
                        autofocus: true,
                        showCursor: true,
                        mouseCursor: SystemMouseCursors.text,
                        enableInteractiveSelection: true,
                        minLines: 1,
                        maxLines: shouldWrap ? null : 1,
                        keyboardType: shouldWrap
                            ? TextInputType.multiline
                            : TextInputType.text,
                        textInputAction: shouldWrap
                            ? TextInputAction.newline
                            : TextInputAction.done,
                        textAlign: TextAlign.left,
                        textAlignVertical: TextAlignVertical.top,
                        style: measureTextStyle.copyWith(
                          fontSize: scaledFontSize,
                        ),
                        strutStyle: StrutStyle.disabled,
                        scrollPadding: EdgeInsets.zero,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTapOutside: (_) {
                          if (_editingNodeId != null) {
                            _finishEdit();
                          }
                        },
                        cursorColor: cursorColor,
                        cursorHeight: scaledFontSize,
                        cursorWidth: 1.0,
                        onChanged: _onEditChanged,
                        onSubmitted: (_) => _finishEdit(),
                        onEditingComplete: _finishEdit,
                      ),
                    ),
                  ),
                ),
                // 深度1的边框
                if (depth == 1)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: scaledWidth,
                        height: scaledHeight,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: node.branchColor ?? theme.mainColor,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(
                            scaledBorderRadius,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryEditOverlay() {
    if (_editingSummaryId == null) return const SizedBox.shrink();

    final data = _controller.getData();
    final summary = _controller.getSummary(_editingSummaryId!);
    if (summary == null) return const SizedBox.shrink();

    final labelBounds = _resolveSummaryLabelBounds(
      summary,
      overrideLabel: _summaryEditController.text,
    );
    if (labelBounds == null) return const SizedBox.shrink();

    final transformedBounds = MatrixUtils.transformRect(
      _transform,
      labelBounds,
    );
    final left = transformedBounds.left;
    final top = transformedBounds.top;
    final scaledWidth = transformedBounds.width;
    final scaledHeight = transformedBounds.height;
    final scaleX = labelBounds.width == 0
        ? 1.0
        : scaledWidth / labelBounds.width;
    final scaleY = labelBounds.height == 0
        ? 1.0
        : scaledHeight / labelBounds.height;
    final scale = (scaleX + scaleY) / 2.0;
    const baseFontSize = 16.0;
    const caretReserve = 4.0;
    final scaledFontSize = baseFontSize * scale;
    final padding = data.theme.variables.topicPadding;
    final scaledPadding = EdgeInsets.fromLTRB(
      padding.left * scaleX,
      padding.top * scaleY,
      padding.right * scaleX,
      padding.bottom * scaleY,
    );
    final editFieldPadding = EdgeInsets.fromLTRB(
      scaledPadding.left,
      scaledPadding.top,
      math.max(0.0, scaledPadding.right - caretReserve * scaleX),
      scaledPadding.bottom,
    );

    final textColor =
        summary.style?.labelColor ??
        summary.style?.stroke ??
        data.theme.variables.color;
    final measureTextStyle = TextStyle(
      inherit: false,
      color: textColor,
      fontSize: baseFontSize,
      fontWeight: FontWeight.normal,
      height: 1.2,
      letterSpacing: 0.0,
      wordSpacing: 0.0,
      textBaseline: TextBaseline.alphabetic,
    );
    final shouldWrap = MindMapState.shouldWrapEditText(
      text: _summaryEditController.text,
      style: measureTextStyle,
      contentWidth: math.max(
        0.0,
        labelBounds.width - padding.horizontal + caretReserve,
      ),
      caretReserve: caretReserve,
    );

    return Positioned(
      left: left,
      top: top,
      child: TextFieldTapRegion(
        child: MouseRegion(
          cursor: SystemMouseCursors.text,
          child: SizedBox(
            width: scaledWidth,
            height: scaledHeight,
            child: Padding(
              padding: editFieldPadding,
              child: TextField(
                controller: _summaryEditController,
                focusNode: _summaryEditFocusNode,
                autofocus: true,
                showCursor: true,
                mouseCursor: SystemMouseCursors.text,
                enableInteractiveSelection: true,
                minLines: 1,
                maxLines: shouldWrap ? null : 1,
                keyboardType: shouldWrap
                    ? TextInputType.multiline
                    : TextInputType.text,
                textInputAction: shouldWrap
                    ? TextInputAction.newline
                    : TextInputAction.done,
                textAlign: TextAlign.left,
                textAlignVertical: TextAlignVertical.top,
                style: measureTextStyle.copyWith(fontSize: scaledFontSize),
                strutStyle: StrutStyle.disabled,
                scrollPadding: EdgeInsets.zero,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                ),
                cursorColor: textColor,
                cursorHeight: scaledFontSize,
                cursorWidth: 1.0,
                onChanged: (_) => setState(() {}),
                onTapOutside: (_) => _finishSummaryEdit(),
                onSubmitted: (_) => _finishSummaryEdit(),
                onEditingComplete: _finishSummaryEdit,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArrowEditOverlay() {
    if (_editingArrowId == null) return const SizedBox.shrink();

    final data = _controller.getData();
    final arrow = _controller.getArrow(_editingArrowId!);
    if (arrow == null) return const SizedBox.shrink();

    final labelBounds = _resolveArrowLabelBounds(
      arrow,
      overrideLabel: _arrowEditController.text,
    );
    if (labelBounds == null) return const SizedBox.shrink();

    final transformedBounds = MatrixUtils.transformRect(
      _transform,
      labelBounds,
    );
    final left = transformedBounds.left;
    final top = transformedBounds.top;
    final scaledWidth = transformedBounds.width;
    final scaledHeight = transformedBounds.height;
    final scaleX = labelBounds.width == 0
        ? 1.0
        : scaledWidth / labelBounds.width;
    final scaleY = labelBounds.height == 0
        ? 1.0
        : scaledHeight / labelBounds.height;
    final scale = (scaleX + scaleY) / 2.0;

    const baseFontSize = 12.0;
    final textColor = data.theme.variables.mainColor;
    final bgColor = data.theme.variables.bgColor.withValues(alpha: 0.9);
    final borderColor = data.theme.variables.mainColor.withValues(alpha: 0.3);
    final scaledFontSize = baseFontSize * scale;

    return Positioned(
      left: left,
      top: top,
      child: TextFieldTapRegion(
        child: MouseRegion(
          cursor: SystemMouseCursors.text,
          child: Container(
            width: scaledWidth,
            height: scaledHeight,
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor, width: 1.0),
              borderRadius: BorderRadius.circular(4.0 * scale),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: _arrowEditController,
              focusNode: _arrowEditFocusNode,
              autofocus: true,
              showCursor: true,
              mouseCursor: SystemMouseCursors.text,
              enableInteractiveSelection: true,
              minLines: 1,
              maxLines: 1,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              style: TextStyle(
                inherit: false,
                color: textColor,
                fontSize: scaledFontSize,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.0,
                wordSpacing: 0.0,
                textBaseline: TextBaseline.alphabetic,
              ),
              strutStyle: StrutStyle.disabled,
              scrollPadding: EdgeInsets.zero,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
              cursorColor: textColor,
              cursorHeight: scaledFontSize,
              cursorWidth: 1.0,
              onChanged: (_) => setState(() {}),
              onTapOutside: (_) => _finishArrowEdit(),
              onSubmitted: (_) => _finishArrowEdit(),
              onEditingComplete: _finishArrowEdit,
            ),
          ),
        ),
      ),
    );
  }

  Rect? _resolveSummaryLabelBounds(
    SummaryData summary, {
    String? overrideLabel,
  }) {
    final data = _controller.getData();
    final parentNode = _findNode(data.nodeData, summary.parentNodeId);
    if (parentNode == null) return null;
    final parentDepth = _findNodeDepth(data.nodeData, summary.parentNodeId);
    if (parentDepth < 0) return null;

    return SummaryRenderer.getSummaryLabelBounds(
      summary,
      parentNode,
      _nodeLayouts,
      data.theme,
      parentHasParent: parentDepth > 0,
      parentDepth: parentDepth,
      overrideLabel: overrideLabel,
    );
  }

  Rect? _resolveArrowLabelBounds(ArrowData arrow, {String? overrideLabel}) {
    final data = _controller.getData();
    return ArrowRenderer.getArrowLabelBounds(
      arrow,
      _nodeLayouts,
      data.theme,
      overrideLabel: overrideLabel,
    );
  }

  int _findNodeDepth(NodeData node, String targetId, [int depth = 0]) {
    if (node.id == targetId) return depth;
    for (final child in node.children) {
      final result = _findNodeDepth(child, targetId, depth + 1);
      if (result != -1) return result;
    }
    return -1;
  }

  @visibleForTesting
  static bool shouldWrapEditText({
    required String text,
    required TextStyle style,
    required double contentWidth,
    double caretReserve = 0.0,
  }) {
    if (text.contains('\n')) return true;
    final availableWidth = contentWidth - caretReserve;
    if (availableWidth <= 0) return true;

    // Avoid false-positive wrap near boundary caused by floating point and
    // glyph metric rounding differences between painter/editable text.
    final singleLinePainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );
    singleLinePainter.layout();
    if (singleLinePainter.width <= availableWidth + 0.5) {
      return false;
    }

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: availableWidth);
    return painter.computeLineMetrics().length > 1;
  }

  /// Build the context menu overlay
  ///
  Widget _buildContextMenu() {
    if (_contextMenuNodeId == null || _contextMenuPosition == null) {
      return const SizedBox.shrink();
    }

    final data = _controller.getData();
    final theme = data.theme.variables;

    return ContextMenuPopup(
      position: _contextMenuPosition!,
      items: _buildContextMenuItems(_contextMenuNodeId!),
      onDismiss: _dismissContextMenu,
      backgroundColor: theme.panelBgColor,
      textColor: theme.panelColor,
      iconColor: theme.panelColor.withValues(alpha: 0.7),
      hoverColor: theme.accentColor.withValues(alpha: 0.1),
      dividerColor: theme.panelBorderColor,
    );
  }
}

class _PendingImageLoad {
  final ImageStream stream;
  final ImageStreamListener listener;

  const _PendingImageLoad({required this.stream, required this.listener});
}

/// Base class for mind map events
abstract class MindMapEvent {
  const MindMapEvent();
}

/// Event emitted when nodes are selected
class SelectNodesEvent extends MindMapEvent {
  final List<String> nodeIds;

  const SelectNodesEvent(this.nodeIds);
}

/// Event emitted when a node is moved
class MoveNodeEvent extends MindMapEvent {
  final String nodeId;
  final String oldParentId;
  final String newParentId;
  final bool isReorder;

  const MoveNodeEvent({
    required this.nodeId,
    required this.oldParentId,
    required this.newParentId,
    required this.isReorder,
  });
}

/// Event emitted when a node is expanded or collapsed
class ExpandNodeEvent extends MindMapEvent {
  final String nodeId;
  final bool expanded;

  const ExpandNodeEvent(this.nodeId, this.expanded);
}

/// Event emitted when editing begins
class BeginEditEvent extends MindMapEvent {
  final String nodeId;

  const BeginEditEvent(this.nodeId);
}

/// Event emitted when editing finishes
class FinishEditEvent extends MindMapEvent {
  final String nodeId;
  final String newTopic;

  const FinishEditEvent(this.nodeId, this.newTopic);
}

/// Event emitted when a hyperlink is clicked
class HyperlinkClickEvent extends MindMapEvent {
  final String nodeId;
  final String url;

  const HyperlinkClickEvent(this.nodeId, this.url);
}

/// Event emitted when a node operation occurs
class NodeOperationEvent extends MindMapEvent {
  final String operation;
  final String nodeId;

  const NodeOperationEvent(this.operation, this.nodeId);
}

/// Event emitted when an arrow is created
class ArrowCreatedEvent extends MindMapEvent {
  final String arrowId;
  final String fromNodeId;
  final String toNodeId;

  const ArrowCreatedEvent(this.arrowId, this.fromNodeId, this.toNodeId);
}

/// Event emitted when a summary is created
class SummaryCreatedEvent extends MindMapEvent {
  final String summaryId;
  final String parentNodeId;

  const SummaryCreatedEvent(this.summaryId, this.parentNodeId);
}

class _SelectionRectPainter extends CustomPainter {
  final Rect? rect;
  final Color fillColor;
  final Color borderColor;

  _SelectionRectPainter({
    required this.rect,
    required this.fillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rect == null) return;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(rect!, fillPaint);
    canvas.drawRect(rect!, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SelectionRectPainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}
