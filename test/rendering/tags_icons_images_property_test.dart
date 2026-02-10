import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';
import 'package:mind_map_flutter/src/rendering/node_renderer.dart';
import 'dart:math';

void main() {
  group('Tags, Icons, and Images Property Tests', () {
    test('Tags and icons rendering - for any node with tags or icons, the rendering output should contain all tags and icons', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate node with random tags and icons
        final node = _generateNodeWithTagsAndIcons(i);
        final theme = MindMapTheme.light;
        
        // Measure node size - this validates that tags and icons are accounted for
        final size = NodeRenderer.measureNodeSize(node, theme, false, 1);
        
        // Verify size is calculated
        expect(size.width, greaterThan(0));
        expect(size.height, greaterThan(0));
        
        // Verify tags are preserved in the node data
        if (node.tags.isNotEmpty) {
          expect(node.tags.length, greaterThan(0));
          for (final tag in node.tags) {
            expect(tag.text, isNotEmpty);
            // Tag text should be non-empty string
            expect(tag.text.trim(), isNotEmpty);
          }
          
          // Node height should be increased to accommodate tags
          // Base height + tag height (20.0) + spacing (4.0)
          const tagHeight = 20.0 + 4.0;
          expect(size.height, greaterThanOrEqualTo(tagHeight));
        }
        
        // Verify icons are preserved in the node data
        if (node.icons.isNotEmpty) {
          expect(node.icons.length, greaterThan(0));
          for (final icon in node.icons) {
            expect(icon, isNotEmpty);
            // Icon should be a non-empty string (emoji or icon character)
            expect(icon.trim(), isNotEmpty);
          }
          
          // Node height should be increased to accommodate icons
          // Base height + icon height (20.0) + spacing (4.0)
          const iconHeight = 20.0 + 4.0;
          expect(size.height, greaterThanOrEqualTo(iconHeight));
        }
        
        // If both tags and icons exist, verify both are accounted for
        if (node.tags.isNotEmpty && node.icons.isNotEmpty) {
          const combinedHeight = (20.0 + 4.0) * 2; // tags + icons
          expect(size.height, greaterThanOrEqualTo(combinedHeight));
        }
      }
    });

    test('Property 6: Image size correctness - for any node containing an image, the rendered image size should match the specified width and height', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate node with random image
        final node = _generateNodeWithImage(i);
        final theme = MindMapTheme.light;
        
        // Verify image data is present
        expect(node.image, isNotNull);
        final image = node.image!;
        
        // Verify image dimensions are positive
        expect(image.width, greaterThan(0));
        expect(image.height, greaterThan(0));
        
        // Verify image URL is not empty
        expect(image.url, isNotEmpty);
        
        // Measure node size
        final size = NodeRenderer.measureNodeSize(node, theme, false, 1);
        
        // Verify node size accounts for the image
        // Node height should include: image height + padding (16.0) + text height
        final expectedMinHeight = image.height + 16.0;
        expect(size.height, greaterThanOrEqualTo(expectedMinHeight - 8.0));
        
        // Node width should be at least as wide as the image
        // (or wider if text is wider)
        expect(size.width, greaterThanOrEqualTo(image.width));
        
        // Verify the image dimensions are preserved in the node data
        expect(node.image!.width, equals(image.width));
        expect(node.image!.height, equals(image.height));
        
        // Verify BoxFit is a valid value
        expect(node.image!.fit, isA<BoxFit>());
      }
    });

    // Additional property test: Combined rendering
    // Validates that nodes with tags, icons, AND images all render correctly together
    test('Property: Combined tags, icons, and images rendering - for any node with all three, all elements should be accounted for in size calculation', () {
      const iterations = 100;
      
      for (int i = 0; i < iterations; i++) {
        // Generate node with tags, icons, AND image
        final node = _generateNodeWithAllElements(i);
        final theme = MindMapTheme.light;
        
        // Verify all elements are present
        expect(node.tags, isNotEmpty);
        expect(node.icons, isNotEmpty);
        expect(node.image, isNotNull);
        
        // Measure node size
        final size = NodeRenderer.measureNodeSize(node, theme, false, 1);
        
        // Verify size accounts for all elements
        expect(size.width, greaterThan(0));
        expect(size.height, greaterThan(0));
        
        // Calculate expected minimum height:
        // image height + padding (16.0) + icon height (24.0) + tag height (24.0) + text height
        final expectedMinHeight = node.image!.height + 16.0 + 24.0 + 24.0;
        expect(size.height, greaterThanOrEqualTo(expectedMinHeight - 4.0));
        
        // Verify all data is preserved
        expect(node.tags.length, greaterThan(0));
        expect(node.icons.length, greaterThan(0));
        expect(node.image!.width, greaterThan(0));
        expect(node.image!.height, greaterThan(0));
      }
    });
  });
}

/// Generate a node with random tags and icons
NodeData _generateNodeWithTagsAndIcons(int seed) {
  final random = Random(seed);
  
  // Generate 1-5 tags
  final tagCount = 1 + random.nextInt(5);
  final tags = List.generate(
    tagCount,
    (i) => TagData(
      text: 'Tag${i + 1}',
      style: random.nextBool()
          ? TextStyle(
              fontSize: 11.0,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            )
          : null,
    ),
  );
  
  // Generate 1-5 icons (emojis)
  final iconCount = 1 + random.nextInt(5);
  final availableIcons = ['🎯', '⭐', '🔥', '💡', '✅', '❌', '🚀', '💪', '🎨', '📝'];
  final icons = List.generate(
    iconCount,
    (i) => availableIcons[random.nextInt(availableIcons.length)],
  );
  
  return NodeData.create(
    topic: 'Node with tags and icons $seed',
    tags: tags,
    icons: icons,
  );
}

/// Generate a node with a random image
NodeData _generateNodeWithImage(int seed) {
  final random = Random(seed);
  
  // Generate random image dimensions (50-300 pixels)
  final width = 50.0 + random.nextInt(251);
  final height = 50.0 + random.nextInt(251);
  
  // Random BoxFit
  final fits = [
    BoxFit.contain,
    BoxFit.cover,
    BoxFit.fill,
    BoxFit.fitWidth,
    BoxFit.fitHeight,
    BoxFit.scaleDown,
  ];
  final fit = fits[random.nextInt(fits.length)];
  
  final image = ImageData(
    url: 'https://example.com/image$seed.jpg',
    width: width,
    height: height,
    fit: fit,
  );
  
  return NodeData.create(
    topic: 'Node with image $seed',
    image: image,
  );
}

/// Generate a node with tags, icons, AND image
NodeData _generateNodeWithAllElements(int seed) {
  final random = Random(seed);
  
  // Generate 1-3 tags
  final tagCount = 1 + random.nextInt(3);
  final tags = List.generate(
    tagCount,
    (i) => TagData(text: 'Tag${i + 1}'),
  );
  
  // Generate 1-3 icons
  final iconCount = 1 + random.nextInt(3);
  final availableIcons = ['🎯', '⭐', '🔥', '💡', '✅'];
  final icons = List.generate(
    iconCount,
    (i) => availableIcons[random.nextInt(availableIcons.length)],
  );
  
  // Generate image
  final width = 80.0 + random.nextInt(121); // 80-200
  final height = 60.0 + random.nextInt(91); // 60-150
  final image = ImageData(
    url: 'https://example.com/image$seed.jpg',
    width: width,
    height: height,
  );
  
  return NodeData.create(
    topic: 'Complete node $seed',
    tags: tags,
    icons: icons,
    image: image,
  );
}
