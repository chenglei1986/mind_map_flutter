# API References

This document lists the public API exported by `lib/mind_map_flutter.dart`, with field and method explanations.

## Export Surface

```dart
export 'src/models/models.dart';
export 'src/layout/layout.dart';
export 'src/rendering/rendering.dart';
export 'src/widgets/widgets.dart';
export 'src/interaction/interaction.dart';
export 'src/history/history.dart';
export 'src/i18n/i18n.dart';
```

Notes:
- Only publicly exported APIs are covered.
- Members marked `@visibleForTesting` are primarily for tests and internal diagnostics.

## Models

### `enum LayoutDirection`
File: `lib/src/models/layout_direction.dart`

- `left`: Place branches on the left side.
- `right`: Place branches on the right side.
- `side`: Split branches to both sides (default).

### `extension LayoutDirectionExtension on LayoutDirection`
File: `lib/src/models/layout_direction.dart`

- `String toJson()`: Converts enum to persisted string (`left/right/side`).
- `static LayoutDirection fromJson(String? value)`: Parses persisted string, defaults to `side`.

### `class NodeData`
File: `lib/src/models/node_data.dart`

Constructors:
- `const NodeData({...})`: Manual immutable node construction.
- `factory NodeData.create({...})`: Recommended constructor with auto UUID generation.

Static:
- `static String generateId()`: Generates a UUID for node identity.

Fields:
- `id`: Unique node identifier.
- `topic`: Node text content.
- `style`: Text/background/layout style overrides.
- `children`: Child node list.
- `tags`: Tag list rendered with the node.
- `icons`: Icon/emoji list rendered inline.
- `hyperLink`: External link associated with the node.
- `expanded`: Expand/collapse state for children.
- `direction`: Optional per-node direction hint.
- `image`: Legacy single-image field.
- `images`: Preferred multi-image field.
- `branchColor`: Per-branch color override.
- `note`: Extended note text.

Getter:
- `effectiveImages`: Normalized image list, preferring `images` and falling back to `image`.

Methods:
- `copyWith({...})`: Returns a new instance with selected updates.
- `addChild(NodeData child)`: Appends one child.
- `removeChild(String childId)`: Removes a direct child by ID.
- `updateChild(String childId, NodeData newChild)`: Replaces a direct child by ID.
- `toJson()`: Serializes node to JSON map.
- `factory fromJson(Map<String, dynamic> json)`: Deserializes node from JSON map.

### `class NodeStyle`
File: `lib/src/models/node_style.dart`

Fields:
- `fontSize`: Text font size.
- `fontFamily`: Text font family.
- `color`: Text color.
- `background`: Background color.
- `fontWeight`: Text weight.
- `width`: Optional explicit node width.
- `border`: Optional border style (not currently serialized).
- `textDecoration`: Decoration such as underline/line-through.

Methods:
- `copyWith({...})`: Returns updated style instance.
- `toJson()`: Serializes style to JSON map.
- `factory fromJson(Map<String, dynamic> json)`: Deserializes style.

### `class TagData`
File: `lib/src/models/tag_data.dart`

Fields:
- `text`: Tag text.
- `style`: Optional tag text style (not currently serialized).
- `className`: Optional semantic class name.

Methods:
- `copyWith({...})`: Returns updated tag instance.
- `toJson()`: Serializes tag (`text` and `className`).
- `factory fromJson(Map<String, dynamic> json)`: Deserializes tag.

### `class ImageData`
File: `lib/src/models/image_data.dart`

Fields:
- `url`: Image source.
- `width`: Render width.
- `height`: Render height.
- `fit`: Box fit mode.

Methods:
- `copyWith({...})`: Returns updated image config.
- `toJson()`: Serializes image config.
- `factory fromJson(Map<String, dynamic> json)`: Deserializes image config.

### `class ArrowData`
File: `lib/src/models/arrow_data.dart`

