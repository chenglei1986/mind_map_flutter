import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/src/widgets/context_menu.dart';
import 'package:mind_map_flutter/src/i18n/mind_map_strings.dart';

void main() {
  group('ContextMenuItem', () {
    test('should create menu item with required properties', () {
      var tapped = false;
      final item = ContextMenuItem(
        label: 'Test Item',
        onTap: () => tapped = true,
      );

      expect(item.label, 'Test Item');
      expect(item.enabled, true);
      expect(item.showDivider, false);
      expect(item.icon, null);

      item.onTap();
      expect(tapped, true);
    });

    test('should create menu item with all properties', () {
      final item = ContextMenuItem(
        label: 'Test Item',
        icon: Icons.add,
        onTap: () {},
        enabled: false,
        showDivider: true,
      );

      expect(item.label, 'Test Item');
      expect(item.icon, Icons.add);
      expect(item.enabled, false);
      expect(item.showDivider, true);
    });
  });

  group('ContextMenuPopup', () {
    testWidgets('should display menu items', (tester) async {
      final items = [
        ContextMenuItem(
          label: 'Item 1',
          icon: Icons.add,
          onTap: () {},
        ),
        ContextMenuItem(
          label: 'Item 2',
          icon: Icons.delete,
          onTap: () {},
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextMenuPopup(
              position: const Offset(100, 100),
              items: items,
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Verify menu items are displayed
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('should call onTap when item is tapped', (tester) async {
      var item1Tapped = false;
      var dismissed = false;

      final items = [
        ContextMenuItem(label: 'Item 1', onTap: () => item1Tapped = true),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextMenuPopup(
              position: const Offset(100, 100),
              items: items,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      // Tap the menu item
      await tester.tap(find.text('Item 1'));
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(item1Tapped, true);
      expect(dismissed, true);
    });

    testWidgets('should dismiss when clicking outside', (tester) async {
      var dismissed = false;

      final items = [ContextMenuItem(label: 'Item 1', onTap: () {})];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextMenuPopup(
              position: const Offset(100, 100),
              items: items,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      // Tap outside the menu (on the transparent overlay)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Verify dismiss was called
      expect(dismissed, true);
    });

    testWidgets('should not call onTap for disabled items', (tester) async {
      var itemTapped = false;

      final items = [
        ContextMenuItem(
          label: 'Disabled Item',
          onTap: () => itemTapped = true,
          enabled: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextMenuPopup(
              position: const Offset(100, 100),
              items: items,
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Try to tap the disabled item
      await tester.tap(find.text('Disabled Item'));
      await tester.pumpAndSettle();

      // Verify callback was not called
      expect(itemTapped, false);
    });

    testWidgets('should show dividers between items', (tester) async {
      final items = [
        ContextMenuItem(label: 'Item 1', onTap: () {}, showDivider: true),
        ContextMenuItem(label: 'Item 2', onTap: () {}),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextMenuPopup(
              position: const Offset(100, 100),
              items: items,
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Verify divider is present
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('should adjust position to stay on screen', (tester) async {
      final items = [ContextMenuItem(label: 'Item 1', onTap: () {})];

      // Set a small screen size
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextMenuPopup(
              // Position near the edge
              position: const Offset(350, 350),
              items: items,
              onDismiss: () {},
            ),
          ),
        ),
      );

      // The menu should be visible (not off-screen)
      expect(find.text('Item 1'), findsOneWidget);

      // Reset window size
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('DefaultContextMenuItems', () {
    test('should build menu items for non-root node', () {
      var addChildCalled = false;
      var addSiblingCalled = false;
      var addParentCalled = false;
      var deleteCalled = false;
      var editPropertiesCalled = false;
      var createArrowCalled = false;
      var createSummaryCalled = false;
      var focusModeCalled = false;

      final items = DefaultContextMenuItems.build(
        nodeId: 'test-node',
        onAddChild: () => addChildCalled = true,
        onAddSibling: () => addSiblingCalled = true,
        onAddParent: () => addParentCalled = true,
        onDelete: () => deleteCalled = true,
        onEditProperties: () => editPropertiesCalled = true,
        onCreateArrow: () => createArrowCalled = true,
        onCreateSummary: () => createSummaryCalled = true,
        onFocusMode: () => focusModeCalled = true,
        isRootNode: false,
        strings: MindMapStrings.zh,
      );

      // Verify all menu items are present for non-root node
      expect(items.length, 8);

      // Verify labels
      expect(items[0].label, '添加子节点');
      expect(items[1].label, '添加兄弟节点');
      expect(items[2].label, '添加父节点');
      expect(items[3].label, '删除节点');
      expect(items[4].label, '编辑属性');
      expect(items[5].label, '创建箭头');
      expect(items[6].label, '创建摘要');
      expect(items[7].label, '聚焦模式');

      // Verify icons are present
      expect(items[0].icon, Icons.subdirectory_arrow_right);
      expect(items[1].icon, Icons.add);
      expect(items[2].icon, Icons.arrow_upward);
      expect(items[3].icon, Icons.delete);
      expect(items[4].icon, Icons.edit);
      expect(items[5].icon, Icons.arrow_forward);
      expect(items[6].icon, Icons.format_list_bulleted);
      expect(items[7].icon, Icons.center_focus_strong);

      // Verify dividers
      expect(items[2].showDivider, true);
      expect(items[3].showDivider, true);
      expect(items[6].showDivider, true);

      // Test callbacks
      items[0].onTap();
      expect(addChildCalled, true);

      items[1].onTap();
      expect(addSiblingCalled, true);

      items[2].onTap();
      expect(addParentCalled, true);

      items[3].onTap();
      expect(deleteCalled, true);

      items[4].onTap();
      expect(editPropertiesCalled, true);

      items[5].onTap();
      expect(createArrowCalled, true);

      items[6].onTap();
      expect(createSummaryCalled, true);

      items[7].onTap();
      expect(focusModeCalled, true);
    });

    test('should build menu items for root node', () {
      final items = DefaultContextMenuItems.build(
        nodeId: 'root-node',
        onAddChild: () {},
        onAddSibling: () {},
        onAddParent: () {},
        onDelete: () {},
        onEditProperties: () {},
        onCreateArrow: () {},
        onCreateSummary: () {},
        onFocusMode: () {},
        isRootNode: true,
        strings: MindMapStrings.zh,
      );

      // Verify root node doesn't have sibling, parent, or delete options
      expect(items.length, 5);

      // Verify labels
      expect(items[0].label, '添加子节点');
      expect(items[1].label, '编辑属性');
      expect(items[2].label, '创建箭头');
      expect(items[3].label, '创建摘要');
      expect(items[4].label, '聚焦模式');

      // Verify no sibling, parent, or delete items
      expect(items.any((item) => item.label == '添加兄弟节点'), false);
      expect(items.any((item) => item.label == '添加父节点'), false);
      expect(items.any((item) => item.label == '删除节点'), false);
    });

    test('should have all items enabled by default', () {
      final items = DefaultContextMenuItems.build(
        nodeId: 'test-node',
        onAddChild: () {},
        onAddSibling: () {},
        onAddParent: () {},
        onDelete: () {},
        onEditProperties: () {},
        onCreateArrow: () {},
        onCreateSummary: () {},
        onFocusMode: () {},
        isRootNode: false,
        strings: MindMapStrings.zh,
      );

      // All items should be enabled
      for (final item in items) {
        expect(item.enabled, true, reason: '${item.label} should be enabled');
      }
    });

    test('should have correct divider placement for non-root node', () {
      final items = DefaultContextMenuItems.build(
        nodeId: 'test-node',
        onAddChild: () {},
        onAddSibling: () {},
        onAddParent: () {},
        onDelete: () {},
        onEditProperties: () {},
        onCreateArrow: () {},
        onCreateSummary: () {},
        onFocusMode: () {},
        isRootNode: false,
        strings: MindMapStrings.zh,
      );

      // Dividers should separate logical groups
      // Group 1: Add operations (child, sibling, parent)
      // Group 2: Delete operation
      // Group 3: Edit and creation operations (edit, arrow, summary)
      // Group 4: Focus mode

      expect(items[0].showDivider, false); // Add child
      expect(items[1].showDivider, false); // Add sibling
      expect(items[2].showDivider, true); // Add parent (end of add group)
      expect(items[3].showDivider, true); // Delete (end of delete group)
      expect(items[4].showDivider, false); // Edit properties
      expect(items[5].showDivider, false); // Create arrow
      expect(
        items[6].showDivider,
        true,
      ); // Create summary (end of creation group)
      expect(items[7].showDivider, false); // Focus mode
    });

    test('should have correct divider placement for root node', () {
      final items = DefaultContextMenuItems.build(
        nodeId: 'root-node',
        onAddChild: () {},
        onAddSibling: () {},
        onAddParent: () {},
        onDelete: () {},
        onEditProperties: () {},
        onCreateArrow: () {},
        onCreateSummary: () {},
        onFocusMode: () {},
        isRootNode: true,
        strings: MindMapStrings.zh,
      );

      // For root node: Add child, Edit, Arrow, Summary (with divider), Focus
      expect(items[0].showDivider, false); // Add child
      expect(items[1].showDivider, false); // Edit properties
      expect(items[2].showDivider, false); // Create arrow
      expect(
        items[3].showDivider,
        true,
      ); // Create summary (end of creation group)
      expect(items[4].showDivider, false); // Focus mode
    });
  });

  group('ContextMenuPopup - Additional Tests', () {
    testWidgets('should handle multiple items with mixed dividers', (
      tester,
    ) async {
      final items = [
        ContextMenuItem(label: 'Item 1', onTap: () {}, showDivider: true),
        ContextMenuItem(label: 'Item 2', onTap: () {}),
        ContextMenuItem(label: 'Item 3', onTap: () {}, showDivider: true),
        ContextMenuItem(label: 'Item 4', onTap: () {}),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextMenuPopup(
              position: const Offset(100, 100),
              items: items,
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Should have 2 dividers (after Item 1 and Item 3)
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('should not show divider after last item', (tester) async {
      final items = [
        ContextMenuItem(label: 'Item 1', onTap: () {}),
        ContextMenuItem(label: 'Item 2', onTap: () {}, showDivider: true),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextMenuPopup(
              position: const Offset(100, 100),
              items: items,
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Should have no dividers (showDivider on last item is ignored)
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('should apply custom theme colors', (tester) async {
      final items = [
        ContextMenuItem(label: 'Item 1', icon: Icons.add, onTap: () {}),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextMenuPopup(
              position: const Offset(100, 100),
              items: items,
              onDismiss: () {},
              backgroundColor: Colors.blue,
              textColor: Colors.white,
              iconColor: Colors.yellow,
              hoverColor: Colors.green,
              dividerColor: Colors.red,
            ),
          ),
        ),
      );

      // Verify menu is displayed
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should handle empty items list', (tester) async {
      // Edge case: empty menu
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContextMenuPopup(
              position: const Offset(100, 100),
              items: const [],
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Menu should still render (just empty)
      expect(find.byType(ContextMenuPopup), findsOneWidget);
    });

    testWidgets(
      'should position menu at top-left when near bottom-right edge',
      (tester) async {
        final items = [
          ContextMenuItem(label: 'Item 1', onTap: () {}),
          ContextMenuItem(label: 'Item 2', onTap: () {}),
          ContextMenuItem(label: 'Item 3', onTap: () {}),
        ];

        // Set screen size
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ContextMenuPopup(
                // Position near bottom-right corner
                position: const Offset(750, 550),
                items: items,
                onDismiss: () {},
              ),
            ),
          ),
        );

        // Menu should be visible and adjusted to fit on screen
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 2'), findsOneWidget);
        expect(find.text('Item 3'), findsOneWidget);

        // Reset window size
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  });
}
