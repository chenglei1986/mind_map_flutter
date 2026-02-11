# API References

本文件基于当前导出入口 `lib/mind_map_flutter.dart` 整理，重点说明每个公开 API 的字段和方法用途。

## 导出入口

```dart
export 'src/models/models.dart';
export 'src/layout/layout.dart';
export 'src/rendering/rendering.dart';
export 'src/widgets/widgets.dart';
export 'src/interaction/interaction.dart';
export 'src/history/history.dart';
export 'src/i18n/i18n.dart';
```

说明：
- 仅覆盖通过上述入口可访问的公开 API。
- 标记为 `@visibleForTesting` 的成员通常只用于测试，不建议业务代码依赖。

## Models

### `enum LayoutDirection`
文件：`lib/src/models/layout_direction.dart`

字段说明：
- `left`：整棵图（根节点子树）向左布局。
- `right`：整棵图向右布局。
- `side`：左右两侧混合布局（默认）。

### `extension LayoutDirectionExtension on LayoutDirection`
文件：`lib/src/models/layout_direction.dart`

方法说明：
- `String toJson()`：把枚举值转换为可持久化字符串（`left/right/side`）。
- `static LayoutDirection fromJson(String? value)`：从字符串恢复枚举，非法值回退到 `side`。

### `class NodeData`
文件：`lib/src/models/node_data.dart`

构造说明：
- `const NodeData({...})`：手动构造节点对象，通常用于反序列化或高级场景。
- `factory NodeData.create({...})`：推荐创建入口；自动生成 UUID（若未传 `id`）。

静态方法说明：
- `static String generateId()`：生成节点唯一 ID。

字段说明：
- `id`：节点唯一标识。
- `topic`：节点文本内容。
- `style`：节点文字/背景/字号等样式。
- `children`：子节点列表。
- `tags`：标签列表。
- `icons`：图标（通常是 emoji）列表。
- `hyperLink`：节点超链接。
- `expanded`：是否展开子节点。
- `direction`：节点方向（主要用于 side 布局下的左右分配）。
- `image`：单图字段（兼容旧格式）。
- `images`：多图字段（推荐使用）。
- `branchColor`：分支连线颜色覆盖值。
- `note`：节点备注文本。

Getter 说明：
- `effectiveImages`：统一图片读取入口；优先 `images`，其次回退 `image`。

方法说明：
- `copyWith({...})`：创建带局部修改的新节点对象（不可变数据模式）。
- `addChild(NodeData child)`：追加一个子节点。
- `removeChild(String childId)`：按 ID 删除直接子节点。
- `updateChild(String childId, NodeData newChild)`：替换指定直接子节点。
- `toJson()`：序列化为 JSON map。
- `factory fromJson(Map<String, dynamic> json)`：从 JSON map 反序列化。

### `class NodeStyle`
文件：`lib/src/models/node_style.dart`

字段说明：
- `fontSize`：字号。
- `fontFamily`：字体族。
- `color`：文本颜色。
- `background`：背景色。
- `fontWeight`：字重。
- `width`：节点宽度覆盖值。
- `border`：边框（当前不参与 JSON 序列化）。
- `textDecoration`：文本装饰（下划线/删除线等）。

方法说明：
- `copyWith({...})`：返回局部变更后的样式副本。
- `toJson()`：样式序列化。
- `factory fromJson(Map<String, dynamic> json)`：样式反序列化。

### `class TagData`
文件：`lib/src/models/tag_data.dart`

字段说明：
- `text`：标签文本。
- `style`：标签文字样式（当前不参与 JSON 序列化）。
- `className`：标签语义分类名。

方法说明：
- `copyWith({...})`：返回局部变更后的标签副本。
- `toJson()`：标签序列化（当前输出 `text/className`）。
- `factory fromJson(Map<String, dynamic> json)`：标签反序列化。

### `class ImageData`
文件：`lib/src/models/image_data.dart`

字段说明：
- `url`：图片来源地址（网络、data URI、资源路径等）。
- `width`：显示宽度。
- `height`：显示高度。
- `fit`：适配模式（`BoxFit`）。

方法说明：
- `copyWith({...})`：返回局部变更后的图片配置副本。
- `toJson()`：图片配置序列化。
- `factory fromJson(Map<String, dynamic> json)`：图片配置反序列化。