Fields:
- `id`: Unique arrow ID.
- `fromNodeId`: Source node ID.
- `toNodeId`: Target node ID.
- `label`: Optional arrow label.
- `delta1`: First bezier control-point delta.
- `delta2`: Second bezier control-point delta.
- `bidirectional`: Whether arrow heads are drawn at both ends.
- `style`: Optional arrow style overrides.

Methods:
- `factory ArrowData.create({...})`: Creates arrow with optional auto ID.
- `copyWith({...})`: Returns updated arrow instance.
- `toJson()`: Serializes arrow.
- `factory fromJson(Map<String, dynamic> json)`: Deserializes arrow.

### `class ArrowStyle`
File: `lib/src/models/arrow_style.dart`

Fields:
- `strokeColor`: Line color.
- `strokeWidth`: Line width.
- `dashPattern`: Dash pattern.
- `opacity`: Opacity.

Methods:
- `copyWith({...})`: Returns updated style instance.
- `toJson()`: Serializes style.
- `factory fromJson(Map<String, dynamic> json)`: Deserializes style.

### `class SummaryData`
File: `lib/src/models/summary_data.dart`

Fields:
- `id`: Unique summary ID.
- `parentNodeId`: Parent node ID of grouped siblings.
- `startIndex`: Start child index (inclusive).
- `endIndex`: End child index (inclusive).
- `label`: Summary label.
- `style`: Optional summary style.

Methods:
- `factory SummaryData.create({...})`: Creates summary with optional auto ID.
- `copyWith({...})`: Returns updated summary instance.
- `toJson()`: Serializes summary.
- `factory fromJson(Map<String, dynamic> json)`: Deserializes summary.

### `class SummaryStyle`
File: `lib/src/models/summary_style.dart`

Fields:
- `stroke`: Bracket line color.
- `labelColor`: Label text color.

Methods:
- `copyWith({Color? stroke, Color? labelColor})`: Returns updated style.
- `toJson()`: Serializes style.
- `factory fromJson(Map<String, dynamic> json)`: Deserializes style.

### `class MindMapTheme`
File: `lib/src/models/mind_map_theme.dart`

Static presets:
- `MindMapTheme.light`: Built-in light theme.
- `MindMapTheme.dark`: Built-in dark theme.

Fields:
- `name`: Theme name.
- `palette`: Branch color palette.
- `variables`: Detailed theme variables.

Methods:
- `copyWith({...})`: Returns updated theme instance.
- `toJson()`: Serializes theme.
- `factory fromJson(Map<String, dynamic> json)`: Deserializes theme.

### `class ThemeVariables`
File: `lib/src/models/theme_variables.dart`

Fields:
- `nodeGapX`, `nodeGapY`, `mainGapX`, `mainGapY`: Core spacing controls.
- `mainColor`, `mainBgColor`, `color`, `bgColor`, `selectedColor`, `accentColor`: Core colors.
- `rootColor`, `rootBgColor`, `rootBorderColor`, `rootRadius`, `mainRadius`: Root and radius settings.
- `topicPadding`, `panelColor`, `panelBgColor`, `panelBorderColor`, `mapPadding`: Padding and panel visuals.

Methods:
- `copyWith({...})`: Returns updated variable set.
- `toJson()`: Serializes variables.
- `factory fromJson(Map<String, dynamic> json)`: Deserializes variables.

### `class MindMapData`
File: `lib/src/models/mind_map_data.dart`

Fields:
- `nodeData`: Root node tree.
- `arrows`: Arrow collection.
- `summaries`: Summary collection.
- `direction`: Global layout direction.
- `theme`: Current theme.

Factories:
- `MindMapData.empty(...)`: Creates minimum usable map data.
- `MindMapData.fromJson(...)`: Deserializes full data.

Methods:
- `copyWith({...})`: Returns updated data object.
- `toJson()`: Serializes full map data.

## Layout

### `class NodeLayout`
File: `lib/src/layout/node_layout.dart`

Fields:
- `position`: Top-left canvas position.
- `size`: Node width and height.

