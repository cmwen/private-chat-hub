import 'package:private_chat_hub/core/utils/result.dart';
import 'package:private_chat_hub/domain/entities/conversation.dart';
import 'package:private_chat_hub/domain/entities/message.dart';

abstract class IChatRepository {
  Future<Result<List<Conversation>>> getConversations();

  Future<Result<Conversation>> getConversation(int id);

  Future<Result<Conversation>> createConversation({
    String? title,
    String? modelName,
    String? systemPrompt,
  });

  Future<Result<Conversation>> updateConversation(Conversation conversation);

  Future<Result<void>> deleteConversation(int id);

  Future<Result<void>> archiveConversation(int id, bool archived);

  Future<Result<List<Message>>> getMessages(
    int conversationId, {
    int limit = 50,
    int offset = 0,
  });

  Future<Result<Message>> createMessage(Message message);

  Future<Result<Message>> updateMessage(Message message);

  Future<Result<void>> deleteMessage(int id);

  Stream<Message> streamChatResponse({
    required int conversationId,
    required String prompt,
    required String modelName,
    List<String>? imagePaths,
    List<String>? filePaths,
  });

  Future<Result<void>> cancelStreamingResponse();

  Future<Result<List<Message>>> searchMessages(String query);
}