### `class ArrowData`
文件：`lib/src/models/arrow_data.dart`

字段说明：
- `id`：箭头唯一 ID。
- `fromNodeId`：起点节点 ID。
- `toNodeId`：终点节点 ID。
- `label`：箭头标签文本。
- `delta1`：贝塞尔第一控制点偏移。
- `delta2`：贝塞尔第二控制点偏移。
- `bidirectional`：是否双向箭头。
- `style`：箭头样式覆盖。

方法说明：
- `factory ArrowData.create({...})`：创建箭头并自动生成 ID（可选）。
- `copyWith({...})`：返回局部变更后的箭头副本。
- `toJson()`：箭头序列化。
- `factory fromJson(Map<String, dynamic> json)`：箭头反序列化。

### `class ArrowStyle`
文件：`lib/src/models/arrow_style.dart`

字段说明：
- `strokeColor`：线条颜色。
- `strokeWidth`：线宽。
- `dashPattern`：虚线模式（如 `[8,4]`）。
- `opacity`：透明度。

方法说明：
- `copyWith({...})`：返回局部变更后的样式副本。
- `toJson()`：样式序列化。
- `factory fromJson(Map<String, dynamic> json)`：样式反序列化。

### `class SummaryData`
文件：`lib/src/models/summary_data.dart`

字段说明：
- `id`：摘要唯一 ID。
- `parentNodeId`：父节点 ID（被分组节点的共同父节点）。
- `startIndex`：分组起始子节点索引（闭区间）。
- `endIndex`：分组结束子节点索引（闭区间）。
- `label`：摘要文字。
- `style`：摘要样式。

方法说明：
- `factory SummaryData.create({...})`：创建摘要并自动生成 ID（可选）。
- `copyWith({...})`：返回局部变更后的摘要副本。
- `toJson()`：摘要序列化。
- `factory fromJson(Map<String, dynamic> json)`：摘要反序列化。

### `class SummaryStyle`
文件：`lib/src/models/summary_style.dart`

字段说明：
- `stroke`：摘要括线颜色。
- `labelColor`：摘要文字颜色。

方法说明：
- `copyWith({Color? stroke, Color? labelColor})`：返回局部变更后的样式副本。
- `toJson()`：样式序列化。
- `factory fromJson(Map<String, dynamic> json)`：样式反序列化。

### `class MindMapTheme`
文件：`lib/src/models/mind_map_theme.dart`

静态字段说明：
- `MindMapTheme.light`：内置浅色主题。
- `MindMapTheme.dark`：内置深色主题。

字段说明：
- `name`：主题名称。
- `palette`：调色板（分支颜色候选）。
- `variables`：主题变量集合（间距、颜色、圆角等）。

方法说明：
- `copyWith({...})`：返回局部变更后的主题副本。
- `toJson()`：主题序列化。
- `factory fromJson(Map<String, dynamic> json)`：主题反序列化。

### `class ThemeVariables`
文件：`lib/src/models/theme_variables.dart`

字段说明：
- 布局间距：`nodeGapX`, `nodeGapY`, `mainGapX`, `mainGapY`。
- 节点颜色：`mainColor`, `mainBgColor`, `color`, `bgColor`, `selectedColor`, `accentColor`。
- 根节点与圆角：`rootColor`, `rootBgColor`, `rootBorderColor`, `rootRadius`, `mainRadius`。
- 面板与内边距：`topicPadding`, `panelColor`, `panelBgColor`, `panelBorderColor`, `mapPadding`。

方法说明：
- `copyWith({...})`：返回局部变更后的变量副本。
- `toJson()`：主题变量序列化。
- `factory fromJson(Map<String, dynamic> json)`：主题变量反序列化。

### `class MindMapData`
文件：`lib/src/models/mind_map_data.dart`

字段说明：
- `nodeData`：根节点（包含整棵树）。
- `arrows`：箭头集合。
- `summaries`：摘要集合。
- `direction`：整体布局方向。
- `theme`：当前主题。

工厂说明：
- `factory MindMapData.empty({String rootTopic = '中心主题', MindMapTheme? theme})`：创建最小可用脑图数据。
- `factory MindMapData.fromJson(Map<String, dynamic> json)`：从 JSON 反序列化。

方法说明：
- `copyWith({...})`：返回局部变更后的数据副本。
- `toJson()`：完整数据序列化。

## Layout

