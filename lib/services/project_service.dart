import 'dart:convert';
import 'package:private_chat_hub/models/project.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:uuid/uuid.dart';

/// Service for managing projects.
class ProjectService {
  final StorageService _storage;
  static const String _projectsKey = 'projects';

  ProjectService(this._storage);

  /// Gets all saved projects.
  List<Project> getProjects() {
    final jsonString = _storage.getString(_projectsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final projects = jsonList
          .map((json) => Project.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort: pinned first, then by updated date
      projects.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

      return projects;
    } catch (e) {
      return [];
    }
  }

  /// Saves projects to storage.
  Future<void> _saveProjects(List<Project> projects) async {
    final jsonString = jsonEncode(projects.map((p) => p.toJson()).toList());
    await _storage.setString(_projectsKey, jsonString);
  }

  /// Creates a new project.
  Future<Project> createProject({
    required String name,
    String? description,
    String? systemPrompt,
    String? instructions,
    int? colorValue,
    String? iconName,
  }) async {
    final project = Project(
      id: const Uuid().v4(),
      name: name,
      description: description,
      systemPrompt: systemPrompt,
      instructions: instructions,
      colorValue: colorValue ?? Project.availableColors[0],
      iconName: iconName ?? 'folder',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final projects = getProjects();
    projects.insert(0, project);
    await _saveProjects(projects);

    return project;
  }

  /// Gets a project by ID.
  Project? getProject(String id) {
    final projects = getProjects();
    try {
      return projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Updates an existing project.
  Future<void> updateProject(Project project) async {
    final projects = getProjects();
    final index = projects.indexWhere((p) => p.id == project.id);

    if (index != -1) {
      projects[index] = project.copyWith(updatedAt: DateTime.now());
      await _saveProjects(projects);
    }
  }

  /// Deletes a project by ID.
  Future<void> deleteProject(String id) async {
    final projects = getProjects();
    final updatedProjects = projects.where((p) => p.id != id).toList();
    await _saveProjects(updatedProjects);
  }

  /// Toggles the pinned status of a project.
  Future<void> togglePinned(String id) async {
    final projects = getProjects();
    final index = projects.indexWhere((p) => p.id == id);

    if (index != -1) {
      projects[index] = projects[index].copyWith(
        isPinned: !projects[index].isPinned,
        updatedAt: DateTime.now(),
      );
      await _saveProjects(projects);
    }
  }

  /// Gets the count of projects.
  int getProjectCount() {
    return getProjects().length;
  }
}
