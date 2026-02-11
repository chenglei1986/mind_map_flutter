import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';
import '../../utils/web_export_downloader_stub.dart'
    if (dart.library.html) '../../utils/web_export_downloader_web.dart'
    as web_export_downloader;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum _ExportFormat { png, json }

enum _AppBarAction {
  importJson,
  exportPng,
  exportJson,
  distributionAverage,
  distributionLeft,
  distributionRight,
  resetScenario,
  undo,
  redo,
  centerView,
}

class _HomePageState extends State<HomePage> {
  late final MindMapController _controller;
  StreamSubscription<MindMapEvent>? _eventSubscription;
  final List<String> _eventLogs = <String>[];
  bool _readOnly = false;

  @override
  void initState() {
    super.initState();
    _controller = MindMapController(initialData: _initialData());
    _controller.addListener(_onControllerChanged);
    _eventSubscription = _controller.eventStream.listen(_onEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.centerViewWhenReady();
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleReadOnly() {
    setState(() {
      _readOnly = !_readOnly;
    });
    _snack(_readOnly ? 'Read-only enabled' : 'Read-only disabled');
  }

  void _toggleTheme() {
    final currentTheme = _controller.getData().theme;
    final isDarkTheme =
        currentTheme.name.toLowerCase() == 'dark' ||
        currentTheme.variables.bgColor.computeLuminance() < 0.5;
    _controller.setTheme(isDarkTheme ? MindMapTheme.light : MindMapTheme.dark);
    _snack(isDarkTheme ? 'Light theme enabled' : 'Dark theme enabled');
  }

  void _onEvent(MindMapEvent event) {
    final log =
        '${DateTime.now().toIso8601String().substring(11, 19)} '
        '${_describeEvent(event)}';
    if (!mounted) return;
    setState(() {
      _eventLogs.insert(0, log);
      if (_eventLogs.length > 10) {
        _eventLogs.removeRange(10, _eventLogs.length);
      }
    });
  }

  NodeData _applyRandomRootBranchColors(NodeData root) {
    final random = math.Random();
    final usedHues = <int>{};
    final updatedChildren = root.children
        .map((child) {
          final color = _randomBranchColor(random, usedHues);
          return _applyBranchColorRecursively(child, color);
        })
        .toList(growable: false);
    return root.copyWith(children: updatedChildren);
  }

  NodeData _applyBranchColorRecursively(NodeData node, Color color) {
    final updatedChildren = node.children
        .map((child) => _applyBranchColorRecursively(child, color))
        .toList(growable: false);
    return node.copyWith(branchColor: color, children: updatedChildren);
  }

  Color _randomBranchColor(math.Random random, Set<int> usedHues) {
    for (int i = 0; i < 24; i++) {
      final hue = random.nextInt(360);
      if (usedHues.add(hue)) {
        return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.72, 0.46).toColor();
      }
    }
    final fallbackHue = random.nextInt(360);
    return HSLColor.fromAHSL(1.0, fallbackHue.toDouble(), 0.72, 0.46).toColor();
  }

  MindMapData _initialData({MindMapTheme? theme, LayoutDirection? direction}) {
    return MindMapData(
      theme: theme ?? MindMapTheme.light,
      direction: direction ?? LayoutDirection.side,
      nodeData: _applyRandomRootBranchColors(
        NodeData.create(
          id: 'root',
          topic: 'Web Frontend Tech',
          style: const NodeStyle(fontSize: 26, fontWeight: FontWeight.w700),
          children: [
            NodeData.create(
              id: 'foundations',
              topic: 'Foundations',
              direction: LayoutDirection.left,
              tags: const [
                TagData(text: 'HTML'),
                TagData(text: 'CSS'),
                TagData(text: 'JS'),
              ],
              children: [
                NodeData.create(
                  id: 'html_semantics',
                  topic: 'HTML Semantics & SEO',
                  icons: const ['!'],
                ),
                NodeData.create(
                  id: 'css_system',
                  topic: 'CSS Architecture',
                  expanded: false,
                  tags: const [TagData(text: 'Collapsed')],
                  children: [
                    NodeData.create(id: 'bem', topic: 'BEM'),
                    NodeData.create(id: 'css_modules', topic: 'CSS Modules'),
                    NodeData.create(id: 'tailwind', topic: 'Tailwind'),
                    NodeData.create(
                      id: 'design_tokens',
                      topic: 'Design Tokens',
                    ),
                  ],
                ),
                NodeData.create(
                  id: 'javascript',
                  topic: 'JavaScript / TypeScript',
                  note: 'Keep domain logic framework-agnostic.',
                  children: [
                    NodeData.create(id: 'esnext', topic: 'ESNext Features'),
                    NodeData.create(id: 'typescript', topic: 'Type Safety'),
                    NodeData.create(
                      id: 'async_patterns',
                      topic: 'Async Patterns',
                    ),
                  ],
                ),
              ],
            ),
            NodeData.create(
              id: 'frameworks',
              topic: 'Frameworks & Runtime',
              direction: LayoutDirection.right,
              tags: const [
                TagData(text: 'SPA'),
                TagData(text: 'SSR'),
              ],
              children: [
                NodeData.create(
                  id: 'react_stack',
                  topic: 'React Ecosystem',
                  children: [
                    NodeData.create(
                      id: 'hooks',
                      topic: 'Hooks & Concurrent UI',
                    ),
                    NodeData.create(id: 'nextjs', topic: 'Next.js App Router'),
                    NodeData.create(
                      id: 'state_react',
                      topic: 'Redux / Zustand',
                    ),
                  ],
                ),
                NodeData.create(
                  id: 'vue_stack',
                  topic: 'Vue Ecosystem',
                  children: [
                    NodeData.create(
                      id: 'composition_api',
                      topic: 'Composition API',
                    ),
                    NodeData.create(id: 'nuxt', topic: 'Nuxt'),
                    NodeData.create(id: 'pinia', topic: 'Pinia'),
                  ],
                ),
                NodeData.create(id: 'web_components', topic: 'Web Components'),
                NodeData.create(
                  id: 'micro_frontend',
                  topic: 'Micro Frontend',
                  hyperLink: 'https://micro-frontends.org',
                  icons: const [],
                ),
              ],
            ),
            NodeData.create(
              id: 'engineering',
              topic: 'Engineering Workflow',
              direction: LayoutDirection.left,
              tags: const [
                TagData(text: 'Build'),
                TagData(text: 'CI'),
              ],
              children: [
                NodeData.create(
                  id: 'build_tools',
                  topic: 'Bundlers',
                  children: [
                    NodeData.create(id: 'vite', topic: 'Vite'),
                    NodeData.create(id: 'webpack', topic: 'Webpack'),
                    NodeData.create(id: 'rspack', topic: 'Rspack / Turbopack'),
                  ],
                ),
                NodeData.create(
                  id: 'quality',
                  topic: 'Code Quality & Testing',
                  children: [
                    NodeData.create(id: 'eslint', topic: 'ESLint + Prettier'),
                    NodeData.create(id: 'vitest', topic: 'Vitest / Jest'),
                    NodeData.create(id: 'playwright', topic: 'Playwright E2E'),
                  ],
                ),
                NodeData.create(
                  id: 'ci_cd',
                  topic: 'CI/CD Pipeline',
                  style: const NodeStyle(
                    textDecoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            NodeData.create(
              id: 'performance',
              topic: 'Performance',
              direction: LayoutDirection.right,
              tags: const [TagData(text: 'CWV')],
              children: [
                NodeData.create(id: 'web_vitals', topic: 'Core Web Vitals'),
                NodeData.create(
                  id: 'rendering_perf',
                  topic: 'Rendering & Hydration',
                ),
                NodeData.create(id: 'cache', topic: 'HTTP Cache & SW'),
                NodeData.create(
                  id: 'image_pipeline',
                  topic: 'Image Optimization',
                  image: const ImageData(
                    url: 'assets/frontend-image.png',
                    width: 132,
                    height: 64,
                  ),
                  style: const NodeStyle(
                    background: Color(0xFFFFF7ED),
                    color: Color(0xFF9A3412),
                  ),
                ),
              ],
            ),
            NodeData.create(
              id: 'architecture',
              topic: 'App Architecture',
              direction: LayoutDirection.left,
              tags: const [TagData(text: 'Patterns')],
              children: [
                NodeData.create(id: 'design_system', topic: 'Design System'),
                NodeData.create(id: 'state_models', topic: 'State Modeling'),
                NodeData.create(
                  id: 'module_federation',
                  topic: 'Module Federation',
                ),
              ],
            ),
          ],
        ),
      ),
      arrows: [
        ArrowData.create(
          id: 'arrow_tokens_to_design',
          fromNodeId: 'design_tokens',
          toNodeId: 'design_system',
          label: 'Token Sync',
          style: const ArrowStyle(
            strokeColor: Color(0xFF2563EB),
            strokeWidth: 2.0,
          ),
        ),
        ArrowData.create(
          id: 'arrow_vitals_to_quality',
          fromNodeId: 'web_vitals',
          toNodeId: 'quality',
          label: 'Perf Budget Gate',
          bidirectional: true,
          style: const ArrowStyle(
            strokeColor: Color(0xFFEA580C),
            strokeWidth: 2.0,
            dashPattern: [6.0, 4.0],
          ),
        ),
        ArrowData.create(
          id: 'arrow_micro_to_ci',
          fromNodeId: 'micro_frontend',
          toNodeId: 'ci_cd',
          label: 'Deploy Orchestration',
          style: const ArrowStyle(
            strokeColor: Color(0xFF0D9488),
            strokeWidth: 2.0,
          ),
        ),
      ],
      summaries: [
        SummaryData.create(
          id: 'summary_foundations',
          parentNodeId: 'foundations',
          startIndex: 0,
          endIndex: 1,
          label: 'Core Language Layer',
          style: const SummaryStyle(
            stroke: Color(0xFF2563EB),
            labelColor: Color(0xFF2563EB),
          ),
        ),
        SummaryData.create(
          id: 'summary_frameworks',
          parentNodeId: 'frameworks',
          startIndex: 0,
          endIndex: 2,
          label: 'UI Runtime Families',
          style: const SummaryStyle(
            stroke: Color(0xFF0D9488),
            labelColor: Color(0xFF0D9488),
          ),
        ),
      ],
    );
  }

  String? get _selectedNodeId {
    final ids = _controller.getSelectedNodeIds();
    return ids.isEmpty ? null : ids.first;
  }

  NodeData? get _selectedNode {
    final id = _selectedNodeId;
    if (id == null) return null;
    return _findNode(_controller.getData().nodeData, id);
  }

  NodeData? _findNode(NodeData node, String id) {
    if (node.id == id) return node;
    for (final child in node.children) {
      final found = _findNode(child, id);
      if (found != null) return found;
    }
    return null;
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  void _resetMap() {
    final current = _controller.getData();
    _controller.refresh(
      _initialData(theme: current.theme, direction: current.direction),
    );
    _controller.centerViewWhenReady();
    _snack('Reset web frontend tech map');
  }

  void _setDistribution(LayoutDirection direction) {
    if (_controller.getLayoutDirection() == direction &&
        direction != LayoutDirection.side) {
      return;
    }
    _controller.setLayoutDirection(direction);
    _snack('Distribution: ${_distributionLabel(direction)}');
  }

  bool get _isMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _onExportSelected(_ExportFormat format) async {
    switch (format) {
      case _ExportFormat.png:
        await _exportPng();
        break;
      case _ExportFormat.json:
        await _exportJson();
        break;
    }
  }

  Future<void> _exportPng() async {
    try {
      final bytes = await _controller.exportToPng(pixelRatio: 1.5);
      if (_isMobilePlatform) {
        final hasAccess = await Gal.hasAccess();
        final granted = hasAccess ? true : await Gal.requestAccess();
        if (!granted) {
          _snack('无法访问相册 / Gallery access denied');
          return;
        }

        final fileName = 'mind_map_${DateTime.now().millisecondsSinceEpoch}';
        await Gal.putImageBytes(bytes, name: fileName);
        _snack('PNG 已保存到相册 / PNG saved to gallery');
        return;
      }

      await _saveBytesByPicker(
        dialogTitle: 'Export PNG',
        fileName: 'mind_map.png',
        bytes: bytes,
        allowedExtensions: const ['png'],
        mimeType: 'image/png',
      );
    } on GalException catch (error) {
      _snack('保存到相册失败 / Save to gallery failed: ${error.type.message}');
    } catch (error) {
      _snack('Export PNG failed: $error');
    }
  }

  Future<void> _exportJson() async {
    try {
      final json = _controller.exportToJson();
      await _saveBytesByPicker(
        dialogTitle: 'Export JSON',
        fileName: 'mind_map.json',
        bytes: Uint8List.fromList(utf8.encode(json)),
        allowedExtensions: const ['json'],
        mimeType: 'application/json',
      );
    } catch (error) {
      _snack('Export JSON failed: $error');
    }
  }

  Future<void> _importJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Import JSON',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (!mounted || result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      if (bytes == null || bytes.isEmpty) {
        _snack('Import JSON failed: empty file data');
        return;
      }

      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        _snack('Import JSON failed: invalid JSON structure');
        return;
      }

      final imported = MindMapData.fromJson(decoded);
      _controller.refresh(imported);
      _controller.centerViewWhenReady();
      _snack('Imported JSON');
    } catch (error) {
      _snack('Import JSON failed: $error');
    }
  }

  Future<void> _saveBytesByPicker({
    required String dialogTitle,
    required String fileName,
    required Uint8List bytes,
    required List<String> allowedExtensions,
    required String mimeType,
  }) async {
    if (kIsWeb) {
      await web_export_downloader.downloadExportBytes(
        fileName,
        bytes,
        mimeType,
      );
      if (!mounted) return;
      _snack('Exported: $fileName');
      return;
    }
    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      bytes: bytes,
    );
    if (!mounted || savedPath == null) return;
    _snack('Exported: $savedPath');
  }

  String _distributionLabel(LayoutDirection direction) {
    switch (direction) {
      case LayoutDirection.side:
        return 'Average';
      case LayoutDirection.left:
        return 'Left';
      case LayoutDirection.right:
        return 'Right';
    }
  }

  String _describeEvent(MindMapEvent event) {
    if (event is NodeOperationEvent) return 'NodeOperation(${event.operation})';
    if (event is MoveNodeEvent) return 'MoveNode(${event.nodeId})';
    if (event is ExpandNodeEvent) {
      return 'ExpandNode(${event.nodeId}, expanded=${event.expanded})';
    }
    if (event is SelectNodesEvent) {
      return 'SelectNodes(${event.nodeIds.length})';
    }
    if (event is BeginEditEvent) return 'BeginEdit(${event.nodeId})';
    if (event is FinishEditEvent) return 'FinishEdit(${event.nodeId})';
    if (event is HyperlinkClickEvent) return 'Hyperlink(${event.nodeId})';
    if (event is ArrowCreatedEvent) return 'ArrowCreated(${event.arrowId})';
    if (event is SummaryCreatedEvent) {
      return 'SummaryCreated(${event.summaryId})';
    }
    return event.runtimeType.toString();
  }

  void _onAppBarActionSelected(_AppBarAction action) {
    switch (action) {
      case _AppBarAction.importJson:
        unawaited(_importJson());
        return;
      case _AppBarAction.exportPng:
        unawaited(_exportPng());
        return;
      case _AppBarAction.exportJson:
        unawaited(_exportJson());
        return;
      case _AppBarAction.distributionAverage:
        _setDistribution(LayoutDirection.side);
        return;
      case _AppBarAction.distributionLeft:
        _setDistribution(LayoutDirection.left);
        return;
      case _AppBarAction.distributionRight:
        _setDistribution(LayoutDirection.right);
        return;
      case _AppBarAction.resetScenario:
        _resetMap();
        return;
      case _AppBarAction.undo:
        if (_controller.canUndo()) {
          _controller.undo();
        }
        return;
      case _AppBarAction.redo:
        if (_controller.canRedo()) {
          _controller.redo();
        }
        return;
      case _AppBarAction.centerView:
        _controller.centerView();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _controller.getData();
    final selected = _selectedNode;
    final currentDirection = data.direction;
    final isDarkTheme =
        data.theme.name.toLowerCase() == 'dark' ||
        data.theme.variables.bgColor.computeLuminance() < 0.5;
    final isCompactAppBar = MediaQuery.sizeOf(context).width < 700;
    final selectedText = selected == null
        ? 'No selection'
        : '${selected.topic} (${selected.id})';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: isCompactAppBar
            ? const Text('Web Frontend Map', overflow: TextOverflow.ellipsis)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Web Frontend Tech Mind Map'),
                  Text(
                    selectedText,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: isDarkTheme
                ? 'Switch to light theme'
                : 'Switch to dark theme',
            onPressed: _toggleTheme,
            icon: Icon(isDarkTheme ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            tooltip: _readOnly ? 'Read-only: ON' : 'Read-only: OFF',
            onPressed: _toggleReadOnly,
            icon: Icon(_readOnly ? Icons.lock : Icons.lock_open),
          ),
          if (isCompactAppBar)
            PopupMenuButton<_AppBarAction>(
              tooltip: 'More actions',
              icon: const Icon(Icons.more_vert),
              onSelected: _onAppBarActionSelected,
              itemBuilder: (context) => [
                const PopupMenuItem<_AppBarAction>(
                  value: _AppBarAction.importJson,
                  child: Text('Import JSON'),
                ),
                const PopupMenuItem<_AppBarAction>(
                  value: _AppBarAction.exportPng,
                  child: Text('Export PNG'),
                ),
                const PopupMenuItem<_AppBarAction>(
                  value: _AppBarAction.exportJson,
                  child: Text('Export JSON'),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<_AppBarAction>(
                  value: _AppBarAction.distributionAverage,
                  child: Row(
                    children: [
                      Icon(
                        currentDirection == LayoutDirection.side
                            ? Icons.check
                            : Icons.circle_outlined,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text('Average distribution'),
                    ],
                  ),
                ),
                PopupMenuItem<_AppBarAction>(
                  value: _AppBarAction.distributionLeft,
                  child: Row(
                    children: [
                      Icon(
                        currentDirection == LayoutDirection.left
                            ? Icons.check
                            : Icons.circle_outlined,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text('Left distribution'),
                    ],
                  ),
                ),
                PopupMenuItem<_AppBarAction>(
                  value: _AppBarAction.distributionRight,
                  child: Row(
                    children: [
                      Icon(
                        currentDirection == LayoutDirection.right
                            ? Icons.check
                            : Icons.circle_outlined,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text('Right distribution'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<_AppBarAction>(
                  value: _AppBarAction.resetScenario,
                  child: Text('Reset scenario'),
                ),
                PopupMenuItem<_AppBarAction>(
                  value: _AppBarAction.undo,
                  enabled: _controller.canUndo(),
                  child: const Text('Undo'),
                ),
                PopupMenuItem<_AppBarAction>(
                  value: _AppBarAction.redo,
                  enabled: _controller.canRedo(),
                  child: const Text('Redo'),
                ),
                const PopupMenuItem<_AppBarAction>(
                  value: _AppBarAction.centerView,
                  child: Text('Center view'),
                ),
              ],
            )
          else ...[
            IconButton(
              tooltip: 'Import JSON',
              onPressed: () {
                unawaited(_importJson());
              },
              icon: const Icon(Icons.file_open_outlined),
            ),
            PopupMenuButton<_ExportFormat>(
              tooltip: 'Export',
              icon: const Icon(Icons.ios_share_outlined),
              onSelected: (format) {
                unawaited(_onExportSelected(format));
              },
              itemBuilder: (context) => const [
                PopupMenuItem<_ExportFormat>(
                  value: _ExportFormat.png,
                  child: Text('Export PNG'),
                ),
                PopupMenuItem<_ExportFormat>(
                  value: _ExportFormat.json,
                  child: Text('Export JSON'),
                ),
              ],
            ),
            PopupMenuButton<LayoutDirection>(
              tooltip: 'Node distribution',
              icon: const Icon(Icons.account_tree_outlined),
              onSelected: _setDistribution,
              itemBuilder: (context) => [
                PopupMenuItem<LayoutDirection>(
                  value: LayoutDirection.side,
                  child: Row(
                    children: [
                      Icon(
                        currentDirection == LayoutDirection.side
                            ? Icons.check
                            : Icons.circle_outlined,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text('Average distribution'),
                    ],
                  ),
                ),
                PopupMenuItem<LayoutDirection>(
                  value: LayoutDirection.left,
                  child: Row(
                    children: [
                      Icon(
                        currentDirection == LayoutDirection.left
                            ? Icons.check
                            : Icons.circle_outlined,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text('Left distribution'),
                    ],
                  ),
                ),
                PopupMenuItem<LayoutDirection>(
                  value: LayoutDirection.right,
                  child: Row(
                    children: [
                      Icon(
                        currentDirection == LayoutDirection.right
                            ? Icons.check
                            : Icons.circle_outlined,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text('Right distribution'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              tooltip: 'Reset scenario',
              onPressed: _resetMap,
              icon: const Icon(Icons.auto_awesome),
            ),
            IconButton(
              tooltip: 'Undo',
              onPressed: _controller.canUndo() ? _controller.undo : null,
              icon: const Icon(Icons.undo_rounded),
            ),
            IconButton(
              tooltip: 'Redo',
              onPressed: _controller.canRedo() ? _controller.redo : null,
              icon: const Icon(Icons.redo_rounded),
            ),
            IconButton(
              tooltip: 'Center view',
              onPressed: _controller.centerView,
              icon: const Icon(Icons.filter_center_focus),
            ),
          ],
        ],
      ),
      body: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: MindMapWidget(
            initialData: data,
            controller: _controller,
            config: MindMapConfig(
              allowUndo: true,
              enableKeyboardShortcuts: true,
              enableContextMenu: true,
              enableDragDrop: true,
              readOnly: _readOnly,
            ),
          ),
        ),
      ),
    );
  }
}