### `class NodeLayout`
文件：`lib/src/layout/node_layout.dart`

字段说明：
- `position`：节点左上角坐标（画布坐标）。
- `size`：节点尺寸。

Getter 说明：
- `bounds`：由 `position + size` 计算得到的矩形边界。

### `class LayoutEngine`
文件：`lib/src/layout/layout_engine.dart`

常量说明：
- `maxWidthEm`：节点文本最大宽度（以 em 表示）用于换行控制。

方法说明：
- `calculateLayout(rootNode, theme, direction)`：根据树结构与主题计算所有节点的 `NodeLayout`。

## Rendering

### `class MindMapPainter extends CustomPainter`
文件：`lib/src/rendering/mind_map_painter.dart`

构造参数字段说明：
- `data`：绘制数据源。
- `nodeLayouts`：每个节点的布局信息。
- `selectedNodeIds`：选中节点集合。
- `transform`：当前画布变换矩阵（缩放/平移）。
- `selectionRect`：框选矩形（屏幕坐标）。
- `draggedNodeId`：拖拽中的节点 ID。
- `dragPosition`：拖拽光标位置。
- `dropTargetNodeId`：当前拖拽目标节点 ID。
- `dropInsertType`：拖拽插入模式（`before/after/in`）。
- `selectedArrowId`：当前选中箭头 ID。
- `selectedSummaryId`：当前选中摘要 ID。
- `arrowSourceNodeId`：箭头创建模式下的源节点 ID。
- `isFocusMode`：是否处于聚焦模式。
- `focusedNodeId`：聚焦节点 ID。
- `hoveredExpandNodeId`：悬停的展开按钮所属节点 ID。
- `strings`：本地化文案。
- `imageCache`：已解码图片缓存。

重写方法说明：
- `paint(Canvas canvas, Size size)`：按顺序绘制分支、节点、箭头、摘要及交互反馈。
- `shouldRepaint(MindMapPainter oldDelegate)`：判断是否需要重绘。
- `shouldRebuildSemantics(MindMapPainter oldDelegate)`：判断是否需要重建语义树。

### `class NodeRenderer`
文件：`lib/src/rendering/node_renderer.dart`

公开静态方法说明：
- `drawNode(...)`：绘制单个节点（含文本、图标、标签、图片、展开按钮等）。
- `getExpandIndicatorBounds(...)`：返回展开/折叠按钮点击区域。
- `getHyperlinkIndicatorBounds(...)`：返回超链接指示器点击区域。
- `measureNodeSize(...)`：按主题与文本计算节点实际尺寸。

### `class BranchRenderer`
文件：`lib/src/rendering/branch_renderer.dart`

公开静态方法说明：
- `drawBranch(...)`：绘制单条父子连线（曲线样式）。
- `drawNodeBranches(...)`：递归绘制整棵树分支。
- `drawStraightBranch(...)`：绘制直线分支（替代样式）。

### `class ArrowRenderer`
文件：`lib/src/rendering/arrow_renderer.dart`

公开静态方法说明：
- `drawArrow(...)`：绘制一条箭头（曲线 + 箭头头 + 可选标签）。
- `drawSelectedArrowHighlight(...)`：绘制选中箭头高亮。
- `getArrowLabelBounds(...)`：返回箭头标签边界框。
- `drawAllArrows(...)`：批量绘制全部箭头并处理选中态。
- `drawControlPoints(...)`：绘制控制点（编辑状态）。
- `getArrowBounds(...)`：返回箭头大致命中区域。
- `getControlPointBounds(...)`：返回控制点命中区域。

### `class SummaryRenderer`
文件：`lib/src/rendering/summary_renderer.dart`

公开静态方法说明：
- `drawSummary(...)`：绘制单个摘要括线与标签。
- `drawAllSummaries(...)`：批量绘制摘要。
- `getSummaryBounds(...)`：返回摘要整体命中区域。
- `getSummaryLabelBounds(...)`：返回摘要标签边界（用于编辑框定位）。

## Widgets

### `class MindMapConfig`
文件：`lib/src/widgets/mind_map_config.dart`

字段说明：
- `allowUndo`：是否启用撤销/重做。
- `maxHistorySize`：历史栈最大长度。
- `minScale`：最小缩放比。
- `maxScale`：最大缩放比。
- `enableKeyboardShortcuts`：是否启用快捷键。
- `enableContextMenu`：是否启用右键菜单。
- `enableDragDrop`：是否启用节点拖拽。
- `readOnly`：只读模式开关。
- `locale`：内置文案语言策略。

