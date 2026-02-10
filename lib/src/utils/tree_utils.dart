import '../models/node_data.dart';
import '../i18n/mind_map_strings.dart';
import 'dart:ui' as ui;

/// Utility functions for tree operations
class TreeUtils {
  /// Find the minimum common parent (MCP) of multiple nodes
  ///
  /// This algorithm finds the lowest common ancestor of a set of nodes,
  /// similar to mind-elixir-core's calcRange function.
  ///
  /// Returns a tuple of (parentId, startIndex, endIndex) representing:
  /// - parentId: The ID of the common parent node
  /// - startIndex: The index of the first child in the range
  /// - endIndex: The index of the last child in the range
  ///
  /// Throws StateError if:
  /// - No nodes are provided
  /// - Root node is selected
  /// - Nodes don't share a common parent at the same level
  ///
  static (String, int, int) findMinimumCommonParent(
    NodeData root,
    List<String> nodeIds, {
    MindMapStrings? strings,
  }) {
    final l10n =
        strings ??
        MindMapStrings.resolve(
          MindMapLocale.auto,
          ui.PlatformDispatcher.instance.locale,
        );

    if (nodeIds.isEmpty) {
      throw StateError(l10n.errorNoNodesSelected);
    }

    // Special case: single node
    if (nodeIds.length == 1) {
      final nodeId = nodeIds.first;
      final node = _findNode(root, nodeId);
      if (node == null) {
        throw StateError(l10n.errorNodeNotFound(nodeId));
      }

      final parent = _findParent(root, nodeId);
      if (parent == null) {
        throw StateError(l10n.errorCannotSelectRootNode);
      }

      final index = parent.children.indexWhere((c) => c.id == nodeId);
      return (parent.id, index, index);
    }

    // Build parent chains for all nodes
    final parentChains = <List<_ParentChainNode>>[];
    int maxLen = 0;

    for (final nodeId in nodeIds) {
      final node = _findNode(root, nodeId);
      if (node == null) {
        throw StateError(l10n.errorNodeNotFound(nodeId));
      }

      final chain = _buildParentChain(root, nodeId);
      if (chain.isEmpty) {
        throw StateError(l10n.errorCannotSelectRootNode);
      }

      parentChains.add(chain);
      if (chain.length > maxLen) {
        maxLen = chain.length;
      }
    }

    // Find the minimum common parent by comparing chains
    int mcpIndex = 0;

    findMcp:
    for (int i = 0; i < maxLen; i++) {
      final baseNode = parentChains[0].length > i
          ? parentChains[0][i].node
          : null;
      if (baseNode == null) break;

      // Check if all chains have the same node at this level
      for (int j = 1; j < parentChains.length; j++) {
        final chain = parentChains[j];
        if (chain.length <= i || chain[i].node.id != baseNode.id) {
          break findMcp;
        }
      }

      mcpIndex = i + 1; // Move to next level
    }

    if (mcpIndex == 0) {
      throw StateError(l10n.errorCannotSelectRootNode);
    }

    // Get the parent node and calculate the range
    // mcpIndex points to the level after the common parent
    final parentNode = parentChains[0][mcpIndex - 1].node;

    // Collect all indices at the MCP level
    final indices = <int>[];
    for (final chain in parentChains) {
      if (chain.length > mcpIndex - 1) {
        indices.add(chain[mcpIndex - 1].index);
      }
    }

    // Sort indices to get the range
    indices.sort();
    final startIndex = indices.first;
    final endIndex = indices.last;

    return (parentNode.id, startIndex, endIndex);
  }

  /// Build a parent chain from root to the specified node
  ///
  /// Returns a list of (node, index) pairs representing the path from root to node,
  /// where index is the position of each node in its parent's children list.
  static List<_ParentChainNode> _buildParentChain(
    NodeData root,
    String nodeId,
  ) {
    final chain = <_ParentChainNode>[];

    void traverse(NodeData current, List<_ParentChainNode> currentChain) {
      if (current.id == nodeId) {
        chain.addAll(currentChain);
        return;
      }

      for (int i = 0; i < current.children.length; i++) {
        final child = current.children[i];
        final newChain = List<_ParentChainNode>.from(currentChain)
          ..add(_ParentChainNode(current, i));
        traverse(child, newChain);
        if (chain.isNotEmpty) return;
      }
    }

    traverse(root, []);
    return chain;
  }

  /// Find a node in the tree by ID
  static NodeData? _findNode(NodeData node, String nodeId) {
    if (node.id == nodeId) return node;

    for (final child in node.children) {
      final found = _findNode(child, nodeId);
      if (found != null) return found;
    }

    return null;
  }

  /// Find the parent of a node in the tree
  static NodeData? _findParent(NodeData node, String childId) {
    for (final child in node.children) {
      if (child.id == childId) return node;
    }

    for (final child in node.children) {
      final parent = _findParent(child, childId);
      if (parent != null) return parent;
    }

    return null;
  }
}

/// Internal class to represent a node in the parent chain
class _ParentChainNode {
  final NodeData node;
  final int index;

  _ParentChainNode(this.node, this.index);
}
