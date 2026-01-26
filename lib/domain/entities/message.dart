import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

enum MessageRole { user, assistant, system }

enum MessageStatus { pending, sent, error }

@freezed
class Message with _$Message {
  const factory Message({
    required int id,
    required int conversationId,
    required MessageRole role,
    required String content,
    String? modelName,
    required DateTime createdAt,
    int? tokenCount,
    List<String>? images,
    List<String>? files,
    @Default(MessageStatus.sent) MessageStatus status,
    String? errorMessage,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  factory Message.user({
    required int id,
    required int conversationId,
    required String content,
    List<String>? images,
    List<String>? files,
  }) => Message(
    id: id,
    conversationId: conversationId,
    role: MessageRole.user,
    content: content,
    createdAt: DateTime.now(),
    images: images,
    files: files,
  );

  factory Message.assistant({
    required int id,
    required int conversationId,
    required String content,
    required String modelName,
    int? tokenCount,
  }) => Message(
    id: id,
    conversationId: conversationId,
    role: MessageRole.assistant,
    content: content,
    modelName: modelName,
    tokenCount: tokenCount,
    createdAt: DateTime.now(),
  );
}