方法说明：
- `copyWith({...})`：返回局部变更后的配置副本。

### `class ContextMenuItem`
文件：`lib/src/widgets/context_menu.dart`

字段说明：
- `label`：菜单项文字。
- `icon`：菜单项图标。
- `onTap`：点击回调。
- `enabled`：是否可点击。
- `showDivider`：该项后是否显示分隔线。

### `class ContextMenuPopup extends StatelessWidget`
文件：`lib/src/widgets/context_menu.dart`

字段说明：
- `position`：菜单锚点位置。
- `items`：菜单项列表。
- `onDismiss`：菜单关闭回调。
- `backgroundColor`：菜单背景色。
- `textColor`：菜单文字色。
- `iconColor`：菜单图标色。
- `hoverColor`：悬停背景色。
- `dividerColor`：分割线颜色。

### `typedef ContextMenuItemBuilder`
文件：`lib/src/widgets/context_menu.dart`

```dart
typedef ContextMenuItemBuilder = List<ContextMenuItem> Function(String nodeId);
```

说明：
- 根据当前节点 ID 返回自定义菜单项列表。

### `class DefaultContextMenuItems`
文件：`lib/src/widgets/context_menu.dart`

方法说明：
- `static List<ContextMenuItem> build({...})`：生成内置右键菜单（增删改、箭头、摘要、聚焦、图片/链接等）。

### `class MindMapWidget extends StatefulWidget`
文件：`lib/src/widgets/mind_map_widget.dart`

字段说明：
- `initialData`：初始脑图数据。
- `config`：组件配置。
- `onEvent`：事件回调。
- `controller`：外部传入控制器（可选）。

方法说明：
- `createState()`：创建 `MindMapState`。

### `class MindMapState extends State<MindMapWidget>`
文件：`lib/src/widgets/mind_map_widget.dart`

公开成员说明（主要用于测试/扩展）：
- `nodeLayouts`（`@visibleForTesting`）：当前布局映射。
- `transform`（`@visibleForTesting`）：当前变换矩阵。
- `dragManager`（`@visibleForTesting`）：内部拖拽管理器。
- `repaintBoundaryKey`：导出 PNG 用绘制边界 key。
- `setCustomContextMenuBuilder(ContextMenuItemBuilder? builder)`：设置自定义右键菜单构建器。
- `@visibleForTesting static bool shouldWrapEditText({...})`：判断编辑态文本是否应换行。

### 事件模型（`mind_map_widget.dart`）

#### `abstract class MindMapEvent`
说明：所有脑图事件基类。

#### `class SelectNodesEvent extends MindMapEvent`
- 字段 `nodeIds`：当前选中节点 ID 列表。

#### `class MoveNodeEvent extends MindMapEvent`
- 字段 `nodeId`：被移动节点 ID。
- 字段 `oldParentId`：原父节点 ID。
- 字段 `newParentId`：新父节点 ID。
- 字段 `isReorder`：是否同父节点重排。

#### `class ExpandNodeEvent extends MindMapEvent`
- 字段 `nodeId`：目标节点 ID。
- 字段 `expanded`：展开状态。

#### `class BeginEditEvent extends MindMapEvent`
- 字段 `nodeId`：进入编辑的节点 ID。

#### `class FinishEditEvent extends MindMapEvent`
- 字段 `nodeId`：完成编辑的节点 ID。
- 字段 `newTopic`：编辑后的文本。

#### `class HyperlinkClickEvent extends MindMapEvent`
- 字段 `nodeId`：被点击链接所在节点 ID。
- 字段 `url`：点击的 URL。

#### `class NodeOperationEvent extends MindMapEvent`
- 字段 `operation`：操作名。
- 字段 `nodeId`：目标节点 ID。

#### `class ArrowCreatedEvent extends MindMapEvent`
- 字段 `arrowId`：箭头 ID。
- 字段 `fromNodeId`：源节点 ID。
- 字段 `toNodeId`：目标节点 ID。

#### `class SummaryCreatedEvent extends MindMapEvent`
- 字段 `summaryId`：摘要 ID。
- 字段 `parentNodeId`：摘要父节点 ID。

