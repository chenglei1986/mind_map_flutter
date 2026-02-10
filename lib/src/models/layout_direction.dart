/// Layout direction for nodes
enum LayoutDirection {
  left,   // All nodes on the left side
  right,  // All nodes on the right side
  side,   // Nodes distributed on both sides
}

extension LayoutDirectionExtension on LayoutDirection {
  String toJson() {
    switch (this) {
      case LayoutDirection.left:
        return 'left';
      case LayoutDirection.right:
        return 'right';
      case LayoutDirection.side:
        return 'side';
    }
  }

  static LayoutDirection fromJson(String? value) {
    switch (value) {
      case 'left':
        return LayoutDirection.left;
      case 'right':
        return LayoutDirection.right;
      case 'side':
      default:
        return LayoutDirection.side;
    }
  }
}
