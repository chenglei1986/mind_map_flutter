import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

/// Supported locale selection for the core library.
enum MindMapLocale { auto, zh, en }

/// Localized strings used by core widgets and interactions.
@immutable
class MindMapStrings {
  final String menuAddChild;
  final String menuAddSibling;
  final String menuAddParent;
  final String menuDeleteNode;
  final String menuEditProperties;
  final String menuCreateArrow;
  final String menuCreateSummary;
  final String menuFocusMode;
  final String menuInsertImage;
  final String menuRemoveImage;
  final String menuSetHyperlink;
  final String menuRemoveHyperlink;
  final String menuAddTag;
  final String menuAddIcon;
  final String menuExpandNode;
  final String menuCollapseNode;

  final String actionCancel;
  final String actionConfirm;

  final String dialogTitleSetImage;
  final String dialogTitleSetHyperlink;
  final String dialogTitleAddTag;
  final String dialogTitleAddIcon;
  final String fieldImageUrl;
  final String fieldImageWidth;
  final String fieldImageHeight;
  final String fieldImageFit;
  final String fieldHyperlink;
  final String fieldTag;
  final String fieldIcon;

  final String focusModePrefix;
  final String focusModeUnknownNode;
  final String focusModeExitHint;

  final String defaultRootTopic;
  final String defaultNewNodeTopic;
  final String defaultSummaryLabel;

  final String errorCannotDeleteRootNode;
  final String errorInvalidNodeIdTemplate;
  final String errorCannotMoveNodesToMovedSet;
  final String errorCannotMoveNodeToOwnDescendant;
  final String errorCannotFindParentOfNodeTemplate;
  final String errorCannotMoveRootNode;
  final String errorCannotMoveNodeToItself;
  final String errorCannotInsertParentForRootNode;
  final String errorNoSourceNodeSelected;
  final String errorNotInArrowCreationMode;
  final String errorNotInSummaryCreationMode;
  final String errorNoNodesSelectedForSummary;
  final String errorFailedToCreateSummaryTemplate;
  final String errorInvalidChildRangeTemplate;
  final String errorArrowNotFoundTemplate;
  final String errorSummaryNotFoundTemplate;
  final String errorNoNodeInClipboard;
  final String errorRepaintBoundaryKeyNotSet;
  final String errorFailedToGetRenderRepaintBoundary;
  final String errorFailedToConvertImageToPng;

  final String errorNoNodesSelected;
  final String errorNodeNotFoundTemplate;
  final String errorCannotSelectRootNode;

  const MindMapStrings({
    required this.menuAddChild,
    required this.menuAddSibling,
    required this.menuAddParent,
    required this.menuDeleteNode,
    required this.menuEditProperties,
    required this.menuCreateArrow,
    required this.menuCreateSummary,
    required this.menuFocusMode,
    required this.menuInsertImage,
    required this.menuRemoveImage,
    required this.menuSetHyperlink,
    required this.menuRemoveHyperlink,
    required this.menuAddTag,
    required this.menuAddIcon,
    required this.menuExpandNode,
    required this.menuCollapseNode,
    required this.actionCancel,
    required this.actionConfirm,
    required this.dialogTitleSetImage,
    required this.dialogTitleSetHyperlink,
    required this.dialogTitleAddTag,
    required this.dialogTitleAddIcon,
    required this.fieldImageUrl,
    required this.fieldImageWidth,
    required this.fieldImageHeight,
    required this.fieldImageFit,
    required this.fieldHyperlink,
    required this.fieldTag,
    required this.fieldIcon,
    required this.focusModePrefix,
    required this.focusModeUnknownNode,
    required this.focusModeExitHint,
    required this.defaultRootTopic,
    required this.defaultNewNodeTopic,
    required this.defaultSummaryLabel,
    required this.errorCannotDeleteRootNode,
    required this.errorInvalidNodeIdTemplate,
    required this.errorCannotMoveNodesToMovedSet,
    required this.errorCannotMoveNodeToOwnDescendant,
    required this.errorCannotFindParentOfNodeTemplate,
    required this.errorCannotMoveRootNode,
    required this.errorCannotMoveNodeToItself,
    required this.errorCannotInsertParentForRootNode,
    required this.errorNoSourceNodeSelected,
    required this.errorNotInArrowCreationMode,
    required this.errorNotInSummaryCreationMode,
    required this.errorNoNodesSelectedForSummary,
    required this.errorFailedToCreateSummaryTemplate,
    required this.errorInvalidChildRangeTemplate,
    required this.errorArrowNotFoundTemplate,
    required this.errorSummaryNotFoundTemplate,
    required this.errorNoNodeInClipboard,
    required this.errorRepaintBoundaryKeyNotSet,
    required this.errorFailedToGetRenderRepaintBoundary,
    required this.errorFailedToConvertImageToPng,
    required this.errorNoNodesSelected,
    required this.errorNodeNotFoundTemplate,
    required this.errorCannotSelectRootNode,
  });