### `class RootNodeDeletionException implements Exception`
文件：`lib/src/widgets/mind_map_controller.dart`

字段说明：
- `message`：错误描述。

### `class InvalidNodeIdException implements Exception`
文件：`lib/src/widgets/mind_map_controller.dart`

字段说明：
- `message`：错误描述。

### `class MindMapController extends ChangeNotifier`
文件：`lib/src/widgets/mind_map_controller.dart`

构造说明：
- `MindMapController({required MindMapData initialData, MindMapConfig config = const MindMapConfig()})`：创建控制器并初始化选择、历史、缩放管理器。

Getter 说明：
- `repaintBoundaryKey`：当前导出边界 key。
- `eventStream`：事件流。
- `isArrowCreationMode`：是否在箭头创建模式。
- `arrowSourceNodeId`：箭头源节点 ID。
- `selectedArrowId`：当前选中箭头 ID。
- `isSummaryCreationMode`：是否在摘要创建模式。
- `summarySelectedNodeIds`：摘要创建阶段临时选中节点列表。
- `selectedSummaryId`：当前选中摘要 ID。
- `isFocusMode`：是否在聚焦模式。
- `focusedNodeId`：当前聚焦节点 ID。
- `localizedStrings`：按配置解析后的文案对象。
- `defaultNewNodeTopic`：默认新节点文本。
- `defaultSummaryLabel`：默认摘要文本。
- `lastEvent`：最后一次发出的事件对象。
- `selectionManager`：内部选择管理器。
- `zoomPanManager`：内部缩放平移管理器。

核心方法说明：

数据与配置：
- `MindMapData getData()`：获取当前完整数据。
- `void updateConfig(MindMapConfig config)`：更新控制器配置并通知刷新。
- `void refresh(MindMapData data)`：替换整份数据并清空选择/历史。
- `void emitEvent(MindMapEvent event)`：向 `onEvent`/`eventStream` 广播事件。
- `void setViewportSize(Size size)`：同步视口尺寸，供居中/自适应计算。
- `List<String> getSelectedNodeIds()`：获取当前选中节点 ID 列表。

节点操作：
- `addChildNode(...)`：在指定父节点下新增子节点。
- `addSiblingNode(...)`：在指定节点后新增同级节点。
- `removeNode(...)`：删除节点（不允许根节点）。
- `updateNode(...)`：按 ID 替换节点对象。
- `updateNodeTopic(...)`：直接更新节点文本。
- `commitNodeTopicEdit(...)`：提交编辑文本并记录历史。
- `toggleNodeExpanded(...)`：切换展开/折叠。
- `expandNode(...)`：强制展开。
- `collapseNode(...)`：强制折叠。
- `moveNodes(...)`：批量移动节点到新父节点或新位置。
- `moveNode(...)`：移动单个节点。
- `addParentNode(...)`：在节点上方插入父节点。

历史：
- `undo()`：撤销上一步操作。
- `redo()`：重做上一步撤销。
- `canUndo()`：当前是否可撤销。
- `canRedo()`：当前是否可重做。

箭头：
- `startArrowCreationMode()`：进入箭头创建模式。
- `exitArrowCreationMode()`：退出箭头创建模式。
- `selectArrowSourceNode(...)`：设置箭头源节点。
- `selectArrowTargetNode(...)`：选择目标节点并创建箭头。
- `addArrow({...})`：直接新增箭头（可自定义样式和控制点）。
- `removeArrow(...)`：删除箭头。
- `updateArrow(...)`：更新箭头对象。
- `updateArrowControlPoints(...)`：更新箭头两个控制点偏移。
- `selectArrow(...)`：选中箭头。
- `deselectArrow()`：取消箭头选中。
- `getArrow(...)`：按 ID 查询箭头。

摘要：
- `startSummaryCreationMode()`：进入摘要创建模式。
- `exitSummaryCreationMode()`：退出摘要创建模式。
- `toggleSummaryNodeSelection(...)`：切换摘要创建过程中的节点选择。
- `createSummaryFromSelection(...)`：按当前临时选择创建摘要。
- `addSummary({...})`：直接新增摘要。
- `removeSummary(...)`：删除摘要。
- `updateSummary(...)`：更新摘要对象。
- `getSummary(...)`：按 ID 查询摘要。
- `selectSummary(...)`：选中摘要。
- `deselectSummary()`：取消摘要选中。

