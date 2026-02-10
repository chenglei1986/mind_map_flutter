import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'node_style.dart';
import 'tag_data.dart';
import 'image_data.dart';
import 'layout_direction.dart';

const _uuid = Uuid();

/// Node data model with immutable structure
@immutable
class NodeData {
  final String id;
  final String topic;
  final NodeStyle? style;
  final List<NodeData> children;
  final List<TagData> tags;
  final List<String> icons;
  final String? hyperLink;
  final bool expanded;
  final LayoutDirection? direction;
  final ImageData? image;
  final List<ImageData> images;
  final Color? branchColor;
  final String? note;

  const NodeData({
    required this.id,
    required this.topic,
    this.style,
    this.children = const [],
    this.tags = const [],
    this.icons = const [],
    this.hyperLink,
    this.expanded = true,
    this.direction,
    this.image,
    this.images = const [],
    this.branchColor,
    this.note,
  });

  /// Returns normalized images for rendering/business logic.
  /// - Prefer `images` when present.
  /// - Fall back to legacy single `image` field.
  List<ImageData> get effectiveImages {
    if (images.isNotEmpty) return images;
    if (image != null) return [image!];
    return const [];
  }

  List<ImageData> get _normalizedImages {
    if (images.isNotEmpty) return images;
    if (image != null) return [image!];
    return const [];
  }

  /// Generate a new unique ID
  static String generateId() => _uuid.v4();

  /// Create a new node with a generated UUID
  factory NodeData.create({
    String? id,
    required String topic,
    NodeStyle? style,
    List<NodeData> children = const [],
    List<TagData> tags = const [],
    List<String> icons = const [],
    String? hyperLink,
    bool expanded = true,
    LayoutDirection? direction,
    ImageData? image,
    List<ImageData> images = const [],
    Color? branchColor,
    String? note,
  }) {
    return NodeData(
      id: id ?? _uuid.v4(),
      topic: topic,
      style: style,
      children: children,
      tags: tags,
      icons: icons,
      hyperLink: hyperLink,
      expanded: expanded,
      direction: direction,
      image: image,
      images: images,
      branchColor: branchColor,
      note: note,
    );
  }

  NodeData copyWith({
    String? id,
    String? topic,
    NodeStyle? style,
    List<NodeData>? children,
    List<TagData>? tags,
    List<String>? icons,
    String? hyperLink,
    bool? expanded,
    LayoutDirection? direction,
    ImageData? image,
    List<ImageData>? images,
    Color? branchColor,
    String? note,
  }) {
    return NodeData(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      style: style ?? this.style,
      children: children ?? this.children,
      tags: tags ?? this.tags,
      icons: icons ?? this.icons,
      hyperLink: hyperLink ?? this.hyperLink,
      expanded: expanded ?? this.expanded,
      direction: direction ?? this.direction,
      image: image ?? this.image,
      images: images ?? this.images,
      branchColor: branchColor ?? this.branchColor,
      note: note ?? this.note,
    );
  }

  NodeData addChild(NodeData child) {
    return copyWith(children: [...children, child]);
  }

  NodeData removeChild(String childId) {
    return copyWith(children: children.where((c) => c.id != childId).toList());
  }

  NodeData updateChild(String childId, NodeData newChild) {
    return copyWith(
      children: children.map((c) => c.id == childId ? newChild : c).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic': topic,
      if (style != null) 'style': style!.toJson(),
      if (children.isNotEmpty)
        'children': children.map((c) => c.toJson()).toList(),
      if (tags.isNotEmpty) 'tags': tags.map((t) => t.toJson()).toList(),
      if (icons.isNotEmpty) 'icons': icons,
      if (hyperLink != null) 'hyperLink': hyperLink,
      'expanded': expanded,
      if (direction != null) 'direction': direction!.toJson(),
      if (image != null) 'image': image!.toJson(),
      if (images.isNotEmpty)
        'images': images.map((img) => img.toJson()).toList(),
      if (branchColor != null) 'branchColor': branchColor!.toARGB32(),
      if (note != null) 'note': note,
    };
  }

  factory NodeData.fromJson(Map<String, dynamic> json) {
    final parsedSingleImage = json['image'] != null
        ? ImageData.fromJson(json['image'])
        : null;
    final parsedImages = json['images'] != null
        ? (json['images'] as List).map((i) => ImageData.fromJson(i)).toList()
        : <ImageData>[];

    final normalizedSingleImage =
        parsedSingleImage ??
        (parsedImages.isNotEmpty ? parsedImages.first : null);

    return NodeData(
      id: json['id'] ?? _uuid.v4(),
      topic: json['topic'] ?? 'New Node',
      style: json['style'] != null ? NodeStyle.fromJson(json['style']) : null,
      children: json['children'] != null
          ? (json['children'] as List).map((c) => NodeData.fromJson(c)).toList()
          : [],
      tags: json['tags'] != null
          ? (json['tags'] as List).map((t) => TagData.fromJson(t)).toList()
          : [],
      icons: json['icons'] != null ? List<String>.from(json['icons']) : [],
      hyperLink: json['hyperLink'],
      expanded: json['expanded'] ?? true,
      direction: json['direction'] != null
          ? LayoutDirectionExtension.fromJson(json['direction'])
          : null,
      image: normalizedSingleImage,
      images: parsedImages,
      branchColor: json['branchColor'] != null
          ? Color(json['branchColor'])
          : null,
      note: json['note'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          topic == other.topic &&
          style == other.style &&
          _listEquals(children, other.children) &&
          _listEquals(tags, other.tags) &&
          _listEquals(icons, other.icons) &&
          hyperLink == other.hyperLink &&
          expanded == other.expanded &&
          direction == other.direction &&
          _listEquals(_normalizedImages, other._normalizedImages) &&
          branchColor == other.branchColor &&
          note == other.note;

  @override
  int get hashCode =>
      id.hashCode ^
      topic.hashCode ^
      style.hashCode ^
      children.hashCode ^
      tags.hashCode ^
      icons.hashCode ^
      hyperLink.hashCode ^
      expanded.hashCode ^
      direction.hashCode ^
      _imagesHash(_normalizedImages) ^
      branchColor.hashCode ^
      note.hashCode;

  static int _imagesHash(List<ImageData> images) {
    int hash = 0;
    for (final image in images) {
      hash = 0x1fffffff & (hash + image.hashCode);
      hash = 0x1fffffff & (hash + ((hash & 0x0007ffff) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((hash & 0x03ffffff) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((hash & 0x00003fff) << 15));
    return hash;
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