  static const MindMapStrings zh = MindMapStrings(
    menuAddChild: '添加子节点',
    menuAddSibling: '添加兄弟节点',
    menuAddParent: '添加父节点',
    menuDeleteNode: '删除节点',
    menuEditProperties: '编辑属性',
    menuCreateArrow: '创建箭头',
    menuCreateSummary: '创建摘要',
    menuFocusMode: '聚焦模式',
    menuInsertImage: '插入图片',
    menuRemoveImage: '移除图片',
    menuSetHyperlink: '设置链接',
    menuRemoveHyperlink: '移除链接',
    menuAddTag: '添加标签',
    menuAddIcon: '添加图标',
    menuExpandNode: '展开节点',
    menuCollapseNode: '折叠节点',
    actionCancel: '取消',
    actionConfirm: '确定',
    dialogTitleSetImage: '设置图片',
    dialogTitleSetHyperlink: '设置链接',
    dialogTitleAddTag: '添加标签',
    dialogTitleAddIcon: '添加图标',
    fieldImageUrl: '图片地址',
    fieldImageWidth: '宽度',
    fieldImageHeight: '高度',
    fieldImageFit: '适应模式',
    fieldHyperlink: '链接地址',
    fieldTag: '标签',
    fieldIcon: '图标',
    focusModePrefix: '聚焦模式',
    focusModeUnknownNode: '未知节点',
    focusModeExitHint: 'ESC 退出',
    defaultRootTopic: '中心主题',
    defaultNewNodeTopic: '新节点',
    defaultSummaryLabel: '摘要',
    errorCannotDeleteRootNode: '不能删除根节点',
    errorInvalidNodeIdTemplate: '未找到节点 ID: {id}',
    errorCannotMoveNodesToMovedSet: '不能把节点移动到待移动节点自身或其后代中',
    errorCannotMoveNodeToOwnDescendant: '不能把节点移动到它自己的后代节点下',
    errorCannotFindParentOfNodeTemplate: '找不到节点 {id} 的父节点',
    errorCannotMoveRootNode: '不能移动根节点',
    errorCannotMoveNodeToItself: '不能把节点移动到它自己',
    errorCannotInsertParentForRootNode: '不能为根节点插入父节点',
    errorNoSourceNodeSelected: '未选择箭头起点节点',
    errorNotInArrowCreationMode: '当前不在箭头创建模式',
    errorNotInSummaryCreationMode: '当前不在摘要创建模式',
    errorNoNodesSelectedForSummary: '未选择用于创建摘要的节点',
    errorFailedToCreateSummaryTemplate: '创建摘要失败: {error}',
    errorInvalidChildRangeTemplate: '无效的子节点范围: {start} 到 {end}',
    errorArrowNotFoundTemplate: '未找到箭头 ID: {id}',
    errorSummaryNotFoundTemplate: '未找到摘要 ID: {id}',
    errorNoNodeInClipboard: '剪贴板中没有节点',
    errorRepaintBoundaryKeyNotSet: '未设置 RepaintBoundary key，请确认组件已初始化',
    errorFailedToGetRenderRepaintBoundary:
        '获取 RenderRepaintBoundary 失败，请确认组件已渲染',
    errorFailedToConvertImageToPng: '将图像转换为 PNG 失败',
    errorNoNodesSelected: '未选择任何节点',
    errorNodeNotFoundTemplate: '未找到节点: {id}',
    errorCannotSelectRootNode: '不能选择根节点',
  );

