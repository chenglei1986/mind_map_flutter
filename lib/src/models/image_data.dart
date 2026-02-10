import 'package:flutter/material.dart';

/// Image data for nodes
@immutable
class ImageData {
  final String url;
  final double width;
  final double height;
  final BoxFit fit;

  const ImageData({
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
  });

  ImageData copyWith({
    String? url,
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return ImageData(
      url: url ?? this.url,
      width: width ?? this.width,
      height: height ?? this.height,
      fit: fit ?? this.fit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'width': width,
      'height': height,
      'fit': fit.toString(),
    };
  }

  factory ImageData.fromJson(Map<String, dynamic> json) {
    return ImageData(
      url: json['url'] ?? '',
      width: json['width']?.toDouble() ?? 100.0,
      height: json['height']?.toDouble() ?? 100.0,
      fit: _parseBoxFit(json['fit']),
    );
  }

  static BoxFit _parseBoxFit(String? value) {
    if (value == null) return BoxFit.contain;
    if (value.contains('cover')) return BoxFit.cover;
    if (value.contains('fill')) return BoxFit.fill;
    if (value.contains('fitWidth')) return BoxFit.fitWidth;
    if (value.contains('fitHeight')) return BoxFit.fitHeight;
    if (value.contains('scaleDown')) return BoxFit.scaleDown;
    return BoxFit.contain;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageData &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          width == other.width &&
          height == other.height &&
          fit == other.fit;

  @override
  int get hashCode =>
      url.hashCode ^ width.hashCode ^ height.hashCode ^ fit.hashCode;
}
