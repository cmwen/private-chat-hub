import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:private_chat_hub/models/project.dart';
import 'package:private_chat_hub/services/knowledge_store_service.dart';

/// Persists projects as Markdown entries in the knowledge store.
class ProjectRepository {
  final KnowledgeStoreService _knowledgeStore;

  ProjectRepository(this._knowledgeStore);

  List<Project> getProjects() {
    final files = _knowledgeStore.listMarkdownFiles(
      _knowledgeStore.projectsRoot,
      recursive: true,
    );

    return files.map(_readProject).toList();
  }

  Project? getProject(String id) {
    final file = _findProjectFile(id);
    if (file == null) {
      return null;
    }
    return _readProject(file);
  }

  Future<void> saveProject(Project project) async {
    final existingFile = _findProjectFile(project.id);
    final yearDirectory = Directory(
      p.join(
        _knowledgeStore.projectsRoot.path,
        '${project.createdAt.toUtc().year}',
      ),
    );
    final slug = _knowledgeStore.slugify(project.name);
    final file =
        existingFile ??
        File(
          p.join(
            yearDirectory.path,
            'project-${slug.isEmpty ? 'untitled' : slug}-${project.id}.md',
          ),
        );

    await _knowledgeStore.writeDocument(
      file,
      project.toJson(),
      _projectBody(project),
    );
  }

  Future<void> deleteProject(String id) async {
    final file = _findProjectFile(id);
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }

  File? _findProjectFile(String id) {
    final files = _knowledgeStore.listMarkdownFiles(
      _knowledgeStore.projectsRoot,
      recursive: true,
    );

    for (final file in files) {
      try {
        final document = _knowledgeStore.readDocument(file);
        if (document.metadata['id'] == id) {
          return file;
        }
      } on FormatException {
        continue;
      }
    }
    return null;
  }

  Project _readProject(File file) {
    final document = _knowledgeStore.readDocument(file);
    return Project.fromJson(document.metadata);
  }

  String _projectBody(Project project) {
    final buffer = StringBuffer()..writeln('# ${project.name}');

    if (project.description != null && project.description!.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(project.description);
    }

    if (project.systemPrompt != null && project.systemPrompt!.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## System Prompt')
        ..writeln()
        ..writeln(project.systemPrompt);
    }

    if (project.instructions != null && project.instructions!.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Instructions')
        ..writeln()
        ..writeln(project.instructions);
    }

    return buffer.toString().trimRight();
  }
}

class MarkdownProjectRepository extends ProjectRepository {
  MarkdownProjectRepository(super.knowledgeStore);
}