  static const MindMapStrings en = MindMapStrings(
    menuAddChild: 'Add Child Node',
    menuAddSibling: 'Add Sibling Node',
    menuAddParent: 'Add Parent Node',
    menuDeleteNode: 'Delete Node',
    menuEditProperties: 'Edit Properties',
    menuCreateArrow: 'Create Arrow',
    menuCreateSummary: 'Create Summary',
    menuFocusMode: 'Focus Mode',
    menuInsertImage: 'Insert Image',
    menuRemoveImage: 'Remove Image',
    menuSetHyperlink: 'Set Hyperlink',
    menuRemoveHyperlink: 'Remove Hyperlink',
    menuAddTag: 'Add Tag',
    menuAddIcon: 'Add Icon',
    menuExpandNode: 'Expand Node',
    menuCollapseNode: 'Collapse Node',
    actionCancel: 'Cancel',
    actionConfirm: 'Confirm',
    dialogTitleSetImage: 'Set Image',
    dialogTitleSetHyperlink: 'Set Hyperlink',
    dialogTitleAddTag: 'Add Tag',
    dialogTitleAddIcon: 'Add Icon',
    fieldImageUrl: 'Image URL',
    fieldImageWidth: 'Width',
    fieldImageHeight: 'Height',
    fieldImageFit: 'Fit',
    fieldHyperlink: 'Hyperlink',
    fieldTag: 'Tag',
    fieldIcon: 'Icon',
    focusModePrefix: 'Focus Mode',
    focusModeUnknownNode: 'Unknown Node',
    focusModeExitHint: 'ESC Exit',
    defaultRootTopic: 'Central Topic',
    defaultNewNodeTopic: 'New Node',
    defaultSummaryLabel: 'Summary',
    errorCannotDeleteRootNode: 'Cannot delete root node',
    errorInvalidNodeIdTemplate: 'Node with ID {id} not found',
    errorCannotMoveNodesToMovedSet:
        'Cannot move nodes to one of the nodes being moved',
    errorCannotMoveNodeToOwnDescendant:
        'Cannot move node to its own descendant',
    errorCannotFindParentOfNodeTemplate: 'Cannot find parent of node {id}',
    errorCannotMoveRootNode: 'Cannot move root node',
    errorCannotMoveNodeToItself: 'Cannot move node to itself',
    errorCannotInsertParentForRootNode: 'Cannot insert parent for root node',
    errorNoSourceNodeSelected: 'No source node selected',
    errorNotInArrowCreationMode: 'Not in arrow creation mode',
    errorNotInSummaryCreationMode: 'Not in summary creation mode',
    errorNoNodesSelectedForSummary: 'No nodes selected for summary',
    errorFailedToCreateSummaryTemplate: 'Failed to create summary: {error}',
    errorInvalidChildRangeTemplate: 'Invalid child range: {start} to {end}',
    errorArrowNotFoundTemplate: 'Arrow with ID {id} not found',
    errorSummaryNotFoundTemplate: 'Summary with ID {id} not found',
    errorNoNodeInClipboard: 'No node in clipboard',
    errorRepaintBoundaryKeyNotSet:
        'RepaintBoundary key not set. Make sure the widget is initialized.',
    errorFailedToGetRenderRepaintBoundary:
        'Failed to get RenderRepaintBoundary. Make sure the widget is rendered.',
    errorFailedToConvertImageToPng: 'Failed to convert image to PNG format.',
    errorNoNodesSelected: 'No nodes selected',
    errorNodeNotFoundTemplate: 'Node not found: {id}',
    errorCannotSelectRootNode: 'Cannot select root node',
  );

  static MindMapStrings resolve(MindMapLocale preferred, [ui.Locale? locale]) {
    switch (preferred) {
      case MindMapLocale.zh:
        return zh;
      case MindMapLocale.en:
        return en;
      case MindMapLocale.auto:
        return _isChinese(locale ?? ui.PlatformDispatcher.instance.locale)
            ? zh
            : en;
    }
  }

  String focusModeTitle(String nodeTitle) => '$focusModePrefix: $nodeTitle';

  String errorInvalidNodeId(String nodeId) =>
      errorInvalidNodeIdTemplate.replaceAll('{id}', nodeId);

  String errorCannotFindParentOfNode(String nodeId) =>
      errorCannotFindParentOfNodeTemplate.replaceAll('{id}', nodeId);

  String errorFailedToCreateSummary(Object error) =>
      errorFailedToCreateSummaryTemplate.replaceAll('{error}', '$error');

  String errorArrowNotFound(String arrowId) =>
      errorArrowNotFoundTemplate.replaceAll('{id}', arrowId);

  String errorSummaryNotFound(String summaryId) =>
      errorSummaryNotFoundTemplate.replaceAll('{id}', summaryId);

  String errorNodeNotFound(String nodeId) =>
      errorNodeNotFoundTemplate.replaceAll('{id}', nodeId);

  String errorInvalidChildRange(int start, int end) =>
      errorInvalidChildRangeTemplate
          .replaceAll('{start}', '$start')
          .replaceAll('{end}', '$end');

  static bool _isChinese(ui.Locale locale) {
    final code = locale.languageCode.toLowerCase();
    return code == 'zh' || code.startsWith('zh-');
  }
}
