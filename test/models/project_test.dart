import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/models/project.dart';

void main() {
  group('Project', () {
    test('should create project with required fields', () {
      final project = Project(
        id: 'test-id',
        name: 'Test Project',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      expect(project.id, 'test-id');
      expect(project.name, 'Test Project');
      expect(project.description, isNull);
      expect(project.systemPrompt, isNull);
      expect(project.instructions, isNull);
      expect(project.isPinned, false);
    });

    test('should serialize to JSON and back', () {
      final project = Project(
        id: 'test-id',
        name: 'Test Project',
        description: 'A test description',
        systemPrompt: 'Be helpful',
        instructions: 'This is a Flutter project',
        colorValue: 0xFF4CAF50,
        iconName: 'code',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
        isPinned: true,
      );

      final json = project.toJson();
      final restored = Project.fromJson(json);

      expect(restored.id, project.id);
      expect(restored.name, project.name);
      expect(restored.description, project.description);
      expect(restored.systemPrompt, project.systemPrompt);
      expect(restored.instructions, project.instructions);
      expect(restored.colorValue, project.colorValue);
      expect(restored.iconName, project.iconName);
      expect(restored.isPinned, project.isPinned);
    });

    test('should generate full context from system prompt and instructions', () {
      final projectWithBoth = Project(
        id: '1',
        name: 'Test',
        systemPrompt: 'System prompt here',
        instructions: 'Instructions here',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(projectWithBoth.fullContext, contains('System prompt here'));
      expect(projectWithBoth.fullContext, contains('Instructions here'));
    });

    test('should return null for full context when no prompts set', () {
      final project = Project(
        id: '1',
        name: 'Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(project.fullContext, isNull);
    });

    test('should copy with updated fields', () {
      final project = Project(
        id: '1',
        name: 'Original',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = project.copyWith(
        name: 'Updated',
        isPinned: true,
      );

      expect(updated.name, 'Updated');
      expect(updated.isPinned, true);
      expect(updated.id, project.id);
    });

    test('should have correct color and icon getters', () {
      final project = Project(
        id: '1',
        name: 'Test',
        colorValue: 0xFF2196F3,
        iconName: 'code',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Use toARGB32() to avoid deprecated value property
      expect(project.color.toARGB32(), 0xFF2196F3);
      expect(project.icon, isNotNull);
    });

    test('available colors should not be empty', () {
      expect(Project.availableColors, isNotEmpty);
      expect(Project.availableColors.length, greaterThanOrEqualTo(5));
    });

    test('available icons should not be empty', () {
      expect(Project.availableIcons, isNotEmpty);
      expect(Project.availableIcons.length, greaterThanOrEqualTo(5));
    });

    test('equality is based on id', () {
      final project1 = Project(
        id: 'same-id',
        name: 'Project 1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final project2 = Project(
        id: 'same-id',
        name: 'Project 2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(project1, equals(project2));
    });
  });
}
