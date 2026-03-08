import '../services/ollama_client.dart';
import '../models/ollama_message.dart';
import '../models/ollama_tool.dart';
import '../models/ollama_response.dart';
import 'agent.dart';
import 'memory.dart';
import 'tools.dart';

/// Ollama-based agent implementation
class OllamaAgent implements Agent {
  final OllamaClient client;
  final String model;
  final Memory memory;
  final int maxIterations;
  final String? systemPrompt;
  final bool enableThinking;

  OllamaAgent({
    required this.client,
    required this.model,
    Memory? memory,
    this.maxIterations = 10,
    this.systemPrompt,
    this.enableThinking = false,
  }) : memory = memory ?? ConversationMemory();

  @override
  Future<AgentResponse> run(String input) async {
    return runWithTools(input, []);
  }

  @override
  Future<AgentResponse> runWithTools(String input, List<Tool> tools) async {
    final steps = <AgentStep>[];

    try {
      // Add system prompt if provided
      if (systemPrompt != null && memory.length == 0) {
        memory.addMessage(OllamaMessage.system(systemPrompt!));
      }

      // Add user input
      memory.addMessage(OllamaMessage.user(input));
      steps.add(AgentStep(type: 'input', content: input));

      String finalResponse = '';
      var iteration = 0;
      bool modelSupportsTools = tools.isNotEmpty; // Assume it does initially

      while (iteration < maxIterations) {
        iteration++;

        // Call Ollama with current conversation and tools
        final toolDefinitions = modelSupportsTools && tools.isNotEmpty
            ? tools
                  .map(
                    (t) => ToolDefinition(
                      name: t.name,
                      description: t.description,
                      parameters: t.parameters,
                    ),
                  )
                  .toList()
            : null;

        // Debug: log tools being sent
        print(
          '[OllamaAgent] Iteration $iteration/$maxIterations: '
          'Sending ${toolDefinitions?.length ?? 0} tools to model $model',
        );
        if (toolDefinitions != null && toolDefinitions.isNotEmpty) {
          for (final tool in toolDefinitions) {
            print(
              '[OllamaAgent]   • ${tool.name}: '
              '${tool.description.split(".").first}',
            );
          }
        } else {
          print(
            '[OllamaAgent]   (no tools — '
            'modelSupportsTools=$modelSupportsTools, '
            'tools.isEmpty=${tools.isEmpty})',
          );
        }

        print('[OllamaAgent] About to call client.chat()...');
        late OllamaChatResponse response;
        try {
          response = await client.chat(
            model,
            memory.getMessages(),
            think: enableThinking,
            tools: toolDefinitions,
          );
        } catch (e) {
          // Check if error is about tools not being supported
          if (e.toString().contains('does not support tools') &&
              modelSupportsTools) {
            print(
              '[OllamaAgent] Model $model does not support tools. Retrying without tools...',
            );
            modelSupportsTools = false;
            // Retry this iteration without tools
            continue;
          }
          // Re-throw other errors
          rethrow;
        }

        print(
          '[OllamaAgent] Response received: toolCalls=${response.message.toolCalls?.length ?? 0}, content length=${response.message.content.length}',
        );

        final message = response.message;
        memory.addMessage(message);

        // Capture thinking trace if present
        if (message.thinking != null && message.thinking!.isNotEmpty) {
          steps.add(AgentStep(type: 'thinking', content: message.thinking!));
        }

        // Check if model wants to call tools
        if (message.toolCalls != null && message.toolCalls!.isNotEmpty) {
          // Execute tools in parallel for better performance
          final toolResults = await Future.wait(
            message.toolCalls!.map((toolCall) async {
              // Skip tool calls with empty names BEFORE adding step
              if (toolCall.name.isEmpty) {
                print(
                  '[OllamaAgent] Skipping tool call with empty name (index: ${toolCall.index})',
                );
                return {
                  'toolName': '',
                  'result': 'Tool call had empty name',
                  'toolId': toolCall.id,
                  'skip': true,
                };
              }

              steps.add(
                AgentStep(
                  type: 'tool_call',
                  content: 'Calling ${toolCall.name}',
                  toolName: toolCall.name,
                  toolArgs: toolCall.arguments,
                ),
              );

              // Find tool, or null if not found
              Tool? tool;
              try {
                tool = tools.firstWhere((t) => t.name == toolCall.name);
              } catch (e) {
                tool = null;
              }

              if (tool == null) {
                print(
                  '[OllamaAgent] Tool not found: ${toolCall.name}. Available tools: ${tools.map((t) => t.name).join(", ")}',
                );
                return {
                  'toolName': toolCall.name,
                  'result': 'Tool not found: ${toolCall.name}',
                  'toolId': toolCall.id,
                  'skip': false,
                };
              }

              final result = await tool.execute(toolCall.arguments);

              steps.add(
                AgentStep(
                  type: 'tool_result',
                  content: result,
                  toolName: toolCall.name,
                ),
              );

              return {
                'result': result,
                'toolName': toolCall.name,
                'toolId': toolCall.id,
                'skip': false,
              };
            }),
          );

          // Add all tool results to memory with proper format
          for (final toolResult in toolResults) {
            // Skip if marked to skip (empty tool name)
            if (toolResult['skip'] == true) {
              continue;
            }

            final toolName = toolResult['toolName'] as String?;
            final toolId = toolResult['toolId'] as String?;
            final result = toolResult['result'] as String?;

            if (toolName != null && toolName.isNotEmpty && result != null) {
              memory.addMessage(
                OllamaMessage.tool(
                  result,
                  toolName: toolName,
                  toolId: toolId ?? '',
                ),
              );
            }
          }

          // Continue loop to get next response
          continue;
        }

        // No tool calls, this is the final answer
        finalResponse = message.content;
        steps.add(AgentStep(type: 'answer', content: finalResponse));
        break;
      }

      if (iteration >= maxIterations) {
        final errorMessage = finalResponse.isEmpty
            ? 'The model reached the maximum number of iterations ($maxIterations) without providing a final answer. This may indicate the model is having difficulty completing the task or tool calls are not being processed correctly.'
            : finalResponse;

        return AgentResponse(
          response: errorMessage,
          steps: steps,
          success: false,
          error: 'Max iterations reached ($maxIterations)',
        );
      }

      return AgentResponse(
        response: finalResponse,
        steps: steps,
        success: true,
      );
    } catch (e, stackTrace) {
      print('[OllamaAgent] ERROR: $e');
      print('[OllamaAgent] Stack trace: $stackTrace');
      return AgentResponse(
        response: '',
        steps: steps,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Run the agent with tools and stream the final text response.
  ///
  /// Identical to [runWithTools] for the tool-calling loop (each iteration
  /// uses [OllamaClient.chat] so that tool-call JSON is received atomically).
  /// Once the model produces a final answer without tool calls, the response
  /// is re-requested via [OllamaClient.chatStream] so that text tokens reach
  /// the caller incrementally.
  ///
  /// [onStep] is called synchronously for every [AgentStep] as it occurs.
  Stream<String> runStream(
    String input,
    List<Tool> tools, {
    void Function(AgentStep step)? onStep,
  }) async* {
    final steps = <AgentStep>[];
    try {
      if (systemPrompt != null && memory.length == 0) {
        memory.addMessage(OllamaMessage.system(systemPrompt!));
      }

      memory.addMessage(OllamaMessage.user(input));
      final inputStep = AgentStep(type: 'input', content: input);
      steps.add(inputStep);
      onStep?.call(inputStep);

      bool modelSupportsTools = tools.isNotEmpty;

      for (var iteration = 0; iteration < maxIterations; iteration++) {
        final toolDefinitions = modelSupportsTools && tools.isNotEmpty
            ? tools
                  .map(
                    (t) => ToolDefinition(
                      name: t.name,
                      description: t.description,
                      parameters: t.parameters,
                    ),
                  )
                  .toList()
            : null;

        print(
          '[OllamaAgent.runStream] Iteration ${iteration + 1}/$maxIterations: '
          'Sending ${toolDefinitions?.length ?? 0} tools to model $model',
        );

        late OllamaChatResponse response;
        try {
          response = await client.chat(
            model,
            memory.getMessages(),
            think: enableThinking,
            tools: toolDefinitions,
          );
        } catch (e) {
          if (e.toString().contains('does not support tools') &&
              modelSupportsTools) {
            print(
              '[OllamaAgent.runStream] Model $model does not support tools.'
              ' Retrying without tools...',
            );
            modelSupportsTools = false;
            continue;
          }
          rethrow;
        }

        final message = response.message;

        if (message.thinking != null && message.thinking!.isNotEmpty) {
          final thinkStep = AgentStep(
            type: 'thinking',
            content: message.thinking!,
          );
          steps.add(thinkStep);
          onStep?.call(thinkStep);
        }

        // Model requested tool calls – execute them and continue.
        if (message.toolCalls != null && message.toolCalls!.isNotEmpty) {
          memory.addMessage(message);

          final toolResults = await Future.wait(
            message.toolCalls!.map((toolCall) async {
              if (toolCall.name.isEmpty) {
                return {
                  'toolName': '',
                  'result': 'Tool call had empty name',
                  'toolId': toolCall.id,
                  'skip': true,
                };
              }

              final callStep = AgentStep(
                type: 'tool_call',
                content: 'Calling ${toolCall.name}',
                toolName: toolCall.name,
                toolArgs: toolCall.arguments,
              );
              steps.add(callStep);
              onStep?.call(callStep);

              Tool? tool;
              try {
                tool = tools.firstWhere((t) => t.name == toolCall.name);
              } catch (_) {
                tool = null;
              }

              if (tool == null) {
                return {
                  'toolName': toolCall.name,
                  'result': 'Tool not found: ${toolCall.name}',
                  'toolId': toolCall.id,
                  'skip': false,
                };
              }

              final result = await tool.execute(toolCall.arguments);

              final resultStep = AgentStep(
                type: 'tool_result',
                content: result,
                toolName: toolCall.name,
              );
              steps.add(resultStep);
              onStep?.call(resultStep);

              return {
                'result': result,
                'toolName': toolCall.name,
                'toolId': toolCall.id,
                'skip': false,
              };
            }),
          );

          for (final toolResult in toolResults) {
            if (toolResult['skip'] == true) continue;
            final toolName = toolResult['toolName'] as String?;
            final toolId = toolResult['toolId'] as String?;
            final result = toolResult['result'] as String?;
            if (toolName != null && toolName.isNotEmpty && result != null) {
              memory.addMessage(
                OllamaMessage.tool(
                  result,
                  toolName: toolName,
                  toolId: toolId ?? '',
                ),
              );
            }
          }

          continue; // next iteration with tool results
        }

        // No tool calls → this is the final answer.
        // The non-streaming call already returned the full text.  Instead
        // of displaying it all at once, re-request using chatStream so the
        // caller can display tokens progressively.
        // Note: message is NOT added to memory here – the streaming re-call
        // will produce the same content, which is added after streaming.
        print(
          '[OllamaAgent.runStream] Final response reached. '
          'Switching to chatStream for progressive display.',
        );

        final streamBuffer = StringBuffer();
        await for (final chunk in client.chatStream(
          model,
          memory.getMessages(),
          think: enableThinking,
        )) {
          if (chunk.message.content.isNotEmpty) {
            streamBuffer.write(chunk.message.content);
            yield chunk.message.content;
          }
        }

        // Add the complete final response to memory (for multi-turn continuity).
        memory.addMessage(OllamaMessage.assistant(streamBuffer.toString()));

        final answerStep = AgentStep(
          type: 'answer',
          content: streamBuffer.toString(),
        );
        steps.add(answerStep);
        onStep?.call(answerStep);

        return; // done
      }

      // Reached maxIterations without a final answer.
      print(
        '[OllamaAgent.runStream] Max iterations ($maxIterations) reached.',
      );
    } catch (e, stackTrace) {
      print('[OllamaAgent.runStream] ERROR: $e');
      print('[OllamaAgent.runStream] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Clear conversation memory
  void clearMemory() {
    memory.clear();
  }
}
