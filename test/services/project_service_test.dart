import 'package:flutter_test/flutter_test.dart';
import 'package:private_chat_hub/services/project_service.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StorageService storageService;
  late ProjectService projectService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storageService = StorageService();
    await storageService.init();
    projectService = ProjectService(storageService);
  });

  group('ProjectService', () {
    test('should return empty list when no projects exist', () {
      final projects = projectService.getProjects();
      expect(projects, isEmpty);
    });

    test('should create a project', () async {
      final project = await projectService.createProject(
        name: 'Test Project',
        description: 'A test project',
      );

      expect(project.name, 'Test Project');
      expect(project.description, 'A test project');
      expect(project.id, isNotEmpty);
    });

    test('should get project by ID', () async {
      final created = await projectService.createProject(name: 'Test');
      final retrieved = projectService.getProject(created.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Test');
    });

    test('should return null for non-existent project', () {
      final project = projectService.getProject('non-existent');
      expect(project, isNull);
    });

    test('should update a project', () async {
      final project = await projectService.createProject(name: 'Original');
      final updated = project.copyWith(name: 'Updated');

      await projectService.updateProject(updated);

      final retrieved = projectService.getProject(project.id);
      expect(retrieved!.name, 'Updated');
    });

    test('should delete a project', () async {
      final project = await projectService.createProject(name: 'To Delete');
      expect(projectService.getProject(project.id), isNotNull);

      await projectService.deleteProject(project.id);

      expect(projectService.getProject(project.id), isNull);
    });

    test('should toggle pinned status', () async {
      final project = await projectService.createProject(name: 'Test');
      expect(project.isPinned, false);

      await projectService.togglePinned(project.id);

      final retrieved = projectService.getProject(project.id);
      expect(retrieved!.isPinned, true);

      await projectService.togglePinned(project.id);

      final retrievedAgain = projectService.getProject(project.id);
      expect(retrievedAgain!.isPinned, false);
    });

    test('should sort projects with pinned first', () async {
      await projectService.createProject(name: 'Project A');
      final projectB = await projectService.createProject(name: 'Project B');
      await projectService.createProject(name: 'Project C');

      await projectService.togglePinned(projectB.id);

      final projects = projectService.getProjects();
      expect(projects.first.name, 'Project B');
      expect(projects.first.isPinned, true);
    });

    test('should get project count', () async {
      expect(projectService.getProjectCount(), 0);

      await projectService.createProject(name: 'Project 1');
      await projectService.createProject(name: 'Project 2');

      expect(projectService.getProjectCount(), 2);
    });

    test('should create project with all optional fields', () async {
      final project = await projectService.createProject(
        name: 'Full Project',
        description: 'Description',
        systemPrompt: 'Be helpful',
        instructions: 'This is a test project',
        colorValue: 0xFF4CAF50,
        iconName: 'code',
      );

      expect(project.name, 'Full Project');
      expect(project.description, 'Description');
      expect(project.systemPrompt, 'Be helpful');
      expect(project.instructions, 'This is a test project');
      expect(project.colorValue, 0xFF4CAF50);
      expect(project.iconName, 'code');
    });
  });
}
