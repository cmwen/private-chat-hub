import 'package:private_chat_hub/models/project.dart';
import 'package:private_chat_hub/repositories/project_repository.dart';
import 'package:private_chat_hub/services/knowledge_store_service.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:uuid/uuid.dart';

/// Service for managing projects.
class ProjectService {
  final ProjectRepository _repository;

  ProjectService(
    StorageService _, {
    ProjectRepository? repository,
    KnowledgeStoreService? knowledgeStoreService,
  }) : _repository =
           repository ??
           MarkdownProjectRepository(
             knowledgeStoreService ?? KnowledgeStoreService.instance,
           );

  /// Gets all saved projects.
  List<Project> getProjects() {
    final projects = _repository.getProjects();
    projects.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return projects;
  }

  /// Imports a project (inserts if not present, replaces if already exists).
  Future<void> importProject(Project project) async {
    await _repository.saveProject(project);
  }

  /// Creates a new project.
  Future<Project> createProject({
    required String name,
    String? description,
    String? systemPrompt,
    String? instructions,
    int? colorValue,
    String? iconName,
    String? modelName,
  }) async {
    final now = DateTime.now();
    final project = Project(
      id: const Uuid().v4(),
      name: name,
      description: description,
      systemPrompt: systemPrompt,
      instructions: instructions,
      colorValue: colorValue ?? Project.availableColors[0],
      iconName: iconName ?? 'folder',
      createdAt: now,
      updatedAt: now,
      modelName: modelName,
    );

    await _repository.saveProject(project);
    return project;
  }

  /// Gets a project by ID.
  Project? getProject(String id) {
    return _repository.getProject(id);
  }

  /// Updates an existing project.
  Future<void> updateProject(Project project) async {
    await _repository.saveProject(project.copyWith(updatedAt: DateTime.now()));
  }

  /// Deletes a project by ID.
  Future<void> deleteProject(String id) async {
    await _repository.deleteProject(id);
  }

  /// Toggles the pinned status of a project.
  Future<void> togglePinned(String id) async {
    final project = getProject(id);
    if (project == null) {
      return;
    }

    await _repository.saveProject(
      project.copyWith(isPinned: !project.isPinned, updatedAt: DateTime.now()),
    );
  }

  /// Gets the count of projects.
  int getProjectCount() {
    return getProjects().length;
  }
}
