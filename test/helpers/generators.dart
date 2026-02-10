import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

final _random = Random();

/// Generate a random NodeData with random children
NodeData generateRandomNode({
  int maxDepth = 3,
  int currentDepth = 0,
  int maxChildren = 5,
}) {
  final childCount = currentDepth < maxDepth ? _random.nextInt(maxChildren) : 0;
  
  return NodeData.create(
    topic: 'Node ${_random.nextInt(1000)}',
    expanded: _random.nextBool(),
    children: List.generate(
      childCount,
      (_) => generateRandomNode(
        maxDepth: maxDepth,
        currentDepth: currentDepth + 1,
        maxChildren: maxChildren,
      ),
    ),
    tags: _random.nextBool()
        ? [TagData(text: 'Tag ${_random.nextInt(100)}')]
        : [],
    icons: _random.nextBool() 
        ? [['🎯', '⭐'][_random.nextInt(2)]]
        : [],
    branchColor: _random.nextBool()
        ? Color(0xFF000000 + _random.nextInt(0xFFFFFF))
        : null,
  );
}

/// Generate a random MindMapData
MindMapData generateRandomMindMapData({
  int maxDepth = 2,
  int maxChildren = 3,
  int maxArrows = 3,
  int maxSummaries = 2,
}) {
  final rootNode = generateRandomNode(
    maxDepth: maxDepth,
    maxChildren: maxChildren,
  );
  
  // Collect all node IDs for arrows
  final nodeIds = <String>[];
  void collectIds(NodeData node) {
    nodeIds.add(node.id);
    for (final child in node.children) {
      collectIds(child);
    }
  }
  collectIds(rootNode);
  
  // Generate random arrows
  final arrows = <ArrowData>[];
  final arrowCount = min(maxArrows, nodeIds.length > 1 ? _random.nextInt(maxArrows + 1) : 0);
  for (int i = 0; i < arrowCount; i++) {
    if (nodeIds.length >= 2) {
      final fromId = nodeIds[_random.nextInt(nodeIds.length)];
      final toId = nodeIds[_random.nextInt(nodeIds.length)];
      if (fromId != toId) {
        arrows.add(ArrowData.create(
          fromNodeId: fromId,
          toNodeId: toId,
          label: _random.nextBool() ? 'Arrow $i' : null,
          bidirectional: _random.nextBool(),
        ));
      }
    }
  }
  
  // Generate random summaries
  final summaries = <SummaryData>[];
  final summaryCount = _random.nextInt(maxSummaries + 1);
  for (int i = 0; i < summaryCount; i++) {
    if (rootNode.children.isNotEmpty) {
      final maxIndex = rootNode.children.length - 1;
      final start = _random.nextInt(maxIndex + 1);
      final end = start + _random.nextInt(maxIndex - start + 1);
      summaries.add(SummaryData.create(
        parentNodeId: rootNode.id,
        startIndex: start,
        endIndex: end,
        label: _random.nextBool() ? 'Summary $i' : null,
      ));
    }
  }
  
  return MindMapData(
    nodeData: rootNode,
    arrows: arrows,
    summaries: summaries,
    direction: LayoutDirection.values[_random.nextInt(3)],
    theme: _random.nextBool() ? MindMapTheme.light : MindMapTheme.dark,
  );
}

/// Collect all node IDs from a tree
Set<String> collectAllNodeIds(NodeData node) {
  final ids = <String>{node.id};
  for (final child in node.children) {
    ids.addAll(collectAllNodeIds(child));
  }
  return ids;
}
