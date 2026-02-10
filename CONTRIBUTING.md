# Contributing to Mind Map Flutter

Thank you for your interest in contributing to Mind Map Flutter! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Setup](#development-setup)
4. [How to Contribute](#how-to-contribute)
5. [Coding Standards](#coding-standards)
6. [Testing Guidelines](#testing-guidelines)
7. [Documentation](#documentation)
8. [Pull Request Process](#pull-request-process)
9. [Reporting Bugs](#reporting-bugs)
10. [Suggesting Features](#suggesting-features)

## Code of Conduct

This project adheres to a code of conduct that all contributors are expected to follow. Please be respectful and constructive in all interactions.

### Our Standards

- Be welcoming and inclusive
- Be respectful of differing viewpoints
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (comes with Flutter)
- Git
- A code editor (VS Code, Android Studio, or IntelliJ IDEA recommended)

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/mind_map_flutter.git
   cd mind_map_flutter
   ```
3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/mind_map_flutter.git
   ```

## Development Setup

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run tests to ensure everything works:
   ```bash
   flutter test
   ```

3. Run an example:
   ```bash
   cd example
   flutter run
   ```

## How to Contribute

### Types of Contributions

We welcome various types of contributions:

- **Bug fixes**: Fix issues reported in the issue tracker
- **New features**: Implement new functionality
- **Documentation**: Improve or add documentation
- **Examples**: Add new example applications
- **Tests**: Add or improve test coverage
- **Performance**: Optimize existing code
- **Refactoring**: Improve code quality

### Contribution Workflow

1. **Check existing issues**: Look for existing issues or create a new one
2. **Discuss**: For major changes, discuss your approach in the issue first
3. **Create a branch**: Create a feature branch from `main`
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Make changes**: Implement your changes following our coding standards
5. **Test**: Add tests and ensure all tests pass
6. **Commit**: Make clear, atomic commits with descriptive messages
7. **Push**: Push your branch to your fork
8. **Pull Request**: Open a pull request to the main repository

## Coding Standards

### Dart Style Guide

Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style):

- Use `dart format` to format your code
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused
- Use const constructors where possible

### Code Organization

```
lib/
├── src/
│   ├── models/          # Data models
│   ├── widgets/         # Flutter widgets
│   ├── rendering/       # Custom painters
│   ├── layout/          # Layout engine
│   ├── interaction/     # Gesture handling
│   └── history/         # Undo/redo system
└── mind_map.dart        # Public API exports
```

### Naming Conventions

- **Classes**: PascalCase (e.g., `MindMapWidget`)
- **Functions/Methods**: camelCase (e.g., `addChildNode`)
- **Variables**: camelCase (e.g., `nodeData`)
- **Constants**: lowerCamelCase with `k` prefix (e.g., `kDefaultNodeTopic`)
- **Private members**: Prefix with underscore (e.g., `_controller`)

### Documentation Comments

Use documentation comments for public APIs:

```dart
/// Creates a new child node under the specified parent.
///
/// The [parentId] must be a valid node ID in the mind map.
/// If [topic] is not provided, a default topic will be used.
///
/// Example:
/// ```dart
/// controller.addChildNode('parent-id', topic: 'New Child');
/// ```
void addChildNode(String parentId, {String? topic}) {
  // Implementation
}
```

## Testing Guidelines

### Test Requirements

All contributions should include appropriate tests:

- **Unit tests**: Test individual functions and classes
- **Widget tests**: Test widget behavior
- **Integration tests**: Test component interactions

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/node_data_test.dart

# Run with coverage
flutter test --coverage
```

### Writing Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mind_map_flutter/mind_map_flutter.dart';

void main() {
  group('NodeData', () {
    test('should create node with default values', () {
      final node = NodeData.create(topic: 'Test');
      
      expect(node.topic, 'Test');
      expect(node.children, isEmpty);
      expect(node.expanded, isTrue);
    });

    test('should add child node', () {
      final parent = NodeData.create(topic: 'Parent');
      final child = NodeData.create(topic: 'Child');
      
      final updated = parent.addChild(child);
      
      expect(updated.children.length, 1);
      expect(updated.children.first.topic, 'Child');
    });
  });
}
```

### Test Coverage

- Aim for at least 80% code coverage
- Focus on testing public APIs
- Test edge cases and error conditions
- Use property-based tests for universal properties

## Documentation

### Types of Documentation

1. **Code comments**: Explain complex logic
2. **API documentation**: Document public APIs with dartdoc
3. **User guide**: Update USER_GUIDE.md for new features
4. **Examples**: Add examples for new features
5. **README**: Update README.md if needed

### Documentation Standards

- Use clear, concise language
- Provide code examples
- Explain the "why" not just the "what"
- Keep documentation up-to-date with code changes

## Pull Request Process

### Before Submitting

1. **Update your branch**: Rebase on the latest main
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run tests**: Ensure all tests pass
   ```bash
   flutter test
   ```

3. **Format code**: Format your code
   ```bash
   dart format .
   ```

4. **Analyze code**: Check for issues
   ```bash
   flutter analyze
   ```

5. **Update documentation**: Update relevant documentation

### Pull Request Template

When creating a pull request, include:

```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe the tests you added or ran

## Checklist
- [ ] Code follows style guidelines
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] All tests pass
- [ ] No new warnings
```

### Review Process

1. A maintainer will review your PR
2. Address any feedback or requested changes
3. Once approved, a maintainer will merge your PR

## Reporting Bugs

### Before Reporting

1. Check if the bug has already been reported
2. Try to reproduce the bug with the latest version
3. Gather relevant information (Flutter version, platform, etc.)

### Bug Report Template

```markdown
## Bug Description
Clear description of the bug

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What you expected to happen

## Actual Behavior
What actually happened

## Environment
- Flutter version:
- Dart version:
- Platform (Android/iOS/Web/Desktop):
- Device/Browser:

## Screenshots
If applicable, add screenshots

## Additional Context
Any other relevant information
```

## Suggesting Features

### Feature Request Template

```markdown
## Feature Description
Clear description of the feature

## Use Case
Why is this feature needed?

## Proposed Solution
How should this feature work?

## Alternatives Considered
Other approaches you've considered

## Additional Context
Any other relevant information
```

## Development Tips

### Hot Reload

Use hot reload for faster development:

```bash
# In the example directory
flutter run
# Press 'r' for hot reload
# Press 'R' for hot restart
```

### Debugging

Use Flutter DevTools for debugging:

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### Performance Profiling

Profile your changes:

```bash
flutter run --profile
# Use DevTools to analyze performance
```

## Questions?

If you have questions:

1. Check the [User Guide](doc/USER_GUIDE.md)
2. Check the [API Reference](doc/API_REFERENCE.md)
3. Search existing issues
4. Create a new issue with the "question" label

## Recognition

Contributors will be recognized in:

- The project README.md
- GitHub's contributors page

Thank you for contributing to Mind Map Flutter! 🎉