主题与视图：
- `setTheme(...)`：切换主题。
- `getTheme()`：获取当前主题。
- `centerView(...)`：按当前缩放居中整图。
- `fitToView(...)`：缩放并居中到可见区域。
- `centerViewWhenReady()`：在视口可用时执行首次自适应/居中。
- `setZoom(...)`：设置缩放比（可动画）。
- `getZoom()`：读取当前缩放比。
- `setLayoutDirection(...)`：切换整体布局方向。
- `getLayoutDirection()`：读取当前布局方向。
- `centerOnNode(...)`：将指定节点居中到视口。

复制粘贴与聚焦：
- `copyNode(...)`：复制节点子树到控制器剪贴板。
- `pasteNode(...)`：将剪贴板节点粘贴为指定父节点子节点。
- `focusNode(...)`：进入节点聚焦模式（只显示该节点子树）。
- `exitFocusMode()`：退出聚焦模式。

节点样式与附加信息：
- `setNodeFontSize(...)`：设置节点字号。
- `setNodeColor(...)`：设置节点文字颜色。
- `setNodeBackground(...)`：设置节点背景色。
- `setNodeFontWeight(...)`：设置节点字重。
- `addNodeTag(...)`：添加标签。
- `removeNodeTag(...)`：删除标签。
- `addNodeIcon(...)`：添加图标。
- `removeNodeIcon(...)`：删除图标。
- `setNodeHyperLink(...)`：设置或清除超链接。
- `setNodeImage(...)`：设置单图（并同步 `images`）。
- `addNodeImage(...)`：追加一张图片到 `images`。
- `clearNodeImages(...)`：清空节点图片。

导出：
- `exportToJson()`：导出为格式化 JSON 字符串。
- `exportToPng({...})`：导出为 PNG 字节（支持尺寸/像素比）。
- `setRepaintBoundaryKey(...)`：注入导出截图边界 key。
- `setExportImageCache(...)`：注入已解码图片缓存供离屏导出使用。

Widget 协调回调（由 `MindMapWidget` 注入）：
- `setNodePositionCallback(...)`：提供节点屏幕坐标查询回调。
- `setViewCompensationCallback(...)`：提供布局变更后的视图漂移补偿回调。

## Interaction

### `class SelectionManager extends ChangeNotifier`
文件：`lib/src/interaction/selection_manager.dart`

Getter 说明：
- `selectedNodeIds`：只读选中节点列表。
- `hasClipboardContent`：剪贴板是否有节点。

方法说明：
- `isSelected(...)`：判断节点是否已选中。
- `copyToClipboard(...)`：把节点放入剪贴板。
- `getFromClipboard()`：读取剪贴板节点。
- `selectNode(...)`：单选（清空旧选择）。
- `addToSelection(...)`：追加到选择集。
- `removeFromSelection(...)`：从选择集中移除。
- `toggleSelection(...)`：切换选中状态。
- `selectNodes(...)`：一次性设置多选结果。
- `clearSelection()`：清空选择。
- `dispose()`：释放内部状态。

### `class ZoomPanManager extends ChangeNotifier`
文件：`lib/src/interaction/zoom_pan_manager.dart`

字段/Getter 说明：
- `minScale` / `maxScale`：缩放上下限。
- `transform`：当前变换矩阵。
- `scale`：当前缩放比。
- `translation`：当前平移偏移。

方法说明：
- `handlePanStart(...)`：开始平移手势。
- `handlePanUpdate(...)`：更新平移。
- `handlePanEnd()`：结束平移手势。
- `handleScaleStart(...)`：开始缩放手势。
- `handleScaleUpdate(...)`：更新缩放手势。
- `handleScaleEnd(...)`：结束缩放手势。
- `handleMouseWheel(...)`：处理滚轮缩放。
- `setZoom(...)`：程序化设置缩放。
- `setTranslation(...)`：程序化设置平移。
- `centerOn(...)`：将某画布点移动到视口中心。
- `reset()`：重置为默认视图。

### `class DragManager extends ChangeNotifier`
文件：`lib/src/interaction/drag_manager.dart`

Getter 说明：
- `isDragging`：是否在拖拽中。
- `draggedNodeId`：当前拖拽节点 ID。
- `dragPosition`：当前拖拽位置。
- `dropTargetNodeId`：当前命中的落点节点 ID。
- `dropInsertType`：当前插入类型（`before/after/in`）。