Getter:
- `bounds`: `Rect` computed from `position` and `size`.

### `class LayoutEngine`
File: `lib/src/layout/layout_engine.dart`

Constant:
- `maxWidthEm`: Maximum text width in em units for wrapping behavior.

Method:
- `calculateLayout(...)`: Computes `NodeLayout` for all visible nodes.

## Rendering

### `class MindMapPainter extends CustomPainter`
File: `lib/src/rendering/mind_map_painter.dart`

Constructor data:
- `data`, `nodeLayouts`, `selectedNodeIds`, `transform`, `selectionRect`, `draggedNodeId`, `dragPosition`, `dropTargetNodeId`, `dropInsertType`, `selectedArrowId`, `selectedSummaryId`, `arrowSourceNodeId`, `isFocusMode`, `focusedNodeId`, `hoveredExpandNodeId`, `strings`, `imageCache`.

Methods:
- `paint(...)`: Draws branches, nodes, arrows, summaries, and interaction overlays.
- `shouldRepaint(...)`: Returns whether repaint is needed.
- `shouldRebuildSemantics(...)`: Returns whether semantics tree should rebuild.

### `class NodeRenderer`
File: `lib/src/rendering/node_renderer.dart`

Static methods:
- `drawNode(...)`: Draws a node with all visual elements.
- `getExpandIndicatorBounds(...)`: Returns expand/collapse indicator hit bounds.
- `getHyperlinkIndicatorBounds(...)`: Returns hyperlink indicator hit bounds.
- `measureNodeSize(...)`: Measures node size using text and style.

### `class BranchRenderer`
File: `lib/src/rendering/branch_renderer.dart`

Static methods:
- `drawBranch(...)`: Draws one parent-child branch curve.
- `drawNodeBranches(...)`: Recursively draws all branches.
- `drawStraightBranch(...)`: Draws alternative straight branch line.

### `class ArrowRenderer`
File: `lib/src/rendering/arrow_renderer.dart`

Static methods:
- `drawArrow(...)`: Draws a single arrow.
- `drawSelectedArrowHighlight(...)`: Draws selected arrow highlight.
- `getArrowLabelBounds(...)`: Returns arrow label bounds.
- `drawAllArrows(...)`: Draws all arrows and selected state.
- `drawControlPoints(...)`: Draws editable control handles.
- `getArrowBounds(...)`: Returns approximate arrow hit bounds.
- `getControlPointBounds(...)`: Returns control-point hit bounds.

### `class SummaryRenderer`
File: `lib/src/rendering/summary_renderer.dart`

Static methods:
- `drawSummary(...)`: Draws one summary bracket and label.
- `drawAllSummaries(...)`: Draws all summaries.
- `getSummaryBounds(...)`: Returns summary hit bounds.
- `getSummaryLabelBounds(...)`: Returns summary label bounds (used by edit overlay).

## Widgets

### `class MindMapConfig`
File: `lib/src/widgets/mind_map_config.dart`

Fields:
- `allowUndo`: Enables undo/redo history recording.
- `maxHistorySize`: Maximum history size.
- `minScale`: Minimum zoom.
- `maxScale`: Maximum zoom.
- `enableKeyboardShortcuts`: Enables built-in keyboard shortcuts.
- `enableContextMenu`: Enables context menu.
- `enableDragDrop`: Enables node drag-drop behavior.
- `readOnly`: Enables read-only interactions only.
- `locale`: Built-in locale selection.

Method:
- `copyWith({...})`: Returns updated config.

### `class ContextMenuItem`
File: `lib/src/widgets/context_menu.dart`

Fields:
- `label`: Menu text.
- `icon`: Menu icon.
- `onTap`: Click action.
- `enabled`: Disabled state control.
- `showDivider`: Whether to draw divider after the item.

### `class ContextMenuPopup extends StatelessWidget`
File: `lib/src/widgets/context_menu.dart`

