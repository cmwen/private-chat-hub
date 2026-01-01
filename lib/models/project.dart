import 'package:flutter/material.dart';

/// Represents a project that groups related conversations with shared context.
class Project {
  final String id;
  final String name;
  final String? description;
  final String? systemPrompt;
  final String? instructions;
  final int colorValue;
  final String iconName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  const Project({
    required this.id,
    required this.name,
    this.description,
    this.systemPrompt,
    this.instructions,
    this.colorValue = 0xFF2196F3, // Default blue
    this.iconName = 'folder',
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  /// Gets the color for this project.
  Color get color => Color(colorValue);

  /// Gets the icon for this project.
  IconData get icon => _iconFromName(iconName);

  /// Gets the full context to prepend to conversations.
  String? get fullContext {
    final parts = <String>[];

    if (systemPrompt != null && systemPrompt!.isNotEmpty) {
      parts.add(systemPrompt!);
    }

    if (instructions != null && instructions!.isNotEmpty) {
      parts.add('\n\nProject Instructions:\n$instructions');
    }

    return parts.isEmpty ? null : parts.join('\n');
  }

  /// Creates a Project from JSON map.
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      systemPrompt: json['systemPrompt'] as String?,
      instructions: json['instructions'] as String?,
      colorValue: json['colorValue'] as int? ?? 0xFF2196F3,
      iconName: json['iconName'] as String? ?? 'folder',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  /// Converts Project to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'systemPrompt': systemPrompt,
      'instructions': instructions,
      'colorValue': colorValue,
      'iconName': iconName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned,
    };
  }

  /// Creates a copy with updated fields.
  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? systemPrompt,
    String? instructions,
    int? colorValue,
    String? iconName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      instructions: instructions ?? this.instructions,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  /// Available project colors.
  static const List<int> availableColors = [
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFFF44336, // Red
    0xFFFF9800, // Orange
    0xFF9C27B0, // Purple
    0xFF00BCD4, // Cyan
    0xFFE91E63, // Pink
    0xFF795548, // Brown
    0xFF607D8B, // Blue Grey
    0xFF009688, // Teal
  ];

  /// Available project icons.
  static const List<String> availableIcons = [
    'folder',
    'code',
    'work',
    'school',
    'science',
    'lightbulb',
    'chat',
    'article',
    'build',
    'explore',
    'favorite',
    'star',
  ];

  static IconData _iconFromName(String name) {
    switch (name) {
      case 'folder':
        return Icons.folder;
      case 'code':
        return Icons.code;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'science':
        return Icons.science;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'chat':
        return Icons.chat;
      case 'article':
        return Icons.article;
      case 'build':
        return Icons.build;
      case 'explore':
        return Icons.explore;
      case 'favorite':
        return Icons.favorite;
      case 'star':
        return Icons.star;
      default:
        return Icons.folder;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