方法说明：
- `startDrag(...)`：开始拖拽。
- `updateDrag(...)`：更新拖拽位置并实时计算落点。
- `resolveDropTargetNow(...)`：立即重新计算落点（用于松手前纠正）。
- `endDrag()`：结束拖拽并返回最终落点节点 ID。
- `cancelDrag()`：取消拖拽。
- `dispose()`：释放内部状态。

### `class KeyboardHandler`
文件：`lib/src/interaction/keyboard_handler.dart`

字段说明：
- `controller`：目标控制器。
- `onCenterView`：可选的“居中”回调覆盖。
- `onBeginEdit`：可选的“开始编辑”回调覆盖。

方法说明：
- `handleKeyEvent(KeyEvent event)`：处理快捷键并返回是否已消费。
- `clearClipboard()`：清空内部复制缓存。

### `class GestureHandler`
文件：`lib/src/interaction/gesture_handler.dart`

字段说明：
- `controller`：目标控制器。
- `nodeLayouts`：当前布局映射。
- `transform`：当前变换矩阵。
- `isReadOnly`：只读模式开关。
- `onBeginEdit`：节点双击编辑回调。
- `onBeginEditSummary`：摘要双击编辑回调。
- `onBeginEditArrow`：箭头双击编辑回调。
- `onSelectionRectChanged`：框选矩形变化回调。
- `onShowContextMenu`：请求显示右键菜单回调。
- `onTapEmptySpace`：空白点击回调。
- `dragManager`：节点拖拽状态管理器。

Getter 说明：
- `selectionRect`：当前框选矩形。

方法说明：
- `updateContext(...)`：更新布局、变换、只读状态。
- `handleTapDown(...)`：处理点击按下事件。
- `handleTapUp(...)`：处理点击抬起（选择/双击/链接/箭头/摘要等）。
- `handleLongPress(...)`：处理长按（通常弹菜单）。
- `handleSecondaryTapUp(...)`：处理右键点击。
- `handlePanStart(...)`：处理拖拽起始。
- `handleScaleStart(...)`：处理缩放/单指拖动起始。
- `handlePanUpdate(...)`：处理拖拽更新。
- `handleScaleUpdate(...)`：处理缩放/拖动更新。
- `handlePanEnd(...)`：处理拖拽结束。
- `handleScaleEnd(...)`：处理缩放结束。
- `hitTestNode(...)`：命中节点检测。
- `hitTestExpandIndicator(...)`：命中展开按钮检测。
- `hitTestHyperlinkIndicator(...)`：命中链接指示器检测。
- `hitTestSummary(...)`：命中摘要检测。
- `hitTestArrow(...)`：命中箭头检测。
- `hitTestArrowControlPoint(...)`：命中箭头控制点检测。

## History

### `abstract class Operation`
文件：`lib/src/history/operation.dart`

方法说明：
- `execute(...)`：执行操作并返回新数据。
- `undo(...)`：回滚操作并返回新数据。
- `description`：操作描述（调试/日志用）。

### `class HistoryManager`
文件：`lib/src/history/history_manager.dart`

字段/Getter 说明：
- `maxHistorySize`：历史容量上限（`<=0` 表示不限制）。
- `canUndo`：是否可撤销。
- `canRedo`：是否可重做。
- `undoCount`：撤销栈数量。
- `redoCount`：重做栈数量。

方法说明：
- `recordOperation(...)`：记录操作并清空重做栈。
- `undo()`：弹出最近操作进入重做栈。
- `redo()`：弹出最近重做进入撤销栈。
- `clear()`：清空历史。

### `class HistoryEntry`
文件：`lib/src/history/history_manager.dart`

字段说明：
- `operation`：对应的历史操作对象。
- `selectionBefore`：操作前选择状态。
- `selectionAfter`：操作后选择状态。

### `class CreateNodeOperation implements Operation`
文件：`lib/src/history/operations.dart`

字段说明：
- `parentId`：父节点 ID。
- `newNode`：新建节点。
- `insertIndex`：插入索引（可选）。
- `parentWasCollapsed`：操作前父节点是否折叠。

方法说明：
- `execute(...)`：执行创建。
- `undo(...)`：撤销创建。
- `description`：操作文本说明。

### `class InsertParentOperation implements Operation`
文件：`lib/src/history/operations.dart`