Fields:
- `position`: Popup anchor position.
- `items`: Item list.
- `onDismiss`: Outside-tap close callback.
- `backgroundColor`, `textColor`, `iconColor`, `hoverColor`, `dividerColor`: Visual style settings.

### `typedef ContextMenuItemBuilder`
File: `lib/src/widgets/context_menu.dart`

```dart
typedef ContextMenuItemBuilder = List<ContextMenuItem> Function(String nodeId);
```

Meaning:
- Builds custom context menu items for a node ID.

### `class DefaultContextMenuItems`
File: `lib/src/widgets/context_menu.dart`

Method:
- `build({...})`: Produces the library's default context menu entries.

### `class MindMapWidget extends StatefulWidget`
File: `lib/src/widgets/mind_map_widget.dart`

Fields:
- `initialData`: Initial map data.
- `config`: Runtime behavior config.
- `onEvent`: Event callback.
- `controller`: Optional external controller.

Method:
- `createState()`: Creates `MindMapState`.

### `class MindMapState extends State<MindMapWidget>`
File: `lib/src/widgets/mind_map_widget.dart`

Public members:
- `nodeLayouts` (`@visibleForTesting`): Current layout map for tests.
- `transform` (`@visibleForTesting`): Current matrix transform for tests.
- `dragManager` (`@visibleForTesting`): Internal drag manager for tests.
- `repaintBoundaryKey`: Repaint boundary key used for PNG export.
- `setCustomContextMenuBuilder(...)`: Sets custom context menu builder.
- `shouldWrapEditText(...)` (`@visibleForTesting`): Utility to detect wrapping behavior in edit overlays.

### Event Types (`mind_map_widget.dart`)

#### `abstract class MindMapEvent`
- Base type for all map events.

#### `class SelectNodesEvent extends MindMapEvent`
- `nodeIds`: Selected node IDs.

#### `class MoveNodeEvent extends MindMapEvent`
- `nodeId`: Moved node ID.
- `oldParentId`: Previous parent ID.
- `newParentId`: New parent ID.
- `isReorder`: Whether move is sibling reorder.

#### `class ExpandNodeEvent extends MindMapEvent`
- `nodeId`: Target node ID.
- `expanded`: Expanded state.

#### `class BeginEditEvent extends MindMapEvent`
- `nodeId`: Node entering edit mode.

#### `class FinishEditEvent extends MindMapEvent`
- `nodeId`: Edited node ID.
- `newTopic`: Updated text.

#### `class HyperlinkClickEvent extends MindMapEvent`
- `nodeId`: Node ID whose link was clicked.
- `url`: Clicked URL.

#### `class NodeOperationEvent extends MindMapEvent`
- `operation`: Operation name.
- `nodeId`: Target node ID.

#### `class ArrowCreatedEvent extends MindMapEvent`
- `arrowId`: Created arrow ID.
- `fromNodeId`: Source node ID.
- `toNodeId`: Target node ID.

#### `class SummaryCreatedEvent extends MindMapEvent`
- `summaryId`: Created summary ID.
- `parentNodeId`: Parent node ID.

### `class RootNodeDeletionException implements Exception`
File: `lib/src/widgets/mind_map_controller.dart`

Field:
- `message`: Error message for forbidden root deletion.

### `class InvalidNodeIdException implements Exception`
File: `lib/src/widgets/mind_map_controller.dart`

Field:
- `message`: Error message for invalid node ID.

### `class MindMapController extends ChangeNotifier`
File: `lib/src/widgets/mind_map_controller.dart`

Constructor:
- `MindMapController({required MindMapData initialData, MindMapConfig config = const MindMapConfig()})`: Initializes data, selection, history, and zoom managers.

