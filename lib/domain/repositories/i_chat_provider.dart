import 'dart:async';

abstract class ChatProvider {
  Stream<String> streamChat({
    required String model,
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
  });

  Future<void> dispose();

  String get providerName;
}