字段说明：
- `nodeId`：目标节点 ID。
- `oldParentId`：原父节点 ID。
- `oldIndex`：原索引。
- `newParent`：插入的新父节点。

方法说明：
- `execute(...)`：执行插入父节点。
- `undo(...)`：还原原结构。
- `description`：操作文本说明。

### `class DeleteNodeOperation implements Operation`
文件：`lib/src/history/operations.dart`

字段说明：
- `nodeId`：删除节点 ID。
- `parentId`：原父节点 ID。
- `deletedNode`：被删除节点快照。
- `originalIndex`：原索引。

方法说明：
- `execute(...)`：执行删除。
- `undo(...)`：恢复节点。
- `description`：操作文本说明。

### `class EditNodeOperation implements Operation`
文件：`lib/src/history/operations.dart`

字段说明：
- `nodeId`：编辑节点 ID。
- `oldTopic`：原文本。
- `newTopic`：新文本。

方法说明：
- `execute(...)`：应用新文本。
- `undo(...)`：恢复旧文本。
- `description`：操作文本说明。

### `class MoveNodeOperation implements Operation`
文件：`lib/src/history/operations.dart`

字段说明：
- `nodeId`：移动节点 ID。
- `oldParentId`：原父节点 ID。
- `newParentId`：新父节点 ID。
- `oldIndex`：原索引。
- `newIndex`：新索引。
- `movedNode`：被移动节点快照。
- `targetWasCollapsed`：目标父节点原折叠状态。

方法说明：
- `execute(...)`：执行移动。
- `undo(...)`：逆向恢复。
- `description`：操作文本说明。

### `class StyleNodeOperation implements Operation`
文件：`lib/src/history/operations.dart`

字段说明：
- `nodeId`：目标节点 ID。
- `oldStyle`：旧样式。
- `newStyle`：新样式。

方法说明：
- `execute(...)`：应用新样式。
- `undo(...)`：恢复旧样式。
- `description`：操作文本说明。

### `class ToggleExpandOperation implements Operation`
文件：`lib/src/history/operations.dart`

字段说明：
- `nodeId`：目标节点 ID。
- `oldExpanded`：旧展开状态。
- `newExpanded`：新展开状态。

方法说明：
- `execute(...)`：应用新展开状态。
- `undo(...)`：恢复旧展开状态。
- `description`：操作文本说明。

## I18n

### `enum MindMapLocale`
文件：`lib/src/i18n/mind_map_strings.dart`

字段说明：
- `auto`：自动按系统语言选择。
- `zh`：强制中文。
- `en`：强制英文。

### `class MindMapStrings`
文件：`lib/src/i18n/mind_map_strings.dart`

字段说明：
- 菜单类字段（`menu*`）：上下文菜单各项文案。
- 操作类字段（`action*`）：确认/取消等按钮文案。
- 对话框类字段（`dialogTitle*`, `field*`）：图片、链接、标签、图标输入文案。
- 聚焦类字段（`focusMode*`）：聚焦模式标题与提示。
- 默认值字段（`default*`）：新建节点/摘要等默认文本。
- 错误字段（`error*`）：异常和提示文案模板。

静态成员说明：
- `MindMapStrings.zh`：中文文案集合。
- `MindMapStrings.en`：英文文案集合。
- `resolve(...)`：按 `MindMapLocale` + 系统语言返回实际文案对象。

格式化方法说明：
- `focusModeTitle(nodeTitle)`：生成“聚焦模式: xxx”标题。
- `errorInvalidNodeId(nodeId)`：填充节点 ID 的错误文案。
- `errorCannotFindParentOfNode(nodeId)`：填充找不到父节点错误文案。
- `errorFailedToCreateSummary(error)`：填充创建摘要失败文案。
- `errorArrowNotFound(arrowId)`：填充箭头不存在文案。
- `errorSummaryNotFound(summaryId)`：填充摘要不存在文案。
- `errorNodeNotFound(nodeId)`：填充节点不存在文案。
- `errorInvalidChildRange(start, end)`：填充子节点索引区间错误文案。

## 维护建议

- 每次新增/删除 `lib/mind_map_flutter.dart` 的导出项后，同步更新本文件。
- 低层渲染与交互类（`*Renderer`, `GestureHandler` 等）变动频繁，发布前建议二次核对签名。