Getters:
- `repaintBoundaryKey`: Current repaint boundary key for export.
- `eventStream`: Broadcast stream of `MindMapEvent`.
- `isArrowCreationMode`: Arrow-creation mode flag.
- `arrowSourceNodeId`: Current arrow source node.
- `selectedArrowId`: Selected arrow.
- `isSummaryCreationMode`: Summary-creation mode flag.
- `summarySelectedNodeIds`: Temporary selected IDs for summary creation.
- `selectedSummaryId`: Selected summary.
- `isFocusMode`: Focus mode flag.
- `focusedNodeId`: Focused node ID.
- `localizedStrings`: Resolved built-in i18n strings.
- `defaultNewNodeTopic`: Default text for new nodes.
- `defaultSummaryLabel`: Default text for new summaries.
- `lastEvent`: Last emitted event.
- `selectionManager`: Internal `SelectionManager`.
- `zoomPanManager`: Internal `ZoomPanManager`.

Data/config methods:
- `getData()`: Returns current full map data.
- `updateConfig(...)`: Updates runtime config and notifies listeners.
- `refresh(...)`: Replaces data and resets selection/history context.
- `emitEvent(...)`: Emits event to callback and stream.
- `setViewportSize(...)`: Updates viewport size for centering and fit logic.
- `getSelectedNodeIds()`: Returns selected IDs.

Node methods:
- `addChildNode(...)`: Adds a child node.
- `addSiblingNode(...)`: Adds sibling node after target.
- `removeNode(...)`: Removes node (root is protected).
- `updateNode(...)`: Replaces a node object by ID.
- `updateNodeTopic(...)`: Updates only topic text.
- `commitNodeTopicEdit(...)`: Commits text edit with history recording.
- `toggleNodeExpanded(...)`: Toggles expanded state.
- `expandNode(...)`: Forces expanded state.
- `collapseNode(...)`: Forces collapsed state.
- `moveNodes(...)`: Batch move with conflict checks.
- `moveNode(...)`: Single-node move.
- `addParentNode(...)`: Inserts a parent above target node.

History methods:
- `undo()`: Undo latest operation.
- `redo()`: Redo latest undone operation.
- `canUndo()`: Query undo availability.
- `canRedo()`: Query redo availability.

Arrow methods:
- `startArrowCreationMode()`: Enters arrow-creation mode.
- `exitArrowCreationMode()`: Exits arrow-creation mode.
- `selectArrowSourceNode(...)`: Sets source node.
- `selectArrowTargetNode(...)`: Sets target and creates arrow.
- `addArrow({...})`: Adds arrow directly.
- `removeArrow(...)`: Removes arrow by ID.
- `updateArrow(...)`: Updates arrow object.
- `updateArrowControlPoints(...)`: Updates bezier control deltas.
- `selectArrow(...)`: Selects one arrow.
- `deselectArrow()`: Clears arrow selection.
- `getArrow(...)`: Returns arrow by ID.

Summary methods:
- `startSummaryCreationMode()`: Enters summary-creation mode.
- `exitSummaryCreationMode()`: Exits summary-creation mode.
- `toggleSummaryNodeSelection(...)`: Toggles temporary summary selection.
- `createSummaryFromSelection(...)`: Creates summary from temporary selection.
- `addSummary({...})`: Adds summary directly.
- `removeSummary(...)`: Removes summary by ID.
- `updateSummary(...)`: Updates summary object.
- `getSummary(...)`: Returns summary by ID.
- `selectSummary(...)`: Selects summary.
- `deselectSummary()`: Clears summary selection.

Theme/view methods:
- `setTheme(...)`: Sets current theme.
- `getTheme()`: Gets current theme.
- `centerView(...)`: Centers current map content at current zoom.
- `fitToView(...)`: Fits content to viewport with padding.
- `centerViewWhenReady()`: Defers fit/center until viewport is known.
- `setZoom(...)`: Programmatically sets zoom, optionally animated.
- `getZoom()`: Returns current zoom value.
- `setLayoutDirection(...)`: Changes global layout direction.
- `getLayoutDirection()`: Returns global layout direction.
- `centerOnNode(...)`: Centers viewport on one node position.

