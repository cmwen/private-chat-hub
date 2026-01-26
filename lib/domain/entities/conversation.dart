import 'package:freezed_annotation/freezed_annotation.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

enum ProviderType { ollama, litert, openai }

@freezed
class Conversation with _$Conversation {
  const factory Conversation({
    required int id,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? modelName,
    String? systemPrompt,
    @Default(false) bool isArchived,
    int? messageCount,
    @Default(ProviderType.ollama) ProviderType providerType,
    String? providerConfig,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  factory Conversation.create({
    required int id,
    String? title,
    String? modelName,
    String? systemPrompt,
  }) {
    final now = DateTime.now();
    return Conversation(
      id: id,
      title: title ?? 'New Conversation',
      createdAt: now,
      updatedAt: now,
      modelName: modelName,
      systemPrompt: systemPrompt,
    );
  }
}