Clipboard/focus methods:
- `copyNode(...)`: Copies node subtree to internal clipboard.
- `pasteNode(...)`: Pastes clipboard subtree under parent.
- `focusNode(...)`: Enters focus mode on node subtree.
- `exitFocusMode()`: Exits focus mode.

Node style/metadata methods:
- `setNodeFontSize(...)`: Sets node font size.
- `setNodeColor(...)`: Sets text color.
- `setNodeBackground(...)`: Sets node background color.
- `setNodeFontWeight(...)`: Sets font weight.
- `addNodeTag(...)`: Adds tag.
- `removeNodeTag(...)`: Removes tag by text.
- `addNodeIcon(...)`: Adds icon.
- `removeNodeIcon(...)`: Removes icon.
- `setNodeHyperLink(...)`: Sets or clears hyperlink.
- `setNodeImage(...)`: Sets single image and syncs image fields.
- `addNodeImage(...)`: Appends one image.
- `clearNodeImages(...)`: Clears image fields.

Export methods:
- `exportToJson()`: Exports pretty JSON text.
- `exportToPng({...})`: Exports PNG bytes using offscreen render.
- `setRepaintBoundaryKey(...)`: Injects repaint key from widget.
- `setExportImageCache(...)`: Injects decoded image cache for export.

Widget coordination methods:
- `setNodePositionCallback(...)`: Registers node screen-position resolver callback.
- `setViewCompensationCallback(...)`: Registers post-layout drift compensation callback.

## Interaction

### `class SelectionManager extends ChangeNotifier`
File: `lib/src/interaction/selection_manager.dart`

Getters:
- `selectedNodeIds`: Immutable selected node ID list.
- `hasClipboardContent`: Clipboard availability flag.

Methods:
- `isSelected(...)`: Checks selected state.
- `copyToClipboard(...)`: Stores node in clipboard.
- `getFromClipboard()`: Retrieves clipboard node.
- `selectNode(...)`: Single-select.
- `addToSelection(...)`: Additive select.
- `removeFromSelection(...)`: Remove from selection.
- `toggleSelection(...)`: Toggle selected state.
- `selectNodes(...)`: Replace selection in one call.
- `clearSelection()`: Clears selection.
- `dispose()`: Clears resources.

### `class ZoomPanManager extends ChangeNotifier`
File: `lib/src/interaction/zoom_pan_manager.dart`

Fields/getters:
- `minScale` and `maxScale`: Zoom constraints.
- `transform`: Matrix for rendering transform.
- `scale`: Current zoom value.
- `translation`: Current pan offset.

Methods:
- `handlePanStart(...)`: Starts pan gesture tracking.
- `handlePanUpdate(...)`: Applies pan delta.
- `handlePanEnd()`: Ends pan gesture.
- `handleScaleStart(...)`: Starts pinch/scale gesture.
- `handleScaleUpdate(...)`: Applies scale update.
- `handleScaleEnd(...)`: Ends scale gesture.
- `handleMouseWheel(...)`: Applies wheel zoom.
- `setZoom(...)`: Programmatic zoom.
- `setTranslation(...)`: Programmatic pan.
- `centerOn(...)`: Moves a canvas point to viewport center.
- `reset()`: Restores identity transform.

### `class DragManager extends ChangeNotifier`
File: `lib/src/interaction/drag_manager.dart`

Getters:
- `isDragging`: Whether drag is active.
- `draggedNodeId`: Dragged node ID.
- `dragPosition`: Current drag position.
- `dropTargetNodeId`: Current drop target ID.
- `dropInsertType`: Current insertion mode.

Methods:
- `startDrag(...)`: Starts drag tracking.
- `updateDrag(...)`: Updates drag and resolves drop candidate.
- `resolveDropTargetNow(...)`: Forces immediate drop-target resolution.
- `endDrag()`: Finishes drag and clears state.
- `cancelDrag()`: Cancels drag and clears state.
- `dispose()`: Releases state.

### `class KeyboardHandler`
File: `lib/src/interaction/keyboard_handler.dart`

Fields:
- `controller`: Target controller.
- `onCenterView`: Optional center-view callback override.
- `onBeginEdit`: Optional begin-edit callback override.

Methods:
- `handleKeyEvent(...)`: Handles keyboard shortcuts and returns handled flag.
- `clearClipboard()`: Clears handler clipboard marker.

### `class GestureHandler`
File: `lib/src/interaction/gesture_handler.dart`

Fields:
- `controller`: Target controller.
- `nodeLayouts`: Current layout map for hit testing.
- `transform`: Current matrix transform.
- `isReadOnly`: Read-only interaction mode.
- `onBeginEdit`: Node edit callback.
- `onBeginEditSummary`: Summary edit callback.
- `onBeginEditArrow`: Arrow label edit callback.
- `onSelectionRectChanged`: Selection rectangle callback.
- `onShowContextMenu`: Context menu callback.
- `onTapEmptySpace`: Empty-space tap callback.
- `dragManager`: Optional drag manager.

Getter:
- `selectionRect`: Current drag-selection rectangle.

Methods:
- `updateContext(...)`: Updates layouts, transform, read-only flag.
- `handleTapDown(...)`: Handles tap-down.
- `handleTapUp(...)`: Handles tap-up with select/edit/hit-test behavior.
- `handleLongPress(...)`: Handles long press.
- `handleSecondaryTapUp(...)`: Handles secondary click.
- `handlePanStart(...)`: Handles drag start.
- `handleScaleStart(...)`: Handles scale/pan start for gesture detector.
- `handlePanUpdate(...)`: Handles drag update.
- `handleScaleUpdate(...)`: Handles scale/pan update.
- `handlePanEnd(...)`: Handles drag end.
- `handleScaleEnd(...)`: Handles scale end.
- `hitTestNode(...)`: Returns hit node ID or `null`.
- `hitTestExpandIndicator(...)`: Returns hit expand-indicator node ID or `null`.
- `hitTestHyperlinkIndicator(...)`: Returns hit hyperlink node ID or `null`.
- `hitTestSummary(...)`: Returns hit summary ID or `null`.
- `hitTestArrow(...)`: Returns hit arrow ID or `null`.
- `hitTestArrowControlPoint(...)`: Returns `(arrowId, controlPointIndex)` on control-point hit.

## History

### `abstract class Operation`
File: `lib/src/history/operation.dart`

Methods:
- `execute(...)`: Applies operation and returns updated data.
- `undo(...)`: Reverts operation and returns updated data.
- `description`: Operation description for logs/debugging.

### `class HistoryManager`
File: `lib/src/history/history_manager.dart`

Fields/getters:
- `maxHistorySize`: Max undo stack size.
- `canUndo`: Whether undo is available.
- `canRedo`: Whether redo is available.
- `undoCount`: Undo stack size.
- `redoCount`: Redo stack size.

Methods:
- `recordOperation(...)`: Pushes operation to undo stack and clears redo stack.
- `undo()`: Pops one undo entry and pushes it to redo stack.
- `redo()`: Pops one redo entry and pushes it to undo stack.
- `clear()`: Clears both stacks.

### `class HistoryEntry`
File: `lib/src/history/history_manager.dart`

Fields:
- `operation`: Operation instance.
- `selectionBefore`: Selection snapshot before operation.
- `selectionAfter`: Selection snapshot after operation.

### `class CreateNodeOperation implements Operation`
File: `lib/src/history/operations.dart`

Fields:
- `parentId`: Target parent ID.
- `newNode`: Node to insert.
- `insertIndex`: Optional insertion index.
- `parentWasCollapsed`: Parent collapsed state before operation.

Methods:
- `execute(...)`: Inserts node.
- `undo(...)`: Removes inserted node and restores parent collapse when needed.
- `description`: Human-readable operation summary.

### `class InsertParentOperation implements Operation`
File: `lib/src/history/operations.dart`

Fields:
- `nodeId`: Original child node ID.
- `oldParentId`: Original parent ID.
- `oldIndex`: Original child index.
- `newParent`: Inserted parent node.

Methods:
- `execute(...)`: Inserts new parent in tree.
- `undo(...)`: Restores original child at original position.
- `description`: Human-readable operation summary.

### `class DeleteNodeOperation implements Operation`
File: `lib/src/history/operations.dart`

Fields:
- `nodeId`: Deleted node ID.
- `parentId`: Original parent ID.
- `deletedNode`: Deleted node snapshot.
- `originalIndex`: Original index under parent.

Methods:
- `execute(...)`: Deletes node.
- `undo(...)`: Re-inserts node snapshot.
- `description`: Human-readable operation summary.

### `class EditNodeOperation implements Operation`
File: `lib/src/history/operations.dart`

Fields:
- `nodeId`: Target node ID.
- `oldTopic`: Previous text.
- `newTopic`: New text.

Methods:
- `execute(...)`: Applies `newTopic`.
- `undo(...)`: Restores `oldTopic`.
- `description`: Human-readable operation summary.

### `class MoveNodeOperation implements Operation`
File: `lib/src/history/operations.dart`

Fields:
- `nodeId`: Moved node ID.
- `oldParentId`: Previous parent ID.
- `newParentId`: New parent ID.
- `oldIndex`: Previous index.
- `newIndex`: New index.
- `movedNode`: Node snapshot.
- `targetWasCollapsed`: New parent collapsed state before move.

Methods:
- `execute(...)`: Applies move.
- `undo(...)`: Reverts move.
- `description`: Human-readable operation summary.

### `class StyleNodeOperation implements Operation`
File: `lib/src/history/operations.dart`

Fields:
- `nodeId`: Target node ID.
- `oldStyle`: Style before change.
- `newStyle`: Style after change.

Methods:
- `execute(...)`: Applies new style.
- `undo(...)`: Restores old style.
- `description`: Human-readable operation summary.

### `class ToggleExpandOperation implements Operation`
File: `lib/src/history/operations.dart`

Fields:
- `nodeId`: Target node ID.
- `oldExpanded`: Previous expanded state.
- `newExpanded`: New expanded state.

Methods:
- `execute(...)`: Applies new expand state.
- `undo(...)`: Restores previous expand state.
- `description`: Human-readable operation summary.

## I18n

### `enum MindMapLocale`
File: `lib/src/i18n/mind_map_strings.dart`

Values:
- `auto`: Resolve by system locale.
- `zh`: Force Chinese strings.
- `en`: Force English strings.

### `class MindMapStrings`
File: `lib/src/i18n/mind_map_strings.dart`

Static members:
- `zh`: Built-in Chinese string table.
- `en`: Built-in English string table.
- `resolve(...)`: Resolves effective language table by config + system locale.

Field groups:
- `menu*`: Context menu labels.
- `action*`: Common action labels.
- `dialogTitle*` and `field*`: Input dialog titles and field labels.
- `focusMode*`: Focus mode labels.
- `default*`: Default node/summary labels.
- `error*`: Error messages and templates.

Formatter methods:
- `focusModeTitle(String nodeTitle)`: Formats focus mode title text.
- `errorInvalidNodeId(String nodeId)`: Formats invalid-node error.
- `errorCannotFindParentOfNode(String nodeId)`: Formats parent-not-found error.
- `errorFailedToCreateSummary(Object error)`: Formats summary-creation error.
- `errorArrowNotFound(String arrowId)`: Formats arrow-not-found error.
- `errorSummaryNotFound(String summaryId)`: Formats summary-not-found error.
- `errorNodeNotFound(String nodeId)`: Formats node-not-found error.
- `errorInvalidChildRange(int start, int end)`: Formats child-range error.

## Maintenance

- Update this file when exported APIs change in `lib/mind_map_flutter.dart`.
- Re-check low-level classes (`*Renderer`, `GestureHandler`) before release because signatures may evolve faster.
